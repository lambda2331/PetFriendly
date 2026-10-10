#!/usr/bin/env python3
import json,urllib.request,urllib.error,secrets,time,hmac,hashlib,base64,struct,argparse
from pathlib import Path
parser=argparse.ArgumentParser();parser.add_argument('--staging',action='store_true');args=parser.parse_args()
s=json.loads(Path('config/staging-backend.local.json' if args.staging else 'config/backend-status.local.json').read_text());base=s['API_URL'];pub=s.get('PUBLISHABLE_KEY')or s['ANON_KEY'];admin=s['SERVICE_ROLE_KEY']
if args.staging:
 if base!='https://cbkmxtplhcdomyeyrwyi.supabase.co':raise SystemExit('Wrong staging project')
elif not base.startswith('http://127.0.0.1:'):raise SystemExit('Local endpoint required')
def call(path,method='GET',data=None,token=None,admin_mode=False):
 req=urllib.request.Request(base+path,method=method,headers={'apikey':admin if admin_mode else pub,'Authorization':'Bearer '+(admin if admin_mode else token or pub),'Content-Type':'application/json'},data=json.dumps(data).encode() if data is not None else None)
 try:
  with urllib.request.urlopen(req,timeout=30)as response:
   raw=response.read();return response.status,json.loads(raw)if raw else None
 except urllib.error.HTTPError as e:
  raw=e.read();return e.code,json.loads(raw)if raw else None
checks=0
def check(ok,name):
 global checks
 if not ok:raise AssertionError(name)
 checks+=1;print('PASS '+name)
user=None
try:
 email='mfa-'+secrets.token_hex(5)+'@example.test';password=secrets.token_urlsafe(24)
 code,user=call('/auth/v1/admin/users','POST',{'email':email,'password':password,'email_confirm':True},admin_mode=True);check(code in(200,201),'MFA fixture created')
 code,session=call('/auth/v1/token?grant_type=password','POST',{'email':email,'password':password});check(code==200,'MFA fixture signed in');token=session['access_token']
 code,factor=call('/auth/v1/factors','POST',{'factor_type':'totp','friendly_name':'Local verification'},token);check(code==200,'TOTP enrollment enabled');secret=factor['totp']['secret'];fid=factor['id']
 code,challenge=call('/auth/v1/factors/'+fid+'/challenge','POST',{},token);check(code==200,'TOTP challenge issued')
 key=base64.b32decode(secret+'='*((-len(secret))%8));digest=hmac.new(key,struct.pack('>Q',int(time.time())//30),hashlib.sha1).digest();offset=digest[-1]&15;otp=str((struct.unpack('>I',digest[offset:offset+4])[0]&0x7fffffff)%1000000).zfill(6)
 code,verified=call('/auth/v1/factors/'+fid+'/verify','POST',{'challenge_id':challenge['id'],'code':otp},token);check(code==200,'TOTP verified');aal2=verified['access_token']
 check(call('/rest/v1/rpc/helper_stats','POST',{},token)[0]==403,'aal1 cannot access protected data after MFA enrollment')
 check(call('/rest/v1/rpc/helper_stats','POST',{},aal2)[0]==200,'aal2 can access protected data')
 check(call('/functions/v1/delete-account','POST',{})[0]==401,'deletion rejects unauthenticated request')
 check(call('/functions/v1/delete-account','POST',{},token)[0]==403,'deletion requires second factor when enrolled')
 code,result=call('/functions/v1/delete-account','POST',{},aal2);check(code==200 and result.get('deleted')==True,'account deletion function completes cleanup')
 check(call('/auth/v1/admin/users/'+user['id'],admin_mode=True)[0]==404,'deleted account cannot be retrieved')
 check(call('/rest/v1/rpc/claim_notifications','POST',{},aal2)[0]==403,'users cannot claim push jobs')
 print('All '+str(checks)+' security checks passed')
finally:
 if user and user.get('id'):call('/auth/v1/admin/users/'+user['id'],'DELETE',admin_mode=True)
