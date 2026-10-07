import sharp from 'sharp';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const sourceDirectory = process.argv[2];
if (!sourceDirectory) throw new Error('Pass the folder containing the five supplied PNG scenes.');
const scenes = [
  ['morning', 'ChatGPT Image Oct 5, 2026, 07_07_06 PM-1.png'],
  ['noon', 'ChatGPT Image Oct 5, 2026, 07_07_09 PM-2.png'],
  ['sunset', 'ChatGPT Image Oct 5, 2026, 07_07_11 PM-3.png'],
  ['twilight', 'ChatGPT Image Oct 5, 2026, 07_07_14 PM-4.png'],
  ['rainy', 'ChatGPT Image Oct 5, 2026, 07_07_15 PM-5.png'],
];
// Optional full-night reference, supplied separately after the original set.
if (process.argv[3]) scenes.push(['night', path.resolve(process.argv[3])]);
for (const [name, filename] of scenes) {
  const input = path.resolve(sourceDirectory, filename);
  const metadata = await sharp(input).metadata();
  if (metadata.width !== 1024 || metadata.height !== 1536) {
    throw new Error(`The ${name} scene must preserve the common 1024×1536 framing.`);
  }
  const output = path.join(root, 'flutter_sundo/assets/images', `environment-${name}.webp`);
  await sharp(input).webp({ lossless: true, effort: 6 }).toFile(output);
  const [original, packaged] = await Promise.all([
    sharp(input).ensureAlpha().raw().toBuffer(),
    sharp(output).ensureAlpha().raw().toBuffer(),
  ]);
  if (!original.equals(packaged)) throw new Error(`The ${name} scene pixels changed during packaging.`);
  console.log(`${name}: preserved all 1024×1536 pixels in ${output}`);
}
