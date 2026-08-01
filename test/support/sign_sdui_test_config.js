#!/usr/bin/env node
/**
 * sign_sdui_test_config.js
 * Generates a signed SDUI filter config response for Flutter tests.
 *
 * Usage: node sign_sdui_test_config.js <configVersion> <firstFilterLabel>
 *
 * Test-only: uses a dedicated test Ed25519 private key (not the production key).
 * privHex = 9783f2db9009fc941d8cec24dfe6766980fc339f0a0982d860613ec84d5b0983
 * pubHex  = 2e9ca1424ed90055b96ab8dd4e64d82e84436d5a2ebc1c8a8fbb6d878eeb933f
 */
'use strict';

const crypto = require('crypto');

const TEST_PRIV_HEX = '9783f2db9009fc941d8cec24dfe6766980fc339f0a0982d860613ec84d5b0983';
const TEST_PUB_HEX  = '2e9ca1424ed90055b96ab8dd4e64d82e84436d5a2ebc1c8a8fbb6d878eeb933f';

const configVersion = parseInt(process.argv[2] || '1', 10);
const firstLabel    = process.argv[3] || 'الكل';

// Build payload identical to what ServerDrivenFilterConfig.toCanonicalJson produces
// (sorted keys recursively, then JSON.stringify).
const payload = {
  configVersion,
  defaultFilterId: 'all',
  expiresAt: '2030-01-01T00:00:00Z',
  filters: [
    {
      colorHex: '#18B2B0',
      enabled: true,
      icon: 'inventory_2_outlined',
      id: 'all',
      label: firstLabel,
      order: 1,
      statuses: [],
    },
  ],
  issuedAt: '2026-07-31T00:00:00Z',
  keyId: 'ed25519-test-key',
  minAppVersion: '1.0.0',
  schemaVersion: 1,
  screenId: 'custody_screen',
};

// Canonical JSON: deep-sort keys alphabetically then JSON.stringify (no extra whitespace).
function sortDeep(v) {
  if (Array.isArray(v)) return v.map(sortDeep);
  if (v !== null && typeof v === 'object') {
    const sorted = {};
    Object.keys(v).sort().forEach(k => { sorted[k] = sortDeep(v[k]); });
    return sorted;
  }
  return v;
}

const canonical = JSON.stringify(sortDeep(payload));

// Sign with Ed25519
function hexToBuffer(hex) {
  return Buffer.from(hex, 'hex');
}

// Node requires PKCS#8 DER for ed25519 private keys
// PKCS#8 header for ed25519 (RFC 8410): 302e020100300506032b657004220420 + 32 bytes seed
const pkcs8Header = Buffer.from('302e020100300506032b657004220420', 'hex');
const privDer = Buffer.concat([pkcs8Header, hexToBuffer(TEST_PRIV_HEX)]);
const privateKey = crypto.createPrivateKey({ key: privDer, format: 'der', type: 'pkcs8' });

const signatureBytes = crypto.sign(null, Buffer.from(canonical, 'utf8'), privateKey);
const signatureHex = signatureBytes.toString('hex');

const response = { data: payload, signature: signatureHex };
process.stdout.write(JSON.stringify({
  body: response,
  pubKeyHex: TEST_PUB_HEX,
  signatureHex,
  canonicalJson: canonical,
}));
