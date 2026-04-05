const CACHE_NAME = 'lt-v1';

const APP_SHELL = [
  '/',
  '/index.html',
  '/css/styles.css',
  '/js/app.js',
  '/js/api.js',
  '/js/render.js',
  '/js/utils.js',
  '/manifest.json',
  '/assets/favicon.ico',
  '/assets/icon-192.png',
  '/assets/icon-512.png',
  '/assets/fonts/Inter-Regular.woff2',
  '/assets/fonts/Inter-SemiBold.woff2',
  '/assets/fonts/Inter-Bold.woff2',
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL))
  );
});

self.addEventListener('message', (e) => {
  if (e.data && e.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

function stripQuery(url) {
  const u = new URL(url);
  u.search = '';
  return u.href;
}

function isDataRequest(url) {
  return new URL(url).pathname.startsWith('/data/');
}

self.addEventListener('fetch', (e) => {
  const { request } = e;
  if (request.method !== 'GET') return;

  if (isDataRequest(request.url)) {
    // Network-first fuer Daten
    e.respondWith(
      fetchWithTimeout(request, 5000)
        .then((res) => {
          const clone = res.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(stripQuery(request.url), clone));
          return res;
        })
        .catch(() => caches.match(stripQuery(request.url)))
    );
  } else {
    // Cache-first fuer statische Assets
    e.respondWith(
      caches.match(request).then(
        (cached) =>
          cached ||
          fetch(request).then((res) => {
            if (res.ok && res.type === 'basic') {
              const clone = res.clone();
              caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
            }
            return res;
          })
      )
    );
  }
});

function fetchWithTimeout(request, ms) {
  return new Promise((resolve, reject) => {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), ms);
    fetch(request, { signal: controller.signal })
      .then((res) => {
        clearTimeout(timer);
        if (!res.ok) reject(new Error('not ok'));
        else resolve(res);
      })
      .catch((err) => {
        clearTimeout(timer);
        reject(err);
      });
  });
}
