(function initDashboard() {
  const API_BASE = "http://localhost:8000";

  const authGate = document.getElementById("authGate");
  const profileBox = document.getElementById("profileBox");
  const usernameForm = document.getElementById("usernameForm");
  const passwordForm = document.getElementById("passwordForm");
  const usernameMsg = document.getElementById("usernameMsg");
  const passwordMsg = document.getElementById("passwordMsg");
  const ordersList = document.getElementById("ordersList");
  const orderDetails = document.getElementById("orderDetails");

  if (!authGate || !profileBox || !usernameForm || !passwordForm || !ordersList || !orderDetails) {
    return;
  }

  function showError(el, msg) {
    el.textContent = msg;
    el.style.color = "rgba(200,50,50,.95)";
  }

  function showOk(el, msg) {
    el.textContent = msg;
    el.style.color = "rgba(23,63,88,.95)";
  }

  function formatFt(n) {
    return (Number(n) || 0).toLocaleString("hu-HU") + " Ft";
  }

  function normalizeErrPayload(payload) {
    return payload?.message || payload?.details || "Request failed";
  }

  function isLoggedIn() {
    return window.Auth?.isLoggedIn?.() ?? false;
  }

  async function apiGet(path) {
    const res = await fetch(`${API_BASE}${path}`, {
      headers: window.Auth.getAuthHeaders(),
    });
    const payload = await res.json();
    if (!res.ok || !payload.success) {
      throw new Error(payload?.message || payload?.details || "Request failed");
    }
    return payload;
  }

  async function apiPut(path, body) {
    const res = await fetch(`${API_BASE}${path}`, {
      method: "PUT",
      headers: window.Auth.getAuthHeaders(),
      body: JSON.stringify(body ?? {}),
    });
    const payload = await res.json();
    if (!res.ok || !payload.success) {
      throw new Error(normalizeErrPayload(payload));
    }
    return payload;
  }

  function orderIdOf(order) {
    return order?.["Rendelésszám"] ?? order?.order_id ?? order?.id ?? null;
  }

  function renderOrders(orders) {
    if (!orders || orders.length === 0) {
      ordersList.innerHTML = `<div class="muted small">No orders yet.</div>`;
      orderDetails.innerHTML = `<div class="small muted">Select an order.</div>`;
      return;
    }

    ordersList.innerHTML = orders
      .map((o) => {
        const id = orderIdOf(o);
        const date = o?.["Dátum"] ?? "";
        const status = o?.["Állapot"] ?? "";
        const address = o?.["Szállítási cím"] ?? "";

        return `
          <button
            type="button"
            class="btn"
            style="width:100%;justify-content:flex-start;margin-bottom:10px;"
            data-order-id="${id}"
            data-address="${address}"
          >
            <span style="font-weight:950;">#${id}</span>
            <span class="small muted" style="margin-left:10px;">
              ${date} • ${status}
            </span>
          </button>
        `;
      })
      .join("");
  }

  function renderOrderDetails(items) {
    if (!items || items.length === 0) {
      orderDetails.innerHTML = `<div class="small muted">No items.</div>`;
      return;
    }

    const orderSum = items.reduce((sum, it) => sum + (Number(it?.["Részösszeg"]) || 0), 0);

    orderDetails.innerHTML = `
      <div style="font-weight:950;margin-bottom:8px;">Order items</div>
      <div class="small muted" style="margin-bottom:10px;">Total: <strong>${formatFt(orderSum)}</strong></div>
      <div>
        ${items
          .map((it) => {
            const name = it?.["Termék"] ?? "";
            const brand = it?.["Márka"] ?? "";
            const qty = Number(it?.["Mennyiség"]) || 0;
            const unit = it?.["Egységár"];
            const sub = it?.["Részösszeg"];
            return `
              <div class="card p" style="box-shadow:none;margin-bottom:10px;">
                <div style="font-weight:950;">${name}</div>
                <div class="small muted">${brand}</div>
                <div class="small muted" style="margin-top:6px;">
                  Qty: ${qty} • Unit: ${unit === null ? "-" : formatFt(unit)} • Subtotal: ${sub === null ? "-" : formatFt(sub)}
                </div>
              </div>
            `;
          })
          .join("")}
      </div>
    `;
  }

  async function loadProfile() {
    const payload = await apiGet("/profile");
    const user = payload?.user;
    profileBox.innerHTML = `
      <div><strong>Username:</strong> ${user?.username ?? "-"}</div>
      <div class="small muted" style="margin-top:6px;"><strong>Email:</strong> ${user?.email ?? "-"}</div>
      <div class="small muted" style="margin-top:6px;"><strong>Role:</strong> ${user?.role ?? "-"}</div>
    `;
  }

  async function loadOrders() {
    const payload = await apiGet("/orders");
    const orders = payload?.orders ?? [];
    renderOrders(orders);
    ordersList.querySelectorAll("[data-order-id]").forEach((btn) => {
      btn.addEventListener("click", async () => {
        const orderId = btn.getAttribute("data-order-id");
        if (!orderId) return;
        orderDetails.innerHTML = `<div class="small muted">Loading order ${orderId}...</div>`;
        try {
          const details = await apiGet(`/orders/${orderId}`);
          renderOrderDetails(details?.items ?? []);
        } catch (err) {
          orderDetails.innerHTML = `<div class="small muted">${err?.message || "Failed to load order details"}</div>`;
        }
      });
    });
  }

  async function initForms() {
    usernameForm.addEventListener("submit", async (e) => {
      e.preventDefault();
      usernameMsg.textContent = "";
      usernameMsg.style.color = "";

      try {
        const newUsername = document.getElementById("newUsername").value;
        const payload = await apiPut("/profile/username", { new_username: newUsername });

        // JWT refresh, hogy ne “régi” username-nel menjenek az auth-alapú hívások.
        if (payload?.token && payload?.user && window.Auth?.setSession) {
          window.Auth.setSession(payload.token, payload.user);
        }

        await loadProfile();
        await loadOrders();
        showOk(usernameMsg, "Username updated.");
      } catch (err) {
        showError(usernameMsg, err?.message || "Failed to update username");
      }
    });

    passwordForm.addEventListener("submit", async (e) => {
      e.preventDefault();
      passwordMsg.textContent = "";
      passwordMsg.style.color = "";

      try {
        const newPassword = document.getElementById("newPassword").value;
        const payload = await apiPut("/profile/password", { new_password: newPassword });
        showOk(passwordMsg, payload?.message || "Password updated.");
      } catch (err) {
        showError(passwordMsg, err?.message || "Failed to update password");
      }
    });
  }

  async function init() {
    if (!isLoggedIn()) {
      authGate.innerHTML = `You need to log in to access the dashboard. <a href="login.html">Log in</a>.`;
      profileBox.innerHTML = "";
      ordersList.innerHTML = "";
      orderDetails.innerHTML = "";
      usernameForm.querySelectorAll("input, button").forEach((el) => (el.disabled = true));
      passwordForm.querySelectorAll("input, button").forEach((el) => (el.disabled = true));
      return;
    }

    authGate.textContent = "";

    try {
      await loadProfile();
      await loadOrders();
    } catch (err) {
      authGate.innerHTML = err?.message ? `Failed: ${err.message}` : "Failed to load dashboard data.";
    }

    await initForms();
  }

  init();
})();

