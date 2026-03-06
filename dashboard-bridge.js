/**
 * Dashboard bridge: runs on whatsync.io dashboard.
 * Syncs userId (and session) from the page into chrome.storage.local
 * so the extension can use them for getConnectionStatus, getPrivacySettings, etc.
 * Privacy is always fetched from the backend via the extension background script.
 */
(function () {
  const STORAGE_KEY = 'external_auth_session';

  function syncSessionToExtension() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return;

      const session = JSON.parse(raw);
      const userId = session?.user?.id || session?.id || null;
      if (!userId) return;

      chrome.storage.local.set({
        userId,
        userLoggedIn: true,
        external_auth_session: session
      });
      console.log('[Dashboard Bridge] Synced userId to extension storage');
    } catch (e) {
      console.warn('[Dashboard Bridge] Could not sync session:', e);
    }
  }

  syncSessionToExtension();

  window.addEventListener('storage', (e) => {
    if (e.key === STORAGE_KEY && e.newValue) syncSessionToExtension();
  });

  const interval = setInterval(syncSessionToExtension, 5000);
  setTimeout(() => clearInterval(interval), 60000);
})();
