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
  showFilterButton,
  extractTeams,
  openFilterSheet,
  closeFilterSheet,
  renderFilterTags,
  filterMatches,
  setFilterCallback,
} from './render.js';

const INFO_TAB = { id: '__info', label: '\u2139\uFE0F Infos', file: 'data/infos.json' };

const REFRESH_INTERVAL = 30_000;

let tournament = null;
let activeGroupId = null;
let activeGroupFile = null;
let lastUpdatedStamp = null;
let refreshTimer = null;
let selectedTeams = new Set();
let currentMatches = null;

async function init() {
  tournament = await fetchTournament();
  if (!tournament) {
    showOffline(null);
    retryInit();
    return;
  }

  renderTournamentName(tournament.tournamentName);

  // Filter setup
  document.getElementById('filter-btn').addEventListener('click', () => {
    openFilterSheet(selectedTeams);
  });
  setFilterCallback(applyFilter);

  // Restore filter state
  const savedTeams = localStorage.getItem('lt_selectedTeams');
  if (savedTeams) try { selectedTeams = new Set(JSON.parse(savedTeams)); } catch {}

  const allTabs = [INFO_TAB, ...tournament.ageGroups];
  if (allTabs.length > 0) {
    const saved = localStorage.getItem('tw_activeTab');
    activeGroupId = allTabs.find((t) => t.id === saved) ? saved : allTabs[0].id;
    renderTabs(allTabs, activeGroupId, switchGroup);
    await loadGroup(activeGroupId);
  }

  startAutoRefresh();
  setupVisibility();
  setupPullToRefresh();
  setupIOSBanner();
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
  currentMatches = null;
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

  const isInfo = groupId === '__info';
  showFilterButton(!isInfo);
  if (!isInfo) renderFilterTags(selectedTeams, removeTeamFilter);

  if (data.lastUpdated === lastUpdatedStamp) return;
  lastUpdatedStamp = data.lastUpdated;

  if (isInfo) {
    renderInfoCards(data.infos);
  } else {
    currentMatches = data.matches;
    extractTeams(data.matches);
    renderMatches(filterMatches(data.matches, selectedTeams), data.pauseTimes);
  }
  renderLastUpdated(data.lastUpdated);
}

function applyFilter(teams) {
  selectedTeams = teams;
  try { localStorage.setItem('lt_selectedTeams', JSON.stringify([...selectedTeams])); } catch {}
  renderFilterTags(selectedTeams, removeTeamFilter);
  if (currentMatches) {
    renderMatches(filterMatches(currentMatches, selectedTeams));
  }
}

function removeTeamFilter(team) {
  selectedTeams.delete(team);
  applyFilter(selectedTeams);
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
    currentMatches = data.matches;
    extractTeams(data.matches);
    renderMatches(filterMatches(data.matches, selectedTeams), data.pauseTimes);
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

/* ── iOS Install Banner ─────────────────────────────── */
function setupIOSBanner() {
  const isIOS = /iphone|ipad|ipod/i.test(navigator.userAgent) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  const isStandalone = window.navigator.standalone === true;
  if (!isIOS || isStandalone || localStorage.getItem('lt_iosBannerDismissed')) return;

  const banner = document.getElementById('ios-install-banner');
  banner.hidden = false;
  banner.querySelector('.ios-banner__close').addEventListener('click', () => {
    banner.hidden = true;
    localStorage.setItem('lt_iosBannerDismissed', '1');
  });
}

/* ── Pull-to-Refresh ────────────────────────────────── */
function setupPullToRefresh() {
  const indicator = document.getElementById('pull-indicator');
  let startY = 0;
  let currentY = 0;
  let pulling = false;

  document.addEventListener('touchstart', (e) => {
    if (window.scrollY === 0) {
      startY = e.touches[0].clientY;
      pulling = true;
    }
  }, { passive: true });

  document.addEventListener('touchmove', (e) => {
    if (!pulling) return;
    currentY = e.touches[0].clientY;
    const dy = currentY - startY;
    if (dy > 0 && dy < 150 && window.scrollY === 0) {
      const progress = Math.min(dy / 80, 1);
      indicator.style.transform = `translateY(${Math.min(dy * 0.5, 40) - 60}px)`;
      indicator.style.opacity = progress;
      if (dy > 10) e.preventDefault();
    } else {
      pulling = false;
      indicator.style.transform = '';
      indicator.style.opacity = '';
    }
  }, { passive: false });

  document.addEventListener('touchend', () => {
    if (!pulling) return;
    const dy = currentY - startY;
    pulling = false;
    if (dy >= 80) {
      indicator.classList.add('pull-indicator--refreshing');
      refreshCurrent().finally(() => {
        indicator.classList.remove('pull-indicator--refreshing');
        indicator.style.transform = '';
        indicator.style.opacity = '';
      });
    } else {
      indicator.style.transform = '';
      indicator.style.opacity = '';
    }
  });
}

/* ── Service Worker Registration ─────────────────── */
if ('serviceWorker' in navigator) {
  let swRefreshing = false;

  navigator.serviceWorker.register('/sw.js').then((reg) => {
    // Wenn ein neuer SW wartet (z.B. ohne skipWaiting), Banner zeigen
    if (reg.waiting) showUpdateBanner(reg.waiting);

    // Neuer SW wurde installiert und wartet
    reg.addEventListener('updatefound', () => {
      const newSW = reg.installing;
      if (!newSW) return;
      newSW.addEventListener('statechange', () => {
        if (newSW.state === 'installed' && navigator.serviceWorker.controller) {
          showUpdateBanner(newSW);
        }
      });
    });

    // Regelmaessig nach Updates suchen (alle 5 Minuten)
    setInterval(() => reg.update().catch(() => {}), 5 * 60 * 1000);
  }).catch(() => {});

  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (!swRefreshing) {
      swRefreshing = true;
      location.reload();
    }
  });
}

function showUpdateBanner(waitingSW) {
  const banner = document.getElementById('update-banner');
  if (!banner || !banner.hidden) return;
  banner.hidden = false;
  banner.querySelector('.update-banner__btn').addEventListener('click', () => {
    waitingSW.postMessage({ type: 'SKIP_WAITING' });
    banner.hidden = true;
  }, { once: true });
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
