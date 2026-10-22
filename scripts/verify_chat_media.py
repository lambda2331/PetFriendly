#!/usr/bin/env python3
"""Isolated local synthetic media, membership, Storage and revocation checks."""
import json,uuid,secrets,urllib.request,urllib.error,urllib.parse,struct,zlib
from pathlib import Path
cfg=json.loads(Path('config/backend-status.local.json').read_text());base=cfg['API_URL'];pub=cfg['PUBLISHABLE_KEY'];staff=cfg['SERVICE_ROLE_KEY']
if not base.startswith('http://127.0.0.1:'):raise SystemExit('Local backend required')
users=[];objects=[];cid=str(uuid.uuid4());count=0

def call(path,data=None,token=None,admin=False,method=None,binary=False,mime='application/json'):
 key=staff if admin else pub
 raw=data if isinstance(data,bytes) else json.dumps(data).encode() if data is not None else None
 req=urllib.request.Request(base+path,data=raw,method=method or ('POST' if raw is not None else 'GET'),headers={'apikey':key,'Authorization':'Bearer '+(key if admin else token or pub),'Content-Type':mime})
 try:
  with urllib.request.urlopen(req,timeout=60) as r:
   body=r.read();return r.status,body if binary else json.loads(body) if body else None,r.headers
 except urllib.error.HTTPError as e:return e.code,None,{}
def check(ok,label):
 global count
 if not ok:raise AssertionError(label)
 count+=1;print('PASS '+label,flush=True)
def fixture():
 email='media-'+secrets.token_hex(6)+'@example.test';password=secrets.token_urlsafe(24)
 status,user,_=call('/auth/v1/admin/users',{'email':email,'password':password,'email_confirm':True},admin=True);check(status in (200,201),'synthetic account created');users.append(user['id'])
 _,session,_=call('/auth/v1/token?grant_type=password',{'email':email,'password':password});return user['id'],session['access_token']
def upload(kind,data,token,nonce=None,caption=''):
 query=urllib.parse.urlencode({'conversation':cid,'client_id':nonce or str(uuid.uuid4()),'kind':kind})
 metadata=json.dumps({'caption':caption,'mime':'image/png' if kind=='image' else 'video/mp4'}).encode()
 return call('/functions/v1/chat-media?'+query,struct.pack('>I',len(metadata))+metadata+data,token,mime='application/octet-stream')
