const TIMEOUT_MS = 5000;

let cache = new Map();

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
