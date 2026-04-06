import { formatTime, formatScore, getStatusClass, getStatusLabel, sortMatches, parseMarkdown, timeAgo, escapeHTML } from './utils.js';

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
  const mergedPauses = mergePauses(pauseTimes || []);
  const allItems = [...(matches || []), ...mergedPauses];

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

function mergePauses(pauseTimes) {
  const grouped = new Map();
  for (const p of pauseTimes) {
    const key = `${p.startTime}|${p.endTime}`;
    if (grouped.has(key)) {
      grouped.get(key).fields.push(p.field);
    } else {
      grouped.set(key, { ...p, fields: [p.field], _type: 'pause', status: 'pause' });
    }
  }
  return [...grouped.values()].map((p) => {
    p.fields.sort((a, b) => a - b);
    return p;
  });
}

function createPauseCard(pause) {
  const card = document.createElement('article');
  card.className = 'match-card match-card--pause';
  const desc = pause.description ? `<div class="match-card__status">${escapeHTML(pause.description)}</div>` : '';
  const fieldsHTML = (pause.fields || [pause.field])
    .map((f) => `<span class="match-card__field">Feld ${escapeHTML(String(f))}</span>`)
    .join('');
  card.innerHTML = `
    <div class="match-card__header">
      <span class="match-card__time">${formatTime(pause.startTime)} – ${formatTime(pause.endTime)}</span>
      <span class="match-card__fields">${fieldsHTML}</span>
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
      <span class="match-card__field">Feld ${escapeHTML(String(match.field))}</span>
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

let lastUpdatedISO = null;
let lastUpdatedTimer = null;
let hideStale = false;

export function renderLastUpdated(isoString, isInfo = false) {
  const el = document.getElementById('last-updated');
  lastUpdatedISO = isoString;
  hideStale = isInfo;
  if (lastUpdatedTimer) clearInterval(lastUpdatedTimer);
  if (!isoString) {
    el.textContent = '';
    return;
  }
  updateLastUpdatedText(el);
  lastUpdatedTimer = setInterval(() => updateLastUpdatedText(el), 60_000);
}

const STALE_THRESHOLD_MS = 3 * 60 * 1000;

function updateLastUpdatedText(el) {
  if (!lastUpdatedISO) return;
  const time = new Date(lastUpdatedISO).toLocaleTimeString('de-DE', {
    hour: '2-digit',
    minute: '2-digit',
  });
  const ago = timeAgo(lastUpdatedISO);
  el.textContent = `Aktualisiert: ${time} (${ago})`;

  const stale = !hideStale && Date.now() - new Date(lastUpdatedISO).getTime() > STALE_THRESHOLD_MS;
  document.getElementById('stale-banner').hidden = !stale;
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
    const ago = timeAgo(lastUpdated);
    timeSpan.textContent = `Stand: ${time} (${ago})`;
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

/* ── Team Filter ──────────────────────────────────── */

const filterOverlay = document.getElementById('filter-overlay');
const filterSheet = document.getElementById('filter-sheet');
const filterList = document.getElementById('filter-list');
const filterSearch = document.getElementById('filter-search');
const filterTagsBar = document.getElementById('filter-tags');
const filterBtn = document.getElementById('filter-btn');

let allTeams = [];
let pendingSelection = new Set();
let onFilterApply = null;

export function setFilterCallback(callback) {
  onFilterApply = callback;
}

export function showFilterButton(visible) {
  filterBtn.hidden = !visible;
  if (!visible) filterTagsBar.hidden = true;
}

export function extractTeams(matches) {
  const teamSet = new Set();
  for (const m of matches || []) {
    if (m.teamA) teamSet.add(m.teamA);
    if (m.teamB) teamSet.add(m.teamB);
  }
  allTeams = [...teamSet].sort((a, b) => a.localeCompare(b, 'de'));
  return allTeams;
}

export function openFilterSheet(selectedTeams) {
  pendingSelection = new Set(selectedTeams);
  filterSearch.value = '';
  renderFilterList('');
  filterOverlay.hidden = false;
  filterOverlay.setAttribute('aria-modal', 'true');
  document.addEventListener('keydown', handleSheetKeydown);
  requestAnimationFrame(() => {
    filterOverlay.classList.add('filter-overlay--visible');
    filterSearch.focus();
  });
}

export function closeFilterSheet() {
  document.removeEventListener('keydown', handleSheetKeydown);
  filterOverlay.classList.remove('filter-overlay--visible');
  filterOverlay.removeAttribute('aria-modal');
  setTimeout(() => {
    filterOverlay.hidden = true;
    filterBtn.focus();
  }, 250);
}

function handleSheetKeydown(e) {
  if (e.key === 'Escape') {
    closeFilterSheet();
    return;
  }
  if (e.key === 'Tab') {
    trapFocus(e);
  }
}

function trapFocus(e) {
  const focusable = filterSheet.querySelectorAll(
    'button, input, [href], [tabindex]:not([tabindex="-1"])'
  );
  if (focusable.length === 0) return;
  const first = focusable[0];
  const last = focusable[focusable.length - 1];
  if (e.shiftKey && document.activeElement === first) {
    e.preventDefault();
    last.focus();
  } else if (!e.shiftKey && document.activeElement === last) {
    e.preventDefault();
    first.focus();
  }
}

function renderFilterList(query) {
  const q = query.toLowerCase();
  const filtered = q ? allTeams.filter((t) => t.toLowerCase().includes(q)) : allTeams;
  filterList.innerHTML = '';
  for (const team of filtered) {
    const label = document.createElement('label');
    label.className = 'filter-team';
    const cb = document.createElement('input');
    cb.type = 'checkbox';
    cb.className = 'filter-team__cb';
    cb.checked = pendingSelection.has(team);
    cb.addEventListener('change', () => {
      if (cb.checked) {
        pendingSelection.add(team);
      } else {
        pendingSelection.delete(team);
      }
    });
    const span = document.createElement('span');
    span.className = 'filter-team__name';
    span.textContent = team;
    label.appendChild(cb);
    label.appendChild(span);
    filterList.appendChild(label);
  }
}

export function renderFilterTags(selectedTeams, onRemove) {
  filterTagsBar.innerHTML = '';
  if (selectedTeams.size === 0) {
    filterTagsBar.hidden = true;
    filterBtn.classList.remove('filter-fab--active');
    updateFilterBadge(0);
    return;
  }
  filterBtn.classList.add('filter-fab--active');
  updateFilterBadge(selectedTeams.size);
  filterTagsBar.hidden = false;
  for (const team of selectedTeams) {
    const tag = document.createElement('span');
    tag.className = 'filter-tag';
    tag.innerHTML = `${escapeHTML(team)} <button class="filter-tag__remove" aria-label="Entfernen">&times;</button>`;
    tag.querySelector('button').addEventListener('click', () => onRemove(team));
    filterTagsBar.appendChild(tag);
  }
}

export function filterMatches(matches, selectedTeams) {
  if (!selectedTeams || selectedTeams.size === 0) return matches;
  return (matches || []).filter(
    (m) => selectedTeams.has(m.teamA) || selectedTeams.has(m.teamB)
  );
}

// Wire up sheet UI events
filterSearch.addEventListener('input', () => renderFilterList(filterSearch.value));

document.getElementById('filter-close').addEventListener('click', closeFilterSheet);

filterOverlay.addEventListener('click', (e) => {
  if (e.target === filterOverlay) closeFilterSheet();
});

document.getElementById('filter-clear').addEventListener('click', () => {
  pendingSelection.clear();
  renderFilterList(filterSearch.value);
});

document.getElementById('filter-apply').addEventListener('click', () => {
  closeFilterSheet();
  if (onFilterApply) onFilterApply(new Set(pendingSelection));
});

function updateFilterBadge(count) {
  let badge = filterBtn.querySelector('.filter-fab__badge');
  if (count > 0) {
    if (!badge) {
      badge = document.createElement('span');
      badge.className = 'filter-fab__badge';
      filterBtn.appendChild(badge);
    }
    badge.textContent = count;
  } else if (badge) {
    badge.remove();
  }
}

