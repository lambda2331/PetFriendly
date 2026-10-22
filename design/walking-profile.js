'use strict';
(() => {
  const root = document.getElementById('app-root');
  const phone = document.getElementById('phone');
  const controls = Object.fromEntries(['screen','scenario','theme','width','scale','platform','failure'].map(k => [k, document.getElementById(k + '-choice')]));
  const state = { screen: 'personal', scenario: 'established', theme: 'light', width: '390', scale: '1', platform: 'ios', tab: 'walking', back: [], busy: false, feedback: '', replyId: null, drafts: {}, submitted: {}, expanded: {}, menu: false, reportTarget: '', reportDraft: '', messageDraft: 'Здравствуйте! Хочу обсудить прогулку с моим питомцем.', messages: [], fail: false, blocked: false };
  const reviews = [
    { id: 'first', author: 'Евгения', initials: 'Е', date: '6 октября 2026', rating: 5, body: 'Нора вернулась довольная и спокойная. Александра заранее уточнила привычки собаки и после прогулки написала, как всё прошло.', reply: '' },
    { id: 'second', author: 'Дмитрий', initials: 'Д', date: '28 сентября 2026', rating: 5, body: 'Всё вовремя. Бруно быстро привык к Александре, договорились о спокойном маршруте в парке.', reply: 'Спасибо, Дмитрий! С Бруно было приятно гулять. Рада, что ему подошёл наш маршрут.', replyDate: '29 сентября 2026' },
    { id: 'third', author: 'Мария', initials: 'М', date: '14 сентября 2026', rating: 4, body: 'Прогулка прошла хорошо. Вначале мы немного по-разному поняли время встречи, но быстро уточнили всё в чате. Мне понравилось, что Александра спросила, какие команды знает Ричи и как он реагирует на других собак. Ричи вернулся спокойным. В следующий раз заранее напишу точное время и ещё раз проверю, что мы одинаково поняли договорённость.', reply: 'Спасибо за отзыв. В следующий раз заранее уточню время в чате, чтобы не было недопонимания.', replyDate: '15 сентября 2026' }
  ];
  const esc = value => String(value ?? '').replace(/[&<>"']/g, x => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[x]));
  const icon = name => `<i data-lucide="${name}" aria-hidden="true"></i>`;
  const btn = (action, text, kind = 'quiet-action', extra = '') => `<button type="button" data-action="${action}" class="${kind}" ${state.busy ? 'disabled' : ''} ${extra}>${text}</button>`;
  const own = () => state.screen === 'own';
  const populated = () => ['established','long'].includes(state.scenario);
  const foreign = () => ['public','chat','block'].includes(state.screen) || (state.screen === 'report' && state.reportForeign);
  const name = () => foreign() ? (state.scenario === 'long' ? 'Виктория Александровна Соколова-Воскресенская' : 'Виктория Соколова') : (state.scenario === 'long' ? 'Александра Константиновна Левина-Соколова' : 'Александра Левина');
  const avatar = (small = false) => state.scenario === 'long' || state.scenario === 'new' ? `<span class="avatar${small ? ' small' : ''}" aria-hidden="true">${foreign() ? 'ВС' : 'АЛ'}</span>` : `<img class="avatar${small ? ' small' : ''}" src="walking-assets/${foreign() ? 'helper.jpg' : 'owner.jpg'}" alt="" width="64" height="64">`;
  function go(screen) { if(state.busy) return; state.back.push(state.screen); state.screen = screen; state.feedback = ''; state.menu = false; render(true); }
  function back() { if(state.busy) return; state.screen = state.back.pop() || 'personal'; state.feedback = ''; state.menu = false; render(true); }
  function operation(success, message) {
    if(state.busy) return;
    state.busy = true; state.feedback = ''; render();
    setTimeout(() => {
      state.busy = false;
      if(state.fail) { state.fail = false; controls.failure.checked = false; state.feedback = message; render(); }
      else { success(); render(); }
    }, 650);
  }
  function nav() {
    return `<nav class="bottom-nav" aria-label="Разделы PetFriendly">
      <span class="nav-label" aria-label="Рядом, вне этого прототипа"><span class="nav-icon">${icon('compass')}</span>Рядом</span>
      <span class="nav-label" aria-label="Люди, вне этого прототипа"><span class="nav-icon">${icon('users')}</span>Люди</span>
      <button class="${state.screen === 'walks' ? 'active' : ''}" data-action="walks"><span class="nav-icon">${icon('paw-print')}</span>Выгул</button>
      <span class="nav-label" aria-label="Чаты, вне этого прототипа"><span class="nav-icon">${icon('message-square')}</span>Чаты</span>
      <button class="${state.screen === 'personal' ? 'active' : ''}" data-action="personal"><span class="nav-icon">${icon('user-round')}</span>Я</button>
    </nav>`;
  }
  function bar(title) {
    if(['personal','walks'].includes(state.screen)) return `<header class="app-bar"><span class="wordmark">petfriendly<b>.</b></span><span class="mode-label">ПРИМЕР</span>${btn('theme',icon(state.theme === 'dark' ? 'sun' : 'moon'),'icon-button',`aria-label="${state.theme === 'dark' ? 'Светлая' : 'Тёмная'} тема"`)}</header>`;
    return `<header class="app-bar">${btn('back',icon('arrow-left'),'icon-button','aria-label="Назад"')}<span class="bar-title">${title}</span>${state.screen === 'public' ? btn('menu',icon('ellipsis'),'icon-button','aria-label="Действия с профилем" aria-expanded="'+state.menu+'"') : ''}</header>`;
  }
  function facts(personal = false) {
    if(state.scenario === 'loading') return `<section class="section" aria-label="Загружается опыт помощника" aria-busy="true"><div class="state-message pending">${icon('loader-circle')}<p>Загружаем опыт и отзывы…</p></div><div class="skeletons" aria-hidden="true"><div class="skeleton medium"></div><div class="skeleton short"></div></div></section>`;
    if(state.scenario === 'unavailable') return `<section class="section"><div class="state-message error" role="alert">${icon('cloud-off')}<div><h3>Опыт не загрузился</h3><p>Не удалось получить данные. Это не означает, что выгулов или отзывов нет.</p></div></div>${btn('retry',state.busy ? 'Загружаем…' : 'Повторить загрузку','soft-action')}</section>`;
    const count = populated() ? 18 : state.scenario === 'unrated' ? 5 : 0;
    return `<div class="facts" aria-label="${personal ? 'Ваш' : 'Помощник: '+esc(name())+', его'} опыт выгула">
      <div class="fact">${populated() ? `<p aria-label="Средняя оценка 4,7 из 5">${icon('star')}<strong>4,7</strong><span class="caption">из 5</span></p><span class="caption">3 опубликованных отзыва</span>` : `<p>Пока нет отзывов</p><span class="caption">Оценка появится после первого отзыва</span>`}</div>
      <div class="fact"><p><strong>${count}</strong></p><span class="caption">завершённых выгулов</span></div>
    </div>`;
  }
  function review(r, preview = false) {
    const long = r.id === 'third' || (state.scenario === 'long' && r.id === 'first');
    const rawBody = state.scenario === 'long' && r.id === 'first' ? reviews[2].body + ' Встречались в нашем районе, а личные детали согласовали только в переписке. Буду обращаться снова.' : r.body;
    const body = foreign() ? rawBody.replaceAll('Александра','Виктория').replaceAll('Александре','Виктории') : rawBody;
    const expanded = !!state.expanded[r.id];
    const reply = own() ? state.submitted[r.id] ?? r.reply : r.reply;
    return `<article class="review" aria-label="Отзыв ${esc(r.author)}, ${r.rating} из 5">
      <div class="review-head"><span class="avatar small" aria-hidden="true">${r.initials}</span><div class="author"><strong>${esc(r.author)}</strong><p class="date">${r.date}</p></div><span class="review-rating" aria-label="${r.rating} из 5">${icon('star')}${r.rating}</span>${!preview ? btn('review-menu:'+r.id,icon('ellipsis'),'icon-button',`aria-label="Действия с отзывом ${esc(r.author)}"`) : ''}</div>
      <p class="review-text">${esc(long && !expanded ? body.slice(0,155) + '…' : body)}</p>
      ${long ? btn('expand:'+r.id, expanded ? 'Свернуть отзыв' : 'Читать полностью','quiet-action review-action',`aria-expanded="${expanded}"`) : ''}
      ${reply && !preview ? `<div class="helper-reply"><p class="caption">Ответ ${own() ? 'от вас' : 'помощника'} · ${r.replyDate || 'сегодня'}</p><p>${esc(reply)}</p></div>` : ''}
      ${!preview && own() && state.replyId !== r.id ? btn('reply:'+r.id,reply ? 'Изменить ответ' : 'Ответить на отзыв','quiet-action review-action') : ''}
      ${state.menu === 'review:'+r.id && !preview ? `<div class="menu">${btn('report-review:'+r.id,icon('flag')+'Пожаловаться на отзыв')}</div>` : ''}
      ${!preview && state.replyId === r.id ? replyForm(r) : ''}
    </article>`;
  }
  function replyForm(r) {
    const value = state.drafts[r.id] ?? state.submitted[r.id] ?? r.reply;
    return `<form data-form="reply" data-id="${r.id}" class="form-group">
      <label for="reply-${r.id}">Ваш ответ</label><textarea id="reply-${r.id}" name="reply" data-draft="${r.id}" maxlength="1000" ${state.busy ? 'disabled' : ''} placeholder="Поблагодарите или уточните детали">${esc(value)}</textarea>
      <p class="caption">Ответ будет публичным. Не указывайте адреса, контакты и инструкции по уходу.</p><p class="caption reply-count" id="reply-count">${value.length} / 1000</p>
      ${state.feedback ? `<p class="state-message error" role="alert">${icon('circle-alert')}${esc(state.feedback)}</p>` : ''}
      <div class="form-actions"><button class="primary-action" type="submit" ${state.busy ? 'disabled' : ''}>${state.busy ? 'Публикуем…' : state.feedback ? 'Повторить публикацию' : 'Опубликовать ответ'}</button>${btn('cancel-reply','Отмена','soft-action')}</div>
    </form>`;
  }
  function empty(personal = false) {
    if(state.scenario === 'new') return `<section class="empty-block"><div class="empty-symbol">${icon('paw-print')}<h3>${personal ? 'Первый выгул впереди' : 'Первый опыт ещё впереди'}</h3></div><p class="caption">${personal ? 'Откликнитесь на запрос владельца. Завершённые выгулы и отзывы появятся здесь.' : 'У помощника пока нет завершённых выгулов и отзывов. Обсудите привычки питомца и детали прогулки в чате.'}</p></section>`;
    return `<section class="section"><h3>Отзывы ещё впереди</h3><p class="explanation">${personal ? 'Вы уже помогали с выгулом. Владелец может оставить отзыв после подтверждения завершённой прогулки.' : 'Есть завершённые выгулы, но владельцы пока не оставили отзывов.'}</p></section>`;
  }
  function reputationNotes() {
    return `<details><summary>${icon('info')}Как считается опыт</summary><p>Здесь только выгулы, завершённые вами как помощником. В оценку входят опубликованные отзывы по подтверждённым прогулкам. Запросы для вашего питомца в эти числа не входят.</p></details>`;
  }
  function personal() {
    return `${bar()}<main class="page screen-enter"><h1 class="intro view-heading" tabindex="-1">Вы, питомцы<br>и ваши истории.</h1>
      <section class="identity-surface" aria-label="Ваш профиль"><div class="identity">${avatar()}<div class="identity-copy"><h2>${esc(name())}</h2><p class="caption">Минск · Первомайский район</p></div></div><div class="pet-line">${state.scenario === 'long' ? `<span class="avatar pet" aria-hidden="true">${icon('paw-print')}</span>` : `<img class="avatar pet" src="walking-assets/pet.jpg" width="36" height="36" alt="">`}<p>Луна · корги</p></div></section>
      <div class="profile-tabs" role="tablist" aria-label="Содержимое профиля"><button type="button" role="tab" id="favorites-tab" tabindex="${state.tab === 'favorites' ? '0' : '-1'}" aria-controls="profile-content" aria-selected="${state.tab === 'favorites'}" data-action="favorites">Избранное</button><button type="button" role="tab" id="walking-tab" tabindex="${state.tab === 'walking' ? '0' : '-1'}" aria-controls="profile-content" aria-selected="${state.tab === 'walking'}" data-action="walking-tab">Выгул</button></div>
      <section id="profile-content" role="tabpanel" aria-labelledby="${state.tab === 'walking' ? 'walking-tab' : 'favorites-tab'}" class="section">
      ${state.tab === 'favorites' ? `<h2>Избранные места</h2><p>Александровский сквер</p><p class="caption">Парк · Минск</p>` : `
        <h2>Ваш опыт как помощника</h2><p class="explanation">Когда вы гуляете с питомцами других владельцев.</p>${facts(true)}
        ${!['loading','unavailable'].includes(state.scenario) ? populated() ? `<div class="section"><h3>Последний отзыв</h3>${review(reviews[0],true)}${btn('own','Мои отзывы · 3 '+icon('chevron-right'),'row-action')}</div>` : `${empty(true)}${btn('own','Мой профиль помощника '+icon('chevron-right'),'row-action')}` : ''}
        ${reputationNotes()}${btn('walks',icon('paw-print')+'Найти запрос на выгул','primary-action')}
      `}</section></main>${nav()}`;
  }
  function helper() {
    const isOwn = own();
    const unknown = ['loading','unavailable'].includes(state.scenario);
    return `${bar(isOwn ? 'Мой профиль помощника' : 'Помощник по выгулу')}<main class="page screen-enter"><section class="section"><div class="identity">${avatar()}<div class="identity-copy"><h1 class="view-heading" tabindex="-1">${esc(name())}</h1><p class="caption">${isOwn ? 'Ваш публичный профиль' : 'Помогает с выгулом'}</p></div></div><p class="district">${icon('map-pin')}Минск · Первомайский район</p><p class="bio">${state.scenario === 'long' ? 'Люблю спокойные прогулки и умею подстраиваться под темп собаки. Сначала обсуждаю привычки питомца и маршрут с владельцем. Если собака тревожится или устаёт, делаю паузу и связываюсь с владельцем. Предпочитаю знакомиться заранее, чтобы всем было комфортно.' : 'Гуляю спокойно, без спешки. Перед встречей обсуждаем привычки питомца и маршрут.'}</p></section>
      ${state.menu === true ? `<div class="menu">${btn('report-profile',icon('flag')+'Пожаловаться на профиль')}${btn('block',icon('user-round-x')+'Заблокировать','destructive')}</div>` : ''}
      <section class="section"><h2>Опыт помощника</h2>${facts()}<p class="safety">Отзывы и опыт помогают принять решение, но не гарантируют безопасность.</p></section>
      ${isOwn ? btn('walks','Найти запрос на выгул','primary-action') : state.blocked ? `<p class="state-message">${icon('user-round-x')}Пользователь заблокирован. Новая переписка недоступна.</p>` : `<div class="section">${btn('contact',state.busy ? 'Открываем чат…' : icon('message-square')+'Обсудить прогулку','primary-action')}${state.feedback ? `<div class="state-message ${state.feedback.startsWith('Жалоба отправлена') ? '' : 'error'}" role="${state.feedback.startsWith('Жалоба отправлена') ? 'status' : 'alert'}">${icon(state.feedback.startsWith('Жалоба отправлена') ? 'check' : 'circle-alert')}<p>${esc(state.feedback)}</p></div>` : ''}</div>`}
      ${!unknown ? `<section class="section"><div class="section-head"><h2>${populated() ? 'Отзывы владельцев · 3' : 'Отзывы владельцев'}</h2></div>${populated() ? `${reviews.map(r => review(r)).join('')}` : empty(isOwn)}</section>` : ''}
      ${isOwn ? reputationNotes() : `<p class="explanation">В профиле виден только район. Личные детали прогулки обсуждаются в приватном чате.</p>`}
    </main>`;
  }
  function walks() {
    return `${bar()}<main class="page screen-enter"><h1 class="view-heading" tabindex="-1">На прогулку<br>с хорошей компанией.</h1><p class="explanation">Запросы владельцев, которым нужна помощь.</p>${btn('request-detail','Открыть запрос на выгул','primary-action')}<section class="section"><h2>Запрос рядом</h2><div class="identity"><img class="avatar" src="walking-assets/pet.jpg" alt="" width="64" height="64"><div class="identity-copy"><h3>Прогулка с Бруно</h3><p class="caption">Минск · Первомайский район</p><p class="caption">Сегодня, 18:30 · 30 минут</p></div></div><p>Спокойная прогулка в парке. Детали обсудим в чате.</p><div class="link-group">${btn('request-detail','Подробнее и отклики '+icon('chevron-right'),'row-action')}${btn('public','Посмотреть профиль помощника '+icon('chevron-right'),'row-action')}</div></section><p class="caption">Пример существующего раздела выгула. Не новая панель договорённостей в профиле.</p></main>${nav()}`;
  }
  function request() {
    return `${bar('Запрос на выгул')}<main class="page"><h1 class="view-heading" tabindex="-1">Прогулка с Бруно</h1><p class="district">${icon('map-pin')}Минск · Первомайский район</p><p>Сегодня, 18:30 · 30 минут</p><p>Публичная часть запроса. Адрес передачи и инструкции здесь не показываются.</p>${btn('public','Профиль помощника '+icon('chevron-right'),'row-action')}${btn('apply',state.busy ? 'Отправляем…' : 'Откликнуться','primary-action')}${state.feedback ? `<p class="state-message ${state.feedback.startsWith('Отклик отправлен') ? '' : 'error'}" role="status">${esc(state.feedback)}</p>` : ''}</main>`;
  }
  function chat() {
    return `${bar('Обсудить прогулку')}<main class="page"><div class="chat-context">${avatar(true)}<div><h3>${esc(name())}</h3><p class="caption">Приватная переписка</p></div></div><p class="caption">Согласуйте время, привычки питомца и детали встречи. Начало переписки не назначает помощника.</p><div class="chat-log" aria-live="polite">${state.messages.map(m => `<article class="bubble mine"><p>${esc(m)}</p><p class="caption">Вы · 9:41</p></article>`).join('')}</div><form class="message-form" data-form="message"><label for="message">Сообщение Виктории</label><textarea id="message" name="message" maxlength="1000" ${state.busy ? 'disabled' : ''}>${esc(state.messageDraft)}</textarea>${state.feedback ? `<p class="state-message error" role="alert">${esc(state.feedback)}</p>` : ''}<button type="submit" class="primary-action" ${state.busy ? 'disabled' : ''}>${state.busy ? 'Отправляем…' : state.feedback ? 'Повторить отправку' : 'Отправить сообщение'}</button></form></main>`;
  }
  function report() {
    return `${bar('Пожаловаться')}<main class="page"><h1 class="view-heading" tabindex="-1">${state.reportTarget.startsWith('review:') ? 'Жалоба на отзыв' : 'Жалоба на профиль'}</h1><p class="caption">${state.reportTarget.startsWith('review:') ? 'Отзыв '+ reviews.find(r => r.id === state.reportTarget.split(':')[1]).author : esc(name())}</p><form class="form-group" data-form="report"><label for="reason">Что произошло?</label><textarea id="reason" name="reason" maxlength="1000" ${state.busy ? 'disabled' : ''} placeholder="Опишите причину жалобы">${esc(state.reportDraft)}</textarea><p class="caption">Жалоба предназначена модераторам. Не добавляйте личные адреса и контакты.</p>${state.feedback ? `<p class="state-message error" role="alert">${esc(state.feedback)}</p>` : ''}<button class="primary-action" type="submit" ${state.busy ? 'disabled' : ''}>${state.busy ? 'Отправляем…' : state.feedback ? 'Повторить отправку' : 'Отправить жалобу'}</button></form></main>`;
  }
  function block() {
    return `${bar('Блокировка')}<main class="page"><h1 class="view-heading" tabindex="-1">Заблокировать Викторию?</h1><p>Вы не сможете начать новую переписку с этим пользователем. Это действие не отменяет договорённость о выгуле.</p>${state.feedback ? `<p class="state-message error" role="alert">${esc(state.feedback)}</p>` : ''}<div class="form-actions">${btn('confirm-block',state.busy ? 'Блокируем…' : 'Заблокировать','soft-action destructive')}${btn('back','Назад','quiet-action')}</div><p class="caption">В прототипе блокировка только демонстрируется и не изменяет данные приложения.</p></main>`;
  }
  function notes() {
    const common = [['Роль названа явно','«Как помощник» отделяет этот опыт от запросов для своего питомца. Нет смешивания с рейтингами мест.'],['Понятные данные','Нет отзывов — это текст без нулевых звёзд. Недоступные данные получают отдельную ошибку и повторную загрузку.'],['Тихая иерархия','Факты сгруппированы в одной строке, а не в отдельных карточках. Один полезный основной шаг; отзывы и пояснение — спокойные вторичные действия.'],['Доступность','Цели нажатия не меньше 48 px. При 200% текста факты и идентичность перестраиваются; содержание не обрезается. Состояния озвучиваются текстом.']];
    const helperNotes = [['Чей профиль перед вами','Фото, имя, публичный район и короткое описание стоят перед опытом. Свой профиль отмечен явно и не предлагает написать или заблокировать себя.'],['Один следующий шаг',own() ? 'В своём профиле доступны ответы на отзывы и переход к запросам. Нет кнопки произвольно оценить другого человека.' : '«Обсудить прогулку» ведёт в приватный чат. Это обсуждение, не назначение и не подтверждение безопасности.'],['Отзывы без лишней навигации','Автор, оценка и дата всегда видны. Длинный текст раскрывается на месте; ответ помощника сгруппирован с исходным отзывом.'],['Безопасные вторичные действия','Жалоба и блокировка находятся в явном меню. Блокировка требует подтверждения. Ошибки сохраняют текст; повторные отправки блокируются.']];
    document.getElementById('note-title').textContent = ['public','own'].includes(state.screen) ? 'Личность → опыт → действие → отзывы' : state.screen === 'personal' ? 'Опыт, который легко понять' : 'Связанные действия';
    const items = ['public','own'].includes(state.screen) ? helperNotes : common;
    document.getElementById('notes').innerHTML = `<ol>${items.map(([title,text]) => `<li><strong>${title}</strong><p>${text}</p></li>`).join('')}</ol>`;
  }
  function render(focus = false) {
    phone.dataset.theme = state.theme; phone.dataset.platform = state.platform; phone.dataset.large = Number(state.scale) >= 1.5;
    for(const control of Object.values(controls)) control.disabled=state.busy;
    phone.style.setProperty('--scale',state.scale); phone.style.setProperty('--phone-width',state.width+'px');
    controls.screen.value = ['personal','own','public','walks'].includes(state.screen) ? state.screen : controls.screen.value;
    controls.scenario.value = state.scenario; controls.theme.value = state.theme;
    root.innerHTML = ({personal,own:helper,public:helper,walks,request,chat,report,block}[state.screen] || personal)();
    if(state.feedback && (state.screen === 'personal' || (state.screen === 'own' && !state.replyId))) root.querySelector('main').insertAdjacentHTML('afterbegin',`<div class="toast" role="status">${esc(state.feedback)}</div>`);
    notes(); lucide.createIcons({attrs:{'stroke-width':1.8}});
    if(focus) root.querySelector('.view-heading')?.focus({preventScroll:true});
  }
  controls.screen.addEventListener('change',e => {state.screen=e.target.value;state.back=[];state.feedback='';state.menu=false;render(true);});
  controls.scenario.addEventListener('change',e => {state.scenario=e.target.value;state.feedback='';state.menu=false;state.replyId=null;render();});
  for(const key of ['theme','width','scale','platform']) controls[key].addEventListener('change',e => {state[key]=e.target.value;render();});
  controls.failure.addEventListener('change',e => state.fail=e.target.checked);
  root.addEventListener('input',e => {
    if(e.target.dataset.draft) {state.drafts[e.target.dataset.draft]=e.target.value;document.getElementById('reply-count').textContent=e.target.value.length+' / 1000';}
    if(e.target.name === 'message') state.messageDraft=e.target.value;
    if(e.target.name === 'reason') state.reportDraft=e.target.value;
  });
  root.addEventListener('click',e => {
    const b=e.target.closest('button[data-action]'); if(!b || b.disabled || state.busy) return;
    const [action,id]=b.dataset.action.split(':');
    if(['personal','own','public','walks','chat','block'].includes(action)) {go(action);return;}
    if(action === 'request' || action === 'request-detail') {go('request');return;}
    if(action === 'back') {back();return;}
    if(action === 'theme') state.theme=state.theme === 'dark' ? 'light' : 'dark';
    if(action === 'walking-tab' || action === 'favorites') state.tab=action === 'favorites' ? 'favorites' : 'walking';
    if(action === 'menu') state.menu=!state.menu;
    if(action === 'review-menu') state.menu=state.menu === 'review:'+id ? false : 'review:'+id;
    if(action === 'expand') state.expanded[id]=!state.expanded[id];
    if(action === 'reply') {state.replyId=id;state.feedback='';}
    if(action === 'cancel-reply') {state.replyId=null;state.feedback='';}
    if(action === 'load') state.scenario='established';
    if(action === 'retry') {operation(() => state.scenario='established','Соединение пока недоступно. Попробуйте ещё раз.');return;}
    if(action === 'contact') {operation(() => go('chat'),'Не удалось открыть чат. Повторите попытку.');return;}
    if(action === 'apply') {operation(() => state.feedback='Отклик отправлен. Владелец ещё не выбрал помощника.','Отклик не отправлен. Попробуйте ещё раз.');return;}
    if(action === 'report-review' || action === 'report-profile') {state.reportForeign=foreign();state.reportTarget=action === 'report-review' ? 'review:'+id : 'profile';state.reportDraft='';go('report');return;}
    if(action === 'confirm-block') {operation(() => {state.blocked=true;state.screen='personal';state.back=[];state.feedback='Пользователь заблокирован · пример';},'Не удалось заблокировать пользователя. Попробуйте ещё раз.');return;}
    render();
  });
  root.addEventListener('keydown', e => {
    if(!e.target.matches('[role=tab]') || !['ArrowLeft','ArrowRight','Home','End'].includes(e.key)) return;
    e.preventDefault();
    state.tab = e.key === 'Home' ? 'favorites' : e.key === 'End' ? 'walking' : state.tab === 'walking' ? 'favorites' : 'walking';
    render(); document.getElementById(state.tab === 'walking' ? 'walking-tab' : 'favorites-tab').focus();
  });
  root.addEventListener('submit',e => {
    e.preventDefault();if(state.busy) return;
    const form=e.target, type=form.dataset.form;
    if(type === 'reply') {
      const id=form.dataset.id, value=(state.drafts[id] ?? state.submitted[id] ?? reviews.find(r => r.id === id).reply).trim();
      if(!value) {state.feedback='Напишите ответ.';render();return;}
      operation(() => {state.submitted[id]=value;state.replyId=null;state.feedback='Ответ опубликован · пример';},'Ответ не опубликован. Текст сохранён — можно повторить.');
    }
    if(type === 'message') {
      if(!state.messageDraft.trim()) {state.feedback='Напишите сообщение.';render();return;}
      operation(() => {state.messages.push(state.messageDraft.trim());state.messageDraft='';},'Сообщение не отправлено. Текст сохранён.');
    }
    if(type === 'report') {
      if(!state.reportDraft.trim()) {state.feedback='Опишите причину жалобы.';render();return;}
      operation(() => {back();state.feedback='Жалоба отправлена модераторам · пример';},'Жалоба не отправлена. Текст сохранён.');
    }
  });
  render();
})();
