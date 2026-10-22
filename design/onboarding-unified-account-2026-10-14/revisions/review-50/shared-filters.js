/* Review 36: shared filter behavior for active browser mocks; no archived source edits. */
(()=>{
 const file=location.pathname.split('/').pop();
 const visible=el=>el.getClientRects().length&&!el.closest('[hidden]');

 function filterTrigger(root){return root.querySelector('.filter.icon-button,.category-select');}
 function dismissMenu(root,restore=true){
  if(file==='places-reference.html')closeCategoryMenu();
  else if(typeof views!=='undefined'){const i=[...document.querySelectorAll('.phone')].indexOf(root);if(i<0)return;views[i].menu=file==='people-reference.html'?false:null;render();}
  if(restore)filterTrigger(document.querySelector('.phone,.places-page'))?.focus();
 }
 function normalize(){
  document.querySelectorAll('.phone,.places-page').forEach((root,index)=>{
   root.querySelectorAll('.filter-menu').forEach((menu,n)=>{
    menu.setAttribute('role','menu');if(!menu.id)menu.id=`studio-filter-${index}-${n}`;
    menu.querySelectorAll('button[aria-checked]').forEach(button=>{button.setAttribute('role','menuitemradio');button.removeAttribute('aria-selected');button.tabIndex=button.getAttribute('aria-checked')==='true'?0:-1;});
    const trigger=menu.closest('.category-anchor,.top-menu,.search-tools')?.querySelector('.filter.icon-button,.category-select');
    if(trigger){trigger.setAttribute('aria-controls',menu.id);trigger.setAttribute('aria-haspopup','menu');trigger.setAttribute('aria-expanded',String(!!visible(menu)));}
   });
   root.querySelectorAll('.filter.icon-button').forEach(button=>{
    if(!button.title)button.title=button.getAttribute('aria-label')||'Фильтры';
    if(!button.hasAttribute('aria-haspopup'))button.setAttribute('aria-haspopup',button.closest('.search-tools,.top-menu')?'menu':'dialog');
    if(button.getAttribute('aria-haspopup')==='dialog')button.setAttribute('aria-expanded',String(!!root.querySelector('.current-filter-sheet')));
   });
   if(file==='people-reference.html'&&typeof views!=='undefined'){
    const v=views[index],button=root.querySelector('.filter.icon-button');if(v&&button){const active=v.tab==='people'?!!v.district:v.membership!=='all';button.classList.toggle('is-filtered',active);button.setAttribute('aria-expanded',String(!!v.menu));}
   }
   const sheet=root.querySelector('.current-filter-sheet');
   for(const child of root.children){if(sheet&&!child.contains(sheet)&&!child.inert){child.inert=true;child.dataset.filterInert='true';}else if(!sheet&&child.dataset.filterInert){child.inert=false;delete child.dataset.filterInert;}}
   root.querySelectorAll('.current-filter-sheet select').forEach(select=>select.classList.add('shared-filter-select'));
   const count=root.querySelector('#count');if(count){count.setAttribute('role','status');count.setAttribute('aria-live','polite');}
  });
 }
 // Existing state callbacks remain authoritative; only add shared opening focus.
 if(['people-reference.html','walking-reference.html'].includes(file)&&typeof toggleMenu==='function'){
  const priorToggle=toggleMenu;toggleMenu=function(...args){priorToggle(...args);normalize();const root=document.querySelectorAll('.phone')[args[0]];root?.querySelector('.filter-menu [aria-checked=true]')?.focus();};
 }
 if(file==='walking-reference.html'&&typeof pick==='function'){const priorPick=pick;pick=function(i,...args){priorPick(i,...args);document.querySelectorAll('.phone')[i]?.querySelector('.top-menu .filter.icon-button')?.focus();};}
 window.addEventListener('keydown',event=>{
  const root=event.target.closest('.phone,.places-page');if(!root)return;
  const sheet=root.querySelector('.current-filter-sheet');
  if(sheet){if(event.key==='Tab'){
   const controls=[...sheet.querySelectorAll('button,input,select,textarea,[tabindex]')].filter(el=>!el.disabled&&el.tabIndex>=0&&visible(el)&&(!el.matches('input[type=radio]')||el.checked));
   const first=controls[0],last=controls.at(-1);if(event.shiftKey&&document.activeElement===first||!event.shiftKey&&document.activeElement===last){event.preventDefault();event.stopImmediatePropagation();(event.shiftKey?last:first)?.focus();}
  }return;}
  const menu=event.target.closest('.filter-menu');
  if(menu){
   const options=[...menu.querySelectorAll('button')].filter(el=>visible(el)&&!el.disabled),index=options.indexOf(event.target);
   if(['ArrowDown','ArrowUp','Home','End'].includes(event.key)){event.preventDefault();event.stopImmediatePropagation();options[event.key==='Home'?0:event.key==='End'?options.length-1:(index+(event.key==='ArrowDown'?1:-1)+options.length)%options.length]?.focus();}
   else if(event.key==='Escape'){event.preventDefault();event.stopImmediatePropagation();dismissMenu(root);}
   else if(event.key==='Tab'){event.preventDefault();event.stopImmediatePropagation();dismissMenu(root);const trigger=filterTrigger(document.querySelector('.phone,.places-page'));const controls=[...document.querySelectorAll('.phone button,.phone input,.places-page button,.places-page input')].filter(el=>visible(el)&&!el.disabled&&el.tabIndex>=0);const i=controls.indexOf(trigger);controls[i+(event.shiftKey?-1:1)]?.focus();}
  }else if(event.key==='ArrowDown'&&event.target.matches('.filter.icon-button,.category-select')&&event.target.getAttribute('aria-haspopup')==='menu'){
   event.preventDefault();event.stopImmediatePropagation();event.target.click();root.querySelector('.filter-menu [aria-checked=true]')?.focus();
  }
 },true);
 new MutationObserver(normalize).observe(document.body,{childList:true,subtree:true});normalize();
})();
