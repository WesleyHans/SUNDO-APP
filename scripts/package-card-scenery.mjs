import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const source = path.resolve(process.argv[2] ?? path.join(root, 'output/sundo-card-scenery'));
const destination = path.join(root, 'flutter_sundo/assets/images/card_scenery');
const manifest = JSON.parse(await fs.readFile(path.join(source, 'manifest.json'), 'utf8'));
let bytes = 0;
for (const scene of manifest.scenes) {
  await fs.mkdir(path.join(destination, scene.id), { recursive: true });
  for (const image of scene.images) {
    const input = path.join(source, image.path);
    const output = path.join(destination, scene.id, `${image.state}.webp`);
    const metadata = await sharp(input).metadata();
    if (metadata.width !== image.width || metadata.height !== image.height) {
      throw new Error(`Inconsistent master canvas: ${image.path}`);
    }
    await sharp(input).webp({ lossless: true, effort: 6 }).toFile(output);
    const [original, packaged] = await Promise.all([
      sharp(input).ensureAlpha().raw().toBuffer(),
      sharp(output).ensureAlpha().raw().toBuffer(),
    ]);
    if (!original.equals(packaged)) throw new Error(`Pixel changes: ${image.path}`);
    bytes += (await fs.stat(output)).size;
    console.log(`${scene.id}/${image.state}: ${image.width}x${image.height} pixels preserved`);
  }
}
console.log(`Packaged ${manifest.generation.finalImages} lossless card assets (${bytes} bytes).`);
