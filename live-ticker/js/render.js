import { formatTime, formatScore, getStatusClass, getStatusLabel, sortMatches, parseMarkdown } from './utils.js';

const tabsWrapper = document.getElementById('tabs-wrapper');
const tabsContainer = document.getElementById('age-group-tabs');
const matchList = document.getElementById('match-list');
const loadingEl = document.getElementById('loading');

function updateScrollHints() {
  const el = tabsContainer;
  const canLeft = el.scrollLeft > 2;
  const canRight = el.scrollLeft + el.clientWidth < el.scrollWidth - 2;
  tabsWrapper.classList.toggle('can-scroll-left', canLeft);
  tabsWrapper.classList.toggle('can-scroll-right', canRight);
}

tabsContainer.addEventListener('scroll', updateScrollHints, { passive: true });

export function renderTabs(ageGroups, activeId, onSwitch) {
  tabsContainer.innerHTML = '';
  ageGroups.forEach((group) => {
    const btn = document.createElement('button');
    btn.className = 'tab';
    btn.role = 'tab';
    btn.textContent = group.label;
    btn.setAttribute('aria-selected', group.id === activeId ? 'true' : 'false');
    btn.addEventListener('click', () => onSwitch(group.id));
    tabsContainer.appendChild(btn);
  });

  // Aktiven Tab ins Sichtfeld scrollen
  const activeBtn = tabsContainer.querySelector('[aria-selected="true"]');
  if (activeBtn) {
    activeBtn.scrollIntoView({ inline: 'center', block: 'nearest', behavior: 'smooth' });
  }
  requestAnimationFrame(updateScrollHints);
}

export function renderMatches(matches, pauseTimes) {
  hideLoading();
  const pauses = (pauseTimes || []).map((p) => ({ ...p, _type: 'pause', status: 'pause' }));
  const allItems = [...(matches || []), ...pauses];

  if (allItems.length === 0) {
    matchList.innerHTML = '';
    const empty = document.createElement('div');
    empty.className = 'empty-state';
    empty.innerHTML = `
      <div class="empty-state__icon">&#9917;</div>
      <p class="empty-state__text">Keine Spiele in dieser Gruppe</p>
    `;
    matchList.appendChild(empty);
    return;
  }

  const sorted = sortMatches(allItems);
  matchList.innerHTML = '';

  let currentSection = null;
  sorted.forEach((item) => {
    const section = item.status;
    if (section !== currentSection && item._type !== 'pause') {
      currentSection = section;
      const label = document.createElement('div');
      label.className = 'section-label';
      label.textContent = getStatusLabel(section);
      matchList.appendChild(label);
    }
    if (item._type === 'pause') {
      matchList.appendChild(createPauseCard(item));
    } else {
      matchList.appendChild(createMatchCard(item));
    }
  });
}

function createPauseCard(pause) {
  const card = document.createElement('article');
  card.className = 'match-card match-card--pause';
  const desc = pause.description ? `<div class="match-card__status">${escapeHTML(pause.description)}</div>` : '';
  card.innerHTML = `
    <div class="match-card__header">
      <span class="match-card__time">${formatTime(pause.startTime)} – ${formatTime(pause.endTime)}</span>
      <span class="match-card__field">Feld ${pause.field}</span>
    </div>
    ${desc}
  `;
  return card;
}

function createMatchCard(match) {
  const card = document.createElement('article');
  card.className = `match-card ${getStatusClass(match.status)}`;

  const showScore = match.status === 'live' || match.status === 'completed';
  const scoreHTML = showScore
    ? `<div class="match-card__score">${formatScore(match.scoreA, match.scoreB)}</div>`
    : `<div class="match-card__vs">vs</div>`;

  const statusDot = match.status === 'live' ? '<span class="pulse-dot"></span>' : '';

  card.innerHTML = `
    <div class="match-card__header">
      <span class="match-card__time">${formatTime(match.startTime)}</span>
      <span class="match-card__field">Feld ${match.field}</span>
    </div>
    <div class="match-card__teams">
      <span class="match-card__team match-card__team--a">${escapeHTML(match.teamA)}</span>
      ${scoreHTML}
      <span class="match-card__team match-card__team--b">${escapeHTML(match.teamB)}</span>
    </div>
    <div class="match-card__status">
      ${statusDot}
      ${getStatusLabel(match.status)}
    </div>
  `;
  return card;
}

export function renderLastUpdated(isoString) {
  const el = document.getElementById('last-updated');
  if (!isoString) {
    el.textContent = '';
    return;
  }
  const time = new Date(isoString).toLocaleTimeString('de-DE', {
    hour: '2-digit',
    minute: '2-digit',
  });
  el.textContent = `Aktualisiert: ${time}`;
}

export function renderTournamentName(name) {
  document.getElementById('tournament-name').textContent = name || 'LiveTicker';
}

export function showOffline(lastUpdated) {
  const bar = document.getElementById('offline-bar');
  const timeSpan = document.getElementById('offline-time');
  if (lastUpdated) {
    const time = new Date(lastUpdated).toLocaleTimeString('de-DE', {
      hour: '2-digit',
      minute: '2-digit',
    });
    timeSpan.textContent = `Stand: ${time}`;
  } else {
    timeSpan.textContent = 'keine Daten';
  }
  bar.hidden = false;
}

export function hideOffline() {
  document.getElementById('offline-bar').hidden = true;
}

export function showLoading() {
  loadingEl.style.display = '';
}

export function hideLoading() {
  loadingEl.style.display = 'none';
}

export function renderInfoCards(infos) {
  hideLoading();
  matchList.innerHTML = '';

  if (!infos || infos.length === 0) {
    const empty = document.createElement('div');
    empty.className = 'empty-state';
    empty.innerHTML = `
      <div class="empty-state__icon">&#8505;</div>
      <p class="empty-state__text">Keine Informationen vorhanden</p>
    `;
    matchList.appendChild(empty);
    return;
  }

  infos.forEach((info) => {
    const card = document.createElement('article');
    card.className = 'info-card';
    card.innerHTML = `
      <div class="info-card__header">${escapeHTML(info.title)}</div>
      <div class="info-card__content">${parseMarkdown(info.content)}</div>
    `;
    matchList.appendChild(card);
  });
}

function escapeHTML(str) {
  const div = document.createElement('span');
  div.textContent = str;
  return div.innerHTML;
}
