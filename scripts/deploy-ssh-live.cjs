const { Client } = require('ssh2');

const conn = new Client();
const commands = [
  'cd /home/stoc/htdocs/stoc.fun || cd /home/cloudpanel/htdocs/stoc.fun || cd ~/htdocs/stoc.fun',
  'pwd',
  'git fetch origin',
  'git checkout main',
  'git reset --hard origin/main',
  'npm install',
  'npm run db:push || true',
  'npm run import:saudi-locations || true',
  'npm run build',
  'pm2 restart all || pm2 restart nulip-inventory || true',
  'pm2 status',
  'echo "=== PRODUCTION DEPLOYMENT COMPLETE ==="'
].join(' && ');

console.log('🚀 Connecting to Hostinger VPS Server (153.92.211.46)...');

conn.on('ready', () => {
  console.log('✅ SSH Connection Established Successfully!');
  conn.exec(commands, { pty: true }, (err, stream) => {
    if (err) {
      console.error('❌ Execution error:', err);
      conn.end();
      return;
    }
    stream.on('close', (code) => {
      console.log(`\n🎉 Deployment execution finished with exit code: ${code}`);
      conn.end();
    });
    stream.on('data', (data) => process.stdout.write(data.toString()));
    stream.stderr.on('data', (data) => process.stderr.write(data.toString()));
  });
}).connect({
  host: '153.92.211.46',
  port: 22,
  username: 'root',
  password: 'Eisa11223344@#',
  readyTimeout: 60000,
  keepaliveInterval: 10000,
});

conn.on('error', (err) => {
  console.error('❌ SSH Connection Error:', err.message);
});
