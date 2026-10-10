#!/usr/bin/env python3
"""Explicit PetFriendly staging smoke/authorization checks, using disposable synthetic accounts."""
import json,secrets,urllib.request,urllib.error,uuid,time,hmac,hashlib,base64,struct
from pathlib import Path
cfg=json.loads(Path('config/staging-backend.local.json').read_text());base=cfg['API_URL'];pub=cfg['PUBLISHABLE_KEY'];staff=cfg['SERVICE_ROLE_KEY']
if base!='https://cbkmxtplhcdomyeyrwyi.supabase.co':raise SystemExit('Wrong staging project')
def call(path,data=None,token=None,admin=False,method=None):
 key=staff if admin else pub
 headers={'apikey':key,'Content-Type':'application/json'}
 if admin or token:headers['Authorization']='Bearer '+(key if admin else token)
 r=urllib.request.Request(base+path,data=json.dumps(data).encode() if data is not None else None,method=method or ('POST' if data is not None else 'GET'),headers=headers)
 try:
  with urllib.request.urlopen(r,timeout=45) as v:
   raw=v.read();return v.status,json.loads(raw) if raw else None
 except urllib.error.HTTPError as e:return e.code,None
count=0;uid=None
def check(ok,label):
 global count
 assert ok,label
 count+=1;print('PASS '+label,flush=True)
try:
 check(call('/rest/v1/places?select=id&limit=1')[0]==200,'public catalog Data API is available')
 _,buckets=call('/storage/v1/bucket',admin=True)
 check(any(b['id']=='petfriendly-photos' and not b['public'] for b in buckets),'photo bucket is private')
 email='stage-'+secrets.token_hex(6)+'@example.test';password=secrets.token_urlsafe(24)
 code,user=call('/auth/v1/admin/users',{'email':email,'password':password,'email_confirm':True},admin=True);check(code in (200,201),'synthetic staging account created');uid=user['id']
 code,session=call('/auth/v1/token?grant_type=password',{'email':email,'password':password});check(code==200,'confirmed fixture signs in');token=session['access_token']
 _,profile=call('/rest/v1/profiles?id=eq.'+uid,token=token);check(len(profile)==1,'profile bootstrap and own access work')
 check(call('/rest/v1/rpc/moderation_queue',{},token)[0]==403,'ordinary staging user cannot read moderation queue')
 code,page=call('/rest/v1/rpc/search_places',{'city_in':'Минск'},token);check(code==200 and page['total']>=130 and len(page['items'])==40,'server returns bounded first page of Minsk parks')
 _,next_page=call('/rest/v1/rpc/search_places',{'city_in':'Минск','offset_in':40},token)
 check(not ({p['id'] for p in page['items']}&{p['id'] for p in next_page['items']}),'next server page has no duplicate IDs')
 _,search=call('/rest/v1/rpc/search_places',{'city_in':'Минск','query_in':'Александровский'},token);check(search['total']==1,'cloud search filters before pagination')
 check(call('/rest/v1/rpc/search_places',{'city_in':'Минск'})[0]>=400,'anonymous cannot invoke private search RPC')
 check(call('/functions/v1/city-catalog',{'city':''},token)[0]==400,'cloud function accepts new account JWT and validates city')
 _,export=call('/rest/v1/rpc/export_my_data',{},token);check('photos' in export and export['profile']['id']==uid,'recently authenticated own export includes media references')
 code,factor=call('/auth/v1/factors',{'factor_type':'totp','friendly_name':'Staging synthetic verification'},token)
 check(code==200,'cloud TOTP enrollment works')
 _,challenge=call('/auth/v1/factors/'+factor['id']+'/challenge',{},token)
 secret=factor['totp']['secret'];key=base64.b32decode(secret+'='*((-len(secret))%8));digest=hmac.new(key,struct.pack('>Q',int(time.time())//30),hashlib.sha1).digest();offset=digest[-1]&15
 otp=str((struct.unpack('>I',digest[offset:offset+4])[0]&0x7fffffff)%1000000).zfill(6)
 code,verified=call('/auth/v1/factors/'+factor['id']+'/verify',{'challenge_id':challenge['id'],'code':otp},token)
 check(code==200,'cloud TOTP challenge verifies')
 check(call('/rest/v1/rpc/search_places',{'city_in':'Минск'},token)[0]==403,'old aal1 session loses protected access after MFA enrollment')
 token=verified['access_token']
 check(call('/rest/v1/rpc/search_places',{'city_in':'Минск'},token)[0]==200,'aal2 session can search in staging')
 check(call('/rest/v1/rpc/revoke_my_sessions',{},token)[0]==204,'cloud session revocation succeeds')
 check(call('/rest/v1/rpc/search_places',{'city_in':'Минск'},token)[0]==403,'existing revoked JWT loses search access')
 check(call('/functions/v1/city-catalog',{'city':'Минск'},token)[0]==403,'existing revoked JWT cannot trigger import')
 print('Staging checks:',count)
finally:
 if uid:call('/auth/v1/admin/users/'+uid,admin=True,method='DELETE')
