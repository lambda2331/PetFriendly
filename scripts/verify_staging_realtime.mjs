// Disposable synthetic fixtures in the single approved staging project.
// Run with Node 22+; no tokens, messages or contact data are logged.
import {readFile} from 'node:fs/promises';
import {randomUUID,randomBytes} from 'node:crypto';
import assert from 'node:assert/strict';

const cfg=JSON.parse(await readFile('config/staging-backend.local.json','utf8'));
const base=cfg.API_URL;
assert.equal(base,'https://cbkmxtplhcdomyeyrwyi.supabase.co');
const users=[],conversations=[],sockets=[];
let checks=0;
function check(ok,label){assert.ok(ok,label);console.log('PASS '+label);checks++;}
async function call(path,data,token,admin=false,method){
  const key=admin?cfg.SERVICE_ROLE_KEY:cfg.PUBLISHABLE_KEY;
  const response=await fetch(base+path,{method:method??(data===undefined?'GET':'POST'),
    headers:{apikey:key,'Content-Type':'application/json',...(admin||token?{Authorization:'Bearer '+(admin?key:token)}:{})},
    body:data===undefined?undefined:JSON.stringify(data),signal:AbortSignal.timeout(20000)});
  const raw=await response.text();let value=null;
  try{if(raw)value=JSON.parse(raw);}catch{}
  return {status:response.status,value};
}
const rpc=(name,data,user)=>call('/rest/v1/rpc/'+name,data,user.token);
const delay=ms=>new Promise(resolve=>setTimeout(resolve,ms));
async function subscribe(user,filterUser){
  const url=new URL(base.replace('https:','wss:')+'/realtime/v1/websocket');
  url.searchParams.set('apikey',cfg.PUBLISHABLE_KEY);url.searchParams.set('vsn','1.0.0');
  const ws=new WebSocket(url);sockets.push(ws);
  const records=[],topic='realtime:staging-check-'+randomUUID();
  await new Promise((resolve,reject)=>{
    const timeout=setTimeout(()=>reject(new Error('Realtime subscription timed out')),20000);
    ws.addEventListener('open',()=>ws.send(JSON.stringify({topic,event:'phx_join',ref:'1',join_ref:'1',payload:{
      config:{broadcast:{self:false},presence:{key:''},postgres_changes:[{event:'INSERT',schema:'public',table:'notifications',filter:'user_id=eq.'+filterUser}],private:false},access_token:user.token}})));
    ws.addEventListener('message',event=>{
      const message=JSON.parse(event.data);
      if(message.event==='phx_reply'&&message.ref==='1'){
        if(message.payload.status==='ok'){clearTimeout(timeout);resolve();}
        else{clearTimeout(timeout);reject(new Error('Realtime subscription rejected'));}
      }
      if(message.event==='postgres_changes')records.push(message.payload.data.record);
    });
    ws.addEventListener('error',()=>{clearTimeout(timeout);reject(new Error('Realtime transport failed'));},{once:true});
  });
  return records;
}
async function awaitRecord(records,context){
  for(let i=0;i<120;i++){if(records.some(r=>r.context_id===context))return true;await delay(100);}
  return false;
}
try{
  for(let i=0;i<3;i++){
    const email='realtime-'+randomBytes(6).toString('hex')+'@example.test',password=randomBytes(24).toString('base64url');
    const created=await call('/auth/v1/admin/users',{email,password,email_confirm:true},undefined,true);
    assert.ok([200,201].includes(created.status),'Synthetic account creation');
    const user={id:created.value.id};users.push(user);
    const session=await call('/auth/v1/token?grant_type=password',{email,password});
    assert.equal(session.status,200,'Synthetic account login');user.token=session.value.access_token;
  }
  const [a,b,c]=users;
  const first=await rpc('open_direct',{target:b.id},a);assert.equal(first.status,200);conversations.push(first.value);
  const control=await rpc('open_direct',{target:c.id},a);assert.equal(control.status,200);conversations.push(control.value);
  const own=await subscribe(b,b.id),outsider=await subscribe(c,b.id),liveControl=await subscribe(c,c.id);
  check(true,'three cloud realtime subscriptions established');
  const send=async conversation=>{
    const result=await rpc('send_message',{conversation_in:conversation,client_id:randomUUID(),body_in:'Synthetic realtime check'},a);
    assert.equal(result.status,200,'Synthetic message saved');return result.value;
  };
  await send(first.value);await send(control.value);
  check(await awaitRecord(own,first.value),'member receives own cloud notification');
  check(await awaitRecord(liveControl,control.value),'independent authorized realtime control receives notification');
  check(own.every(r=>!('body' in r)&&!('message' in r)),'notification payload does not contain chat text');
  check(outsider.length===0,'outsider subscription receives no other user notifications');
  const hidden=await call('/rest/v1/messages?conversation_id=eq.'+first.value,undefined,c.token);
  check(hidden.status===200&&hidden.value.length===0,'outsider cannot fetch private chat');
  const revocation=await rpc('revoke_my_sessions',{},b);
  check(revocation.status===204,'member revokes session while socket remains connected');
  const oldCount=own.length,controlCount=liveControl.length;
  const secondMessage=await send(first.value);await send(control.value);
  for(let i=0;i<120&&liveControl.length===controlCount;i++)await delay(100);
  check(liveControl.length>controlCount,'authorized control still receives changes after revocation');
  const persisted=await call('/rest/v1/messages?id=eq.'+secondMessage,undefined,a.token);
  check(persisted.status===200&&persisted.value.length===1,'post-revocation message was persisted');
  await delay(2500);
  check(own.length===oldCount,'existing revoked realtime connection receives no new notifications');
  check(outsider.length===0,'outsider remains isolated on later changes');
  const denied=await call('/rest/v1/messages?conversation_id=eq.'+first.value,undefined,b.token);
  check(denied.status===200&&denied.value.length===0,'existing revoked JWT cannot fetch chat');
  console.log('Cloud realtime checks: '+checks);
}finally{
  for(const ws of sockets)ws.close();
  // This staging deliberately does not expose admin table DELETE via Data API.
  // Auth deletion cascades all fixture messages, memberships and notifications;
  // empty conversation UUIDs are retained until the staging SQL cleanup.
  console.log('Empty fixture conversations awaiting SQL cleanup: '+conversations.length);
  const cleanup=await Promise.allSettled(users.map(async user=>{const r=await call('/auth/v1/admin/users/'+user.id,undefined,undefined,true,'DELETE');assert.equal(r.status,200,'Synthetic account cleanup');}));
  assert.ok(cleanup.every(result=>result.status==='fulfilled'),'All synthetic account cleanup requests succeed');
}
