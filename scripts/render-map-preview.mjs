import sharp from 'sharp';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const scenes = [
  { file: 'day', label: '3D · Daylight' },
  { file: 'night', label: '3D · Evening' },
  { file: 'flat', label: '2D · Street inspection' },
];
const width = 1320;
const height = 984;
const positions = scenes.map((_, i) => ({ x: 45 + i * 420, y: 78 }));
const mask = Buffer.from('<svg width="390" height="844" xmlns="http://www.w3.org/2000/svg"><rect width="390" height="844" rx="24" fill="white"/></svg>');
const backdrop = Buffer.from(`<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">
  <rect width="${width}" height="${height}" fill="#eaf4ea"/>
  <text x="45" y="42" fill="#185632" font-family="sans-serif" font-size="27" font-weight="700">SUNDO · Clay map and camera controls</text>
  ${positions.map(({ x, y }, i) => `<rect x="${x - 2}" y="${y - 2}" width="394" height="848" rx="26" fill="#b8d0bc"/>
    <text x="${x + 195}" y="${y + 870}" fill="#185632" text-anchor="middle" font-family="sans-serif" font-size="18" font-weight="600">${scenes[i].label}</text>`).join('')}
  <text x="45" y="972" fill="#617364" font-family="sans-serif" font-size="13">Native Flutter renders · Synthetic QA basemap · The app uses OpenStreetMap · Demo truck and route</text>
</svg>`);
const layers = await Promise.all(scenes.map(async (scene, i) => ({
  input: await sharp(path.join(root, 'flutter_sundo/test/goldens', `map_scene_${scene.file}.png`))
    .composite([{ input: mask, blend: 'dest-in' }]).png().toBuffer(),
  left: positions[i].x,
  top: positions[i].y,
})));
const output = path.join(root, 'map-preview.png');
await sharp(backdrop).composite(layers).png().toFile(output);
console.log(output);
