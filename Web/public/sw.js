// Web Service Worker for Offline Support
const CACHE_NAME = 'url-bookmarks-v1';
const STATIC_CACHE_NAME = 'url-bookmarks-static-v1';

const STATIC_ASSETS = [
  '/',
  '/static/js/bundle.js',
  '/static/css/main.css',
  '/manifest.json',
  '/favicon.ico'
];

const API_CACHE_NAME = 'url-bookmarks-api-v1';

// Install event - cache static assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    Promise.all([
      caches.open(STATIC_CACHE_NAME).then((cache) => {
        return cache.addAll(STATIC_ASSETS);
      }),
      caches.open(API_CACHE_NAME)
    ])
  );
  self.skipWaiting();
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== STATIC_CACHE_NAME && 
              cacheName !== API_CACHE_NAME && 
              cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
  self.clients.claim();
});

// Fetch event - serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Handle static assets
  if (STATIC_ASSETS.some(asset => url.pathname.endsWith(asset))) {
    event.respondWith(
      caches.match(request).then((response) => {
        return response || fetch(request);
      })
    );
    return;
  }

  // Handle API requests
  if (url.pathname.includes('/api/') || url.hostname.includes('icloud.com')) {
    event.respondWith(
      handleAPIRequest(request)
    );
    return;
  }

  // Handle navigation requests
  if (request.mode === 'navigate') {
    event.respondWith(
      caches.match('/').then((response) => {
        return response || fetch(request);
      })
    );
    return;
  }

  // Default: try network first, fallback to cache
  event.respondWith(
    fetch(request).catch(() => {
      return caches.match(request);
    })
  );
});

async function handleAPIRequest(request) {
  const cache = await caches.open(API_CACHE_NAME);
  
  try {
    // Try network first
    const networkResponse = await fetch(request);
    
    // Cache successful responses
    if (networkResponse.ok) {
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
  } catch (error) {
    // Network failed, try cache
    const cachedResponse = await cache.match(request);
    
    if (cachedResponse) {
      return cachedResponse;
    }
    
    // Return offline response
    return new Response(
      JSON.stringify({ 
        error: 'Offline', 
        message: 'This request requires an internet connection' 
      }),
      {
        status: 503,
        statusText: 'Service Unavailable',
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }
}

// Background sync for offline operations
self.addEventListener('sync', (event) => {
  if (event.tag === 'background-sync') {
    event.waitUntil(syncOfflineOperations());
  }
});

async function syncOfflineOperations() {
  try {
    // Get offline operations from IndexedDB
    const operations = await getOfflineOperations();
    
    for (const operation of operations) {
      try {
        await processOfflineOperation(operation);
        await removeOfflineOperation(operation.id);
      } catch (error) {
        console.error('Failed to sync operation:', operation, error);
      }
    }
  } catch (error) {
    console.error('Background sync failed:', error);
  }
}

async function processOfflineOperation(operation) {
  const { type, data } = operation;
  
  switch (type) {
    case 'ADD_BOOKMARK':
      return await fetch('/api/bookmarks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });
      
    case 'UPDATE_BOOKMARK':
      return await fetch(`/api/bookmarks/${data.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });
      
    case 'DELETE_BOOKMARK':
      return await fetch(`/api/bookmarks/${data.id}`, {
        method: 'DELETE'
      });
      
    default:
      throw new Error(`Unknown operation type: ${type}`);
  }
}

// IndexedDB operations for offline queue
async function getOfflineOperations() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('URLBookmarksOffline', 1);
    
    request.onerror = () => reject(request.error);
    
    request.onsuccess = () => {
      const db = request.result;
      const transaction = db.transaction(['operations'], 'readonly');
      const store = transaction.objectStore('operations');
      const getAllRequest = store.getAll();
      
      getAllRequest.onsuccess = () => resolve(getAllRequest.result);
      getAllRequest.onerror = () => reject(getAllRequest.error);
    };
    
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains('operations')) {
        db.createObjectStore('operations', { keyPath: 'id' });
      }
    };
  });
}

async function removeOfflineOperation(id) {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('URLBookmarksOffline', 1);
    
    request.onsuccess = () => {
      const db = request.result;
      const transaction = db.transaction(['operations'], 'readwrite');
      const store = transaction.objectStore('operations');
      const deleteRequest = store.delete(id);
      
      deleteRequest.onsuccess = () => resolve();
      deleteRequest.onerror = () => reject(deleteRequest.error);
    };
  });
}
