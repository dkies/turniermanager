const TIMEOUT_MS = 5000;
const LS_PREFIX = 'lt_data_';

let cache = new Map();

// Hydrate from localStorage on startup
try {
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    if (key.startsWith(LS_PREFIX)) {
      cache.set(key.slice(LS_PREFIX.length), JSON.parse(localStorage.getItem(key)));
    }
  }
} catch { /* private browsing or quota */ }

async function fetchWithTimeout(url, timeoutMs = TIMEOUT_MS) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, { signal: controller.signal });
    clearTimeout(timer);
    if (!res.ok) return null;
    return res;
  } catch {
    clearTimeout(timer);
    return null;
  }
}

async function fetchJSON(url) {
  const bustUrl = `${url}?t=${Date.now()}`;
  const res = await fetchWithTimeout(bustUrl);
  if (!res) return cache.get(url) ?? null;
  try {
    const data = await res.json();
    cache.set(url, data);
    try { localStorage.setItem(LS_PREFIX + url, JSON.stringify(data)); } catch { /* quota */ }
    return data;
  } catch {
    return cache.get(url) ?? null;
  }
}

export async function fetchTournament() {
  return fetchJSON('data/tournament.json');
}

export async function fetchAgeGroup(filePath) {
  return fetchJSON(filePath);
}

export function isCached(url) {
  return cache.has(url);
}
