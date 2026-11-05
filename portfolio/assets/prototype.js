/* English adaptation of the current Flutter screen structure. Synthetic demo data. */
(() => {
  'use strict';
  const root = document.getElementById('pf-final');
  const app = root.querySelector('.app');
  const body = root.querySelector('.app-body');
  const header = root.querySelector('.app-header');
  const nav = root.querySelector('.bottom-nav');
  const overlay = root.querySelector('[data-overlay]');
  const content = root.querySelector('.sheet-content');
  const storageKey = 'petfriendly-portfolio-v2';
  const esc = value => String(value ?? '').replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
  const icon = name => `<i data-lucide="${name}" aria-hidden="true"></i>`;
  const button = (action, label, cls = 'secondary', extra = '') => `<button type="button" class="${cls}" data-action="${action}" ${extra}>${label}</button>`;
  const iconButton = (action, label, name, extra = '') => button(action, icon(name), 'icon-button', `aria-label="${esc(label)}" ${extra}`);
  let saved = {};
  try { saved = JSON.parse(localStorage.getItem(storageKey) || '{}'); } catch { /* Optional storage. */ }
  const tabs = ['nearby','people','walk','chats','profile'];
  const requested = new URLSearchParams(location.search).get('screen');
  const state = {
    theme: ['light','dark','system'].includes(saved.theme) ? saved.theme : 'system',
    tab: tabs.includes(requested) ? requested : tabs.includes(saved.tab) ? saved.tab : 'nearby',
    city: ['Minsk','Warsaw','Vilnius'].includes(saved.city) ? saved.city : 'Minsk',
    favorites: Array.isArray(saved.favorites) ? saved.favorites.filter(id => ['park','cafe','vet'].includes(id)) : [],
    segment: 'people', personQuery: '', placeQuery: '', category: 'all', access: 'all', savedOnly: false,
    page: null, profile: {name:'Alex',district:'Central district',about:'I enjoy walks and meeting new people.',interests:'Walking, hiking'},
    pet: {name:'Luna',kind:'Dog',age:'2',temperament:'Playful, takes time to make friends'},
    chats: {}, messages: {}, joined: false, offered: false, newWalks: [], newEvents: [], groups: [], reviews: {},
  };
  const people = [
    {id:'anna', name:'Anna & Bruno', district:'Central district', kind:'Dog · calm and friendly', interests:'Easygoing walks'},
    {id:'sasha', name:'Sasha', district:'Sovetsky district', kind:'', interests:'Walking help'},
  ];
  const places = [
    {id:'park',name:'Green Park',category:'park',categoryLabel:'Park',description:'Wide walking paths and a quiet place to spend time outdoors.',access:'unknown',distance:'600 m',icon:'trees'},
    {id:'cafe',name:'Coffee & Paws',category:'cafe',categoryLabel:'Cafe',description:'A small courtyard cafe. This is a fictional venue for the browser demo.',access:'confirmed',distance:'900 m',icon:'coffee'},
    {id:'vet',name:'Neighborhood Vet',category:'vet',categoryLabel:'Veterinary clinic',description:'A fictional veterinary clinic used to demonstrate service discovery.',access:'unknown',distance:'1.2 km',icon:'stethoscope'},
  ];
  let lastFocus = null, focusAction = null, focusId = null, timer, activeChat = null, activePlace = null;
  const icons = () => { if (window.lucide) lucide.createIcons(); };
  const save = () => { try { localStorage.setItem(storageKey, JSON.stringify({theme:state.theme,tab:state.tab,city:state.city,favorites:state.favorites})); } catch { /* Storage can be disabled. */ } };
  const isDark = () => state.theme === 'dark' || (state.theme === 'system' && matchMedia('(prefers-color-scheme:dark)').matches);
  const notice = text => {
    const toast = root.querySelector('.toast'); toast.textContent = text; toast.hidden = false;
    clearTimeout(timer); timer = setTimeout(() => { toast.hidden = true; }, 3000);
  };
  const footerNote = '<p class="notice">Fictional demo data · PetFriendly</p>';
  function select(tab) {
    state.tab = tab; state.page = null; closeSheet(false); render(); save(); body.scrollTop = 0;
  }
  function renderHeader() {
    const titles = {nearby:'petfriendly',people:'People',walk:'Walking',chats:'Chats',profile:'Profile'};
    const subTitles = {places:'Places',events:'Meetups',settings:'Settings',conversation:state.chats[activeChat] || 'Conversation'};
    const sub = state.page;
    const title = sub ? `<span class="header-title">${iconButton('back','Go back','arrow-left')}${esc(subTitles[sub] || 'Details')}</span>` : state.tab === 'nearby' ? '<span class="wordmark">petfriendly<span>.</span></span>' : `<h2 class="header-title">${titles[state.tab]}</h2>`;
    const theme = !sub && ['nearby','profile'].includes(state.tab) ? iconButton('theme',isDark()?'Switch to light theme':'Switch to dark theme',isDark()?'sun':'moon') : '';
    const compose = !sub && state.tab === 'chats' ? iconButton('compose','New conversation','message-square-plus') : '';
    const settings = !sub && state.tab === 'profile' ? iconButton('settings','Settings','settings') : '';
    header.innerHTML = `${title}<div class="header-actions"><span class="demo-badge">DEMO</span>${compose}${theme}${settings}</div>`;
  }
  function render() {
    app.dataset.theme = state.theme; renderHeader();
    nav.hidden = !!state.page;
    nav.querySelectorAll('[data-tab]').forEach(b => b.setAttribute('aria-pressed',String(b.dataset.tab === state.tab)));
    if (state.page === 'places') renderPlaces();
    else if (state.page === 'events') renderEvents();
    else if (state.page === 'settings') renderSettings();
    else if (state.page === 'conversation') renderConversation();
    else ({nearby:renderNearby,people:renderPeople,walk:renderWalk,chats:renderChats,profile:renderProfile})[state.tab]();
    icons();
  }
  function renderNearby() {
    body.innerHTML = `<h1>A good day<br>for a walk.</h1><p class="intro-subtitle">And a little company for you both.</p>
      ${button('events',`<span><strong>Evening walk</strong><span class="small">Tomorrow, 18:30 · ${esc(state.city)}</span><span class="event-link">Open meetups</span></span>${icon('arrow-right')}`,'event-banner')}
      <div class="section-heading"><h2>Places nearby</h2>${button('city',`${esc(state.city)}${icon('chevron-down')}`,'city-button')}</div>
      ${button('places',`${icon('list')}<span class="grow">Open places list</span>${icon('chevron-right')}`,'navigation-row')}
      <p class="map-note">Map unavailable in this browser preview.</p>`;
  }
  function renderPeople() {
    body.innerHTML = `<div class="segments" aria-label="Community view">${button('people-segment','People nearby','',`aria-pressed="${state.segment==='people'}"`)}${button('groups-segment','Communities','',`aria-pressed="${state.segment==='groups'}"`)}</div>
      <label class="field">${icon('search')}<input type="search" data-search="people" aria-label="Search people or communities" placeholder="${state.segment==='people'?'Name, pet or interest':'Name or interest'}" value="${esc(state.personQuery)}"></label><div id="people-results"></div>`;
    renderPeopleResults();
  }
  function renderPeopleResults() {
    const result = body.querySelector('#people-results'); if (!result) return;
    const query = state.personQuery.toLowerCase();
    if (state.segment === 'people') {
      const visible = people.filter(p => Object.values(p).join(' ').toLowerCase().includes(query));
      result.innerHTML = '<p class="small">People’s exact locations are hidden.</p>' + visible.map(p => `<article class="person"><div class="identity-row"><span class="avatar">${icon('user-round')}</span><div class="grow"><h3>${esc(p.name)}</h3><p class="small">${esc(p.district)}</p></div>${iconButton('chat',`Message ${p.name}`,'message-circle',`data-id="${p.id}"`)}</div>${p.kind?`<div class="pet-fact">${icon('paw-print')}<span>${esc(p.kind)}</span></div>`:''}<p class="small" style="margin-top:8px">${esc(p.interests)}</p></article>`).join('') + (!visible.length?'<div class="blank"><h3>No one found</h3><p class="muted">Try another name, pet or interest.</p></div>':'') + footerNote;
    } else {
      const groups = [{id:'neighbors',title:'Pets in the neighborhood',description:'Walks, new friends and neighborhood advice.'},...state.groups].filter(g => `${g.title} ${g.description}`.toLowerCase().includes(query));
      result.innerHTML = `<div class="section-heading"><h2>Find a community</h2>${iconButton('new-group','Create community','plus')}</div>${button('events',`${icon('calendar-days')}Shared walks`,'text-button')}` + groups.map(g=>button('group',`<h3>${esc(g.title)}</h3><p style="margin-top:12px">${esc(g.description)}</p><span class="small">${icon('users')} 1 member · Open community</span>`,'studio-card',`data-id="${esc(g.id)}" style="width:100%;text-align:left"`)).join('') + (!groups.length?'<p>No communities found. Try another search.</p>':'') + footerNote;
    }
    icons();
  }
  function renderWalk() {
    body.innerHTML = `<p class="intro-subtitle">Ask your neighbors for help, or lend a hand.</p>${button('new-walk',`${icon('plus')}Request walking help`,'primary')}<h2>Walking requests</h2>
      <article class="studio-card"><div class="identity-row"><span class="avatar">${icon('paw-print')}</span><div><h3>Walk with Bruno</h3><p class="small">Dog · 3 years old</p></div></div><div class="facts"><span>${icon('calendar-days')}Tomorrow, 13:00</span><span>${icon('clock')}45 min</span><span>${icon('map-pin')}Central district</span></div><p class="small">Calm and friendly</p><p>Please help take Bruno for a walk.</p><p class="small">Open · ${state.offered?'1 offer':'0 offers'}</p><div class="request-footer"><span class="small">Anna</span>${button('walk-details','Details & offers','text-button')}</div></article>
      ${state.newWalks.length?'<h2>My requests</h2>'+state.newWalks.map(w=>`<article class="studio-card"><h3>Walk with ${esc(state.pet.name)}</h3><p class="small">${esc(w.duration)} min · ${esc(w.time)}</p><p>${esc(w.description)}</p><p class="small">Open · 0 offers</p></article>`).join(''):''}
      <h2>Helpers</h2><div class="helper-row"><span class="avatar">${icon('user-round')}</span><div class="grow"><strong>Sasha</strong><p class="small">No reviews yet · 0 completed walks</p></div>${iconButton('helper','View Sasha’s walking experience','chevron-right')}</div>`;
  }
  function renderChats() {
    const entries = Object.entries(state.chats);
    body.innerHTML = '<p class="muted">People, meetups and communities.</p>' + (entries.length ? entries.map(([id,title])=>button('chat',`<span class="avatar">${icon('user-round')}</span><span class="grow"><h3>${esc(title)}</h3><span class="small">${esc(state.messages[id]?.at(-1)?.text || 'Start the conversation')}</span></span>${icon('chevron-right')}`,'place-row',`data-id="${id}"`)).join('') : `<div class="empty-chats"><div>${icon('message-circle')}<h2>No conversations yet</h2><p>Meet people nearby or join a meetup.</p>${button('find-people','Find company','primary')}</div></div>`);
  }
  function renderProfile() {
    body.innerHTML = `<article class="studio-card profile-card"><div class="identity-row"><span class="avatar large">${icon('user-round')}${icon('camera').replace('<i ','<i class="camera" ')}</span><div><h3>${esc(state.profile.name)}</h3><p class="small">${esc(state.profile.district)}</p></div></div><p>${esc(state.profile.about)}</p><p class="small">${esc(state.profile.interests)}</p>${button('edit-profile',`${icon('pencil')}Edit profile`,'secondary')}</article>
      <p class="small">Only your district is visible on your public profile.</p><div class="section-heading"><h2>My pets</h2>${iconButton('edit-pet','Add or edit a pet','plus')}</div>
      <article class="studio-card"><div class="identity-row" style="margin:0"><span class="avatar">${icon('paw-print')}</span><div class="grow"><h3>${esc(state.pet.name)}</h3><p class="small">${esc(state.pet.kind)} · ${esc(state.pet.age)} years old</p><p class="small">${esc(state.pet.temperament)}</p></div>${iconButton('edit-pet','Edit pet','pencil')}</div></article>
      <h2>My walking experience</h2>${button('my-reputation',`<span class="grow"><strong>No reviews yet</strong><span class="small" style="display:block">0 completed walks</span></span>${icon('chevron-right')}`,'place-row')}
      <h2>Saved places${state.favorites.length?` · ${state.favorites.length}`:''}</h2>${state.favorites.length?state.favorites.map(id=>placeRow(places.find(p=>p.id===id))).join(''):button('places',`${icon('heart')}<span class="grow"><span>Saved places</span><span class="small" style="display:block">Save places to find them here.</span></span>${icon('chevron-right')}`,'navigation-row')}`;
  }
  function placeRow(p) {
    return button('place',`<span class="avatar">${icon(p.icon)}</span><span class="grow"><h3>${esc(p.name)}</h3><span class="small">${esc(p.categoryLabel)} · ${p.distance}</span><span class="small">${p.access==='unknown'?'Pet access unknown':'Pets welcome · demo evidence'}</span></span>${icon('chevron-right')}`,'place-row',`data-id="${p.id}"`);
  }
  function renderPlaces() {
    body.innerHTML = `<label class="field">${icon('search')}<input type="search" data-search="places" aria-label="Search places" placeholder="Name or category" value="${esc(state.placeQuery)}"></label><div class="toolbar"><select data-select="category" aria-label="Place category"><option value="all">All categories</option><option value="park">Parks</option><option value="cafe">Cafes</option><option value="vet">Veterinary clinics</option></select>${button('filters',`${icon('sliders-horizontal')}Place filters`,'secondary')}</div><p class="small">${esc(state.city)} · Fictional demo catalog</p><div id="places-results"></div>`;
    body.querySelector('[data-select="category"]').value = state.category; renderPlaceResults();
  }
  function renderPlaceResults() {
    const results = body.querySelector('#places-results'); if (!results) return;
    const filtered = places.filter(p => (!state.savedOnly || state.favorites.includes(p.id)) && (state.access==='all'||p.access===state.access) && (state.category==='all'||p.category===state.category) && `${p.name} ${p.categoryLabel}`.toLowerCase().includes(state.placeQuery.toLowerCase()));
    results.innerHTML = filtered.length ? filtered.map(placeRow).join('') : `<div class="blank"><h3>No matching places</h3><p class="muted">Try another search or clear your filters.</p>${button('reset-filters','Clear filters','secondary')}</div>`; icons();
  }
  function renderEvents() {
    body.innerHTML = `<div class="section-heading"><h2>Shared walks</h2>${iconButton('new-event','Create meetup','plus')}</div><article class="studio-card"><h3>Evening walk</h3><p class="small" style="margin-top:8px">Tomorrow, 18:30 · ${esc(state.city)}</p><p>Easygoing pace and new friends.</p><p class="small">${state.joined?'2':'1'} of 8 participants</p>${button('join',state.joined?'Leave meetup':'Join meetup','primary')}</article>${state.newEvents.map(e=>`<article class="studio-card"><h3>${esc(e.title)}</h3><p class="small">${esc(e.time)}</p><p>${esc(e.description)}</p><p class="small">You are the organizer · Demo only</p></article>`).join('')}`;
  }
  function renderSettings() {
    body.innerHTML = `<h2>Appearance</h2>${button('theme-sheet',`<span class="grow">App theme<span class="small" style="display:block">${esc(state.theme==='system'?'System default':state.theme==='dark'?'Dark':'Light')}</span></span>${icon('chevron-right')}`,'place-row')}<h2>Privacy & security</h2><p class="muted">Your public profile shows your district, not an exact location.</p><p class="small">Account security, MFA, session management and data export are native, server-backed features. They are not connected in this browser preview.</p><h2>About this preview</h2><p class="small">An English adaptation of the current Flutter layouts. Map unavailable state is shown because this preview has no Mapbox connection. All identities, places and activity are fictional.</p>`;
  }
  function renderConversation() {
    const messages = state.messages[activeChat] || [];
    body.innerHTML = `<p class="small">Demo conversation · messages stay in memory</p><div class="messages" role="log" aria-label="Messages" aria-live="polite">${messages.map(m=>`<div class="bubble ${m.mine?'mine':''}"><small>${m.mine?'You':esc(state.chats[activeChat])} · ${esc(m.time)}</small>${esc(m.text)}</div>`).join('')}</div><form class="composer" data-form="message"><input name="message" aria-label="Message" placeholder="Write a message…" maxlength="1000" required autocomplete="off"><button class="primary" aria-label="Send message">${icon('arrow-up')}</button></form>`;
  }
  function startChat(id) {
    const person = people.find(p=>p.id===id); if (!person) return;
    state.chats[id] = person.name; state.messages[id] ||= []; activeChat = id;
    state.page = 'conversation'; render(); body.scrollTop = 0;
  }
  function showSheet(title, html) {
    if (overlay.hidden) {
      lastFocus = document.activeElement;
      focusAction = lastFocus?.dataset?.action || null;
      focusId = lastFocus?.dataset?.id || null;
    }
    root.querySelector('#sheet-title').textContent = title;
    content.innerHTML = html; overlay.hidden = false; header.inert = body.inert = nav.inert = true;
    icons(); overlay.querySelector('[data-action="close"]').focus();
  }
  function closeSheet(restore = true) {
    overlay.hidden = true; header.inert = body.inert = nav.inert = false;
    if (restore) restoreFocus();
  }
  function restoreFocus() {
    let target = lastFocus?.isConnected ? lastFocus : null;
    if (!target && focusAction) target = [...root.querySelectorAll('[data-action]')].find(el => el.dataset.action === focusAction && (!focusId || el.dataset.id === focusId));
    (target || body).focus({preventScroll:true});
  }
  const field = (label,name,value='',type='text',extra='') => `<label>${label}<input name="${name}" type="${type}" value="${esc(value)}" ${extra} required></label>`;
  function showPlace(id) {
    const p = places.find(p=>p.id===id); if (!p) return; activePlace = id;
    const reviews = state.reviews[id] || [];
    showSheet(p.name,`<p class="small">${p.categoryLabel} · ${p.distance}</p><p>${p.description}</p><p class="small">${p.access==='unknown'?'Pet access is unknown. Check with the venue.':'Pets welcome · fictional demo evidence'}</p><div class="sheet-actions">${button('save-place',`${icon('heart')}${state.favorites.includes(id)?'Saved':'Save place'}`,'secondary',`aria-pressed="${state.favorites.includes(id)}"`)}${button('evidence','Pet-access details','secondary')}</div><h3>Reviews</h3>${reviews.length?reviews.map(r=>`<p style="margin-top:12px"><strong>${r.rating}/5 · You</strong><br>${esc(r.text)}</p>`).join(''):'<p class="small" style="margin-top:8px">No reviews yet.</p>'}${button('review','Leave a review','text-button')}<div id="review-editor"></div><p class="notice">Fictional venue. Native map and correction actions require configured services.</p>`);
  }
  root.addEventListener('click', event => {
    const target = event.target.closest('button'); if (!target || target.disabled) return;
    if (target.dataset.tab) { select(target.dataset.tab); return; }
    const action = target.dataset.action;
    switch (action) {
      case 'close': closeSheet(); break;
      case 'back': state.page = null; render(); break;
      case 'theme': state.theme = isDark()?'light':'dark'; save(); render(); break;
      case 'theme-sheet': showSheet('Appearance',['system','light','dark'].map(t=>button('choose-theme',`<span>${t==='system'?'System default':t==='light'?'Light':'Dark'}</span>${state.theme===t?icon('check'):''}`,'choice',`data-value="${t}" aria-pressed="${state.theme===t}"`)).join('')); break;
      case 'choose-theme': state.theme = target.dataset.value; save(); closeSheet(false); render(); restoreFocus(); break;
      case 'settings': state.page = 'settings'; render(); break;
      case 'places': state.page = 'places'; render(); body.scrollTop = 0; break;
      case 'events': state.page = 'events'; render(); break;
      case 'people-segment': state.segment='people'; renderPeople(); icons(); break;
      case 'groups-segment': state.segment='groups'; renderPeople(); icons(); break;
      case 'find-people': select('people'); break;
      case 'chat': startChat(target.dataset.id); break;
      case 'compose': showSheet('New conversation',people.map(p=>button('choose-chat',`<span class="avatar">${icon('user-round')}</span><span>${esc(p.name)}</span>${icon('chevron-right')}`,'choice',`data-id="${p.id}"`)).join('')); break;
      case 'choose-chat': closeSheet(false); startChat(target.dataset.id); break;
      case 'city': showSheet('Choose a city',`<p class="small">Manual selection remains under your control. This preview does not request your location.</p>${['Minsk','Warsaw','Vilnius'].map(city=>button('choose-city',`<span>${city}</span>${state.city===city?icon('check'):''}`,'choice',`data-value="${city}"`)).join('')}`); break;
      case 'choose-city': state.city=target.dataset.value;save();closeSheet(false);render();restoreFocus();break;
      case 'place': showPlace(target.dataset.id); break;
      case 'save-place': {const i=state.favorites.indexOf(activePlace);if(i<0)state.favorites.push(activePlace);else state.favorites.splice(i,1);save();target.setAttribute('aria-pressed',String(i<0));target.innerHTML=`${icon('heart')}${i<0?'Saved':'Save place'}`;icons();notice(i<0?'Place saved':'Place removed from saved places');break;}
      case 'evidence': showSheet('Pet-access details','<p>This fictional catalog demonstrates two states: unknown access and a venue with demo evidence. The native application keeps real source provenance and community evidence separate.</p>'); break;
      case 'review': content.querySelector('#review-editor').innerHTML=`<form data-form="review"><label>Rating<select name="rating" required><option value="">Choose a rating</option>${[1,2,3,4,5].map(i=>`<option value="${i}">${i} of 5</option>`).join('')}</select></label><label>Comment<textarea name="comment" maxlength="1000" required></textarea></label><p class="small" style="margin-top:8px">Demo review; stored only in memory.</p><button class="primary">Publish demo review</button></form>`;target.hidden=true;break;
      case 'filters': showSheet('Place filters',`<form data-form="filters"><label>Pet access<select name="access"><option value="all">All places</option><option value="confirmed">Pets welcome</option><option value="unknown">Unknown access</option></select></label><label>Saved places<select name="saved"><option value="all">All places</option><option value="saved">Saved only</option></select></label><button class="primary">Show places</button></form>`);content.querySelector('[name="access"]').value=state.access;content.querySelector('[name="saved"]').value=state.savedOnly?'saved':'all';break;
      case 'reset-filters': state.category=state.access='all';state.placeQuery='';state.savedOnly=false;renderPlaces();icons();break;
      case 'join': state.joined=!state.joined;renderEvents();icons();notice(state.joined?'Joined the meetup. Demo only.':'Left the meetup. Demo only.');break;
      case 'walk-details': showSheet('Walk with Bruno',`<p>Tomorrow, 13:00 · 45 min</p><p class="small">Central district · Anna</p><p>Please help take Bruno for a walk.</p><p>Pet: Bruno, dog, 3 years old. Calm and friendly.</p><p class="small">${state.offered?'Your offer has been sent. Waiting for the owner.':'Discuss details before agreeing. This demo does not create a real arrangement.'}</p>${button('offer',state.offered?'Offer sent':'Offer to help','primary',state.offered?'disabled':'')}`);break;
      case 'offer': state.offered=true;target.disabled=true;target.textContent='Offer sent';notice('Your offer was sent. Demo only.');break;
      case 'helper': showSheet('Sasha’s walking experience','<p>No reviews yet.</p><p class="small">0 completed walks. Ratings support decisions; they are not an identity or safety guarantee.</p>');break;
      case 'my-reputation': showSheet('My walking experience','<p>No reviews yet.</p><p class="small">0 completed walks. In the native app, only an owner can review a helper after an eligible completed agreement.</p>');break;
      case 'edit-profile': showSheet('Edit profile',`<form data-form="profile">${field('Display name','name',state.profile.name,'text','maxlength="60"')}${field('District','district',state.profile.district,'text','maxlength="100"')}${field('About you','about',state.profile.about,'text','maxlength="300"')}${field('Interests','interests',state.profile.interests,'text','maxlength="150"')}<button class="primary">Save demo profile</button></form>`);break;
      case 'edit-pet': showSheet('Edit pet',`<form data-form="pet">${field('Name','name',state.pet.name,'text','maxlength="60"')}${field('Species','kind',state.pet.kind,'text','maxlength="40"')}${field('Age in years','age',state.pet.age,'number','min="0" max="80"')}${field('Temperament','temperament',state.pet.temperament,'text','maxlength="200"')}<button class="primary">Save demo pet</button></form>`);break;
      case 'new-walk': showSheet('Request walking help',`<form data-form="walk">${field('When','time','','datetime-local')}${field('Duration in minutes','duration','30','number','min="10" max="240"')}<label>Details<textarea name="description" maxlength="500" required></textarea></label><p class="small" style="margin-top:12px">Pet: ${esc(state.pet.name)}. This request stays in the browser demo.</p><button class="primary">Create demo request</button></form>`);break;
      case 'new-event': showSheet('Create meetup',`<form data-form="event">${field('Title','title','','text','maxlength="80"')}${field('When','time','','datetime-local')}<label>Description<textarea name="description" maxlength="500" required></textarea></label><button class="primary">Create demo meetup</button></form>`);break;
      case 'new-group': showSheet('Create community',`<form data-form="group">${field('Name','title','','text','maxlength="80"')}<label>Description<textarea name="description" maxlength="500" required></textarea></label><button class="primary">Create demo community</button></form>`);break;
      case 'group': {const group=[{id:'neighbors',title:'Pets in the neighborhood',description:'Walks, new friends and neighborhood advice.'},...state.groups].find(g=>g.id===target.dataset.id);if(group)showSheet(group.title,`<p>${esc(group.description)}</p><p class="small">Joining requires a voluntary action. This community is fictional.</p>${button('join-group','Join demo community','primary')}`);break;}
      case 'join-group': target.textContent='Joined';target.disabled=true;notice('Joined the community. Demo only.');break;
    }
  });
  root.addEventListener('input', event => {
    if(event.target.dataset.search==='people'){state.personQuery=event.target.value;renderPeopleResults();}
    if(event.target.dataset.search==='places'){state.placeQuery=event.target.value;renderPlaceResults();}
  });
  root.addEventListener('change', event => {
    if(event.target.dataset.select==='category'){state.category=event.target.value;renderPlaceResults();}
  });
  root.addEventListener('submit', event => {
    const form=event.target;if(!form.dataset.form)return;event.preventDefault();
    const values=Object.fromEntries([...new FormData(form)].map(([key,value])=>[key,String(value).trim()]));
    if(Object.values(values).some(value=>!value)){notice('Please complete all fields.');return;}
    switch(form.dataset.form){
      case 'message': state.messages[activeChat].push({mine:true,text:values.message,time:new Intl.DateTimeFormat('en-GB',{hour:'2-digit',minute:'2-digit'}).format(new Date())});renderConversation();icons();body.querySelector('[name="message"]').focus();body.scrollTop=body.scrollHeight;return;
      case 'profile': state.profile=values;break;
      case 'pet': state.pet=values;break;
      case 'walk':state.newWalks.push(values);break;
      case 'event':state.newEvents.push(values);break;
      case 'group':state.groups.push({...values,id:`community-${state.groups.length+1}`});break;
      case 'filters':state.access=values.access;state.savedOnly=values.saved==='saved';break;
      case 'review':state.reviews[activePlace]||=[];state.reviews[activePlace].push({rating:Number(values.rating),text:values.comment});showPlace(activePlace);notice('Demo review added.');return;
    }
    closeSheet(false);render();restoreFocus();notice(form.dataset.form==='filters'?'Filters applied':'Saved in this demo until reload.');
  });
  overlay.addEventListener('click',event=>{if(event.target===overlay)closeSheet();});
  root.addEventListener('keydown',event=>{
    if(overlay.hidden)return;
    if(event.key==='Escape'){event.preventDefault();closeSheet();}
    if(event.key==='Tab'){
      const items=[...overlay.querySelectorAll('button,input,select,textarea')].filter(el=>!el.disabled&&el.getClientRects().length);
      const first=items[0],last=items.at(-1);
      if(event.shiftKey&&document.activeElement===first){event.preventDefault();last.focus();}
      else if(!event.shiftKey&&document.activeElement===last){event.preventDefault();first.focus();}
    }
  });
  matchMedia('(prefers-color-scheme:dark)').addEventListener('change',()=>{if(state.theme==='system')render();});
  document.getElementById('reset-demo')?.addEventListener('click',()=>{try{localStorage.removeItem(storageKey);}catch{}const url=new URL(location.href);url.searchParams.set('screen','nearby');location.replace(url.href);});
  render();
})();
