/* A164/A169/A175/A181/A187: shared inbox routing and shared conversation text sending; lifecycle actions stay pending. */
(()=>{
 const port=window.PFPreviewConnection;if(!port)return;let host;try{for(let w=parent;w;w=w===w.parent?null:w.parent)if(w.PFPreviewHost){host=w.PFPreviewHost;break}}catch{}if(!host?.conversations)return;
 const api=host.conversations,q=new URLSearchParams(location.search),file=location.pathname.split('/').pop(),id=q.get('conversation'),unavailable=file==='workflow-additions.html'&&q.get('state')==='target-unavailable';
 const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
 if(file==='endpoint.html'&&typeof chatRows==='function'){
  const originalRows=chatRows;chatRows=function(i,query=''){if(scenario!=='ready')return originalRows(i,query);const records=api.list(port,{query,tab:views[i].tab||0});return records.map(c=>{const last=c.messages?.at(-1);return btn(`<div class="avatar">${ic({direct:'user-round',community:'users-round',meeting:'calendar-days',walking:'paw-print'}[c.type])}</div><span class="copy"><span class="chat-top"><strong class="name">${esc(c.title)}</strong><time class="time">${esc(last?.time||'')}</time></span><span class="last-message"><span>${last?esc(last.sender+': '+last.text):esc(c.subtitle)}</span>${c.unread?`<span class="unread">${c.unread}</span>`:''}</span></span>`,'','chat-row',`data-preview-conversation="${esc(c.id)}"`)}).join('')||`<div class="state-center"><h3>${query?'Ничего не найдено':'Нет переписок'}</h3><p>${query?'Попробуйте другое имя.':'Новые сообщения появятся здесь.'}</p></div>`};
 }
 // Stable IDs are attached to the approved sample agreement's existing controls, without adding layout.
 if(file==='walking-reference.html'&&!id){
  const explicit=q.get('agreement'),state=q.get('state');
  const projectAgreement=()=>{const root=document.querySelector('.phone');if(!root)return;const currentSample=state==='current',scheduledDetail=state==='details',completedDetail=state==='history-detail';
   const agreement=explicit||(completedDetail?'agreement-persik-completed':currentSample||scheduledDetail?'agreement-persik':null);
   root.querySelectorAll('[onclick^="openChat("]').forEach(button=>{if(agreement)button.dataset.previewAgreementChat=agreement});
   if(scheduledDetail||completedDetail){root.dataset.previewAgreementChat=agreement||'';}
  };
  if(typeof render==='function'){const prior=render;render=function(...args){const result=prior(...args);projectAgreement();return result;};}projectAgreement();
 }
 let record=id?api.resolve(port,id):null;
 if(id&&!record&&!unavailable){document.documentElement.hidden=true;host.openConversation(id,{replace:true});return}
 const thread=!!record,directSend=record?.type==='direct'&&file==='profile-edit-reference.html'&&q.get('state')==='direct',communitySend=record?.type==='community'&&file==='profile-edit-reference.html'&&q.get('state')==='group',meetingSend=record?.type==='meeting'&&file==='meetings-reference.html'&&q.get('state')==='chat',walkingSend=record?.type==='walking'&&file==='walking-reference.html'&&q.get('state')?.startsWith('chat-'),selector=file==='meetings-reference.html'?'.meeting-composer input':'.composer textarea,.composer input[name=message]';
 const newChat=file==='endpoint.html'&&q.get('state')==='newChat';
 function filterNewChat(root){
  if(!newChat||!port.valid())return;
  const input=root.querySelector('.sheet input[aria-label="Поиск по имени"]'),body=root.querySelector('.sheet-body');if(!input||!body)return;
  const ids=new Set(api.searchDirectPeople(port,input.value).map(person=>person.id));
  const choices=[...body.querySelectorAll('[data-preview-start-direct]')];let visible=0;
  for(const choice of choices){const show=ids.has(choice.dataset.previewStartDirect);choice.hidden=!show;choice.style.display=show?'':'none';if(show)visible++}
  let empty=body.querySelector('[data-preview-people-empty]');
  if(!empty){empty=document.createElement('div');empty.dataset.previewPeopleEmpty='true';empty.className='state-center search-empty';empty.setAttribute('role','status');empty.setAttribute('aria-live','polite');empty.innerHTML=ic('search')+'<h3>Ничего не найдено</h3><p>Попробуйте другое имя.</p>';body.append(empty);window.lucide?.createIcons();}
  empty.hidden=!!visible;empty.style.display=visible?'none':'';
 }
 function closeNewChat(e){e.preventDefault();e.stopImmediatePropagation();if(!port.valid())return;if(!host.back())host.navigate('chats',true)}
 function project(){if(!port.valid())return;const root=document.querySelector('.phone');if(!root)return;
  if(unavailable){root.querySelectorAll('.addition-head>.icon-button,.addition-actions button[data-go="chats"]').forEach(b=>b.dataset.previewConversationBack='true');return}
  if(file==='endpoint.html'){
   root.querySelectorAll('.toolbar .create[aria-label="Новая переписка"]').forEach(b=>b.dataset.previewNewChat='true');
   if(newChat){const choice=root.querySelector('.sheet [onclick^="startChat("]');if(choice)choice.dataset.previewStartDirect='person-ulyana';root.querySelectorAll('.sheet-head [aria-label="Закрыть"]').forEach(b=>b.dataset.previewNewChatClose='true');filterNewChat(root)}
   else if(q.get('state')==='chats'&&port.context('new-chat-return-focus')){root.querySelector('[data-preview-new-chat]')?.focus({preventScroll:true});port.saveContext('new-chat-return-focus',false)}
  }
  if(!thread)return;record=api.resolve(port,id);if(!record){document.documentElement.hidden=true;host.openConversation(id,{replace:true});return}
  const draft=api.draft(port,id);root.querySelectorAll(selector).forEach(e=>{e.value=draft?.text||'';if(meetingSend||walkingSend)e.maxLength=1000});
  const back=root.querySelector('.conversation-head>.icon-button,.chat-bar>.icon-button,.meeting-head>.icon-button');if(back)back.dataset.previewConversationBack='true';
  const title=root.querySelector('.conversation-head .name,.chat-bar .chat-title,.meeting-head h2');if(title)title.textContent=record.type==='walking'?(record.ownerId===port.accountId?(record.helperName||record.peerName):(record.ownerName||'Участник прогулки')):record.title;
  const subtitle=root.querySelector('.conversation-head .copy>.meta');if(subtitle)subtitle.textContent=record.subtitle;
  if(record.type==='walking'){const pet=root.querySelector('.context .identity-copy strong');if(pet)pet.textContent=record.petName;const when=root.querySelector('.context .identity-copy .meta');if(when)when.textContent=record.when;}
  const messages=root.querySelector('.messages,.meeting-messages');if(messages){const isMeeting=file==='meetings-reference.html';messages.innerHTML=`<${isMeeting?'p':'div'} class="${isMeeting?'meeting-day':'day'}">Сегодня</${isMeeting?'p':'div'}>`+(record.messages||[]).map(m=>{const own=m.senderId===port.accountId;return isMeeting?`<div class="meeting-message${own?' mine':''}"><strong>${esc(m.sender)}</strong><p>${esc(m.text)}</p><span class="meta">${esc(m.time)}</span></div>`:`<div class="bubble${own?(file==='walking-reference.html'?' outgoing':' mine'):''}"><strong>${esc(m.sender)}</strong>${esc(m.text)}<${file==='walking-reference.html'?'small':'span class="stamp"'}>${esc(m.time)}</${file==='walking-reference.html'?'small':'span'}></div>`}).join('')}
  root.querySelectorAll('.composer button[type=submit],.meeting-composer button[type=submit]').forEach(b=>{if(directSend||communitySend||meetingSend||walkingSend){if(directSend)b.dataset.previewDirectSend='true';else if(communitySend)b.dataset.previewCommunitySend='true';else if(meetingSend)b.dataset.previewMeetingSend='true';else b.dataset.previewWalkingSend='true';b.disabled=!draft?.text?.trim()||draft.text.length>1000;b.title=''}else{b.disabled=true;b.title='Отправка сообщений — отдельный этап'}});root.dataset.conversationId=id;root.dataset.conversationType=record.type;
 }
 if(thread){const renderName=file==='meetings-reference.html'?'meetingRender':'render';const prior=window[renderName];if(typeof prior==='function')window[renderName]=function(...args){if(typeof views!=='undefined'&&views[0]){views[0].draft=api.draft(port,id)?.text||'';if(record.type==='direct')views[0].directName=record.title;if(record.type==='walking'){views[0].mode=record.ownerId===port.accountId?'owner':'helper';views[0].status=record.status}}if(file==='meetings-reference.html'){meetingSelected=record.eventId;}const result=prior(...args);project();return result;};}
 function send(e){
  e.preventDefault();e.stopImmediatePropagation();
  if(!(directSend||communitySend||meetingSend||walkingSend)||!port.valid())return;
  const input=document.querySelector('.phone '+selector);if(!input)return;
  const result=(walkingSend?api.sendWalking:meetingSend?api.sendMeeting:communitySend?api.sendCommunity:api.sendDirect)(port,id,input.value);
  if(!result.ok){if(result.reason==='unavailable')host.openConversation(id,{replace:true});return}
  if(typeof views!=='undefined'&&views[0])views[0].draft='';
  if(meetingSend)meetingDraftText='';
  project();const messages=document.querySelector('.phone .messages,.phone .meeting-messages');if(messages)messages.scrollTop=messages.scrollHeight;
  input.focus({preventScroll:true});window.PFPreviewCapture?.();
 }
 document.addEventListener('click',e=>{if(!port.valid()){e.preventDefault();e.stopImmediatePropagation();return}const agreement=e.target.closest('button[data-preview-agreement-chat]');if(agreement){e.preventDefault();e.stopImmediatePropagation();host.openAgreement(agreement.dataset.previewAgreementChat);return}const opener=e.target.closest('[data-preview-new-chat]'),person=e.target.closest('[data-preview-start-direct]');if(opener){e.preventDefault();e.stopImmediatePropagation();host.openNewChat();return}if(person){e.preventDefault();e.stopImmediatePropagation();if(person.hidden)return;host.startDirect(person.dataset.previewStartDirect);return}if(e.target.closest('[data-preview-new-chat-close]')||newChat&&e.target.matches('.shade')){closeNewChat(e);return}if(e.target.closest('[data-preview-direct-send],[data-preview-community-send],[data-preview-meeting-send],[data-preview-walking-send]')){send(e);return}const row=e.target.closest('[data-preview-conversation]'),back=e.target.closest('[data-preview-conversation-back]');if(row){e.preventDefault();e.stopImmediatePropagation();host.openConversation(row.dataset.previewConversation)}else if(back){e.preventDefault();e.stopImmediatePropagation();if((host.backConversation||host.backDirect)&&(['direct','community','meeting','walking'].includes(record?.type)||unavailable&&port.current()?.originKey))(host.backConversation||host.backDirect)();else if(!host.back())host.navigate('chats',true)}},true);
 document.addEventListener('input',e=>{if(newChat&&e.target.matches('.sheet input[aria-label="Поиск по имени"]'))filterNewChat(document.querySelector('.phone'));if(thread&&e.target.matches(selector)&&port.valid()){api.saveDraft(port,id,e.target.value);if(directSend||communitySend||meetingSend||walkingSend){const button=document.querySelector('.phone [data-preview-direct-send],.phone [data-preview-community-send],.phone [data-preview-meeting-send],.phone [data-preview-walking-send]');if(button)button.disabled=!e.target.value.trim()||e.target.value.length>1000}}});
 document.addEventListener('submit',e=>{if((directSend||communitySend||meetingSend||walkingSend)&&e.target.matches('.composer,.meeting-composer'))send(e);else if(thread){e.preventDefault();e.stopImmediatePropagation()}},true);
 document.addEventListener('keydown',e=>{if(newChat&&e.key==='Escape')closeNewChat(e)},true);
 const style=document.createElement('style');style.textContent='.phone button[data-preview-agreement-chat],.phone [data-preview-new-chat],.phone [data-preview-start-direct],.phone [data-preview-new-chat-close],.phone [data-preview-conversation],.phone [data-preview-conversation-back],.phone [data-preview-direct-send],.phone [data-preview-community-send],.phone [data-preview-meeting-send],.phone [data-preview-walking-send]{pointer-events:auto!important}';document.head.append(style);
 document.addEventListener('DOMContentLoaded',project,{once:true});
})();
