#!/usr/bin/env python3
"""Integration checks against this project's LOCAL Supabase only."""
import json,urllib.request,urllib.error,secrets,uuid,concurrent.futures
from pathlib import Path
config=json.loads(Path('config/backend-status.local.json').read_text())
base=config.get('API_URL','http://127.0.0.1:54321').rstrip('/')
if not base.startswith(('http://127.0.0.1:','http://localhost:')):raise SystemExit('Local endpoint required')
pub=config.get('PUBLISHABLE_KEY') or config['ANON_KEY'];admin=config.get('SERVICE_ROLE_KEY') or config.get('SECRET_KEY')
if not admin:raise SystemExit('Local admin key not available')
checks=0

def call(path,method='GET',data=None,token=None,admin_mode=False,prefer=None):
 headers={'apikey':admin if admin_mode else pub,'Content-Type':'application/json','Authorization':'Bearer '+(admin if admin_mode else token or pub)}
 if prefer:headers['Prefer']=prefer
 req=urllib.request.Request(base+path,headers=headers,data=json.dumps(data).encode() if data is not None else None,method=method)
 try:
  with urllib.request.urlopen(req,timeout=25) as response:
   raw=response.read();return response.status,json.loads(raw) if raw else None
 except urllib.error.HTTPError as e:
  raw=e.read();return e.code,json.loads(raw) if raw else None

def check(condition,name):
 global checks
 if not condition:raise AssertionError(name)
 checks+=1;print('PASS '+name)

def rpc(name,params,token):return call('/rest/v1/rpc/'+name,'POST',params,token)
users=[]
for _ in range(4):
 email='pf-'+secrets.token_hex(6)+'@example.test';password=secrets.token_urlsafe(24)
 code,user=call('/auth/v1/admin/users','POST',{'email':email,'password':password,'email_confirm':True},admin_mode=True)
 check(code in (200,201),'create local fixture user')
 code,session=call('/auth/v1/token?grant_type=password','POST',{'email':email,'password':password})
 check(code==200,'email sign-in')
 users.append({'id':user['id'],'token':session['access_token'],'email':email,'password':password})
a,b,c,d=users
code,signup=call('/auth/v1/signup','POST',{'email':'pf-signup-'+secrets.token_hex(6)+'@example.test','password':secrets.token_urlsafe(24)})
check(code==200 and not signup.get('access_token'),'registration waits for email confirmation')
code,pets=call('/rest/v1/pets','POST',{'owner_id':a['id'],'name':'Локальный тест','kind':'Собака','age':2},a['token'],prefer='return=representation')
check(code==201,'create own pet');pet=pets[0]['id']
code,_=call('/rest/v1/pets','POST',{'owner_id':a['id'],'name':'Чужой'},b['token'])
check(code==403,'cannot create pet for another owner')
code,_=call('/rest/v1/profiles?id=eq.'+a['id'],'PATCH',{'display_name':'Сломанный профиль'},b['token'])
_,profiles=call('/rest/v1/profiles?id=eq.'+a['id'],token=a['token'])
check(profiles[0]['display_name']!='Сломанный профиль','cannot edit another profile')
from datetime import datetime,timedelta,timezone
future=(datetime.now(timezone.utc)+timedelta(days=1)).isoformat()
code,rid=rpc('create_walk',{'pet_in':pet,'city_in':'Минск','starts_in':future,'duration_in':45,'description_in':'Тест','instructions_in':'Приватная инструкция'},a['token'])
check(code==200,'create walking request')
code,private=call('/rest/v1/walk_details?request_id=eq.'+rid,token=c['token'])
check(code==200 and private==[],'private instructions hidden from outsider')
for user in [b,c]:check(rpc('apply_walk',{'request_in':rid},user['token'])[0]==204,'helper applies')
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
 futures=[pool.submit(rpc,'assign_walk',{'request_in':rid,'helper_in':user['id']},a['token']) for user in [b,c]]
 results=[f.result() for f in futures]
