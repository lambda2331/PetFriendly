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
 payload={'client_id':str(uuid.uuid4()),'name_in':'Синтетическое место для теста','category_in':'Парк','city_in':'Минск','latitude_in':53.9,'longitude_in':27.56,'description_in':'Тестовая запись'}
 check(rpc('submit_place',payload)[0]>=400,'anonymous cannot submit')
 code,sid=rpc('submit_place',payload,a);check(code==200,'owner submits a venue')
 check(rpc('submit_place',payload,a)==(200,sid),'retry does not duplicate submission')
 _,own=call('/rest/v1/place_submissions?id=eq.'+sid,token=a)
 check(len(own)==1 and own[0]['status']=='pending','owner sees pending submission')
 _,other=call('/rest/v1/place_submissions?id=eq.'+sid,token=b);check(other==[],'other users cannot read private submissions')
 _,public=call('/rest/v1/places?source_id=eq.submission:'+sid);check(public==[],'pending point is absent from public map')
 check(call('/rest/v1/place_submissions?id=eq.'+sid,'PATCH',{'status':'approved'},a)[0]>=400,'owner cannot self-publish with direct write')
 check(rpc('review_place_submission',{'submission_in':sid,'approve_in':True},a)[0]==403,'non-moderator cannot publish')
 invalid={**payload,'client_id':str(uuid.uuid4()),'latitude_in':91}
 check(rpc('submit_place',invalid,a)[0]>=400,'invalid coordinates rejected on server')
 invalid={**payload,'client_id':str(uuid.uuid4()),'category_in':'Private home'}
 check(rpc('submit_place',invalid,a)[0]>=400,'unsupported category rejected on server')
 for category in ['Зоомагазин','Ветклиника']:
  code,new_id=rpc('submit_place',{**payload,'client_id':str(uuid.uuid4()),'category_in':category},a)
  check(code==200,'owner proposes '+category)
  code,private=call('/rest/v1/place_submissions?id=eq.'+new_id,token=b)
  check(code==200 and private==[],'new category stays private before moderation')

 # Synthetic local moderator only, set via the server-controlled role table.
 env={**os.environ,'DOCKER_HOST':'unix:///Users/artem.dudinskij/.colima/petfriendly/docker.sock'}
 subprocess.run(['docker','exec','supabase_db_PetFriendly','psql','-U','postgres','-d','postgres','-c',"update private.accounts set moderator=true where id='"+str(uuid.UUID(moderator))+"'"],env=env,check=True,stdout=subprocess.DEVNULL)
 check(rpc('review_place_submission',{'submission_in':sid,'approve_in':True},m)[0]==403,'moderator without MFA cannot publish')
 _,factor=call('/auth/v1/factors','POST',{'factor_type':'totp','friendly_name':'Place test'},m)
 secret=factor['totp']['secret'];fid=factor['id'];_,challenge=call('/auth/v1/factors/'+fid+'/challenge','POST',{},m)
 key=base64.b32decode(secret+'='*((-len(secret))%8));digest=hmac.new(key,struct.pack('>Q',int(time.time())//30),hashlib.sha1).digest();offset=digest[-1]&15
 otp=str((struct.unpack('>I',digest[offset:offset+4])[0]&0x7fffffff)%1000000).zfill(6)
 code,verified=call('/auth/v1/factors/'+fid+'/verify','POST',{'challenge_id':challenge['id'],'code':otp},m)
 check(code==200,'synthetic moderator completes MFA');m2=verified['access_token']
 code,pid=rpc('review_place_submission',{'submission_in':sid,'approve_in':True},m2);check(code==200 and isinstance(pid,str),'moderator with MFA publishes verified venue');published.append(pid)
 check(rpc('review_place_submission',{'submission_in':sid,'approve_in':True},m2)==(200,pid),'moderation retry is idempotent')
 _,public=call('/rest/v1/places?id=eq.'+pid)
 check(len(public)==1 and public[0]['pet_access']=='unknown' and 'author_id' not in public[0],'published venue preserves unknown access and hides author')
 code,export=rpc('export_my_data',{},a);check(code==200 and export['place_submissions'][0]['id']==sid,'account export includes own submissions')
 check(rpc('revoke_my_sessions',{},a)[0]==204,'owner revokes sessions')
 _,own=call('/rest/v1/place_submissions?id=eq.'+sid,token=a);check(own==[],'revoked JWT cannot read submission')
finally:
 for pid in published:call('/rest/v1/places?id=eq.'+pid,'DELETE',staff=True)
 for uid in users:call('/auth/v1/admin/users/'+uid,'DELETE',staff=True)
print('All '+str(checks)+' place checks passed')
