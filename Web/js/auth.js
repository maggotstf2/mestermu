// Shared authentication/session helpers for frontend pages.
(function initAuthHelpers() {
  const USER_KEY = "user";
  const TOKEN_KEY = "token";
  const EXPIRES_KEY = "authExpiresAt";
  const SESSION_TTL_MS = 60 * 60 * 1000; // 1 hour

  function clearSession() {
    localStorage.removeItem(USER_KEY);
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(EXPIRES_KEY);
  }

  function parseUser(raw) {
    try {
      return JSON.parse(raw || "null");
    } catch {
      return null;
    }
  }

  function getSession() {
    const token = localStorage.getItem(TOKEN_KEY);
    const user = parseUser(localStorage.getItem(USER_KEY));
    const expiresAt = Number(localStorage.getItem(EXPIRES_KEY) || "0");

    if (!token || !user || !expiresAt) {
      return null;
    }

    if (Date.now() > expiresAt) {
      clearSession();
      return null;
    }

    return { token, user, expiresAt };
  }

  function setSession(token, user) {
    const expiresAt = Date.now() + SESSION_TTL_MS;
    localStorage.setItem(TOKEN_KEY, token);
    localStorage.setItem(USER_KEY, JSON.stringify(user));
    localStorage.setItem(EXPIRES_KEY, String(expiresAt));
  }

  function isLoggedIn() {
    return !!getSession();
  }

  function requireLogin() {
    if (isLoggedIn()) return true;
    alert("You need to log in to use this feature.");
    window.location.href = "login.html";
    return false;
  }

  function requireAdmin() {
    const session = getSession();
    if (!session || session.user?.role !== "admin") {
      alert("You do not have permission.");
      window.location.href = "login.html";
      return false;
    }
    return true;
  }

  function getAuthHeaders() {
    const session = getSession();
    if (!session) {
      return { "Content-Type": "application/json" };
    }
    return {
      "Content-Type": "application/json",
      Authorization: "Bearer " + session.token,
    };
  }

  window.Auth = {
    clearSession,
    getSession,
    setSession,
    isLoggedIn,
    requireLogin,
    requireAdmin,
    getAuthHeaders,
  };
})();