check(sum(code==200 for code,_ in results)==1,'concurrent assignment selects exactly one helper')
selected=[b,c][next(i for i,(code,_)in enumerate(results)if code==200)]
check(rpc('assign_walk',{'request_in':rid,'helper_in':selected['id']},a['token'])[0]==200,'assignment retry is idempotent')
code,private=call('/rest/v1/walk_details?request_id=eq.'+rid,token=selected['token'])
check(code==200 and len(private)==1,'assigned helper sees instructions')
check(rpc('review_walk',{'request_in':rid,'rating_in':5},a['token'])[0]==403,'cannot review unfinished walk')
check(rpc('advance_walk',{'request_in':rid,'next_status':'in_progress'},a['token'])[0]==403,'owner cannot impersonate helper')
for status in ['in_progress','awaiting_confirmation']:check(rpc('advance_walk',{'request_in':rid,'next_status':status},selected['token'])[0]==204,'helper advances walk')
check(rpc('advance_walk',{'request_in':rid,'next_status':'completed'},a['token'])[0]==204,'owner confirms completion')
check(rpc('review_walk',{'request_in':rid,'rating_in':5,'body_in':'Тестовый отзыв'},a['token'])[0]==204,'completed walk can be reviewed')
check(rpc('review_walk',{'request_in':rid,'rating_in':1},a['token'])[0]==409,'one review per walk')
code,reviews=call('/rest/v1/walk_reviews?request_id=eq.'+rid,token=a['token'])
review_id=reviews[0]['id']
check(rpc('reply_walk_review',{'review_in':review_id,'body_in':'Спасибо за отзыв'},a['token'])[0]==403,'review author cannot impersonate helper reply')
check(rpc('reply_walk_review',{'review_in':review_id,'body_in':'Чужой ответ'},[u for u in [b,c] if u['id']!=selected['id']][0]['token'])[0]==403,'stranger cannot reply as helper')
check(rpc('reply_walk_review',{'review_in':review_id,'body_in':' '},selected['token'])[0]==400,'empty helper reply rejected')
check(rpc('reply_walk_review',{'review_in':review_id,'body_in':'x'*1001},selected['token'])[0]==400,'oversized helper reply rejected')
check(rpc('reply_walk_review',{'review_in':review_id,'body_in':' Спасибо за отзыв '},selected['token'])[0]==204,'assigned helper replies to own completed review')
code,reviews=call('/rest/v1/walk_reviews?id=eq.'+review_id,token=a['token'])
check(reviews[0]['helper_reply']=='Спасибо за отзыв' and reviews[0]['replied_at'] is not None,'reply and timestamp visible on published review')
check(call('/rest/v1/walk_reviews?id=eq.'+review_id,'PATCH',{'rating':1,'helper_reply':'Обход RPC'},selected['token'])[0]==403,'review direct writes remain forbidden')
check(call('/rest/v1/walk_reviews?id=eq.'+review_id,'PATCH',{'published':False},admin_mode=True)[0]==204,'test fixture hides review')
check(rpc('reply_walk_review',{'review_in':review_id,'body_in':'Ответ на скрытый отзыв'},selected['token'])[0]==403,'helper cannot reply to unpublished review')
check(call('/rest/v1/walk_reviews?id=eq.'+review_id,'PATCH',{'published':True},admin_mode=True)[0]==204,'test fixture restores review')

code,stats=rpc('helper_stats',{},c['token'])
helper=next(row for row in stats if row['id']==selected['id'])
check(code==200 and helper['rating']==5 and helper['review_count']==1 and helper['completed']==1,'ratings are server-derived and readable by others')
code,cid=rpc('open_direct',{'target':b['id']},a['token']);check(code==200,'open direct chat')
nonce=str(uuid.uuid4());params={'conversation_in':cid,'client_id':nonce,'body_in':'Приватный тест'}
code,mid=rpc('send_message',params,a['token']);check(code==200,'message saved')
code,repeat=rpc('send_message',params,a['token']);check(code==200 and repeat==mid,'message retry does not duplicate')
code,other=call('/rest/v1/messages?conversation_id=eq.'+cid,token=c['token']);check(code==200 and other==[],'outsider cannot read chat')
check(rpc('send_message',params,c['token'])[0]==403,'outsider cannot send to chat')
code,eid=rpc('create_event',{'title_in':'Локальная встреча','city_in':'Минск','starts_in':future,'capacity_in':2},a['token']);check(code==200,'create event')
check(rpc('join_event',{'event_in':eid},b['token'])[0]==204,'join last event place')
check(rpc('join_event',{'event_in':eid},c['token'])[0]>=400,'event capacity enforced')
code,gid=rpc('create_group',{'title_in':'Тестовое сообщество'},a['token']);check(code==200,'create group')
check(rpc('join_group',{'group_in':gid},b['token'])[0]==204,'join group')
check(rpc('leave_group',{'group_in':gid},b['token'])[0]==204,'leave group')
check(rpc('request_account_deletion',{},d['token'])[0]==204,'request deletion after recent authentication')
code,hidden=call('/rest/v1/profiles?id=eq.'+d['id'],token=a['token']);check(code==200 and hidden==[],'deletion immediately hides profile')
check(rpc('helper_stats',{},d['token'])[0]==403,'deletion revokes existing JWT access')
check(call('/auth/v1/admin/users/'+d['id'],'DELETE',admin_mode=True)[0]==200,'delete local fixture account')
check(rpc('revoke_my_sessions',{},b['token'])[0]==204,'revoke all sessions')
check(rpc('helper_stats',{},b['token'])[0]==403,'revoked JWT denied')
code,places=call('/rest/v1/places?select=id,source_id,pet_access&limit=2000')
check(code==200 and len([p for p in places if p['source_id'].startswith(('node/','way/','relation/'))])>=130,'OSM seed is queryable without private account data')
# Only synthetic local test credentials are stored for native integration tests.
client=json.loads(Path('config/supabase.local.json').read_text());client['TEST_EMAIL']=a['email'];client['TEST_PASSWORD']=a['password'];Path('config/test.local.json').write_text(json.dumps(client,indent=2)+'\n')
print('All '+str(checks)+' backend checks passed')
