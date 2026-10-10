#!/usr/bin/env python3
"""Local-only catalog access, cache and source checks, using a synthetic account."""
import json, secrets, urllib.request, urllib.error, urllib.parse, uuid, os, subprocess
from pathlib import Path
cfg=json.loads(Path('config/backend-status.local.json').read_text());base=cfg['API_URL'];pub=cfg['PUBLISHABLE_KEY'];staff=cfg['SERVICE_ROLE_KEY']
if not base.startswith('http://127.0.0.1:'):raise SystemExit('Local endpoint required')
def call(path,data=None,token=None,admin=False,method=None):
 key=staff if admin else pub
 req=urllib.request.Request(base+urllib.parse.quote(path,safe='/?=&.,!()'),data=json.dumps(data).encode() if data is not None else None,method=method or ('POST' if data is not None else 'GET'),headers={'apikey':key,'Authorization':'Bearer '+(key if admin else token or pub),'Content-Type':'application/json'})
 try:
  with urllib.request.urlopen(req,timeout=65) as r:
   b=r.read();return r.status,json.loads(b) if b else None
 except urllib.error.HTTPError as e:
  b=e.read();return e.code,json.loads(b) if b else None
count=0;uid=None;city='Catalog synthetic '+secrets.token_hex(5)
def check(ok,label):
 global count
 if not ok:raise AssertionError(label)
 count+=1;print('PASS '+label,flush=True)
try:
 email='catalog-'+secrets.token_hex(6)+'@example.test';password=secrets.token_urlsafe(24)
 code,user=call('/auth/v1/admin/users',{'email':email,'password':password,'email_confirm':True},admin=True);check(code in (200,201),'synthetic fixture created');uid=user['id']
 code,session=call('/auth/v1/token?grant_type=password',{'email':email,'password':password});token=session['access_token']
 claim={'user_in':uid,'city_in':city}
 check(call('/rest/v1/rpc/claim_city_catalog',claim,token)[0]>=400,'client cannot claim privileged import')
 check(call('/rest/v1/rpc/finish_city_catalog',{'city_in':city,'lease_in':str(uuid.uuid4()),'success_in':True},token)[0]>=400,'client cannot mark catalog ready')
 check(call('/functions/v1/city-catalog',{'city':'Гродно'})[0]==401,'anonymous cannot trigger import')
 check(call('/functions/v1/city-catalog',{'city':''},token)[0]==400,'empty city is rejected')
 code,job=call('/rest/v1/rpc/claim_city_catalog',claim,admin=True);check(code==200 and job['status']=='fetch','server claims first city import')
 code,other=call('/rest/v1/rpc/claim_city_catalog',claim,admin=True);check(other['status']=='busy','same city concurrent request is coalesced')
 call('/rest/v1/rpc/finish_city_catalog',{'city_in':city,'lease_in':str(uuid.uuid4()),'success_in':True},admin=True)
 check(call('/rest/v1/rpc/claim_city_catalog',claim,admin=True)[1]['status']=='busy','wrong lease cannot finish another import')
 call('/rest/v1/rpc/finish_city_catalog',{'city_in':city,'lease_in':job['lease'],'success_in':True},admin=True)
 check(call('/rest/v1/rpc/claim_city_catalog',claim,admin=True)[1]['status']=='ready','completed city is reused from cache')
 check(call('/rest/v1/city_catalog_places',{'city_key':city.lower(),'place_id':str(uuid.uuid4())},token)[0]>=400,'client cannot forge catalog membership')
 check(call('/rest/v1/places?source=eq.osm&category=in.(Кафе,Ресторан)&published=eq.true')[1]==[],'imported eateries are hidden from public catalog')
 call('/rest/v1/rpc/revoke_my_sessions',{},token)
 check(call('/functions/v1/city-catalog',{'city':'Гродно'},token)[0]==403,'revoked JWT cannot trigger new catalog imports')
 print('City catalog checks:',count)
finally:
 if uid:
  call('/auth/v1/admin/users/'+uid,admin=True,method='DELETE')
 # Only the synthetic job created by this script, never actual city data.
 env={**os.environ,'DOCKER_HOST':'unix:///Users/artem.dudinskij/.colima/petfriendly/docker.sock'}
 subprocess.run(['docker','exec','supabase_db_PetFriendly','psql','-U','postgres','-d','postgres','-c',"delete from private.city_catalog where city_key='"+city.lower()+"'"],env=env,check=True,stdout=subprocess.DEVNULL)
