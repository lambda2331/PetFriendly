// Run with Node and sharp available (bundled desktop runtime is supported).
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'assets/branding/app-icon.svg'));
async function opaquePng(size, output) {
  fs.mkdirSync(path.dirname(output), { recursive: true });
  await sharp(source, { density: 384 }).resize(size, size)
    .flatten({ background: '#20271D' }).removeAlpha().png().toFile(output);
}
async function main() {
  await opaquePng(1024, path.join(root, 'assets/branding/app-icon.png'));
  const catalog = path.join(root, 'ios/Runner/Assets.xcassets/AppIcon.appiconset');
  const images = JSON.parse(fs.readFileSync(path.join(catalog, 'Contents.json'))).images;
  for (const entry of images) {
    const size = Math.round(parseFloat(entry.size) * parseFloat(entry.scale));
    await opaquePng(size, path.join(catalog, entry.filename));
  }
  const res = path.join(root, 'android/app/src/main/res');
  for (const [density, size] of Object.entries({mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192})) {
    await opaquePng(size, path.join(res, 'mipmap-' + density, 'ic_launcher.png'));
  }
  const foreground = source.toString().replace(/  <rect[^>]*\/>\n/, '');
  fs.mkdirSync(path.join(res, 'drawable-nodpi'), {recursive: true});
  await sharp(Buffer.from(foreground), {density: 384}).resize(432, 432).png()
    .toFile(path.join(res, 'drawable-nodpi/ic_launcher_foreground.png'));
  console.log('Generated iOS and Android icons from assets/branding/app-icon.svg');
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
