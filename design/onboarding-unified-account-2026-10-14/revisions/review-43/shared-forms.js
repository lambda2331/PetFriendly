/* Shared browser form presentation/semantics. Existing feature validators own validity and drafts. */
(()=>{
 let nextId=0,queued=false;const ownedInvalid=new WeakSet();
 const visible=e=>e.getClientRects().length&&!e.hidden&&!e.closest('[hidden]');
 const controls='input:not([type=hidden]):not([type=radio]):not([type=checkbox]):not([type=file]),textarea,select,button.city-select,button.shared-city-trigger,button.shared-temporal-trigger,button.meeting-point-trigger';
 const supportSelector='.field-message,.field-error,.field-hint,.optional-hint,.hint';
 const isError=e=>e.matches('.field-error,.field-message.error,.field-message[role=alert],.field-error[role=alert]')&&!!e.textContent.trim();
 function id(el,prefix){return el.id||(el.id=prefix+(++nextId));}
 function tokens(el,attr){return (el.getAttribute(attr)||'').split(/\s+/).filter(Boolean);}
 function link(control,messages){
  const previous=tokens(control,'data-studio-support'),existing=tokens(control,'aria-describedby').filter(value=>!previous.includes(value));
  const refs=messages.filter(e=>e.textContent.trim()).map(e=>id(e,'studio-support-'));
  const combined=[...new Set([...existing,...refs])];
  if(combined.length)control.setAttribute('aria-describedby',combined.join(' '));else control.removeAttribute('aria-describedby');
  control.setAttribute('data-studio-support',refs.join(' '));
  const errors=messages.filter(isError);
  if(errors.length){if(control.getAttribute('aria-invalid')!=='true'){control.setAttribute('aria-invalid','true');ownedInvalid.add(control);}control.setAttribute('aria-errormessage',errors.map(e=>id(e,'studio-error-')).join(' '));control.dataset.studioError='true';}
  else{if(ownedInvalid.has(control)){control.removeAttribute('aria-invalid');ownedInvalid.delete(control);}if(control.dataset.studioError){control.removeAttribute('aria-errormessage');delete control.dataset.studioError;}}
 }
 function normalize(){queued=false;
  document.querySelectorAll('.phone,.places-page').forEach(root=>{
   root.querySelectorAll('.field-message,.field-error,.field-hint,.optional-hint,.form-error').forEach(message=>{message.classList.add('studio-field-support');if(message.matches('.form-error')&&message.textContent.trim())message.classList.add('studio-field-error');});
   root.querySelectorAll('[aria-describedby]').forEach(control=>{for(const ref of tokens(control,'aria-describedby')){const support=document.getElementById(ref);if(support&&root.contains(support)&&support.matches('.plain-hint,.meta'))support.classList.add('studio-field-support');}});
   root.querySelectorAll('label,.field').forEach(label=>{
    if(label.closest('.search,.composer,.meeting-composer,.addition-composer,[data-user-content]'))return;
    const fields=[...label.querySelectorAll(controls)].filter(visible);if(fields.length!==1)return;
    const control=fields[0];
    if(label.matches('label')){
     for(const node of [...label.childNodes])if(node.nodeType===3&&node.textContent.trim()){const caption=document.createElement('span');caption.className='studio-field-caption';node.before(caption);caption.append(node);}
    }
    const caption=[...label.children].find(el=>el.matches('.studio-field-caption,span:not(.field-hint):not(.optional-hint):not(.field-error):not(.field-message):not(.hint)')&&el.textContent.trim());
    if(caption)caption.classList.add('studio-field-caption');
    if(caption&&!control.hasAttribute('aria-label')&&!control.hasAttribute('aria-labelledby')){
     let ids=id(caption,'studio-label-');
     if(control.tagName==='BUTTON'){const value=[...control.children].find(el=>el.tagName==='SPAN'&&el.textContent.trim());if(value)ids+=' '+id(value,'studio-value-');}
     control.setAttribute('aria-labelledby',ids);
    }
    label.classList.add('studio-field-label');control.classList.add('studio-field-control');
    if(getComputedStyle(control).borderTopLeftRadius==='0px')control.classList.add('studio-field-rounded');
    const messages=[...label.querySelectorAll(supportSelector)];let sibling=label.nextElementSibling;
    while(sibling?.matches(supportSelector)){if(sibling.id!=='manual-error')messages.push(sibling);sibling=sibling.nextElementSibling;}
    for(const message of messages){message.classList.add('studio-field-support');if(isError(message)){message.classList.add('studio-field-error');message.setAttribute('role','alert');}else message.classList.remove('studio-field-error');}
    link(control,messages);
   });
   root.querySelectorAll('fieldset').forEach(group=>{const errors=[...group.querySelectorAll('.field-message.error,.field-error')].filter(isError);if(errors.length){for(const e of errors){e.classList.add('studio-field-support','studio-field-error');e.setAttribute('role','alert');}link(group,errors);}else if(group.dataset.studioError)link(group,[]);});
  });
 }
 // Reflect the existing manual-city validator; do not introduce new acceptance rules.
 if(typeof saveNearbyManual==='function'){const priorSave=saveNearbyManual;saveNearbyManual=function(...args){
  document.querySelectorAll('[data-studio-manual-invalid]').forEach(control=>{control.removeAttribute('aria-invalid');control.removeAttribute('aria-errormessage');const refs=tokens(control,'aria-describedby').filter(ref=>ref!=='manual-error');if(refs.length)control.setAttribute('aria-describedby',refs.join(' '));else control.removeAttribute('aria-describedby');delete control.dataset.studioManualInvalid;});
  const result=priorSave(...args),error=document.getElementById('manual-error');if(!error?.textContent.trim())return result;
  const required=['manual-city','manual-country'].map(key=>document.getElementById(key)).filter(Boolean);let invalid=required.filter(control=>!control.value.trim());
  if(!invalid.length){const zone=document.getElementById('manual-time-zone');if(zone)invalid=[zone];}
  for(const control of invalid){control.setAttribute('aria-invalid','true');control.setAttribute('aria-errormessage',error.id);control.setAttribute('aria-describedby',[...new Set([...tokens(control,'aria-describedby'),error.id])].join(' '));control.dataset.studioManualInvalid='true';}
  error.classList.add('studio-field-support','studio-field-error');error.setAttribute('role','alert');invalid[0]?.focus();return result;
 };}
 function schedule(){if(!queued){queued=true;queueMicrotask(normalize);}}
 new MutationObserver(schedule).observe(document.documentElement,{childList:true,subtree:true,characterData:true,attributes:true,attributeFilter:['aria-invalid']});normalize();
})();
