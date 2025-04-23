// Événement d'installation du Service Worker
self.addEventListener('install', (event) => {
    self.skipWaiting(); // Activation immédiate du nouveau SW

    event.waitUntil(
        caches.open('calculatrice-cache').then((cache) => {
            return cache.addAll([
                '/',
                '/index.html',
                '/style.css',
                '/app.js',
                '/images/space.jpeg',
                '/images/icon-192x192.png',
                '/images/icon-512x512.png',
                '/offline.html' // Fallback en cas de coupure réseau
            ]);
        })
    );
});

// Événement de récupération
self.addEventListener('fetch', (event) => {
    event.respondWith(
        caches.match(event.request).then((response) => {
            // Si on a la réponse en cache
            if (response) {
                return response;
            }

            // Sinon, tentative réseau + mise en cache conditionnelle
            return fetch(event.request).then((networkResponse) => {
                if (
                    event.request.url.includes('/index.html') ||
                    event.request.url.includes('.css') ||
                    event.request.url.includes('.js')
                ) {
                    caches.open('calculatrice-cache').then((cache) => {
                        cache.put(event.request, networkResponse.clone());
                    });
                }
                return networkResponse;
            }).catch(() => {
                // Si la requête échoue, on renvoie le fallback
                return caches.match('/offline.html');
            });
        })
    );
});

// Événement d'activation du Service Worker
self.addEventListener('activate', (event) => {
    const cacheWhitelist = ['calculatrice-cache'];

    event.waitUntil(
        caches.keys().then((cacheNames) => {
            return Promise.all(
                cacheNames.map((cacheName) => {
                    if (!cacheWhitelist.includes(cacheName)) {
                        return caches.delete(cacheName);
                    }
                })
            );
        })
    );

    self.clients.claim(); // Contrôle immédiat de la page par le nouveau SW
});