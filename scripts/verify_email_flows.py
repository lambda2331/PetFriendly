#!/usr/bin/env python3
"""Local Auth + Mailpit only, synthetic signup/recovery, no credentials printed."""
import json,secrets,urllib.request,urllib.error,urllib.parse,hashlib,base64,time,re,html
from pathlib import Path
cfg=json.loads(Path('config/backend-status.local.json').read_text())
base=cfg['API_URL'];pub=cfg['PUBLISHABLE_KEY'];admin=cfg['SERVICE_ROLE_KEY']
if base!='http://127.0.0.1:54321':raise SystemExit('Exact local backend required')
mail='http://127.0.0.1:54324';uid=None;email='email-flow-'+secrets.token_hex(6)+'@example.test';message_ids=set();count=0
def call(path,data=None,token=None,staff=False,method=None):
 key=admin if staff else pub
 req=urllib.request.Request(base+path,data=json.dumps(data).encode() if data is not None else None,method=method,headers={'apikey':key,'Authorization':'Bearer '+(token or key),'Content-Type':'application/json'})
 try:
  with urllib.request.urlopen(req,timeout=20) as r:return r.status,json.load(r)
 except urllib.error.HTTPError as e:return e.code,None
def check(ok,label):
 global count
 if not ok:raise AssertionError(label)
 count+=1;print('PASS '+label,flush=True)
def challenge(verifier):return base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).decode().rstrip('=')
def messages():
 with urllib.request.urlopen(mail+'/api/v1/messages?limit=100',timeout=5) as r:data=json.load(r)
 result=[m for m in data.get('messages',[]) if any(t.get('Address')==email for t in m.get('To',[]))]
 message_ids.update(m['ID'] for m in result);return result
def latest_mail(previous=0):
 for _ in range(30):
  found=messages()
  if len(found)>previous:
   with urllib.request.urlopen(mail+'/api/v1/message/'+found[0]['ID'],timeout=5) as r:return json.load(r)
  time.sleep(.2)
 raise AssertionError('Synthetic email was not delivered locally')
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args,**kwargs):return None
def verify_link(body):
 content=html.unescape(body.get('HTML','')+' '+body.get('Text',''))
 links=re.findall(r'https?://[^\s"<>]+',content)
 link=next((v for v in links if urllib.parse.urlparse(v).path=='/auth/v1/verify'),None)
 check(link is not None,'email contains verification link')
 parsed=urllib.parse.urlparse(link)
 if parsed.scheme!='http' or parsed.hostname!='127.0.0.1' or parsed.port!=54321:raise AssertionError('Unexpected email endpoint')
 try:urllib.request.build_opener(NoRedirect).open(link,timeout=10)
 except urllib.error.HTTPError as e:
  check(e.code in (302,303),'verification redirects to mobile callback')
  target=urllib.parse.urlparse(e.headers.get('Location',''))
  check(target.scheme=='petfriendly' and target.netloc=='auth' and target.path=='/callback','callback matches approved mobile address')
  values=urllib.parse.parse_qs(target.query)
  check('code' in values and 'access_token' not in values,'PKCE callback exposes code, not access token')
  return values['code'][0]
 raise AssertionError('Verification did not return callback')
try:
 password=secrets.token_urlsafe(24);verifier=secrets.token_urlsafe(48)
 redirect=urllib.parse.urlencode({'redirect_to':'petfriendly://auth/callback'})
 code,data=call('/auth/v1/signup?'+redirect,{'email':email,'password':password,'code_challenge':challenge(verifier),'code_challenge_method':'s256'})
 uid=(data.get('user',{}) or {}).get('id') or data.get('id') if isinstance(data,dict) else None
 check(code==200 and uid and not data.get('access_token'),'signup waits for email confirmation')
 check(call('/auth/v1/token?grant_type=password',{'email':email,'password':password})[0]>=400,'unconfirmed account cannot sign in')
 first=latest_mail();check(bool(first),'signup email delivered to local Mailpit')
 time.sleep(1.1)
 before=len(messages())
 verifier=secrets.token_urlsafe(48)
 check(call('/auth/v1/resend?'+redirect,{'type':'signup','email':email,'code_challenge':challenge(verifier),'code_challenge_method':'s256'})[0]==200,'confirmation can be resent with fresh PKCE proof')
 auth_code=verify_link(latest_mail(before))
 check(call('/auth/v1/token?grant_type=pkce',{'auth_code':auth_code,'code_verifier':secrets.token_urlsafe(48)})[0]>=400,'wrong device verifier is rejected')
 code,session=call('/auth/v1/token?grant_type=pkce',{'auth_code':auth_code,'code_verifier':verifier})
 check(code==200 and bool(session.get('access_token')),'matching signup verifier establishes session')
 check(call('/auth/v1/token?grant_type=pkce',{'auth_code':auth_code,'code_verifier':verifier})[0]>=400,'signup callback cannot be replayed')
 check(call('/auth/v1/token?grant_type=password',{'email':email,'password':password})[0]==200,'confirmed account signs in with password')
 verifier=secrets.token_urlsafe(48);before=len(messages())
 check(call('/auth/v1/recover?'+redirect,{'email':email,'code_challenge':challenge(verifier),'code_challenge_method':'s256'})[0]==200,'recovery accepts email request')
 auth_code=verify_link(latest_mail(before))
 code,session=call('/auth/v1/token?grant_type=pkce',{'auth_code':auth_code,'code_verifier':verifier})
 check(code==200 and bool(session.get('access_token')),'recovery exchanges same-device PKCE proof')
 new_password=secrets.token_urlsafe(24)
 check(call('/auth/v1/user',{'password':new_password},token=session['access_token'],method='PUT')[0]==200,'recovery session sets new password')
 check(call('/auth/v1/token?grant_type=password',{'email':email,'password':password})[0]>=400,'old password no longer signs in')
 check(call('/auth/v1/token?grant_type=password',{'email':email,'password':new_password})[0]==200,'new password signs in')
 check(call('/auth/v1/recover?'+redirect,{'email':'missing-'+secrets.token_hex(6)+'@example.test'})[0]==200,'unknown recovery address receives the same response status')
 print('Local email checks:',count)
finally:
 if uid:call('/auth/v1/admin/users/'+uid,staff=True,method='DELETE')
 if message_ids:
  req=urllib.request.Request(mail+'/api/v1/messages',data=json.dumps({'IDs':list(message_ids)}).encode(),method='DELETE',headers={'Content-Type':'application/json'})
  with urllib.request.urlopen(req,timeout=5):pass
