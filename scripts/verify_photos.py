#!/usr/bin/env python3
"""Private photo ACL, server encoding and deletion checks; disposable local fixtures only."""
import json,secrets,urllib.request,urllib.error,uuid,base64,zlib,struct,argparse
from pathlib import Path
parser=argparse.ArgumentParser();parser.add_argument('--staging',action='store_true');args=parser.parse_args()
cfg=json.loads(Path('config/staging-backend.local.json' if args.staging else 'config/backend-status.local.json').read_text());base=cfg['API_URL'];pub=cfg['PUBLISHABLE_KEY'];staff=cfg['SERVICE_ROLE_KEY']
if args.staging:
 if base!='https://cbkmxtplhcdomyeyrwyi.supabase.co':raise SystemExit('Wrong staging project')
elif not base.startswith('http://127.0.0.1:'):raise SystemExit('Local backend required')
def call(path,data=None,token=None,admin=False,method=None,binary=False):
 global response_cache
 response_cache={}
 key=staff if admin else pub
 body=data if isinstance(data,bytes) else json.dumps(data).encode() if data is not None else None
 req=urllib.request.Request(base+path,data=body,method=method or ('POST' if body is not None else 'GET'),headers={'apikey':key,'Authorization':'Bearer '+(key if admin else token or pub),'Content-Type':'image/png' if isinstance(data,bytes) else 'application/json'})
 try:
  with urllib.request.urlopen(req,timeout=90) as r:
   response_cache={k:r.headers.get(k) for k in ('Cache-Control','Age','CF-Cache-Status')};raw=r.read();return r.status,raw if binary else json.loads(raw) if raw else None
 except urllib.error.HTTPError as e:
  return e.code,None
count=0;users=[];response_cache={}
def check(ok,name):
 global count
 assert ok,name
 count+=1;print('PASS '+name,flush=True)
def account():
 email='photo-'+secrets.token_hex(6)+'@example.test';password=secrets.token_urlsafe(24)
 code,u=call('/auth/v1/admin/users',{'email':email,'password':password,'email_confirm':True},admin=True);assert code in (200,201)
 users.append(u['id']);session=call('/auth/v1/token?grant_type=password',{'email':email,'password':password})[1];return u['id'],session['access_token']
def chunk(kind,data):return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',2,2,8,2,0,0,0))+chunk(b'tEXt',b'Description\x00PRIVATE_EXIF_TEST')+chunk(b'IDAT',zlib.compress(b'\x00\xff\x00\x00\x00\xff\x00'*2))+chunk(b'IEND',b'')
try:
 uid,token=account();other,other_token=account()
 endpoint='/functions/v1/upload-photo?kind=profile&target='+uid
 check(call(endpoint,png)[0]==401,'anonymous cannot upload')
 check(call(endpoint,png,other_token)[0]==403,'cannot replace another owner photo')
 check(call('/storage/v1/object/petfriendly-photos/'+uid+'/forged.jpg',png,token)[0]>=400,'direct client upload rejected')
 check(call(endpoint,png,token)[0]==200,'owner upload succeeds through server encoder')
 photo=call('/rest/v1/entity_photos?target_id=eq.'+uid,token=token)[1][0]['object_path'];path='/storage/v1/object/authenticated/petfriendly-photos/'+photo
 read_endpoint='/functions/v1/read-photo';read_input={'kind':'profile','target':uid}
 code,encoded=call(read_endpoint,read_input,token,binary=True)
 check(response_cache.get('Cache-Control')=='private, no-store, max-age=0','photo response forbids caching')
 check(code==200 and encoded[:2]==b'\xff\xd8' and b'PRIVATE_EXIF_TEST' not in encoded,'stored bytes are fresh JPEG without original metadata')
 check(call(read_endpoint,read_input,binary=True)[0]==401,'anonymous cannot download private bytes')
 check(call(path,token=token,binary=True)[0]>=400,'direct authenticated Storage read is closed')
 check(call(read_endpoint,read_input,other_token,binary=True)[0]==200,'unblocked signed-in community can view profile photo')
 check(call('/rest/v1/entity_photos',{'kind':'profile','target_id':uid,'owner_id':uid,'object_path':uid+'/forged.jpg'},token)[0]>=400,'client cannot forge published photo reference')
 check(call('/rest/v1/blocks',{'user_id':other,'target_id':uid},other_token)[0]==201,'block saved on server')
 check(call('/rest/v1/entity_photos?target_id=eq.'+uid,token=other_token)[1]==[],'block hides photo metadata')
 check(call(read_endpoint,read_input,other_token,binary=True)[0]>=400,'same photo request denied immediately after block')
 call('/rest/v1/rpc/revoke_my_sessions',{},token)
 check(call(read_endpoint,read_input,token,binary=True)[0]>=400,'existing revoked JWT cannot read photo')
 # Deletion endpoint supports a retry after revocation: authorize fixture via admin account flag through its RPC flow instead.
 delete_uid,delete_token=account()
 check(call('/functions/v1/upload-photo?kind=profile&target='+delete_uid,png,delete_token)[0]==200,'deletion fixture photo uploaded')
 deletion_path=call('/rest/v1/entity_photos?target_id=eq.'+delete_uid,token=delete_token)[1][0]['object_path']
 check(call('/functions/v1/delete-account',{},delete_token)[0]==200,'account deletion cleans owned Storage blobs')
 check(call('/storage/v1/object/list/petfriendly-photos',{'prefix':delete_uid,'limit':100},admin=True)[1]==[],'deleted account photo no longer stored')
 check(call(read_endpoint,{'kind':'profile','target':delete_uid},delete_token,binary=True)[0]==401,'deleted account cannot obtain cached photo through endpoint')
 users.remove(delete_uid)
 print('Photo checks:',count)
finally:
 for uid in users:
  code,items=call('/storage/v1/object/list/petfriendly-photos',{'prefix':uid,'limit':100},admin=True)
  if items:call('/storage/v1/object/petfriendly-photos',{'prefixes':[uid+'/'+i['name'] for i in items]},admin=True,method='DELETE')
  call('/auth/v1/admin/users/'+uid,admin=True,method='DELETE')
