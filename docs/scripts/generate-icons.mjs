import { writeFileSync, mkdirSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const dir = join(dirname(fileURLToPath(import.meta.url)), '../icons');
mkdirSync(dir, { recursive: true });
const b = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  'base64'
);
writeFileSync(join(dir, 'icon-192.png'), b);
writeFileSync(join(dir, 'icon-512.png'), b);
console.log('Icons created in', dir);
