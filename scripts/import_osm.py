#!/usr/bin/env python3
"""Fetch public Minsk POIs, preserving OSM attribution and provenance."""
import json, urllib.request, time, math, uuid
from pathlib import Path
query='''[out:json][timeout:90];(nwr["leisure"~"^(park|dog_park)$"](53.80,27.30,54.03,27.78);nwr["shop"="pet"](53.80,27.30,54.03,27.78);nwr["amenity"="veterinary"](53.80,27.30,54.03,27.78););out center meta;'''
raw=None
for endpoint in ['https://overpass-api.de/api/interpreter','https://overpass.kumi.systems/api/interpreter']:
    try:
        request=urllib.request.Request(endpoint,data=query.encode(),headers={'User-Agent':'PetFriendly-dev/0.2 (OSM catalog prototype)'})
        with urllib.request.urlopen(request,timeout=120) as response:raw=json.load(response)
        break
    except Exception as e: print(type(e).__name__+' from Overpass, retrying another endpoint')
if raw is None:raise SystemExit('OSM import unavailable; existing catalog is unchanged')
places=[];seen=set();duplicate_count=0
for item in raw['elements']:
    tags=item.get('tags',{});name=tags.get('name:ru') or tags.get('name') or tags.get('name:be')
    if not name:continue
    source_id=f"{item['type']}/{item['id']}"
    if source_id in seen:continue
    seen.add(source_id)
    point=item if 'lat' in item else item.get('center',{})
    if 'lat' not in point:continue
    category={'park':'Парк','dog_park':'Площадка'}.get(tags.get('leisure')) or ('Ветклиника' if tags.get('amenity')=='veterinary' else 'Зоомагазин' if tags.get('shop')=='pet' else None)
    if category is None:continue
    dog=tags.get('dog');access=dog if dog in ['yes','no','leashed'] else 'unknown'
    record={'id':str(uuid.uuid5(uuid.NAMESPACE_URL,'https://www.openstreetmap.org/'+source_id)),'source':'osm','source_id':source_id,'name':name,'category':category,'city':'Минск','latitude':point['lat'],'longitude':point['lon'],'pet_access':access,'source_tags':tags,'source_updated_at':item.get('timestamp'),'imported_at':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'position_kind':'node' if item['type']=='node' else 'representative_center'}
    twin=None
    for existing in places:
        if existing['name'].casefold()!=name.casefold() or existing['category']!=category:continue
        distance=111000*math.hypot(point['lat']-existing['latitude'],(point['lon']-existing['longitude'])*math.cos(math.radians(point['lat'])))
        if distance<30:twin=existing;break
    if twin:
        twin.setdefault('source_aliases',[]).append(source_id);duplicate_count+=1
        if twin['pet_access']=='unknown' and access!='unknown':twin['pet_access']=access
    else:places.append(record)
places.sort(key=lambda x:(x['category'],x['name']))
output={'source':'OpenStreetMap','license':'ODbL-1.0','attribution':'© OpenStreetMap contributors','license_url':'https://www.openstreetmap.org/copyright','bounds':[53.80,27.30,54.03,27.78],'places':places}
path=Path('assets/data/minsk_places.json');path.write_text(json.dumps(output,ensure_ascii=False,indent=2))
print(json.dumps({'places':len(places),'pet_access_tagged':sum(p['pet_access']!='unknown' for p in places),'duplicates_collapsed':duplicate_count},ensure_ascii=False))
# Generate an idempotent seed; only source-derived fields are replaced.
keys=['id','source','source_id','name','category','city','latitude','longitude','pet_access','source_tags','source_updated_at','imported_at']
def sql(value):
    if value is None:return 'null'
    if isinstance(value,(float,int)):return str(value)
    if isinstance(value,dict):value=json.dumps(value,ensure_ascii=False)
    return "'"+str(value).replace("'","''")+"'"
seed='-- OpenStreetMap contributors; ODbL. Community reviews are stored separately.\n'
for place in places:
    seed+='insert into public.places('+','.join(keys)+') values('+','.join(sql(place.get(k)) for k in keys)+') on conflict(source_id) do update set '+','.join(k+'=excluded.'+k for k in keys if k not in ['id','source_id'])+';\n'
Path('supabase/seed.sql').write_text(seed)
