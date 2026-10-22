/* Shared browser sheet/modal behavior. Feature close actions remain authoritative. */
(()=>{
 const readonly=new URLSearchParams(location.search).has('kind')&&new URLSearchParams(location.search).get('interactive')!=='1';
 const selector='[role="dialog"],[role="alertdialog"]';
 const visible=el=>el.getClientRects().length&&getComputedStyle(el).visibility!=='hidden'&&!el.closest('[hidden]');
 const ownedInert=new Map(),ownedModal=new Map();let stack=[],lastInteraction=null,lastFocus=null,nextId=0,scheduled=false;
 function descriptor(el){if(!el||!el.matches('button,input,select,textarea,a,[tabindex]'))return null;return {id:el.id,tag:el.tagName,name:el.getAttribute('name'),aria:el.getAttribute('aria-label'),action:el.getAttribute('onclick'),go:el.getAttribute('data-go'),text:el.tagName==='BUTTON'?el.textContent.trim():null};}
 function find(root,d){if(!d||!root)return null;return [...root.querySelectorAll('button,input,select,textarea,a,[tabindex]')].find(el=>visible(el)&&!el.disabled&&(d.id?el.id===d.id:d.aria?el.getAttribute('aria-label')===d.aria:d.name?el.tagName===d.tag&&el.getAttribute('name')===d.name:d.action?el.getAttribute('onclick')===d.action:d.go?el.getAttribute('data-go')===d.go:d.text?el.tagName===d.tag&&el.textContent.trim()===d.text:false));}
 function roots(){return [...document.querySelectorAll('.phone,.places-page')].filter(visible);}
 function dialogs(){return roots().flatMap(root=>[...root.querySelectorAll(selector)].filter(visible));}
 function active(){return dialogs().at(-1);}
 function identity(el){return (el.closest('.phone,.places-page')?.id||'phone')+'|'+el.className+'|'+(el.getAttribute('aria-label')||el.querySelector('.sheet-head h2,.full-head h2')?.textContent||el.getAttribute('aria-labelledby')||'dialog');}
 function controls(dialog){const nodes=[...dialog.querySelectorAll('button,input,textarea,select,a[href],iframe,[tabindex]')].filter(el=>!el.disabled&&el.tabIndex>=0&&visible(el)&&!el.closest('[inert]'));
  return nodes.filter(el=>!el.matches('input[type=radio]')||el.checked||!nodes.some(other=>other!==el&&other.matches('input[type=radio]')&&other.name===el.name&&other.checked));}
 function closeAction(dialog){const head=dialog?.querySelector('.sheet-head,.full-head,.conversation-head');if(!head)return null;const buttons=[...head.querySelectorAll('button')];return buttons.find(button=>/закрыть|close|зачыніць|zamknij/i.test(button.getAttribute('aria-label')||''))||buttons.find(button=>button.querySelector('[data-lucide="x"],.lucide-x'))||buttons.find(button=>/назад|back|вярнуцца|wstecz/i.test(button.getAttribute('aria-label')||''));}
 function restoreOwned(){for(const [el,value]of ownedInert){if(el.isConnected)el.inert=value;}ownedInert.clear();for(const[el,value]of ownedModal){if(el.isConnected){if(value===null)el.removeAttribute('aria-modal');else el.setAttribute('aria-modal',value);}}ownedModal.clear();}
 function normalize(){scheduled=false;
  const all=dialogs();restoreOwned();
  for(const root of roots())root.classList.add('studio-overlay-host');
  for(const dialog of all){
   const sheet=dialog.classList.contains('sheet');dialog.dataset.studioDialogKind=sheet?'sheet':'fullscreen';
   const head=dialog.querySelector(':scope>.sheet-head,:scope>.full-head');
   if(sheet&&head&&!dialog.querySelector('.sheet-body')){
    const body=document.createElement('div');body.className='sheet-body studio-sheet-body';
    const children=[...dialog.childNodes].filter(node=>node!==head&&!(node.nodeType===1&&node.matches('.home-indicator,.modal-footer,.current-filter-actions,.addition-actions')));
    head.after(body);for(const node of children)body.append(node);
   }
   const title=head?.querySelector('h2');if(title){if(!title.id)title.id='studio-dialog-title-'+(++nextId);if(!dialog.hasAttribute('aria-label'))dialog.setAttribute('aria-labelledby',title.id);}
  }
  const top=all.at(-1);if(top){
   for(const dialog of all)if(dialog!==top){ownedModal.set(dialog,dialog.getAttribute('aria-modal'));dialog.setAttribute('aria-modal','false');}
   top.setAttribute('aria-modal','true');
   const root=top.closest('.phone,.places-page');let branch=top;
   while(branch&&branch!==root){for(const sibling of branch.parentElement.children){if(sibling===branch||sibling.tagName==='SCRIPT'||sibling.tagName==='STYLE')continue;if(!sibling.inert){ownedInert.set(sibling,false);sibling.inert=true;}}branch=branch.parentElement;}
   if(!readonly){
    const keys=all.map(identity),removed=stack.filter(entry=>!keys.includes(entry.key)),restore=removed[0]?.opener;
    stack=all.map(dialog=>stack.find(entry=>entry.key===identity(dialog))||{key:identity(dialog),opener:lastInteraction});
    const restored=find(top,restore);
    if(restored)restored.focus({preventScroll:true});
    else if(!top.contains(document.activeElement)||document.activeElement.closest('[inert]')){
     const target=find(top,lastFocus)||top.querySelector('.sheet-head h2,.full-head h2')||controls(top)[0];if(target){if(target.matches('h2'))target.tabIndex=-1;target.focus({preventScroll:true});}
    }
   }
  }else if(stack.length){const opener=stack[0].opener;stack=[];if(!readonly&&(!document.activeElement||document.activeElement===document.body||document.activeElement.closest('[inert]')))find(document,opener)?.focus({preventScroll:true});}
 }
 function schedule(){if(!scheduled){scheduled=true;queueMicrotask(normalize);}}
 window.addEventListener('click',event=>{
  const top=active();if(top&&event.target===top.closest('.shade')){const close=closeAction(top);if(close&&!readonly){event.preventDefault();event.stopImmediatePropagation();close.click();}return;}
  const target=event.target.closest('button,input,select,textarea,a,[tabindex]');if(target)lastInteraction=descriptor(target);
 },true);
 document.addEventListener('focusin',event=>{lastFocus=descriptor(event.target);});
 window.addEventListener('keydown',event=>{
  if(readonly)return;const top=active();if(!top)return;
  if(event.key==='Escape'){const close=closeAction(top);if(close){event.preventDefault();event.stopImmediatePropagation();close.click();}}
  else if(event.key==='Tab'){const items=controls(top),first=items[0],last=items.at(-1);if(!items.length){event.preventDefault();return;}if(!top.contains(document.activeElement)||!items.includes(document.activeElement)||event.shiftKey&&document.activeElement===first||!event.shiftKey&&document.activeElement===last){event.preventDefault();event.stopImmediatePropagation();(event.shiftKey?last:first).focus();}}
 },true);
 new MutationObserver(schedule).observe(document.documentElement,{childList:true,subtree:true});normalize();
})();
