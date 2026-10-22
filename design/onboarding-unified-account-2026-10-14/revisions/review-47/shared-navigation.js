/* Review 41: presentation/semantics only. Feature callbacks own navigation and history. */
(()=>{
 const copies={ru:['Основная навигация','Разделы','Профиль'],en:['Main navigation','Sections','Profile'],be:['Асноўная навігацыя','Раздзелы','Профіль'],pl:['Nawigacja główna','Sekcje','Profil']};
 const file=location.pathname.split('/').pop();
 function normalize(){const code=typeof locale==='string'?locale:typeof lang==='number'?['ru','en','be','pl'][lang]:(document.documentElement.lang||'ru').slice(0,2),copy=copies[code]||copies.ru;document.querySelectorAll('.phone,.places-page').forEach(root=>{
  root.querySelectorAll('.full-head,.meeting-head,.places-header,.helper-page-head').forEach(head=>{
   head.classList.add('studio-page-head');
   head.querySelectorAll('button').forEach(button=>{button.type='button';button.querySelectorAll('svg,.icon').forEach(icon=>icon.setAttribute('aria-hidden','true'))});
  });
  root.querySelectorAll('.chat-bar').forEach(head=>head.classList.add('studio-chat-head'));
  root.querySelectorAll('.nav').forEach(nav=>{
   nav.setAttribute('aria-label',copy[0]);
   const buttons=[...nav.querySelectorAll('button')];
   if(!buttons.some(b=>b.getAttribute('aria-current')==='page'||b.classList.contains('active'))&&['profile-edit-reference.html','pet-edit-reference.html'].includes(file))buttons.at(-1)?.setAttribute('aria-current','page');
   buttons.forEach(button=>{
    button.type='button';if(button.classList.contains('active'))button.setAttribute('aria-current','page');
    let label=button.querySelector('.nav-label');
    if(!label){const nodes=[...button.childNodes].filter(n=>n.nodeType===Node.TEXT_NODE),text=nodes.map(n=>n.textContent).join('').trim();if(text){label=document.createElement('span');label.className='nav-label';label.textContent=text;nodes.forEach(n=>n.remove());button.append(label)}}
    if(label){if(['Я','Me','Ja'].includes(label.textContent.trim()))label.textContent=copy[2];const name=label.textContent.trim();if(name)button.setAttribute('aria-label',name)}
    button.querySelectorAll('svg,.icon').forEach(icon=>icon.setAttribute('aria-hidden','true'));
   });
  });
  root.querySelectorAll('.tabs').forEach(tabs=>{
   tabs.setAttribute('role','tablist');if(!tabs.hasAttribute('aria-label')&&!tabs.hasAttribute('aria-labelledby'))tabs.setAttribute('aria-label',copy[1]);
   tabs.querySelectorAll('button').forEach(button=>{button.type='button'});
  });
 });}
 new MutationObserver(normalize).observe(document.documentElement,{childList:true,subtree:true});normalize();
})();
