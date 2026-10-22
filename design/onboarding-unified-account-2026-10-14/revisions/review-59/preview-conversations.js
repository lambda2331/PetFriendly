/* A164/A169/A175/A181/A187: stable-ID conversation resolution for the local preview only. */
(function(root){
 const screens={direct:'chat-direct-design',community:'chat-group-design',meeting:'meeting-chat',walking:'chat-walk-design'};
 function seed(port){if(port.preferences().conversationFixtureVersion)return;port.savePreferences({conversationFixtureVersion:1});if(port.accountId!=='preview-A')return;
  const own=port.accountId,records=[
   {id:'direct-ulyana',type:'direct',title:'Ульяна',subtitle:'Личная переписка',peerId:'person-ulyana',memberIds:[own,'person-ulyana'],access:'active',unread:2,messages:[{id:'du-1',senderId:'person-ulyana',sender:'Ульяна',text:'Привет! Персик любит длинные прогулки?',time:'10:47'},{id:'du-2',senderId:own,sender:'Вы',text:'Да, особенно если есть время спокойно всё рассмотреть.',time:'10:49'}]},
   {id:'community-neighbors',type:'community',title:'Соседи с питомцами',subtitle:'Чат сообщества',communityId:'neighbors',memberIds:[own,'person-mikhail'],access:'active',unread:1,messages:[{id:'cn-1',senderId:'person-mikhail',sender:'Михаил',text:'Кто сегодня идёт в парк? Буду у входа к 18:00.',time:'09:32'}]},
   {id:'meeting-park',type:'meeting',title:'Прогулка в парке',subtitle:'Чат встречи',eventId:'park',memberIds:[own,'person-mikhail'],access:'active',unread:0,messages:[{id:'mp-1',senderId:'person-mikhail',sender:'Михаил',text:'Буду у главного входа в Парк Победы.',time:'10:42'}]},
   {id:'walk-persik',type:'walking',title:'Прогулка с Персиком',subtitle:'Чат прогулки',agreementId:'agreement-persik',ownerId:own,helperId:'person-ulyana',ownerName:'Анна',helperName:'Ульяна',peerName:'Ульяна',petName:'Персик',when:'18 октября · 10:00 · 45 мин',status:'selected',memberIds:[own,'person-ulyana'],access:'active',unread:0,messages:[{id:'wp-1',senderId:'person-ulyana',sender:'Ульяна',text:'Встречаемся у входа со стороны двора?',time:'10:47'},{id:'wp-2',senderId:own,sender:'Вы',text:'Да, буду с Персиком в 10:00.',time:'10:49'}]},
   {id:'walk-persik-completed',type:'walking',title:'Прогулка с Персиком',subtitle:'Чат завершённой прогулки',agreementId:'agreement-persik-completed',ownerId:own,helperId:'person-ulyana',ownerName:'Анна',helperName:'Ульяна',peerName:'Ульяна',petName:'Персик',when:'11 октября · 10:00 · 45 мин',status:'completed',memberIds:[own,'person-ulyana'],access:'active',unread:0,messages:[{id:'wpc-1',senderId:'person-ulyana',sender:'Ульяна',text:'Прогулка завершена. Спасибо!',time:'10:45'}]}
  ];for(const record of records)port.put('conversations',record);
 }
 function walkingParticipant(record,accountId){return typeof record.agreementId==='string'&&!!record.agreementId&&typeof record.ownerId==='string'&&!!record.ownerId&&typeof record.helperId==='string'&&!!record.helperId&&record.ownerId!==record.helperId&&[record.ownerId,record.helperId].includes(accountId)}
 function resolve(port,id){const record=port.records('conversations').find(r=>r.id===id);return record&&screens[record.type]&&record.access==='active'&&Array.isArray(record.memberIds)&&record.memberIds.includes(port.accountId)&&(record.type!=='walking'||walkingParticipant(record,port.accountId))?record:null}
 function list(port,{query='',tab=0}={}){const type={1:'direct',2:'community',3:'walking'}[tab];return port.records('conversations').map(r=>resolve(port,r.id)).filter(r=>r&&(!type||r.type===type)&&r.title.toLocaleLowerCase().includes(query.toLocaleLowerCase())).sort((a,b)=>(b.updatedAt||'').localeCompare(a.updatedAt||''))}
 function route(port,id){const r=resolve(port,id);if(!r)return {screen:'target-unavailable',params:{conversation:id},mode:port.mode()};const params={conversation:r.id};if(r.peerId)params.member=r.peerId;if(r.communityId)params.community=r.communityId;if(r.eventId)params.event=r.eventId;if(r.agreementId)params.agreement=r.agreementId;return {screen:screens[r.type],params,mode:port.mode()}}
 // Agreement identity is canonical; titles/pet names never select a thread. No creation or assignment here.
 function walkingForAgreement(port,agreementId){if(typeof agreementId!=='string'||!agreementId)return null;const matches=port.records('conversations').filter(r=>r.type==='walking'&&r.agreementId===agreementId);return matches.length===1?resolve(port,matches[0].id):null}
 function draft(port,id){return resolve(port,id)?port.draft('conversation',id)||{text:''}:null}
 function saveDraft(port,id,text){if(!resolve(port,id))return false;port.saveDraft('conversation',id,{text:String(text)});return true}
 // A169/A175/A181/A187 share explicit text sending; each entry point enforces its own thread type.
 function sendText(port,id,text,type){
  const record=resolve(port,id);
  if(!record)return {ok:false,reason:'unavailable'};
  if(record.type!==type)return {ok:false,reason:'type'};
  if(type==='community'&&!(typeof record.communityId==='string'&&record.communityId))return {ok:false,reason:'unavailable'};
  if(type==='meeting'&&!(typeof record.eventId==='string'&&record.eventId))return {ok:false,reason:'unavailable'};
  if(typeof text!=='string'||!text.trim())return {ok:false,reason:'empty'};
  if(text.length>1000)return {ok:false,reason:'length'};
  const now=new Date(),message={id:type+'-message-'+crypto.randomUUID(),senderId:port.accountId,sender:'Вы',text:text.trim(),createdAt:now.toISOString(),time:new Intl.DateTimeFormat(port.context('locale')||'ru',{hour:'2-digit',minute:'2-digit',hour12:false}).format(now)};
  port.put('conversations',{...record,messages:[...(record.messages||[]),message],updatedAt:message.createdAt,unread:0});
  port.clearDraft('conversation',id);
  return {ok:true,message};
 }
 function sendDirect(port,id,text){return sendText(port,id,text,'direct')}
 function sendCommunity(port,id,text){return sendText(port,id,text,'community')}
 function sendMeeting(port,id,text){return sendText(port,id,text,'meeting')}
 function sendWalking(port,id,text){return sendText(port,id,text,'walking')}
 // Existing approved New chat fixture: display content never serves as account identity.
 function directPeople(){return [{id:'person-ulyana',name:'Ульяна'},{id:'person-anna',name:'Анна'},{id:'person-kat',name:'Екатерина Александровская-Лисовская'},{id:'person-max',name:'Максим'}]}
 function searchDirectPeople(port,query=''){
  if(!port.valid())throw Error('Stale preview connection');
  const normalized=value=>String(value??'').normalize('NFKC').trim().replace(/\s+/gu,' ').toLocaleLowerCase('ru');
  const term=normalized(query);
  return directPeople().filter(person=>person.id!==port.accountId&&normalized(person.name).includes(term)).map(({id,name})=>({id,name}));
 }
 function startDirect(port,personId){
  const records=port.records('conversations'),person=directPeople().find(p=>p.id===personId);
  if(personId===port.accountId)return {ok:false,reason:'self'};
  if(!person)return {ok:false,reason:'person'};
  const pair=[port.accountId,personId].sort(),pairKey=JSON.stringify(pair);
  const existing=records.find(r=>r.type==='direct'&&Array.isArray(r.memberIds)&&(
   JSON.stringify([...new Set(r.memberIds)].sort())===pairKey||r.peerId===personId&&r.memberIds.includes(port.accountId)));
  if(existing){if(!resolve(port,existing.id)||existing.peerId&&existing.peerId!==personId||existing.memberIds.length!==2||new Set(existing.memberIds).size!==2||!existing.memberIds.includes(personId))return {ok:false,reason:'unavailable',id:existing.id};return {ok:true,id:existing.id,created:false}}
  const id='direct-thread-'+crypto.randomUUID(),now=new Date().toISOString();
  port.put('conversations',{id,type:'direct',title:person.name,subtitle:'Личная переписка',peerId:personId,pairKey,memberIds:[port.accountId,personId],access:'active',unread:0,messages:[],createdAt:now,updatedAt:now});
  return {ok:true,id,created:true};
 }
 root.PFPreviewConversations={walkingForAgreement,seed,resolve,list,route,draft,saveDraft,directPeople,searchDirectPeople,startDirect,sendDirect,sendCommunity,sendMeeting,sendWalking};if(typeof module!=='undefined')module.exports=root.PFPreviewConversations;
})(typeof window==='undefined'?globalThis:window);
