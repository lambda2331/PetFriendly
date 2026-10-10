#!/usr/bin/env python3
"""Place submission authorization checks on the isolated local PetFriendly backend."""
import json, urllib.request, urllib.error, uuid, secrets, subprocess, os, time, hmac, hashlib, base64, struct
from pathlib import Path
cfg=json.loads(Path('config/backend-status.local.json').read_text())
base=cfg['API_URL'].rstrip('/');pub=cfg.get('PUBLISHABLE_KEY') or cfg['ANON_KEY'];admin=cfg['SERVICE_ROLE_KEY']
if not base.startswith('http://127.0.0.1:'):raise SystemExit('Local endpoint required')
def call(path,method='GET',data=None,token=None,staff=False):
 key=admin if staff else pub
 req=urllib.request.Request(base+path,method=method,headers={'apikey':key,'Authorization':'Bearer '+(key if staff else token or pub),'Content-Type':'application/json'},data=json.dumps(data).encode() if data is not None else None)
 try:
  with urllib.request.urlopen(req,timeout=30) as r:
   b=r.read();return r.status,json.loads(b) if b else None
 except urllib.error.HTTPError as e:
  b=e.read();return e.code,json.loads(b) if b else None
checks=0;users=[];published=[]
def check(ok,label):
 global checks
 if not ok:raise AssertionError(label)
 checks+=1;print('PASS '+label)
def rpc(name,data,token=None):return call('/rest/v1/rpc/'+name,'POST',data,token)
def fixture():
 email='places-'+secrets.token_hex(6)+'@example.test';password=secrets.token_urlsafe(24)
 c,u=call('/auth/v1/admin/users','POST',{'email':email,'password':password,'email_confirm':True},staff=True)
 if c not in (200,201):raise AssertionError('Fixture creation')
 users.append(u['id']);c,s=call('/auth/v1/token?grant_type=password','POST',{'email':email,'password':password})
 if c!=200:raise AssertionError('Fixture login')
 return u['id'],s['access_token']
try:
 maker,a=fixture();observer,b=fixture();moderator,m=fixture()
 check(rpc('moderation_queue',{},a)[0]==403,'ordinary user cannot read moderation queue')
 check(rpc('moderation_available',{},a)==(200,False),'ordinary user cannot impersonate a moderator')
 env={**os.environ,'DOCKER_HOST':'unix:///Users/artem.dudinskij/.colima/petfriendly/docker.sock'}
 subprocess.run(['docker','exec','supabase_db_PetFriendly','psql','-U','postgres','-d','postgres','-c',"update private.accounts set moderator=true where id='"+str(uuid.UUID(moderator))+"'"],env=env,check=True,stdout=subprocess.DEVNULL)
 check(rpc('moderation_queue',{},m)[0]==403,'moderator without MFA cannot read queue')
 _,factor=call('/auth/v1/factors','POST',{'factor_type':'totp','friendly_name':'Place test'},m)
 secret=factor['totp']['secret'];fid=factor['id'];_,challenge=call('/auth/v1/factors/'+fid+'/challenge','POST',{},m)
 key=base64.b32decode(secret+'='*((-len(secret))%8));digest=hmac.new(key,struct.pack('>Q',int(time.time())//30),hashlib.sha1).digest();offset=digest[-1]&15
 otp=str((struct.unpack('>I',digest[offset:offset+4])[0]&0x7fffffff)%1000000).zfill(6)
 code,verified=call('/auth/v1/factors/'+fid+'/verify','POST',{'challenge_id':challenge['id'],'code':otp},m)
 check(code==200,'synthetic moderator completes MFA');m2=verified['access_token']

 city='Fixture city '+secrets.token_hex(6)
 ids=[]
 for name in ['Парк Б','Парк А']:
  payload={'client_id':str(uuid.uuid4()),'name_in':name,'category_in':'Парк','city_in':city,'latitude_in':53.9,'longitude_in':27.56,'description_in':'Synthetic fixture'}
  _,sid=rpc('submit_place',payload,a)
  queue=rpc('moderation_queue',{},m2)[1]
  check(any(p['id']==sid for p in queue['submissions']),'MFA moderator sees submitted fixture')
  code,pid=rpc('review_place_submission',{'submission_in':sid,'approve_in':True},m2);assert code==200;published.append(pid);ids.append(pid)
 _,page=rpc('search_places',{'city_in':city},a)
 check(page['total']==2 and [p['name'] for p in page['items']]==['Парк А','Парк Б'],'server page sorts and counts matching city')
 check(rpc('search_places',{'city_in':city,'query_in':'Парк А'},a)[1]['total']==1,'search is performed on server')
 check(rpc('search_places',{'city_in':city,'query_in':'%'},a)[1]['total']==0,'query wildcard is treated as literal text')
 check(rpc('search_places',{'city_in':city,'favorites_in':[ids[0]]},a)[1]['total']==1,'favorite filter applies before pagination')
 check(rpc('search_places',{'city_in':city,'offset_in':1},a)[1]['items'][0]['name']=='Парк Б','next page respects stable offset')
 check(rpc('search_places',{'city_in':city,'offset_in':-1},a)[0]>=400,'negative page offset rejected')
 report={'target_kind':'place','target_id':ids[0],'reason':'Synthetic moderation fixture'}
 _,created=call('/rest/v1/reports','POST',report|{'author_id':maker},a)
 own=call('/rest/v1/reports?target_id=eq.'+ids[0],token=a)[1];rid=own[0]['id']
 check(rpc('resolve_report',{'report_in':rid,'action_in':'hide','note_in':'Test'},a)[0]==403,'reporter cannot hide a publication')
 check(any(r['id']==rid for r in rpc('moderation_queue',{},m2)[1]['reports']),'MFA moderator sees complaint')
 check(rpc('resolve_report',{'report_in':rid,'action_in':'hide','note_in':'Fixture decision'},m2)[0]==204,'moderator records a hide decision')
 check(call('/rest/v1/places?id=eq.'+ids[0])[1]==[],'hidden place disappears from public catalog')
 check(not any(r['id']==rid for r in rpc('moderation_queue',{},m2)[1]['reports']),'resolved report leaves pending queue')
 check(rpc('search_places',{'city_in':city},a)[1]['total']==1,'server search excludes hidden place')
 check(rpc('moderation_queue',{},m)[0]==403,'old aal1 token stays rejected after MFA enrollment')
 rpc('revoke_my_sessions',{},m2)
 check(rpc('moderation_queue',{},m2)[0]==403,'revoked moderator JWT loses queue access')
finally:
 for pid in published:call('/rest/v1/places?id=eq.'+pid,'DELETE',staff=True)
 for uid in users:call('/auth/v1/admin/users/'+uid,'DELETE',staff=True)
print('Moderation and search checks:',checks)
