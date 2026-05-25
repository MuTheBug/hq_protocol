/**
 * Service Worker لجمعية حقّنا
 * يخزّن الصفحات والأصول للعمل offline
 * يدعم Background Sync لرفع البيانات عند عودة الاتصال
 */

const CACHE_NAME = "haqquna-v1";
const STATIC_CACHE = "haqquna-static-v1";

// الأصول الأساسية التي تُحمَّل دائماً
const ESSENTIAL_ASSETS = [
  "/static/manifest.json",
  "/static/img/logo.jpg",
  "/static/css/tour.css",
  "/static/js/tour.js",
  "/static/js/offline.js",
  "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.rtl.min.css",
  "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css",
  "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js",
  "https://fonts.googleapis.com/css2?family=Cairo:wght@300;400;600;700;900&display=swap",
];

// تثبيت SW - تحميل الأصول الأساسية
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then((cache) => {
      return cache.addAll(ESSENTIAL_ASSETS).catch((err) => {
        console.warn("[SW] فشل تحميل بعض الأصول الخارجية:", err);
      });
    })
  );
  self.skipWaiting();
});

// تفعيل SW - حذف الذاكرات القديمة
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((names) => {
      return Promise.all(
        names
          .filter((name) => name !== CACHE_NAME && name !== STATIC_CACHE)
          .map((name) => caches.delete(name))
      );
    })
  );
  self.clients.claim();
});

// استراتيجية: Network-first للطلبات الديناميكية، Cache-first للأصول
self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url);

  // نتجاهل طلبات POST (تذهب مباشرة للشبكة، عند الفشل تُحفظ محلياً عبر offline.js)
  if (event.request.method !== "GET") {
    return;
  }

  // نتجاهل طلبات admin
  if (url.pathname.startsWith("/admin/")) {
    return;
  }

  // الأصول الثابتة: Cache-first
  if (url.pathname.startsWith("/static/") || url.hostname.includes("cdn.")) {
    event.respondWith(
      caches.match(event.request).then((cached) => {
        return cached || fetch(event.request).then((response) => {
          if (response.ok) {
            const clone = response.clone();
            caches.open(STATIC_CACHE).then((cache) => cache.put(event.request, clone));
          }
          return response;
        });
      })
    );
    return;
  }

  // الصفحات الديناميكية: Network-first بسقوط لـCache
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        if (response.ok && response.type === "basic") {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
        }
        return response;
      })
      .catch(() => {
        return caches.match(event.request).then((cached) => {
          if (cached) return cached;
          // صفحة offline احتياطية
          return caches.match("/offline-fallback/") || new Response(
            `<!DOCTYPE html><html lang="ar" dir="rtl"><head><meta charset="UTF-8">
             <title>غير متصل</title><style>body{font-family:sans-serif;text-align:center;padding:50px;}</style>
             </head><body>
             <h1>📡 غير متصل بالشبكة</h1>
             <p>لم نتمكن من الوصول للسيرفر. تأكد من اتصالك بشبكة الواي فاي الخاصة باللابتوب.</p>
             <button onclick="location.reload()">إعادة المحاولة</button>
             </body></html>`,
            { headers: { "Content-Type": "text/html; charset=utf-8" } }
          );
        });
      })
  );
});

// Background Sync - عند عودة الاتصال
self.addEventListener("sync", (event) => {
  if (event.tag === "haqquna-sync-drafts") {
    event.waitUntil(syncPendingDrafts());
  }
});

async function syncPendingDrafts() {
  const clients = await self.clients.matchAll();
  for (const client of clients) {
    client.postMessage({ type: "sync-trigger" });
  }
}
