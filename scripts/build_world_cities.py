"""Build a bundled GeoNames snapshot from public downloads (no runtime API)."""
import hashlib,json,pathlib,zipfile,datetime,collections
root=pathlib.Path(__file__).resolve().parents[1]; src=root/'tooling/.cache/geonames'; out=root/'assets/data/geonames'
admins={p[0]:p[1] for line in (src/'admin1CodesASCII.txt').read_text().splitlines() if len(p:=line.split('\t'))>=2}
countries={p[0]:p[4] for line in (src/'countryInfo.txt').read_text().splitlines() if not line.startswith('#') and len(p:=line.split('\t'))>4}
rows=[]
with zipfile.ZipFile(src/'cities15000.zip') as z:
 for line in z.read('cities15000.txt').decode().splitlines():
  p=line.split('\t'); cc=p[8];region=admins.get(f'{cc}.{p[10]}','');country=countries.get(cc,cc)
  key=', '.join(x for x in [p[1],region,cc] if x)
  if len(key)>96:key=f'{p[1][:70]}, {cc}, #{p[0]}'
  aliases=list(dict.fromkeys([p[1],p[2],*p[3].split(',')]))
  rows.append([p[0],p[1],key,cc,country,region,p[17],float(p[4]),float(p[5]),int(p[14]),aliases])
counts=collections.Counter(r[2] for r in rows)
for r in rows:
 if counts[r[2]]>1:r[2]=r[2][:85]+f', #{r[0]}'
rows.sort(key=lambda r:-r[9]);out.mkdir(parents=True,exist_ok=True)
(out/'cities.json').write_text(json.dumps(rows,ensure_ascii=False,separators=(',',':')))
localized={lang:json.loads((src/f'countries-{lang}.json').read_text())['main'][lang]['localeDisplayNames']['territories'] for lang in ['ru','en','be','pl']}
(out/'countries.json').write_text(json.dumps(localized,ensure_ascii=False,separators=(',',':')))
(out/'NOTICE.txt').write_text('Cities: GeoNames, https://www.geonames.org/ — Creative Commons Attribution 4.0, https://creativecommons.org/licenses/by/4.0/. Source: https://download.geonames.org/export/dump/cities15000.zip. Snapshot '+str(datetime.date.today())+'. Selected fields, population sorting and country/region-qualified keys derived by PetFriendly. Covers cities with population > 15000 or capitals; smaller settlements may be entered manually. Data provided as is.\nCountry labels: Unicode CLDR, https://github.com/unicode-org/cldr-json. See UNICODE-LICENSE.txt.\n')
(out/'snapshot.json').write_text(json.dumps({'date':str(datetime.date.today()),'cities':len(rows),'countries':len({r[3] for r in rows}),'source_sha256':hashlib.sha256((src/'cities15000.zip').read_bytes()).hexdigest()},indent=2))
print(len(rows),'cities',len({r[3] for r in rows}),'countries', (out/'cities.json').stat().st_size,'bytes')