def read(mid,token):return call('/functions/v1/chat-media?mode=read&message='+mid,b'',token,binary=True)
def chunk(kind,data):return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',2,2,8,2,0,0,0))+chunk(b'tEXt',b'Description\x00PRIVATE_PHOTO_TEST')+chunk(b'IDAT',zlib.compress(b'\x00\xff\x00\x00\x00\xff\x00'*2))+chunk(b'IEND',b'')
try:
 a,ta=fixture();b,tb=fixture();c,tc=fixture()
 check(call('/rest/v1/conversations',{'id':cid,'kind':'direct'},admin=True)[0]==201,'synthetic conversation created')
 call('/rest/v1/conversation_members',[{'conversation_id':cid,'user_id':a},{'conversation_id':cid,'user_id':b}],admin=True)
 check(upload('image',png,None)[0]==401,'anonymous upload rejected')
 check(upload('image',png,tc)[0]==403,'outsider upload rejected')
 check(call('/rest/v1/rpc/publish_chat_media',{},ta)[0]>=400,'client cannot invoke privileged publish')
 check(call('/storage/v1/object/petfriendly-chat/'+a+'/forged.jpg',png,ta,mime='image/jpeg')[0]>=400,'direct Storage upload rejected')
 nonce=str(uuid.uuid4());status,result,_=upload('image',png,ta,nonce,caption='🐕'*501);check(status==200,'member sends reencoded photo with 501 Unicode characters');mid=result['id']
 check(call('/rest/v1/messages?id=eq.'+mid,token=ta)[1][0]['body']=='🐕'*501,'Unicode caption is preserved exactly')
 check(upload('image',png,ta,caption='🐕'*1001)[0]==400,'caption above 1000 Unicode characters is rejected')
 status,retry,_=upload('image',png,ta,nonce,caption='🐕'*501);check(status==200 and retry['id']==mid,'retry creates one message')
 status,rows,_=call('/rest/v1/chat_attachments?message_id=eq.'+mid,token=ta);check(status==200 and len(rows)==1,'one private attachment reference');objects.extend(x['object_path'] for x in rows)
 path=rows[0]['object_path']
 check(read(mid,tc)[0]==404,'outsider cannot download')
 check(call('/rest/v1/chat_attachments?message_id=eq.'+mid,token=tc)[1]==[],'outsider cannot enumerate media')
 check(call('/storage/v1/object/authenticated/petfriendly-chat/'+path,token=tb,binary=True)[0]>=400,'member cannot bypass read endpoint')
 status,data,headers=read(mid,tb);check(status==200 and data[:2]==b'\xff\xd8' and b'PRIVATE_PHOTO_TEST' not in data,'member reads JPEG without original metadata')
 check(headers.get('Cache-Control')=='private, no-store, max-age=0','media response disables caching')
 video=Path('test/fixtures/chat-video.mp4').read_bytes()
 check(upload('video',video,ta)[0]==400,'video upload is disabled')
 check(upload('image',b'x'*(5*1024*1024+1),ta)[0]==413,'photo above 5 MiB is rejected before decoding')
 status,export,_=call('/rest/v1/rpc/export_my_data',{},ta);check(status==200 and len(export['chat_attachments'])==1,'recent-auth export includes own photo reference')
 call('/rest/v1/blocks',{'user_id':b,'target_id':a},tb)
 check(read(mid,tb)[0]==404,'block removes subsequent attachment access')
 call('/rest/v1/blocks?user_id=eq.'+b+'&target_id=eq.'+a,token=tb,method='DELETE')
 call('/rest/v1/conversation_members?conversation_id=eq.'+cid+'&user_id=eq.'+b,admin=True,method='DELETE')
 check(read(mid,tb)[0]==404,'removed membership cannot reuse download')
 # Session remains valid but membership was removed between upload authorization and commit.
 import base64
 payload=json.loads(base64.urlsafe_b64decode(tb.split('.')[1]+'==='))
 race={'claims_in':{'sub':b,'session_id':payload['session_id'],'aal':payload['aal']},'conversation_in':cid,'client_id':str(uuid.uuid4()),'body_in':'','path_in':b+'/never-published.jpg','kind_in':'image','mime_in':'image/jpeg','size_in':100,'duration_in':None}
 check(call('/rest/v1/rpc/publish_chat_media',race,admin=True)[0]==403,'commit rechecks membership after upload')
 # Full account deletion must also remove media blobs before deleting identity.
 call('/rest/v1/conversation_members',{'conversation_id':cid,'user_id':c},admin=True)
 check(upload('image',png,tc)[0]==200,'deletion fixture uploads private media')
 check(call('/functions/v1/delete-account',{},tc)[0]==200,'account deletion cleans chat bucket')
 check(call('/storage/v1/object/list/petfriendly-chat',{'prefix':c,'limit':100},admin=True)[1]==[],'deleted account leaves no owned media blobs')

 call('/rest/v1/rpc/revoke_my_sessions',{},ta)
 check(read(mid,ta)[0]==404,'revoked existing JWT cannot read attachment')
 check(upload('image',png,ta)[0]==403,'revoked existing JWT cannot upload')
finally:
 # Only disposable local objects belonging to this script's own synthetic users.
 for user in users:
  _,rows,_=call('/storage/v1/object/list/petfriendly-chat',{'prefix':user,'limit':100},admin=True)
  if rows:call('/storage/v1/object/petfriendly-chat',{'prefixes':[user+'/'+x['name'] for x in rows]},admin=True,method='DELETE')
 call('/rest/v1/conversations?id=eq.'+cid,admin=True,method='DELETE')
 for user in users:call('/auth/v1/admin/users/'+user,admin=True,method='DELETE')
print('Chat media checks:',count)
