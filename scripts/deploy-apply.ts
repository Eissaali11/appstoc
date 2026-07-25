import 'dotenv/config';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const { Client } = require('ssh2');

const conn = new Client();
conn.on('ready', () => {
  console.log('🚀 SSH connection ready! Starting automated production deployment...');
  
  const commands = [
    'cd /home/stoc/htdocs/stoc.fun || cd /home/cloudpanel/htdocs/inventory.yourdomain.com || cd ~/htdocs/stoc.fun',
    'git fetch origin',
    'git checkout main',
    'git reset --hard origin/main',
    'npm install',
    'npm run db:push',
    'npm run import:saudi-locations',
    'npm run build',
    'pm2 restart all',
    'pm2 status'
  ];
  
  const fullCommand = commands.join(' && ');
  console.log(`Executing commands on server:\n${commands.map((c: string) => `  $ ${c}`).join('\n')}\n`);
  
  conn.exec(fullCommand, (err: any, stream: any) => {
    if (err) throw err;
    stream.on('close', (code: number) => {
      console.log('\n=== Deployment completed with exit code: ' + code + ' ===');
      conn.end();
    }).on('data', (data: Buffer) => {
      process.stdout.write(data.toString());
    }).stderr.on('data', (data: Buffer) => {
      process.stderr.write(data.toString());
    });
  });
}).connect({
  host: process.env.SSH_HOST || '153.92.211.46',
  port: 22,
  username: process.env.SSH_USER || 'root',
  password: process.env.SSH_PASSWORD || 'Eisa11223344@#',
  readyTimeout: 60000
});
