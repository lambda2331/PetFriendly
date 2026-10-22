/* A164/A169: shared inbox routing and direct text sending; other send/lifecycle actions stay pending. */
(()=>{
 const port=window.PFPreviewConnection;if(!port)return;let host;try{for(let w=parent;w;w=w===w.parent?null:w.parent)if(w.PFPreviewHost){host=w.PFPreviewHost;break}}catch{}if(!host?.conversations)return;
 const api=host.conversations,q=new URLSearchParams(location.search),file=location.pathname.split('/').pop(),id=q.get('conversation'),unavailable=file==='workflow-additions.html'&&q.get('state')==='target-unavailable';
 const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
 if(file==='endpoint.html'&&typeof chatRows==='function'){
  const originalRows=chatRows;chatRows=function(i,query=''){if(scenario!=='ready')return originalRows(i,query);const records=api.list(port,{query,tab:views[i].tab||0});return records.map(c=>{const last=c.messages?.at(-1);return btn(`<div class="avatar">${ic({direct:'user-round',community:'users-round',meeting:'calendar-days',walking:'paw-print'}[c.type])}</div><span class="copy"><span class="chat-top"><strong class="name">${esc(c.title)}</strong><time class="time">${esc(last?.time||'')}</time></span><span class="last-message"><span>${last?esc(last.sender+': '+last.text):esc(c.subtitle)}</span>${c.unread?`<span class="unread">${c.unread}</span>`:''}</span></span>`,'','chat-row',`data-preview-conversation="${esc(c.id)}"`)}).join('')||`<div class="state-center"><h3>${query?'Ничего не найдено':'Нет переписок'}</h3><p>${query?'Попробуйте другое имя.':'Новые сообщения появятся здесь.'}</p></div>`};
 }
 let record=id?api.resolve(port,id):null;
 if(id&&!record&&!unavailable){document.documentElement.hidden=true;host.openConversation(id,{replace:true});return}
 const thread=!!record,directSend=record?.type==='direct'&&file==='profile-edit-reference.html'&&q.get('state')==='direct',selector=file==='meetings-reference.html'?'.meeting-composer input':'.composer textarea,.composer input[name=message]';
 function project(){if(!port.valid())return;const root=document.querySelector('.phone');if(!root)return;
  if(unavailable){root.querySelectorAll('.addition-head>.icon-button,.addition-actions button[data-go="chats"]').forEach(b=>b.dataset.previewConversationBack='true');return}
  if(!thread)return;record=api.resolve(port,id);if(!record){document.documentElement.hidden=true;host.openConversation(id,{replace:true});return}
  const draft=api.draft(port,id);root.querySelectorAll(selector).forEach(e=>e.value=draft?.text||'');
  const back=root.querySelector('.conversation-head>.icon-button,.chat-bar>.icon-button,.meeting-head>.icon-button');if(back)back.dataset.previewConversationBack='true';
  const title=root.querySelector('.conversation-head .name,.chat-bar .chat-title,.meeting-head h2');if(title)title.textContent=record.type==='walking'?record.peerName:record.title;
  const subtitle=root.querySelector('.conversation-head .copy>.meta');if(subtitle)subtitle.textContent=record.subtitle;
  if(record.type==='walking'){const pet=root.querySelector('.context .identity-copy strong');if(pet)pet.textContent=record.petName;const when=root.querySelector('.context .identity-copy .meta');if(when)when.textContent=record.when;}
  const messages=root.querySelector('.messages,.meeting-messages');if(messages){const isMeeting=file==='meetings-reference.html';messages.innerHTML=`<${isMeeting?'p':'div'} class="${isMeeting?'meeting-day':'day'}">Сегодня</${isMeeting?'p':'div'}>`+(record.messages||[]).map(m=>{const own=m.senderId===port.accountId;return isMeeting?`<div class="meeting-message${own?' mine':''}"><strong>${esc(m.sender)}</strong><p>${esc(m.text)}</p><span class="meta">${esc(m.time)}</span></div>`:`<div class="bubble${own?(file==='walking-reference.html'?' outgoing':' mine'):''}"><strong>${esc(m.sender)}</strong>${esc(m.text)}<${file==='walking-reference.html'?'small':'span class="stamp"'}>${esc(m.time)}</${file==='walking-reference.html'?'small':'span'}></div>`}).join('')}
  root.querySelectorAll('.composer button[type=submit],.meeting-composer button[type=submit]').forEach(b=>{if(directSend){b.dataset.previewDirectSend='true';b.disabled=!draft?.text?.trim()||draft.text.length>1000;b.title=''}else{b.disabled=true;b.title='Отправка сообщений — отдельный этап'}});root.dataset.conversationId=id;root.dataset.conversationType=record.type;
 }
 if(thread){const renderName=file==='meetings-reference.html'?'meetingRender':'render';const prior=window[renderName];if(typeof prior==='function')window[renderName]=function(...args){if(typeof views!=='undefined'&&views[0]){views[0].draft=api.draft(port,id)?.text||'';if(record.type==='direct')views[0].directName=record.title;if(record.type==='walking'){views[0].mode=record.ownerId===port.accountId?'owner':'helper';views[0].status=record.status}}if(file==='meetings-reference.html'){meetingSelected=record.eventId;}const result=prior(...args);project();return result;};}
 function send(e){
  e.preventDefault();e.stopImmediatePropagation();
  if(!directSend||!port.valid())return;
  const input=document.querySelector('.phone '+selector);if(!input)return;
  const result=api.sendDirect(port,id,input.value);
  if(!result.ok){if(result.reason==='unavailable')host.openConversation(id,{replace:true});return}
  if(typeof views!=='undefined'&&views[0])views[0].draft='';
  project();const messages=document.querySelector('.phone .messages');if(messages)messages.scrollTop=messages.scrollHeight;
  input.focus({preventScroll:true});window.PFPreviewCapture?.();
 }
 document.addEventListener('click',e=>{if(e.target.closest('[data-preview-direct-send]')){send(e);return}const row=e.target.closest('[data-preview-conversation]'),back=e.target.closest('[data-preview-conversation-back]');if(row){e.preventDefault();e.stopImmediatePropagation();host.openConversation(row.dataset.previewConversation)}else if(back){e.preventDefault();e.stopImmediatePropagation();if(!host.back())host.navigate('chats',true)}},true);
 document.addEventListener('input',e=>{if(thread&&e.target.matches(selector)&&port.valid()){api.saveDraft(port,id,e.target.value);if(directSend){const button=document.querySelector('.phone [data-preview-direct-send]');if(button)button.disabled=!e.target.value.trim()||e.target.value.length>1000}}});
 document.addEventListener('submit',e=>{if(directSend&&e.target.matches('.composer'))send(e);else if(thread){e.preventDefault();e.stopImmediatePropagation()}},true);
 const style=document.createElement('style');style.textContent='.phone [data-preview-conversation],.phone [data-preview-conversation-back],.phone [data-preview-direct-send]{pointer-events:auto!important}';document.head.append(style);
 document.addEventListener('DOMContentLoaded',project,{once:true});
})();
