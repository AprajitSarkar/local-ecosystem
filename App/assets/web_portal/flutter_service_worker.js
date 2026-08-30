'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "d485108c55bc4686dfa78a342e66aaf8",
"assets/AssetManifest.bin.json": "1f012ff20f567b7fdad19187d3bac889",
"assets/AssetManifest.json": "2e8a7321bd21f729f7af0f4a1d896b17",
"assets/assets/icons/app_icon.png": "e8c803cc6ccffffe39f513118515f453",
"assets/assets/web_portal/assets/AssetManifest.bin": "a6e47f2c0aea40794e7804b246adc513",
"assets/assets/web_portal/assets/AssetManifest.bin.json": "3c0a1ff183669fbcd10ce40fd3269a28",
"assets/assets/web_portal/assets/AssetManifest.json": "fccc3a4d09d9be8b85a96e0522696223",
"assets/assets/web_portal/assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/assets/web_portal/assets/fonts/MaterialIcons-Regular.otf": "a75d6325d69854963e5db4dd2188bfb2",
"assets/assets/web_portal/assets/NOTICES": "23a264682ad311aba39561b7761e9758",
"assets/assets/web_portal/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/assets/web_portal/assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/assets/web_portal/assets/shaders/stretch_effect.frag": "f0ab847ccb98001d214e09f120664284",
"assets/assets/web_portal/canvaskit/canvaskit.js": "6cfe36b4647fbfa15683e09e7dd366bc",
"assets/assets/web_portal/canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"assets/assets/web_portal/canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"assets/assets/web_portal/canvaskit/chromium/canvaskit.js": "ba4a8ae1a65ff3ad81c6818fd47e348b",
"assets/assets/web_portal/canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"assets/assets/web_portal/canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"assets/assets/web_portal/canvaskit/experimental_webparagraph/canvaskit.js": "230c0e2b182dcd1061c06c2fe7b64b5f",
"assets/assets/web_portal/canvaskit/experimental_webparagraph/canvaskit.js.symbols": "0c6d97b036dffdc0f4bc4552ae7b5c9d",
"assets/assets/web_portal/canvaskit/experimental_webparagraph/canvaskit.wasm": "e008e87c245b0718932b34e9a15be803",
"assets/assets/web_portal/canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"assets/assets/web_portal/canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"assets/assets/web_portal/canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"assets/assets/web_portal/canvaskit/skwasm_heavy.js": "19b2126c270db6dde2255bec30c3e4f9",
"assets/assets/web_portal/canvaskit/skwasm_heavy.js.symbols": "455930e12e6ef2d961627fe6f0c0cd0c",
"assets/assets/web_portal/canvaskit/skwasm_heavy.wasm": "f22698a773ef756eff818039e37be5c3",
"assets/assets/web_portal/canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"assets/assets/web_portal/canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"assets/assets/web_portal/canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"assets/assets/web_portal/canvaskit/wimp.js": "40195751139ab9e4b7c62b19c420f63b",
"assets/assets/web_portal/canvaskit/wimp.js.symbols": "e9ac11318ebff9b7ad24ca7841f69b3f",
"assets/assets/web_portal/canvaskit/wimp.wasm": "9242e201530449825b5645ed3d5af22c",
"assets/assets/web_portal/favicon.png": "e8c803cc6ccffffe39f513118515f453",
"assets/assets/web_portal/flutter.js": "76f08d47ff9f5715220992f993002504",
"assets/assets/web_portal/flutter_bootstrap.js": "f997d9120e78540a6d407a8e2e422761",
"assets/assets/web_portal/icons/Icon-192.png": "e8c803cc6ccffffe39f513118515f453",
"assets/assets/web_portal/icons/Icon-512.png": "e8c803cc6ccffffe39f513118515f453",
"assets/assets/web_portal/icons/Icon-maskable-192.png": "e8c803cc6ccffffe39f513118515f453",
"assets/assets/web_portal/icons/Icon-maskable-512.png": "e8c803cc6ccffffe39f513118515f453",
"assets/assets/web_portal/index.html": "14ec20e5e5577768fef7c89130b1b0ce",
"assets/assets/web_portal/main.dart.js": "48e5dd3992cd814ffac1fc900bcf7643",
"assets/assets/web_portal/manifest.json": "e862089f3480a1d2ea35771096f33222",
"assets/assets/web_portal/sql-wasm.js": "ece4da02bfb3e2ffeb3655fdbbfc1a36",
"assets/assets/web_portal/sql-wasm.wasm": "f6ad6454f4630b310eb8473858eb33bb",
"assets/assets/web_portal/sqlite3.wasm": "fa7637a49a0e434f2a98f9981856d118",
"assets/assets/web_portal/version.json": "623e1ff6a2918445f7fff29aecbaa10a",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "3781aef3186dd5b666287e66edd4f7b1",
"assets/NOTICES": "8a693b4e00c3d6a2789bf2f5cadf53c7",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "6cfe36b4647fbfa15683e09e7dd366bc",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/chromium/canvaskit.js": "ba4a8ae1a65ff3ad81c6818fd47e348b",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"favicon.png": "e8c803cc6ccffffe39f513118515f453",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"flutter_bootstrap.js": "ec98d6d47f3f181f4b33ae462732eda6",
"icons/Icon-192.png": "e8c803cc6ccffffe39f513118515f453",
"icons/Icon-512.png": "e8c803cc6ccffffe39f513118515f453",
"icons/Icon-maskable-192.png": "e8c803cc6ccffffe39f513118515f453",
"icons/Icon-maskable-512.png": "e8c803cc6ccffffe39f513118515f453",
"index.html": "14ec20e5e5577768fef7c89130b1b0ce",
"/": "14ec20e5e5577768fef7c89130b1b0ce",
"main.dart.js": "fc827e15b7464b4bf8436c8ff58d447e",
"manifest.json": "e862089f3480a1d2ea35771096f33222",
"sql-wasm.js": "ece4da02bfb3e2ffeb3655fdbbfc1a36",
"sql-wasm.wasm": "f6ad6454f4630b310eb8473858eb33bb",
"sqlite3.wasm": "fa7637a49a0e434f2a98f9981856d118",
"version.json": "623e1ff6a2918445f7fff29aecbaa10a"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
