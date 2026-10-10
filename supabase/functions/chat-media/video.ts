// Metadata removal preserves atom sizes and sample offsets. No URL-based media.
export function sanitizeVideo(input: Uint8Array) {
  if (input.length > 20 * 1024 * 1024) throw new Error('Video too large');
  const bytes = input.slice(), view = new DataView(bytes.buffer);
  const text = (at: number) => String.fromCharCode(...bytes.slice(at, at + 4));
  const children: Record<string, string[]> = {
    root: ['ftyp','moov','mdat','wide'], moov: ['mvhd','trak'], trak: ['tkhd','mdia','edts'],
    mdia: ['mdhd','hdlr','minf'], minf: ['vmhd','smhd','dinf','stbl'], dinf: ['dref'], edts: ['elst'],
    stbl: ['stsd','stts','stsc','stsz','stco','co64','stss','ctts','sdtp'],
    sample: ['avcC','hvcC','pasp','colr','btrt','clap','fiel'],
  };
  let atoms = 0, duration = 0, video = false, videoSample = false;
  const roots = new Set<string>();
  function walk(start: number, end: number, parent: string, depth = 0) {
    if (depth > 12) throw new Error('Invalid nesting');
    let p = start;
    while (p < end) {
      if (++atoms > 50000 || p + 8 > end) throw new Error('Invalid atom');
      let size = view.getUint32(p), header = 8;
      if (size === 1) { if(p+16>end || view.getUint32(p+8)!==0) throw new Error('Invalid size'); size=view.getUint32(p+12);header=16; }
      if (size === 0) size = end-p;
      if (size < header || p + size > end) throw new Error('Truncated video');
      const type = text(p+4), finish = p+size;
      if(parent==='root') roots.add(type);
      if (!(children[parent]??[]).includes(type)) {
        bytes.set([102,114,101,101],p+4);bytes.fill(0,p+header,finish);
      } else if (children[type]) walk(p+header,finish,type,depth+1);
      else if (type === 'mvhd' || type === 'mdhd' || type === 'tkhd') {
        const v = bytes[p+header];
        if (v>1 || size<header+(v===1?32:20)) throw new Error('Invalid time');
        if (type==='mvhd') {
          const scaleAt=p+header+(v===1?20:12), ticksAt=scaleAt+4;
          if (ticksAt+(v===1?8:4)>finish) throw new Error('Invalid duration');
          const scale=view.getUint32(scaleAt);
          if (!scale || v===1 && view.getUint32(ticksAt)!==0) throw new Error('Invalid duration');
          duration=view.getUint32(ticksAt+(v===1?4:0))/scale;
          if (!duration || duration>60) throw new Error('Video must be at most 60 seconds');
        }
        bytes.fill(0,p+header+4,p+header+(v===1?20:12));
      } else if (type==='hdlr') {
        if(size<header+24)throw new Error('Invalid handler');
        if(text(p+header+8)==='vide')video=true;
        bytes.fill(0,p+header+24,finish);
      } else if(type==='dref') {
        if(size!==header+20 || view.getUint32(p+header+4)!==1 || text(p+header+12)!=='url ' || view.getUint32(p+header+16)!==1)throw new Error('External data is forbidden');
      } else if(type==='stsd') {
        if(size<header+8 || view.getUint32(p+header+4)!==1)throw new Error('Unsupported samples');
        const sample=p+header+8, codec=text(sample+4), sampleSize=view.getUint32(sample);
        if(sampleSize<8 || sample+sampleSize!==finish)throw new Error('Invalid sample');
        if(['avc1','avc3','hvc1','hev1'].includes(codec)) {
          if(sampleSize<86)throw new Error('Invalid video sample');
          const width=view.getUint16(sample+32),height=view.getUint16(sample+34);
          if(!width||!height||width>4096||height>4096)throw new Error('Invalid dimensions');
          videoSample=true;
          bytes.fill(0,sample+50,sample+82);walk(sample+86,finish,'sample',depth+1);
        } else if(codec!=='mp4a')throw new Error('Unsupported codec');
      }
      p=finish;
    }
  }
  walk(0,bytes.length,'root');
  if(!roots.has('ftyp')||!roots.has('moov')||!roots.has('mdat')||!video||!videoSample||!duration)throw new Error('MP4/MOV video required');
  // The player still validates and decodes the bitstream; this validates structure.
  return {bytes,duration};
}
