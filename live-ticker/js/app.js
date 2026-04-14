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
  setupSwipeNavigation();
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
  renderLastUpdated(data.lastUpdated, isInfo);
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
  renderLastUpdated(data.lastUpdated, activeGroupId === '__info');
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

/* ── Swipe Navigation zwischen Tabs ─────────────── */
function setupSwipeNavigation() {
  const el = document.getElementById('match-list');
  let startX = 0;
  let startY = 0;
  let deltaX = 0;
  let deltaY = 0;
  let tracking = false;
  let horizontal = false;

  el.addEventListener('touchstart', (e) => {
    if (e.touches.length !== 1) {
      tracking = false;
      return;
    }
    startX = e.touches[0].clientX;
    startY = e.touches[0].clientY;
    deltaX = 0;
    deltaY = 0;
    tracking = true;
    horizontal = false;
  }, { passive: true });

  el.addEventListener('touchmove', (e) => {
    if (!tracking) return;
    deltaX = e.touches[0].clientX - startX;
    deltaY = e.touches[0].clientY - startY;
    if (!horizontal && Math.abs(deltaX) > 10 && Math.abs(deltaX) > Math.abs(deltaY) * 1.5) {
      horizontal = true;
    }
  }, { passive: true });

  el.addEventListener('touchend', () => {
    if (!tracking) return;
    tracking = false;
    if (!horizontal) return;
    const threshold = 60;
    if (Math.abs(deltaX) < threshold) return;
    navigateTab(deltaX < 0 ? 1 : -1);
  });

  el.addEventListener('touchcancel', () => {
    tracking = false;
  });
}

function navigateTab(direction) {
  if (!tournament) return;
  const allTabs = [INFO_TAB, ...tournament.ageGroups];
  if (allTabs.length <= 1) return;
  const idx = allTabs.findIndex((t) => t.id === activeGroupId);
  if (idx < 0) return;
  const nextIdx = idx + direction;
  if (nextIdx < 0 || nextIdx >= allTabs.length) return;
  switchGroup(allTabs[nextIdx].id);
}

document.addEventListener('DOMContentLoaded', init);
