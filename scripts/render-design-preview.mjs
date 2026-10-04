import sharp from 'sharp';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const screens = ['splash', 'welcome', 'register', 'login', 'home', 'alert', 'schedule', 'calendar', 'notifications', 'report', 'profile'];
const names = ['Splash', 'Welcome', 'Create Account', 'Login', 'Home Dashboard', 'Truck Alert', 'Collection Schedule', 'Schedule Calendar', 'Notifications', 'Report a Concern', 'Profile / Settings'];
const mask = Buffer.from('<svg width="390" height="844" xmlns="http://www.w3.org/2000/svg"><rect width="390" height="844" rx="24" fill="white"/></svg>');

async function render(entries, title, filename, night = false) {
  const columns = 4;
  const rows = Math.ceil(entries.length / columns);
  const width = 1740;
  const height = 96 + rows * 908;
  const positions = entries.map((_, i) => ({ x: 40 + (i % columns) * 420, y: 76 + Math.floor(i / columns) * 908 }));
  const color = night ? '#e2f4e8' : '#185632';
  const background = Buffer.from(`<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">
    <rect width="${width}" height="${height}" fill="${night ? '#10271f' : '#eff7ec'}"/>
    <text x="40" y="43" fill="${color}" font-family="sans-serif" font-size="27" font-weight="700">${title}</text>
    ${positions.map(({ x, y }, i) => `<rect x="${x - 2}" y="${y - 2}" width="394" height="848" rx="26" fill="${night ? '#496453' : '#c4d8c6'}"/>
      <text x="${x + 195}" y="${y + 876}" fill="${color}" text-anchor="middle" font-family="sans-serif" font-size="19" font-weight="600">${entries[i].label}</text>`).join('')}
    <text x="40" y="${height - 16}" fill="${night ? '#a8c3b1' : '#617364'}" font-family="sans-serif" font-size="14">Native Flutter renders · Supplied logo preserved · Local demo · The interactive live map is tested separately</text>
  </svg>`);
  const layers = await Promise.all(entries.map(async (entry, i) => ({
    input: await sharp(path.join(root, 'flutter_sundo/test/goldens', `${entry.file}.png`)).composite([{ input: mask, blend: 'dest-in' }]).png().toBuffer(),
    left: positions[i].x, top: positions[i].y,
  })));
  const output = path.join(root, filename);
  await sharp(background).composite(layers).png().toFile(output);
  console.log(output);
}

await render(screens.map((name, i) => ({ file: name, label: names[i] })), 'SUNDO · Resident app in daylight', 'resident-design-day.png');
await render(screens.map((name, i) => ({ file: `${name}_night`, label: names[i] })), 'SUNDO · Resident app in the evening', 'resident-design-night.png', true);
await render([
  { file: 'welcome', label: 'Morning · Welcome' },
  { file: 'home', label: 'Morning · Home' },
  { file: 'welcome_night', label: 'Evening · Welcome' },
  { file: 'home_night', label: 'Evening · Home' },
], 'SUNDO · Automatic day and evening clay design', 'design-preview.png');
