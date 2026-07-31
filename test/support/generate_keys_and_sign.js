const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const configDir = path.resolve(__dirname, '../../config');
if (!fs.existsSync(configDir)) fs.mkdirSync(configDir, { recursive: true });

const privateKeyPath = path.resolve(configDir, 'sdui_ed25519_private.key');
const signedConfigPath = path.resolve(configDir, 'external_sdui_filters_signed.json');

let privateKeyPem;
if (!fs.existsSync(privateKeyPath)) {
  const { privateKey } = crypto.generateKeyPairSync('ed25519');
  privateKeyPem = privateKey.export({ type: 'pkcs8', format: 'pem' });
  fs.writeFileSync(privateKeyPath, privateKeyPem, { mode: 0o600 });
} else {
  privateKeyPem = fs.readFileSync(privateKeyPath, 'utf8');
}

const privateKey = crypto.createPrivateKey(privateKeyPem);
const publicKey = crypto.createPublicKey(privateKey);
const rawPublicKey = publicKey.export({ type: 'spki', format: 'der' });
const pubKeyHex = rawPublicKey.subarray(rawPublicKey.length - 32).toString('hex');

const payload = {
  schemaVersion: 1,
  configVersion: 1,
  issuedAt: new Date().toISOString(),
  expiresAt: '2030-01-01T00:00:00Z',
  keyId: 'ed25519-prod-key-2',
  minAppVersion: '1.0.0',
  screenId: 'custody_screen',
  defaultFilterId: 'all',
  filters: [
    {
      id: 'all',
      label: 'جميع العهد (محدث من السيرفر الأصلي)',
      enabled: true,
      order: 1,
      icon: 'inventory_2_outlined',
      colorHex: '#18B2B0',
      statuses: []
    },
    {
      id: 'under_action',
      label: 'تحت الإجراء الميداني',
      enabled: true,
      order: 2,
      icon: 'pending_actions_rounded',
      colorHex: '#FFB300',
      statuses: ['UNDER_ACTION']
    }
  ]
};

const sortKeys = (obj) => {
  if (Array.isArray(obj)) return obj.map(sortKeys);
  if (obj !== null && typeof obj === 'object') {
    return Object.keys(obj).sort().reduce((acc, k) => {
      acc[k] = sortKeys(obj[k]);
      return acc;
    }, {});
  }
  return obj;
};

const canonicalJson = JSON.stringify(sortKeys(payload));
const signatureHex = crypto.sign(null, Buffer.from(canonicalJson, 'utf8'), privateKey).toString('hex');

fs.writeFileSync(signedConfigPath, JSON.stringify({
  publicKeyHex: pubKeyHex,
  signature: signatureHex,
  data: payload
}, null, 2));

console.log('Test fixtures generated safely in test/support');
