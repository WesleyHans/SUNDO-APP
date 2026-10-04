import sharp from 'sharp';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const screens = ['welcome', 'login', 'register', 'home'];
const labels = ['Welcome / Get Started', 'Resident Login', 'Create Account', 'Home Dashboard'];
const positions = screens.map((_, i) => 40 + i * 420);
const background = Buffer.from(`<svg width="1740" height="1030" xmlns="http://www.w3.org/2000/svg">
  <rect width="1740" height="1030" fill="#eff7ec"/>
  <text x="40" y="43" fill="#185632" font-family="sans-serif" font-size="27" font-weight="700">SUNDO · Claymorphism mobile design</text>
  ${positions.map((x, i) => `<rect x="${x - 10}" y="74" width="410" height="864" rx="38" fill="#183329"/>
    <text x="${x + 195}" y="974" fill="#185632" text-anchor="middle" font-family="sans-serif" font-size="20" font-weight="600">${labels[i]}</text>`).join('')}
  <text x="40" y="1012" fill="#617364" font-family="sans-serif" font-size="15">Rendered Flutter components · Illustrated city backgrounds, leaf accents, soft clay cards and green controls</text>
</svg>`);
const roundedMask = Buffer.from('<svg width="390" height="844" xmlns="http://www.w3.org/2000/svg"><rect width="390" height="844" rx="29" fill="white"/></svg>');
const layers = await Promise.all(screens.map(async (name, index) => ({
  input: await sharp(path.join(root, 'flutter_sundo/test/goldens', `${name}.png`))
    .composite([{ input: roundedMask, blend: 'dest-in' }]).png().toBuffer(),
  left: positions[index], top: 84,
})));
const output = path.join(root, 'design-preview.png');
await sharp(background).composite(layers).png().toFile(output);
console.log(output);
