// Only replace simplified shell-review fixtures with the approved prior pages.
// Frozen scripts and all source reference pages remain untouched.
const originalRender=render;
render=function(){originalRender();const v=views[0];if(['nearby','people'].includes(v.page)&&!v.modal&&!v.sheet){document.getElementById('phone-0').innerHTML=`<iframe title="Approved ${v.page} reference" src="${v.page}-reference.html" style="width:100%;height:100%;border:0"></iframe>`;}}
go(0,new URLSearchParams(location.search).get('screen')||'nearby');
const originalSheet=sheet,originalProfile=profile;
let profilePreview=null;
sheet=function(i){if(views[i].sheet==='editProfile')return '<iframe title="Existing profile editor" src="profile-edit-reference.html" style="position:absolute;inset:0;width:100%;height:100%;border:0;z-index:10"></iframe>';return originalSheet(i);}
profile=function(i){const html=originalProfile(i);return profilePreview?html.replace('Анна Ковалевская',escape(profilePreview.name)).replace('Минск · Центральный район',escape(profilePreview.city+' · '+profilePreview.district)):html;}
function updateProfilePreview(value){profilePreview={name:value.name,city:value.city,district:value.district};views[0].about=value.about;closeSheet(0);}
function profileDraftForEditor(){return profilePreview?{...profilePreview,about:views[0].about}:null;}
let petPreview={name:'Персик',breed:'Британский',kind:'cat'};
const priorProfileWithPreview=profile;
profile=function(i){let html=priorProfileWithPreview(i);const start=html.indexOf('<h3 class="section-title">Мои питомцы</h3>'),end=html.indexOf('<h3 class="section-title">Избранные места</h3>');if(start>=0&&end>=0)html=html.slice(0,start)+`<section class="section restored-pets"><div class="section-heading"><h3>Мои питомцы</h3>${btn(ic('plus'),`openSheet(${i},'addPetReference')`,'icon-button','aria-label="Добавить питомца"')}</div>${btn(`<span class="avatar">${ic('paw-print')}</span><span class="copy"><strong class="name">${escape(petPreview.name)}</strong><span class="meta">${petPreview.kind==='dog'?'Собака':'Кот'} · ${escape(petPreview.breed)}</span></span>${ic('chevron-right')}`,`openSheet(${i},'pet')`,'pet-card')}</section>`+html.slice(end);return html;}
const priorSheetWithEditor=sheet;
sheet=function(i){return views[i].sheet==='addPetReference'?'<iframe title="Existing pet form" src="pet-edit-reference.html" style="position:absolute;inset:0;width:100%;height:100%;border:0;z-index:10"></iframe>':priorSheetWithEditor(i);}
function updatePetPreview(value){petPreview={name:value.name,breed:value.breed,kind:value.kind};closeSheet(0);}
function getThemePreview(){return dark;}
render();

let nearbyCityPreview='Минск',nearbySelectionPreview='manual';
function getNearbyCityPreview(){return {city:nearbyCityPreview,selection:nearbySelectionPreview};}
function setNearbyCityPreview(city,selection){nearbyCityPreview=city;nearbySelectionPreview=selection;}

const settingsWithRoles=settings;
settings=function(i){const label=capability==='both'?'Владелец и помощник':capability==='helper'?'Помощник по выгулу':'Владелец питомца';return settingsWithRoles(i).replace('<div class="rule"></div>'+row('Роли в приложении',label,'users-round',`openModal(${i},'mode')`),'');}
const renderBeforeNeutralRoles=render;
render=function(){renderBeforeNeutralRoles();refineNavigation();document.querySelectorAll('iframe.original-walks').forEach(frame=>{const url=new URL(frame.src);frame.src='walking-reference.html'+url.search;});}
render();

// Restore the earlier Studio meeting hierarchy from studio-review-native's meetup.
const priorMeetingDetail=detail;let meetingJoinedPreview=false;
detail=function(i,page){if(page==='conversation'&&views[i].meetingChatPreview)return '<h3>Прогулка у озера</h3><p class="meta">Чат встречи · макет</p><div class="soft-note"><strong>Анна · 18:10</strong><p>Встречаемся у общественного входа. Возьмите воду для питомцев.</p></div>';if(page!=='conversation')views[i].meetingChatPreview=false;if(page!=='meeting')return priorMeetingDetail(i,page);return `<div class="meeting-restored"><h3 class="meeting-title">Прогулка у озера</h3><div class="meeting-fact">${ic('calendar-days')}<div><strong>Завтра · 18:30</strong><span class="meta">60 минут · Europe/Minsk</span></div></div><div class="meeting-fact">${ic('map-pin')}<div><strong>Комсомольское озеро</strong><span class="meta">Минск · общественный вход</span></div></div><div class="meeting-map">${ic('map')}<span>Карта пока недоступна</span></div><h3 class="section-title">Организатор</h3><div class="meeting-fact"><span class="avatar">АН</span><div><strong>Анна</strong><span class="meta">${meetingJoinedPreview?'9':'8'} из 12 участников · макет</span></div></div><p>Встречаемся у общественного входа. Пойдём спокойным маршрутом.</p><p class="plain-hint">Время встречи обновлено. Участие добровольное.</p>${meetingJoinedPreview?btn('Открыть чат',`openMeetingChatPreview(${i})`,'primary')+btn('Отменить участие',`setMeetingParticipation(false)`,'subtle-button'):btn('Присоединиться',`setMeetingParticipation(true)`,'primary')}<p class="role-note">Участие сохраняется только в макете.</p></div>`;}
function setMeetingParticipation(value){meetingJoinedPreview=value;render();}
render();

function openMeetingChatPreview(i){views[i].meetingChatPreview=true;openModal(i,'conversation');}
