/* Feature command bridge for the workflow board; approved reference layouts stay intact. */
(()=>{
 const host=PFPreviewHost,api=PFPreviewFeatures,port=()=>host.connect();api.seed(port());host.features=api;
 try{const saved=JSON.parse(localStorage.getItem('pf-preview-device')||'null');if(saved)host.store.setDevice(saved)}catch{}
 const frame=()=>document.querySelector('#preview iframe');
 function payload(){try{return frame()?.contentWindow.PFPreviewFeatureFrame?.read()||{}}catch{return {}}}
 function route(target,params={}){host.capture();const p=port();if(params.conversation&&target.startsWith('chat-'))return host.openConversation(params.conversation);if(!p.current()&&document.querySelector('#preview').dataset.screen)p.navigate({screen:document.querySelector('#preview').dataset.screen,params:{},mode:p.mode()});p.navigate({screen:target,params,mode:p.mode()});delete document.getElementById('preview').dataset.screen;host.navigateFeatureApply(p.current())}
 host.navigateFeatureApply=routeValue=>{chooseFeatureRestore=true;try{host.applyFeatureRoute(routeValue)}finally{chooseFeatureRestore=false}};
 let chooseFeatureRestore=false;
 host.featureRoute=route;
 host.featureAction=(action,extra={})=>{
  host.capture();const p=port();api.seed(p);const v={...p.current()?.params,...payload(),...extra};if(action==='A053'&&!v.petId)v.petId=p.current()?.params?.pet||'pet-persik';
  if(action==='A209'){host.store.signOut();host.navigate('account-entry',true);return {ok:true}}
  if(action==='A048')p.saveDraft('editor-photo','profile-edit',v.profile?.photo||null);if(action==='A047'){if(!String(v.profile?.name||'').trim())return host.featureNotice('Укажите имя.');p.saveProfile(v.profile);p.saveContext('dirty-edit',undefined);p.saveContext('edit-baseline:profile-edit',undefined);p.clearDraft('editor-photo','profile-edit');p.clearDraft('fields:'+v.fieldKey,v.record||'');route('profile');return {ok:true}}
  if(['A027','A028'].includes(action)){if(!v.helper.isNew&&!String(v.helper.experience||'').trim())return host.featureNotice('Опишите опыт или отметьте, что вы только начинаете.');if(!api.zone(v.helper.zone||v.helper.serviceCity?.[3]))return host.featureNotice('request-invalid');p.savePreferences({helperSaved:v.helper});p.saveContext('dirty-edit',undefined);p.saveContext('edit-baseline:helper',undefined);p.saveContext('edit-onboarding-baseline',undefined);route(action==='A027'?'profile':'apply-confirm',{request:v.request||'nearby-bonya'});return {ok:true}}
  if(action==='A126'){try{frame().contentWindow.PFPreviewFeatureFrame.applyFilters()}catch{}return {ok:true}}
  const result=api.execute(p,action,v);
  if(!result.ok){if(action==='A212'){route('target-unavailable',{record:v.activity||''});return result}host.featureNotice(result.reason);return result}
  if(result.copy){navigator.clipboard?.writeText(new URL('workflow-map.html'+result.copy,location.href).href).catch(()=>host.featureNotice('Не удалось скопировать ссылку.'));host.featureNotice('Ссылка на сообщество скопирована.');return result}
  if(result.device){host.store.setDevice(result.device);localStorage.setItem('pf-preview-device',JSON.stringify(host.store.device()))}
  if(['A050','A051','A107','A217'].includes(action)){p.clearDraft('feature-id',p.current()?.screen);p.clearDraft('fields:'+v.fieldKey,v.record||'')}if(action==='R27-502'){while(p.history().length>1&&p.current()?.screen!==result.target)p.back()}if(result.target)route(result.target,result.params);return result;
 };
 host.returnFromReport=()=>{host.capture();const p=port(),origin=p.context('report-origin');if(!origin)return route('chats');const same=r=>r&&r.screen===origin.screen&&JSON.stringify(r.params||{})===JSON.stringify(origin.params||{});while(p.history().length>1&&!same(p.current()))p.back();p.setMode(origin.mode||p.mode());route(origin.screen,origin.params||{});};
 host.featureNotice=text=>{try{frame().contentWindow.PFPreviewFeatureFrame?.notice(text)}catch{}return {ok:false,reason:text}};
 const commands=new Set(['A014','A007','A022','A029','A048','A033','A050','A051','A053','A061','A066','A073','A089','A095','A104','A107','A117','A124','A126','A135','A136','A140','A141','A146','A152','A156','A158','A160','A173','A179','A191','A200','A202','A209','A212','A217','A047','A027','A028','R27-500','R27-501','R27-502','R27-544','R27-541','R27-530','R27-534']);
 document.addEventListener('click',e=>{const button=e.target.closest('#detail .edge button[data-screen]');if(!button)return;const action=button.closest('.edge').querySelector('.top span')?.textContent.trim();if(commands.has(action)){e.preventDefault();e.stopImmediatePropagation();host.featureAction(action)}},true);
 // Explicit fixture controls are outside product screens. Provider state is simulated, never inferred from navigation.
 const controls=document.getElementById('preview-foundations');controls.insertAdjacentHTML('beforeend','<label>Email fixture state <select id="preview-email-state"><option value="pending">Pending</option><option value="confirmed">Confirmed</option><option value="expired">Expired link</option></select></label><p>Browser fixture only. No provider, GPS, map token or server commands.</p>');document.getElementById('preview-email-state').onchange=e=>port().savePreferences({emailState:e.target.value});
 document.getElementById('preview-back').onclick=()=>{const screen=port().current()?.screen;return ['helper','profile-edit'].includes(screen)?host.featureAction(screen==='helper'?'A029':'A048'):host.back()};
 window.addEventListener('hashchange',e=>{const current=port().current();if(!['helper','profile-edit'].includes(current?.screen)||location.hash.slice(1)===current.screen)return;e.stopImmediatePropagation();host.featureAction(current.screen==='helper'?'A029':'A048')},true);
 host.store.subscribe(()=>api.seed(port()));
 const originalNavigate=host.navigate;host.navigate=(screen,replace)=>{if(host.store.accountId()==='signed-out'&&!['account-entry','email-register','account-recovery','password-reset-sent','password-new','email'].includes(screen))return originalNavigate('account-entry',true);return originalNavigate(screen,replace)};
})();
