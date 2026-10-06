import sharp from 'sharp';
import fs from 'node:fs/promises';
const manifest = JSON.parse(await fs.readFile('truck-generation-manifest.json', 'utf8'));
const tiles = [];
for (const [index, frame] of manifest.frames.entries()) {
  const path = `flutter_sundo/assets/images/truck_directions/${frame.file}`;
  const {data, info} = await sharp(path).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let left=info.width, top=info.height, right=0, bottom=0, transparent=0;
  let blueX=0,blueY=0,blueN=0,yellowX=0,yellowY=0,yellowN=0;
  for(let y=0;y<info.height;y++) for(let x=0;x<info.width;x++) {
    const alpha=data[(y*info.width+x)*4+3];
    if(alpha===0) transparent++;
    if(alpha>64) {left=Math.min(left,x); top=Math.min(top,y); right=Math.max(right,x); bottom=Math.max(bottom,y);}
    const p=(y*info.width+x)*4, r=data[p],g=data[p+1],b=data[p+2];
    if(alpha>200 && b>90 && b>r*1.6 && b>g*1.1) {blueX+=x;blueY+=y;blueN++;}
    if(alpha>200 && r>180 && g>140 && b<80) {yellowX+=x;yellowY+=y;yellowN++;}
  }
  Object.assign(frame,{width:info.width,height:info.height,bounds:{left,top,right,bottom},transparentPixels:transparent});
  if(!blueN || !yellowN) throw new Error(`${path}: missing windshield or rear compactor`);
  frame.illustratedBearing=(Math.atan2(blueX/blueN-yellowX/yellowN,-(blueY/blueN-yellowY/yellowN))*180/Math.PI+360)%360;
  if(!transparent) throw new Error(`${path} has no transparency`);
  const tile=await sharp(path).resize(250,250,{fit:'contain'}).png().toBuffer();
  tiles.push({input:tile,left:(index%4)*280+15,top:Math.floor(index/4)*290+30});
  tiles.push({input:Buffer.from(`<svg width="280" height="30"><text x="140" y="22" text-anchor="middle" font-family="Arial" font-size="18">${frame.angle}°</text></svg>`),left:(index%4)*280,top:Math.floor(index/4)*290});
}
await sharp({create:{width:1120,height:1160,channels:4,background:'#edf4ef'}}).composite(tiles).png().toFile('truck-directions-preview.png');
await fs.writeFile('truck-generation-manifest.json',JSON.stringify(manifest,null,2)+'\n');
console.log(manifest.frames.map(({file,width,height,bounds})=>({file,width,height,bounds})));
console.log('Illustrated screen bearings:',manifest.frames.map(f=>Number(f.illustratedBearing.toFixed(2))));
