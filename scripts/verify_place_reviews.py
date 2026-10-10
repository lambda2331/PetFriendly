#!/usr/bin/env python3
"""Verify inline venue reviews against the isolated LOCAL backend only."""
import json, secrets, uuid, urllib.request, urllib.error
from pathlib import Path
cfg=json.loads(Path('config/backend-status.local.json').read_text())
base=cfg['API_URL'].rstrip('/');pub=cfg.get('PUBLISHABLE_KEY') or cfg['ANON_KEY'];admin=cfg['SERVICE_ROLE_KEY']
if not base.startswith('http://127.0.0.1:'):raise SystemExit('Local endpoint required')
def call(path,method='GET',data=None,token=None,staff=False):
 key=admin if staff else pub
 req=urllib.request.Request(base+path,method=method,headers={'apikey':key,'Authorization':'Bearer '+(key if staff else token or pub),'Content-Type':'application/json'},data=json.dumps(data).encode() if data is not None else None)
 try:
  with urllib.request.urlopen(req,timeout=30) as r:
   raw=r.read();return r.status,json.loads(raw) if raw else None
 except urllib.error.HTTPError as e:
  raw=e.read();return e.code,json.loads(raw) if raw else None
users=[];vid=str(uuid.uuid4());checks=0

def check(ok,label):
 global checks
 if not ok:raise AssertionError(label)
 checks+=1;print('PASS '+label)
def fixture():
 email='review-'+secrets.token_hex(6)+'@example.test';password=secrets.token_urlsafe(24)
 c,u=call('/auth/v1/admin/users','POST',{'email':email,'password':password,'email_confirm':True},staff=True)
 if c not in(200,201):raise AssertionError('Fixture creation')
 users.append(u['id']);c,s=call('/auth/v1/token?grant_type=password','POST',{'email':email,'password':password})
 if c!=200:raise AssertionError('Fixture login')
 return u['id'],s['access_token']
def stats(token=None):return call('/rest/v1/rpc/place_rating_stats','POST',{},token)
try:
 a,ta=fixture();b,tb=fixture()
 c,_=call('/rest/v1/places','POST',{'id':vid,'source':'community','source_id':'review-fixture:'+vid,'name':'Синтетический сквер','category':'Ветклиника','city':'Минск','latitude':53.9,'longitude':27.56},staff=True)
 check(c==201,'create synthetic public venue')
 check(stats()[0]>=400,'anonymous cannot execute authenticated rating RPC')
 check(not any(r['place_id']==vid for r in stats(ta)[1]),'unrated venue has no zero-star aggregate')
 check(call('/rest/v1/place_reviews','POST',{'place_id':vid,'author_id':a,'rating':5,'body':'Синтетический отзыв'},ta)[0]==201,'author posts review')
 check(call('/rest/v1/place_reviews','POST',{'place_id':vid,'author_id':b,'rating':3},tb)[0]==201,'second author rates venue')
 row=next(r for r in stats(ta)[1] if r['place_id']==vid)
 check(float(row['average_rating'])==4 and row['review_count']==2,'server derives average from all reviews')
 check(call('/rest/v1/place_reviews','POST',{'place_id':vid,'author_id':a,'rating':1},ta)[0]==409,'duplicate review rejected')
 check(call('/rest/v1/place_reviews','POST',{'place_id':vid,'author_id':a,'rating':1},tb)[0]==403,'cannot impersonate another author')
 check(call('/rest/v1/places?id=eq.'+vid,'PATCH',{'published':False},ta)[0]>=400,'client cannot rewrite catalog or aggregates')
 c,export=call('/rest/v1/rpc/export_my_data','POST',{},ta)
 check(c==200 and len(export['place_reviews'])==1,'own venue review is included in account export')
 call('/rest/v1/places?id=eq.'+vid,'PATCH',{'published':False},staff=True)
 check(not any(r['place_id']==vid for r in stats(ta)[1]),'hidden venues excluded from public aggregates')
 call('/rest/v1/places?id=eq.'+vid,'PATCH',{'published':True},staff=True)
 call('/auth/v1/admin/users/'+b,'DELETE',staff=True);users.remove(b)
 row=next(r for r in stats(ta)[1] if r['place_id']==vid)
 check(float(row['average_rating'])==5 and row['review_count']==1,'deleting author removes their review and updates aggregate')
 call('/rest/v1/rpc/revoke_my_sessions','POST',{},ta)
 check(stats(ta)[0]==403,'revoked JWT cannot read rating RPC')
finally:
 call('/rest/v1/places?id=eq.'+vid,'DELETE',staff=True)
 for uid in users:call('/auth/v1/admin/users/'+uid,'DELETE',staff=True)
print('All '+str(checks)+' venue review checks passed')
