import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import sharp from 'sharp';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const source = path.resolve(process.argv[2] ?? path.join(root, 'output/sundo-card-icons'));
const destination = path.join(root, 'flutter_sundo/assets/images/card_icons');
const manifest = JSON.parse(await fs.readFile(path.join(root, 'scripts/card-icons-manifest.json'), 'utf8'));
const report = [];
await fs.mkdir(destination, { recursive: true });
for (const image of manifest.images) {
  const input = path.join(source, image.source);
  const output = path.join(destination, `${image.name}.webp`);
  const original = await sharp(input).metadata();
  if (!original.hasAlpha) throw new Error(`Missing generated transparency: ${image.name}`);
  await sharp(input)
    .resize(224, 224, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .extend({ top: 16, bottom: 16, left: 16, right: 16,
      background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .webp({ lossless: true, effort: 6 })
    .toFile(output);
  const { data, info } = await sharp(output).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  if (info.width !== 256 || info.height !== 256 || info.channels !== 4) {
    throw new Error(`Wrong packaged canvas: ${image.name}`);
  }
  if (data[3] !== 0 || data[data.length - 1] !== 0) {
    throw new Error(`Opaque packaged corners: ${image.name}`);
  }
  let visible = 0;
  for (let i = 3; i < data.length; i += 4) if (data[i] > 0) visible++;
  const occupancy = visible / (256 * 256);
  if (occupancy <= .15 || occupancy >= .85) {
    throw new Error(`Incorrect silhouette occupancy ${occupancy}: ${image.name}`);
  }
  const encoded = await fs.readFile(output);
  const record = { name: image.name, asset: image.asset, width: 256, height: 256,
    hasAlpha: true, cornerAlpha: [data[3], data[data.length - 1]],
    visibleOccupancy: Number(occupancy.toFixed(4)), bytes: encoded.length,
    sha256: createHash('sha256').update(encoded).digest('hex') };
  report.push(record);
  console.log(JSON.stringify(record));
}

// QA only: show each actual WebP composited on three UI surfaces at 224px and 44px.
// Ordering is the manifest ordering; no generated asset includes labels or a backing disc.
const backgrounds = [{ r: 248, g: 252, b: 241 }, { r: 223, g: 245, b: 231 },
  { r: 18, g: 52, b: 40 }];
const tileWidth = 248;
const tileHeight = 300;
const composite = [];
for (let row = 0; row < backgrounds.length; row++) {
  for (let col = 0; col < manifest.images.length; col++) {
    const input = path.join(destination, `${manifest.images[col].name}.webp`);
    const tile = await sharp({ create: { width: tileWidth, height: tileHeight, channels: 4,
      background: { ...backgrounds[row], alpha: 1 } } })
      .composite([
        { input: await sharp(input).resize(224, 224).toBuffer(), left: 12, top: 8 },
        { input: await sharp(input).resize(44, 44).toBuffer(), left: 102, top: 248 },
      ]).png().toBuffer();
    composite.push({ input: tile, left: col * tileWidth, top: row * tileHeight });
  }
}
await sharp({ create: { width: manifest.images.length * tileWidth,
  height: backgrounds.length * tileHeight, channels: 4,
  background: { r: 248, g: 252, b: 241, alpha: 1 } } })
  .composite(composite).png().toFile(path.join(source, 'packaged-contact-sheet.png'));
await fs.writeFile(path.join(source, 'packaging-report.json'), JSON.stringify(report, null, 2));
console.log(`Packaged ${report.length} transparent illustrations (${report.reduce((sum, row) => sum + row.bytes, 0)} bytes).`);
