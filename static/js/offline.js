/**
 * إدارة وضع Offline والمزامنة لجمعية حقّنا
 *
 * المسؤوليات:
 * 1. تسجيل Service Worker
 * 2. عرض حالة الاتصال (متصل/غير متصل)
 * 3. حفظ مسوّدات الناجين في IndexedDB عند الـoffline
 * 4. رفع المسوّدات تلقائياً عند عودة الاتصال
 * 5. زر "مزامنة الآن" يدوي
 */

(function () {
  "use strict";

  const DB_NAME = "haqquna_offline";
  const DB_VERSION = 1;
  const STORE_DRAFTS = "draft_survivors";

  // ============================================================
  // 1. تسجيل Service Worker
  // ============================================================
  if ("serviceWorker" in navigator) {
    window.addEventListener("load", () => {
      navigator.serviceWorker.register("/sw.js", { scope: "/" })
        .then((reg) => console.log("[Haqquna] SW مسجَّل:", reg.scope))
        .catch((err) => console.warn("[Haqquna] فشل تسجيل SW:", err));
    });
  }

  // ============================================================
  // 2. IndexedDB - تخزين محلي للمسوّدات
  // ============================================================
  function openDB() {
    return new Promise((resolve, reject) => {
      const req = indexedDB.open(DB_NAME, DB_VERSION);
      req.onerror = () => reject(req.error);
      req.onsuccess = () => resolve(req.result);
      req.onupgradeneeded = () => {
        const db = req.result;
        if (!db.objectStoreNames.contains(STORE_DRAFTS)) {
          const store = db.createObjectStore(STORE_DRAFTS, {
            keyPath: "id",
            autoIncrement: true,
          });
          store.createIndex("created_at", "created_at", { unique: false });
          store.createIndex("synced", "synced", { unique: false });
        }
      };
    });
  }

  async function saveDraft(draft) {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_DRAFTS, "readwrite");
      const store = tx.objectStore(STORE_DRAFTS);
      draft.created_at = new Date().toISOString();
      draft.synced = false;
      const req = store.add(draft);
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  async function getPendingDrafts() {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_DRAFTS, "readonly");
      const store = tx.objectStore(STORE_DRAFTS);
      const req = store.getAll();
      req.onsuccess = () => resolve(req.result.filter((d) => !d.synced));
      req.onerror = () => reject(req.error);
    });
  }

  async function markSynced(id, serverId) {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_DRAFTS, "readwrite");
      const store = tx.objectStore(STORE_DRAFTS);
      const getReq = store.get(id);
      getReq.onsuccess = () => {
        const draft = getReq.result;
        draft.synced = true;
        draft.server_id = serverId;
        draft.synced_at = new Date().toISOString();
        const putReq = store.put(draft);
        putReq.onsuccess = () => resolve();
        putReq.onerror = () => reject(putReq.error);
      };
      getReq.onerror = () => reject(getReq.error);
    });
  }

  async function deleteDraft(id) {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_DRAFTS, "readwrite");
      const req = tx.objectStore(STORE_DRAFTS).delete(id);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  }

  // ============================================================
  // 3. مؤشّر حالة الاتصال
  // ============================================================
  function updateNetworkStatus() {
    const banner = document.getElementById("haqquna-offline-banner");
    if (!banner) return;
    const online = navigator.onLine;
    banner.classList.toggle("offline", !online);
    banner.classList.toggle("online", online);
    if (online) {
      checkPendingAndSync();
    }
  }

  window.addEventListener("online", updateNetworkStatus);
  window.addEventListener("offline", updateNetworkStatus);

  // ============================================================
  // 4. التقاط نموذج إنشاء ناجٍ في وضع offline
  // ============================================================
  function interceptSurvivorForm() {
    const form = document.querySelector('form[action*="/survivors/new/"], form[data-offline-capture]');
    if (!form) return;

    form.addEventListener("submit", async (e) => {
      // إن كنا متصلين، لا نفعل شيئاً (الفورم يُرسل عادياً)
      if (navigator.onLine) return;

      e.preventDefault();
      const formData = new FormData(form);
      const data = {};
      formData.forEach((value, key) => {
        if (key !== "csrfmiddlewaretoken") data[key] = value;
      });
      try {
        const id = await saveDraft({
          type: "survivor",
          form_action: form.action,
          data: data,
        });
        showToast(`✓ حُفظ كمسودة محلية رقم ${id}. سيُرفع عند الاتصال.`, "info");
        form.reset();
        updatePendingCount();
      } catch (err) {
        showToast(`✗ فشل الحفظ المحلي: ${err.message}`, "danger");
      }
    });
  }

  // ============================================================
  // 5. مزامنة - رفع المسوّدات للسيرفر
  // ============================================================
  async function checkPendingAndSync(silent = true) {
    const pending = await getPendingDrafts();
    if (pending.length === 0) {
      if (!silent) showToast("لا توجد مسوّدات للمزامنة.", "info");
      updatePendingCount();
      return;
    }
    if (!silent) showToast(`جاري مزامنة ${pending.length} مسوّدة...`, "info");

    const csrf = getCookie("hq_csrf") || getCookie("hq_csrf_training") ||
                 getCookie("csrftoken");
    let success = 0, failed = 0;
    for (const draft of pending) {
      try {
        const fd = new FormData();
        for (const [k, v] of Object.entries(draft.data)) fd.append(k, v);
        const res = await fetch(draft.form_action, {
          method: "POST",
          body: fd,
          headers: { "X-CSRFToken": csrf || "" },
          credentials: "same-origin",
        });
        if (res.ok || res.redirected) {
          await markSynced(draft.id, res.url);
          success++;
        } else {
          failed++;
        }
      } catch (err) {
        failed++;
      }
    }
    if (!silent || success > 0) {
      showToast(`مزامنة: ${success} ناجح، ${failed} فشل.`, success > 0 ? "success" : "warning");
    }
    updatePendingCount();
  }

  // ============================================================
  // 6. عدّاد المسوّدات المعلّقة
  // ============================================================
  async function updatePendingCount() {
    const badge = document.getElementById("haqquna-pending-count");
    if (!badge) return;
    const pending = await getPendingDrafts();
    badge.textContent = pending.length || "";
    badge.style.display = pending.length > 0 ? "inline-block" : "none";
  }

  // ============================================================
  // أدوات مساعدة
  // ============================================================
  function getCookie(name) {
    const m = document.cookie.match(new RegExp("(^| )" + name + "=([^;]+)"));
    return m ? m[2] : null;
  }

  function showToast(msg, type) {
    let toast = document.getElementById("haqquna-toast");
    if (!toast) {
      toast = document.createElement("div");
      toast.id = "haqquna-toast";
      document.body.appendChild(toast);
    }
    toast.className = `haqquna-toast alert alert-${type || "info"}`;
    toast.textContent = msg;
    toast.style.display = "block";
    setTimeout(() => { toast.style.display = "none"; }, 4000);
  }

  // كشف عام للاستخدام من واجهات أخرى
  window.HaqqunaOffline = {
    saveDraft, getPendingDrafts, markSynced, deleteDraft,
    syncNow: () => checkPendingAndSync(false),
  };

  // ============================================================
  // تشغيل عند تحميل الصفحة
  // ============================================================
  document.addEventListener("DOMContentLoaded", () => {
    updateNetworkStatus();
    updatePendingCount();
    interceptSurvivorForm();
  });

  // الاستماع لرسائل من SW (Background Sync)
  if (navigator.serviceWorker) {
    navigator.serviceWorker.addEventListener("message", (event) => {
      if (event.data && event.data.type === "sync-trigger") {
        checkPendingAndSync(true);
      }
    });
  }
})();
