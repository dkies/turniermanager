import { fetchTournament, fetchAgeGroup } from './api.js';
import {
  renderTabs,
  renderMatches,
  renderInfoCards,
  renderLastUpdated,
  renderTournamentName,
  showOffline,
  hideOffline,
  showLoading,
} from './render.js';

const INFO_TAB = { id: '__info', label: '\u2139\uFE0F Infos', file: 'data/infos.json' };

const REFRESH_INTERVAL = 30_000;

let tournament = null;
let activeGroupId = null;
let activeGroupFile = null;
let lastUpdatedStamp = null;
let refreshTimer = null;

async function init() {
  tournament = await fetchTournament();
  if (!tournament) {
    showOffline(null);
    retryInit();
    return;
  }

  renderTournamentName(tournament.tournamentName);

  const allTabs = [INFO_TAB, ...tournament.ageGroups];
  if (allTabs.length > 0) {
    const saved = localStorage.getItem('tw_activeTab');
    activeGroupId = allTabs.find((t) => t.id === saved) ? saved : allTabs[0].id;
    renderTabs(allTabs, activeGroupId, switchGroup);
    await loadGroup(activeGroupId);
  }

  startAutoRefresh();
  setupVisibility();
}

async function retryInit() {
  setTimeout(async () => {
    await init();
  }, REFRESH_INTERVAL);
}

async function switchGroup(groupId) {
  if (groupId === activeGroupId) return;
  activeGroupId = groupId;
  lastUpdatedStamp = null;
  const allTabs = [INFO_TAB, ...tournament.ageGroups];
  renderTabs(allTabs, activeGroupId, switchGroup);
  localStorage.setItem('tw_activeTab', groupId);
  showLoading();
  await loadGroup(groupId);
}

async function loadGroup(groupId) {
  const allTabs = [INFO_TAB, ...tournament.ageGroups];
  const group = allTabs.find((g) => g.id === groupId);
  if (!group) return;

  activeGroupFile = group.file;
  const data = await fetchAgeGroup(activeGroupFile);

  if (!data) {
    showOffline(lastUpdatedStamp);
    return;
  }

  hideOffline();

  if (data.lastUpdated === lastUpdatedStamp) return;
  lastUpdatedStamp = data.lastUpdated;

  if (groupId === '__info') {
    renderInfoCards(data.infos);
  } else {
    renderMatches(data.matches, data.pauseTimes);
  }
  renderLastUpdated(data.lastUpdated);
}

function startAutoRefresh() {
  stopAutoRefresh();
  refreshTimer = setInterval(() => refreshCurrent(), REFRESH_INTERVAL);
}

function stopAutoRefresh() {
  if (refreshTimer) {
    clearInterval(refreshTimer);
    refreshTimer = null;
  }
}

async function refreshCurrent() {
  if (!activeGroupFile) return;
  const data = await fetchAgeGroup(activeGroupFile);
  if (!data) {
    showOffline(lastUpdatedStamp);
    return;
  }
  hideOffline();
  if (data.lastUpdated === lastUpdatedStamp) return;
  lastUpdatedStamp = data.lastUpdated;
  if (activeGroupId === '__info') {
    renderInfoCards(data.infos);
  } else {
    renderMatches(data.matches, data.pauseTimes);
  }
  renderLastUpdated(data.lastUpdated);
}

function setupVisibility() {
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
      stopAutoRefresh();
    } else {
      refreshCurrent();
      startAutoRefresh();
    }
  });
}

/* ── Service Worker Registration ─────────────────── */
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js').catch(() => {});
}

/* ── PWA Install Prompt ──────────────────────────── */
let deferredPrompt = null;
const installBtn = document.getElementById('install-btn');

window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();
  deferredPrompt = e;
  installBtn.hidden = false;
});

installBtn.addEventListener('click', async () => {
  if (!deferredPrompt) return;
  deferredPrompt.prompt();
  const { outcome } = await deferredPrompt.userChoice;
  if (outcome === 'accepted') {
    installBtn.hidden = true;
  }
  deferredPrompt = null;
});

window.addEventListener('appinstalled', () => {
  installBtn.hidden = true;
  deferredPrompt = null;
});

document.addEventListener('DOMContentLoaded', init);
