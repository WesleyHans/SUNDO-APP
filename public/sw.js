// Remove the retired SUNDO simulator worker after the installer page deploys.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil((async () => {
  const names = await caches.keys();
  await Promise.all(names.filter(name => name.startsWith('workbox-') || ['google-fonts-cache','gstatic-fonts-cache','carto-map-tiles-cache'].includes(name)).map(name => caches.delete(name)));
  await self.registration.unregister();
  await self.clients.claim();
})()));
