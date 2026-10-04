import fs from 'node:fs/promises';
import path from 'node:path';
import sharp from 'sharp';
const root=process.cwd();
const asset=path.join(root,'flutter_sundo/assets/images/sundo-brand-logo.png');
const res=path.join(root,'flutter_sundo/android/app/src/main/res');
const bg={r:247,g:250,b:239,alpha:1};
for (const [density,size] of Object.entries({'mdpi':48,'hdpi':72,'xhdpi':96,'xxhdpi':144,'xxxhdpi':192})) {
  const inset=Math.round(size*.08);
  const mark=await sharp(asset).resize(size-inset*2,size-inset*2,{fit:'inside'}).toBuffer();
  await sharp({create:{width:size,height:size,channels:4,background:bg}}).composite([{input:mark,gravity:'center'}]).png().toFile(path.join(res,`mipmap-${density}/ic_launcher.png`));
}
const foreground=await sharp(asset).resize(256,179,{fit:'inside'}).toBuffer();
await fs.mkdir(path.join(res,'drawable-nodpi'),{recursive:true});
await sharp({create:{width:432,height:432,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:foreground,gravity:'center'}]).png().toFile(path.join(res,'drawable-nodpi/ic_launcher_foreground.png'));
await fs.mkdir(path.join(res,'mipmap-anydpi-v26'),{recursive:true});
await fs.writeFile(path.join(res,'mipmap-anydpi-v26/ic_launcher.xml'),`<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/sundo_launcher_background" />
  <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
`);
await fs.writeFile(path.join(res,'values/colors.xml'),`<?xml version="1.0" encoding="utf-8"?>
<resources><color name="sundo_launcher_background">#F7FAEF</color></resources>
`);
console.log('Packaged supplied artwork into Android launcher assets.');

// Package the same supplied artwork for the later macOS/iOS build.
const iosIcons=path.join(root,'flutter_sundo/ios/Runner/Assets.xcassets/AppIcon.appiconset');
const catalog=JSON.parse(await fs.readFile(path.join(iosIcons,'Contents.json'),'utf8'));
for(const entry of catalog.images){
 if(!entry.filename)continue;
 const size=Math.round(Number(entry.size.split('x')[0])*Number(entry.scale.replace('x','')));
 const mark=await sharp(asset).resize(Math.round(size*.84),Math.round(size*.84),{fit:'inside'}).toBuffer();
 await sharp({create:{width:size,height:size,channels:3,background:bg}}).composite([{input:mark,gravity:'center'}]).flatten({background:bg}).png().toFile(path.join(iosIcons,entry.filename));
}
