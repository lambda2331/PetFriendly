/* Studio feedback presentation; feature state/retry callbacks remain authoritative. */
(()=>{
 const q=new URLSearchParams(location.search),file=location.pathname.split('/').pop();
 // Review-only matrix exercises existing local scenarios. Never enables a new production request.
 const preview=q.has('kind')&&q.get('feedback');
 if(['empty','loading','error','saving'].includes(preview)){
  if(['people-reference.html','walking-reference.html','endpoint.html'].includes(file)){
   if(typeof scenario!=='undefined')scenario=preview;
   if(typeof render==='function')render();
  }else if(file==='index.html'){status=preview==='error'?'failure':preview;render();}
 }
 const blocks='.state,.state-center,.loading-state,.places-empty,.meeting-empty,.meeting-unavailable';
 function normalize(){document.querySelectorAll('.phone,.places-page').forEach(root=>{
  root.querySelectorAll(blocks).forEach(block=>{
   if(block.closest('[data-user-content]'))return;block.classList.add('studio-feedback');
   block.setAttribute('role','status');block.setAttribute('aria-live','polite');
   block.querySelectorAll('.spinner,.loading-dot,.icon').forEach(icon=>icon.setAttribute('aria-hidden','true'));
  });
  root.querySelectorAll('.review-error,.review-loading,.save-error').forEach(block=>{
   block.classList.add('studio-inline-feedback');
   if(!block.hasAttribute('role'))block.setAttribute('role',block.classList.contains('save-error')?'alert':'status');
   if(block.getAttribute('role')==='status')block.setAttribute('aria-live','polite');
  });
  root.querySelectorAll('.shared-temporal-trigger[data-temporal-display=date]').forEach(button=>{
   const value=button.previousElementSibling?.value;if(!value)return;const [y,m,d]=value.split('-').map(Number);
   if(y&&m&&d)button.title=new Intl.DateTimeFormat(document.documentElement.lang||'ru',{dateStyle:'long',timeZone:'UTC'}).format(new Date(Date.UTC(y,m-1,d)));
  });
 });}
 new MutationObserver(normalize).observe(document.documentElement,{childList:true,subtree:true});normalize();
})();
