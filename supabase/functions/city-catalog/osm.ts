export function parsePlaces(raw: any, city: string) {
  if(raw.remark||!Array.isArray(raw.elements))throw new Error('Incomplete OSM response');
  const records=new Map<string,any>();
  for(const item of raw.elements){
    const tags=item.tags??{};const category=tags.leisure==='park'?'Парк':tags.leisure==='dog_park'?'Площадка':tags.amenity==='veterinary'?'Ветклиника':tags.shop==='pet'?'Зоомагазин':null;
    if(!category||!['node','way','relation'].includes(item.type)||!Number.isSafeInteger(item.id))continue;
    const name=tags['name:ru']??tags.name??tags['name:be'];const point=item.lat!=null?item:item.center;
    if(typeof name!=='string'||!name.trim()||!point||!Number.isFinite(point.lat)||!Number.isFinite(point.lon)||Math.abs(point.lat)>90||Math.abs(point.lon)>180)continue;
    const source_id=`${item.type}/${item.id}`;
    records.set(source_id,{source:'osm',source_id,name:name.trim().slice(0,120),category,city,
      latitude:point.lat,longitude:point.lon,pet_access:['yes','no','leashed'].includes(tags.dog)?tags.dog:'unknown',
      source_tags:tags,source_updated_at:item.timestamp??null,imported_at:new Date().toISOString(),published:true});
  }
  return [...records.values()];
}
