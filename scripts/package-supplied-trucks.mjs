import sharp from 'sharp';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { copyFile } from 'node:fs/promises';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const inputs = [
  ['map', process.argv[2]],
  ['side', process.argv[3]],
];
for (const [name, input] of inputs) {
  if (!input) throw new Error('Supply the map PNG and side-view PNG.');
  const metadata = await sharp(input).metadata();
  if (!metadata.hasAlpha) throw new Error(`${name} artwork must have transparency.`);
  const output = path.join(root, 'flutter_sundo/assets/images', `sundo-${name}-truck.png`);
  // Copy the original PNG, including RGB values in fully transparent pixels.
  await copyFile(input, output);
  const [original, packaged] = await Promise.all([
    sharp(input).ensureAlpha().raw().toBuffer(),
    sharp(output).ensureAlpha().raw().toBuffer(),
  ]);
  if (!original.equals(packaged)) throw new Error(`${name} pixels changed during packaging.`);
  console.log(`${name}: all ${metadata.width}x${metadata.height} RGBA pixels preserved.`);
}
