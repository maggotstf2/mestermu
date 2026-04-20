// Active nav link + mobile drawer + cart badge
const path = location.pathname.split("/").pop() || "index.html";

document.querySelectorAll("[data-nav-link]").forEach((a) => {
  const href = a.getAttribute("href");
  if (href === path) a.classList.add("is-active");
});

const burger = document.querySelector("#burger");
const drawer = document.querySelector("#drawer");
const drawerClose = document.querySelector("#drawerClose");

function getSessionFallback() {
  const token = localStorage.getItem("token");
  const userRaw = localStorage.getItem("user");
  const expiresAt = Number(localStorage.getItem("authExpiresAt") || "0");
  if (!token || !userRaw) return null;

  let user = null;
  try {
    user = JSON.parse(userRaw);
  } catch {
    return null;
  }

  if (expiresAt && Date.now() > expiresAt) {
    localStorage.removeItem("token");
    localStorage.removeItem("user");
    localStorage.removeItem("authExpiresAt");
    return null;
  }

  return { token, user, expiresAt };
}

function isLoggedInNow() {
  if (window.Auth?.isLoggedIn) return window.Auth.isLoggedIn();
  return !!getSessionFallback();
}

function clearSessionNow() {
  if (window.Auth?.clearSession) {
    window.Auth.clearSession();
    return;
  }
  localStorage.removeItem("token");
  localStorage.removeItem("user");
  localStorage.removeItem("authExpiresAt");
}

function isValidEmail(value) {
  const email = String(value || "").trim();
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function toggleDrawer(open) {
  if (!drawer) return;
  if (open) drawer.classList.add("is-open");
  else drawer.classList.remove("is-open");
}
burger?.addEventListener("click", () =>
  toggleDrawer(!drawer.classList.contains("is-open")),
);
drawerClose?.addEventListener("click", () => toggleDrawer(false));
drawer?.addEventListener("click", (e) => {
  if (e.target.matches("a")) toggleDrawer(false);
});

function loadCartItems() {
  try {
    return JSON.parse(localStorage.getItem("cartItems") || "[]");
  } catch {
    return [];
  }
}

function saveCartItems(items) {
  localStorage.setItem("cartItems", JSON.stringify(items));
}

function normalizeStock(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return 0;
  return Math.max(0, Math.floor(n));
}

function ensureCartSpeechBubble() {
  let el = document.getElementById("cartSpeechBubble");
  if (el) return el;
  el = document.createElement("div");
  el.id = "cartSpeechBubble";
  el.className = "cart-speech-bubble";
  el.setAttribute("aria-live", "polite");
  el.setAttribute("aria-atomic", "true");
  document.body.appendChild(el);
  return el;
}

function isElementVisible(el) {
  if (!el) return false;
  const rect = el.getBoundingClientRect();
  const style = window.getComputedStyle(el);
  return (
    style.display !== "none" &&
    style.visibility !== "hidden" &&
    rect.width > 0 &&
    rect.height > 0
  );
}

function getVisibleCartAnchor() {
  const isResponsive = window.matchMedia("(max-width: 860px)").matches;
  const drawerEl = document.getElementById("drawer");
  const burgerBtn = document.getElementById("burger");

  if (isResponsive && drawerEl) {
    const drawerOpen = drawerEl.classList.contains("is-open");
    if (drawerOpen) {
      const drawerCart = drawerEl.querySelector('a[href="cart.html"]');
      if (isElementVisible(drawerCart)) return drawerCart;
    } else if (isElementVisible(burgerBtn)) {
      return burgerBtn;
    }
  }

  const candidates = Array.from(document.querySelectorAll('a[href="cart.html"]'));
  for (const el of candidates) {
    if (isElementVisible(el)) return el;
  }
  return isElementVisible(burgerBtn) ? burgerBtn : null;
}

function positionCartBubble() {
  const bubble = document.getElementById("cartSpeechBubble");
  if (!bubble) return;

  const cartAnchor = getVisibleCartAnchor();
  if (!cartAnchor) {
    bubble.style.left = "";
    bubble.style.top = "";
    bubble.style.setProperty("--cart-bubble-arrow-left", "28px");
    return;
  }

  const anchorRect = cartAnchor.getBoundingClientRect();
  const bubbleRect = bubble.getBoundingClientRect();
  const margin = 10;
  const desiredCenterX = anchorRect.left + anchorRect.width / 2;
  const maxLeft = window.innerWidth - bubbleRect.width - margin;
  const bubbleLeft = Math.max(margin, Math.min(maxLeft, desiredCenterX - bubbleRect.width / 2));
  const bubbleTop = Math.min(window.innerHeight - bubbleRect.height - margin, anchorRect.bottom + 10);
  const arrowLeft = Math.max(16, Math.min(bubbleRect.width - 18, desiredCenterX - bubbleLeft));

  bubble.style.left = `${bubbleLeft}px`;
  bubble.style.top = `${Math.max(margin, bubbleTop)}px`;
  bubble.style.setProperty("--cart-bubble-arrow-left", `${arrowLeft}px`);
}

window.showCartBubble = function (message, kind = "ok", durationMs = 2600) {
  const el = ensureCartSpeechBubble();
  if (!el) return;
  el.textContent = String(message || "");
  positionCartBubble();
  el.classList.remove("is-ok", "is-warn", "is-error", "is-visible");
  el.classList.add(
    kind === "warn" ? "is-warn" : kind === "error" ? "is-error" : "is-ok",
  );
  // reflow for transition restart
  void el.offsetWidth;
  el.classList.add("is-visible");
  clearTimeout(window.showCartBubble._timer);
  window.showCartBubble._timer = setTimeout(() => {
    el.classList.remove("is-visible");
  }, Math.max(1200, Number(durationMs) || 2600));
};

window.addEventListener("resize", positionCartBubble);
window.addEventListener("scroll", positionCartBubble, { passive: true });

function getCartCountFromItems(items) {
  return items.reduce((sum, it) => sum + (Number(it.qty) || 0), 0);
}

const badgeEls = document.querySelectorAll("[data-cart-badge]");
// Ha van részletes kosár, abból számoljuk a mennyiséget
let initialCartItems = loadCartItems();
let cartCount =
  initialCartItems.length > 0
    ? getCartCountFromItems(initialCartItems)
    : Number(localStorage.getItem("cartCount") || "0");
badgeEls.forEach((el) => (el.textContent = String(cartCount)));

window.__addToCart = function (product) {
  const items = loadCartItems();
  const id = product?.id ?? null;
  const stock = normalizeStock(product?.stock ?? product?.quantity);

  if (id == null) {
    // visszaesés: csak darabszám növelés, ha valamiért nincs termék
    const fallbackNext = Number(localStorage.getItem("cartCount") || "0") + 1;
    localStorage.setItem("cartCount", String(fallbackNext));
    badgeEls.forEach((el) => (el.textContent = String(fallbackNext)));
    return;
  }

  if (stock <= 0) {
    window.showCartBubble?.("This product is out of stock.", "warn", 3200);
    return;
  }

  const idx = items.findIndex((it) => String(it.id) === String(id));
  if (idx >= 0) {
    const currentQty = Number(items[idx].qty) || 0;
    if (currentQty >= stock) {
      window.showCartBubble?.(
        `You can only add ${stock} pcs (current stock limit).`,
        "warn",
        3400,
      );
      return;
    }
    items[idx].qty = currentQty + 1;
    items[idx].stock = stock;
  } else {
    items.push({
      id: product.id,
      name: product.name,
      price: product.price,
      brand: product.brand,
      category: product.category,
      subCategory: product.subCategory,
      stock,
      qty: 1,
    });
  }

  saveCartItems(items);

  const nextCount = getCartCountFromItems(items);
  localStorage.setItem("cartCount", String(nextCount));
  badgeEls.forEach((el) => (el.textContent = String(nextCount)));
  window.showCartBubble?.(`${product?.name || "Product"} added to cart.`, "ok", 2200);
};

// =========================
// Hero slider (index.html) – vanilla
// =========================
(function initHeroSlider(){
  const slider = document.querySelector("[data-slider]");
  if (!slider) return;

  const slides = Array.from(slider.querySelectorAll("[data-slide]"));
  const dots = Array.from(slider.querySelectorAll("[data-dot]"));
  const prev = slider.querySelector("[data-prev]");
  const next = slider.querySelector("[data-next]");
  let idx = 0;
  let timer = null;

  function show(i){
    idx = (i + slides.length) % slides.length;
    slides.forEach((s, si) => s.style.display = (si === idx ? "block" : "none"));
    dots.forEach((d, di) => d.classList.toggle("is-active", di === idx));
  }

  function start(){
    stop();
    timer = setInterval(() => show(idx + 1), 4500);
  }
  function stop(){
    if (timer) clearInterval(timer);
    timer = null;
  }

  dots.forEach((d, di) => d.addEventListener("click", () => { show(di); start(); }));
  prev?.addEventListener("click", () => { show(idx - 1); start(); });
  next?.addEventListener("click", () => { show(idx + 1); start(); });

  slider.addEventListener("mouseenter", stop);
  slider.addEventListener("mouseleave", start);

  show(0);
  start();
})();

// Logged-in UI: dashboard links + account dropdown
try {
  const loggedIn = isLoggedInNow();
  const session = getSessionFallback();
  const currentUser = session?.user || (() => {
    try { return JSON.parse(localStorage.getItem("user") || "null"); }
    catch { return null; }
  })();
  const isAdminUser = (currentUser?.role || "").toLowerCase() === "admin";
  const accountBtn = document.querySelector('.actions a.btn[href="login.html"]');
  const drawerLoginBtn = document.querySelector('#drawer a.btn[href="login.html"]');
  const drawerSignUpBtn = document.querySelector('#drawer a.btn.btn--primary[href="register.html"]');

  if (loggedIn) {
    document.querySelectorAll('a[href="login.html"]').forEach((a) => a.setAttribute("href", "dashboard.html"));

    if (accountBtn) {
      accountBtn.removeAttribute("href");
      accountBtn.setAttribute("role", "button");
      accountBtn.setAttribute("aria-haspopup", "true");
      accountBtn.setAttribute("aria-expanded", "false");
      accountBtn.classList.add("account-trigger");

      if (!accountBtn.querySelector("[data-account-label]")) {
        const label = document.createElement("span");
        label.setAttribute("data-account-label", "1");
        label.textContent = "My account";
        accountBtn.appendChild(label);
      }

      const wrap = document.createElement("div");
      wrap.className = "account-menu-wrap";
      accountBtn.parentNode.insertBefore(wrap, accountBtn);
      wrap.appendChild(accountBtn);

      const menu = document.createElement("div");
      menu.className = "account-menu";
      menu.setAttribute("role", "menu");
      menu.innerHTML = `
        <a href="dashboard.html#orders" role="menuitem">My orders</a>
        <a href="dashboard.html#profile" role="menuitem">My profile</a>
        ${isAdminUser ? `<a href="admin.html" role="menuitem">Admin panel</a>` : ""}
        <button type="button" data-logout-btn role="menuitem">Log out</button>
      `;
      wrap.appendChild(menu);

      const closeMenu = () => {
        menu.classList.remove("is-open");
        accountBtn.setAttribute("aria-expanded", "false");
      };

      accountBtn.addEventListener("click", (e) => {
        e.preventDefault();
        const isOpen = menu.classList.toggle("is-open");
        accountBtn.setAttribute("aria-expanded", String(isOpen));
      });

      document.addEventListener("click", (e) => {
        if (!wrap.contains(e.target)) closeMenu();
      });

      document.addEventListener("keydown", (e) => {
        if (e.key === "Escape") closeMenu();
      });

      menu.querySelector("[data-logout-btn]")?.addEventListener("click", () => {
        clearSessionNow();
        closeMenu();
        window.location.href = "index.html";
      });
    }
  }  
} catch {
  // ignore
}

// =========================
// Booking (contact.html) –  (localStorage)
// =========================
(async function initBooking(){
  const form = document.querySelector("#bookingForm");
  if (!form) return;

  const serviceEl = document.querySelector("#service");
  const dateEl = document.querySelector("#date");
  const timeEl = document.querySelector("#time");
  const locationEl = document.querySelector("#locationType");
  const nameEl = document.querySelector("#name");
  const phoneEl = document.querySelector("#phone");
  const emailEl = document.querySelector("#email");
  const noteEl = document.querySelector("#note");
  const summaryEl = document.querySelector("#summary");
  const listEl = document.querySelector("#bookingsList");
  const msgEl = document.querySelector("#formMsg");
  const clearBtn = document.querySelector("#clearBookings");
  const API_BASE = "http://localhost:8000";
  let previousLoginState = window.Auth?.isLoggedIn?.() ?? false;

  const DRAFT_KEY = "bookingDraft";

  const today = new Date();
  const tomorrow = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1);
  dateEl.min = toISODate(tomorrow);

  function generateSlots(){
    const slots = [];
    slots.push("07:30");
    for (let h = 8; h <= 16; h++){
      slots.push(`${pad(h)}:00`);
      slots.push(`${pad(h)}:30`);
    }
    slots.push("17:00");
    return slots;
  }

  function isWeekendDate(isoDate){
    if (!isoDate) return false;
    const d = new Date(`${isoDate}T00:00:00`);
    const day = d.getDay();
    return day === 0 || day === 6;
  }

  let cachedBookings = [];

  function loadDraft(){
    try { return JSON.parse(localStorage.getItem(DRAFT_KEY) || "null"); }
    catch { return null; }
  }

  async function fetchUserReservations(){
    if (!isLoggedInNow()) {
      cachedBookings = [];
      return [];
    }

    try {
      const res = await fetch(`${API_BASE}/reservations`, {
        method: "GET",
        headers: window.Auth?.getAuthHeaders?.() || {}
      });
      const data = await res.json().catch(() => ({}));
      
      if (res.ok && data?.success) {
        cachedBookings = (data?.reservations || []).map(r => ({
          id: r["Foglalás Azonosító"],
          service: r["Szolgáltatás"],
          date: r["Dátum"],
          time: r["Időpont"]?.substring(0, 5),
          locationType: r["Helyszín"],
          name: r["Név"],
          phone: r["Telefon"],
          email: r["Email"],
          note: r["Megjegyzés"]
        }));
      } else {
        cachedBookings = [];
      }
    } catch (err) {
      console.error("Failed to fetch reservations:", err);
      cachedBookings = [];
    }

    return cachedBookings;
  }

  function saveDraftFromForm(){
    const draft = {
      service: serviceEl.value || "",
      date: dateEl.value || "",
      time: timeEl.value || "",
      locationType: locationEl.value || "",
      name: nameEl.value || "",
      phone: phoneEl.value || "",
      email: emailEl.value || "",
      note: noteEl.value || ""
    };
    localStorage.setItem(DRAFT_KEY, JSON.stringify(draft));
  }

  function clearDraft(){
    localStorage.removeItem(DRAFT_KEY);
  }

  function refreshTimeOptions(){
    const d = dateEl.value;
    timeEl.innerHTML = "";
    if (!d){
      timeEl.innerHTML = `<option value="" selected disabled>Select a date first…</option>`;
      updateSummary();
      return;
    }

    if (isWeekendDate(d)) {
      timeEl.innerHTML = `<option value="" selected disabled>Weekend booking is not available.</option>`;
      msgEl.textContent = "Appointments are available only on weekdays between 07:30 and 17:00.";
      updateSummary();
      return;
    }

    const taken = new Set(cachedBookings.filter(b => b.date === d).map(b => b.time));
    const opts = generateSlots().map(t => {
      const disabled = taken.has(t) ? "disabled" : "";
      const label = taken.has(t) ? `${t} (booked)` : t;
      return `<option value="${t}" ${disabled}>${label}</option>`;
    }).join("");

    timeEl.innerHTML = `<option value="" selected disabled>Select time…</option>` + opts;
    updateSummary();
  }

  function updateSummary(){
    const s = serviceEl.value || "—";
    const d = dateEl.value || "—";
    const t = timeEl.value || "—";
    const loc = locationEl.value || "—";

    summaryEl.innerHTML = `
      <div><strong>Service:</strong> ${escapeHtml(s)}</div>
      <div><strong>Date:</strong> ${escapeHtml(d)}</div>
      <div><strong>Time:</strong> ${escapeHtml(t)}</div>
      <div><strong>Location:</strong> ${escapeHtml(loc)}</div>
    `;
  }

  function renderBookings(){
    const currentLoginState = window.Auth?.isLoggedIn?.() ?? false;
    
    // If login state changed, refetch reservations
    if (currentLoginState !== previousLoginState) {
      previousLoginState = currentLoginState;
      if (currentLoginState) {
        fetchUserReservations().then(() => {
          renderBookingsContent();
        });
        return;
      } else {
        cachedBookings = [];
        renderBookingsContent();
        return;
      }
    }
    
    renderBookingsContent();
  }

  function renderBookingsContent(){
    const currentLoginState = window.Auth?.isLoggedIn?.() ?? false;
    
    if (!currentLoginState) {
      listEl.textContent = "Log in to see your bookings.";
      return;
    }

    const items = cachedBookings.sort((a,b) => (a.date + a.time).localeCompare(b.date + b.time));
    if (items.length === 0){
      listEl.textContent = "No bookings yet.";
      return;
    }

    listEl.innerHTML = items.map((b, idx) => `
      <div class="card p" style="box-shadow:none; margin-bottom:12px;">
        <div style="font-weight:950;">${escapeHtml(b.service)}</div>
        <div class="muted">${escapeHtml(b.date)} • ${escapeHtml(b.time)} • ${escapeHtml(b.locationType)}</div>
        <div class="muted" style="margin-top:6px;">${escapeHtml(b.name)} • ${escapeHtml(b.phone)} • ${escapeHtml(b.email)}</div>
        ${b.note ? `<div class="small muted">Note: ${escapeHtml(b.note)}</div>` : ""}
        <div style="margin-top:10px;">
          <button class="btn" type="button" data-del="${idx}" data-reservation-id="${escapeHtml(b.id || "")}">Delete</button>
        </div>
      </div>
    `).join("");
  }

  dateEl.addEventListener("change", () => {
    msgEl.textContent = "";
    if (isWeekendDate(dateEl.value)) {
      dateEl.value = "";
      msgEl.textContent = "Weekend booking is not available. Please choose a weekday.";
    }
    refreshTimeOptions();
    saveDraftFromForm();
  });
  timeEl.addEventListener("change", () => {
    updateSummary();
    saveDraftFromForm();
  });
  serviceEl.addEventListener("change", () => {
    updateSummary();
    saveDraftFromForm();
  });
  locationEl.addEventListener("change", () => {
    updateSummary();
    saveDraftFromForm();
  });

  [nameEl, phoneEl, emailEl, noteEl].forEach(el => {
    el?.addEventListener("input", saveDraftFromForm);
  });

  listEl.addEventListener("click", async (e) => {
    const btn = e.target.closest("[data-del]");
    if (!btn) return;
    const idx = Number(btn.getAttribute("data-del"));
    const reservationId = btn.getAttribute("data-reservation-id");
    const booking = cachedBookings[idx];
    
    if (!booking) return;

    // If reservation has an ID, delete from server
    if (reservationId && reservationId !== "") {
      btn.disabled = true;
      const prevText = btn.textContent;
      btn.textContent = "Deleting...";
      
      try {
        const res = await fetch(`${API_BASE}/reservations/${reservationId}`, {
          method: "DELETE",
          headers: window.Auth?.getAuthHeaders?.() || {}
        });
        
        const data = await res.json().catch(() => ({}));
        if (!res.ok || data?.success === false) {
          throw new Error(data?.message || "Failed to delete booking");
        }

        cachedBookings.splice(idx, 1);
        renderBookings();
        refreshTimeOptions();
        msgEl.textContent = "Booking deleted successfully ✅";
      } catch (err) {
        console.error(err);
        msgEl.textContent = err?.message || "Failed to delete booking";
        btn.disabled = false;
        btn.textContent = prevText;
      }
    } else {
      // Fallback: no reservation ID, just remove from cache
      cachedBookings.splice(idx, 1);
      renderBookings();
      refreshTimeOptions();
      msgEl.textContent = "Booking deleted.";
    }
  });

  clearBtn.addEventListener("click", async () => {
    cachedBookings = [];
    renderBookings();
    clearDraft();
    serviceEl.selectedIndex = 0;
    dateEl.value = "";
    refreshTimeOptions();
    timeEl.selectedIndex = 0;
    updateSummary();
    msgEl.textContent = "All bookings deleted.";
  });

  form.addEventListener("submit", (e) => {
    e.preventDefault();
    msgEl.textContent = "";

    const currentLoginState = window.Auth?.isLoggedIn?.() ?? false;
    if (!currentLoginState) {
      msgEl.innerHTML = `Appointment booking requires login. <a href="login.html">Log in here</a>.`;
      return;
    }

    if (!serviceEl.value || !dateEl.value || !timeEl.value || !locationEl.value){
      msgEl.textContent = "Please choose a service, date and time.";
      return;
    }

    if (isWeekendDate(dateEl.value)) {
      msgEl.textContent = "Weekend booking is not available. Please choose a weekday.";
      return;
    }

    const booking = {
      service: serviceEl.value,
      date: dateEl.value,
      time: timeEl.value,
      locationType: locationEl.value,
      name: nameEl.value.trim(),
      phone: phoneEl.value.trim(),
      email: emailEl.value.trim(),
      note: noteEl.value.trim(),
      createdAt: new Date().toISOString()
    };

    if (!booking.name || !booking.phone || !booking.email){
      msgEl.textContent = "Name, phone and email are required.";
      return;
    }

    if (!isValidEmail(booking.email)) {
      msgEl.textContent = "Please enter a valid email address.";
      return;
    }

    if (cachedBookings.some(b => b.date === booking.date && b.time === booking.time)){
      msgEl.textContent = "This time slot is already booked. Please choose another.";
      refreshTimeOptions();
      return;
    }

    const submitBtn = form.querySelector("button[type='submit']");
    const prevBtnText = submitBtn ? submitBtn.textContent : "";
    if (submitBtn) {
      submitBtn.disabled = true;
      submitBtn.textContent = "Booking...";
    }

    const reservation_time = booking.time.length === 5 ? `${booking.time}:00` : booking.time;
    const payload = {
      service: booking.service,
      reservation_date: booking.date,
      reservation_time,
      location: booking.locationType,
      name: booking.name,
      phone: booking.phone,
      email: booking.email,
      note: booking.note || null
    };

    fetch(`${API_BASE}/reservations`, {
      method: "POST",
      headers: {
        ...window.Auth?.getAuthHeaders?.(),
        "Content-Type": "application/json"
      },
      body: JSON.stringify(payload)
    })
      .then(async (res) => {
        const data = await res.json().catch(() => ({}));
        if (!res.ok || data?.success === false) {
          throw new Error(data?.message || "Booking failed");
        }

        booking.id = data?.reservation_id || null;
        cachedBookings.push(booking);

        clearDraft();
        form.reset();
        refreshTimeOptions();
        renderBookings();
        updateSummary();
        msgEl.textContent = "Booking successful ✅";
      })
      .catch((err) => {
        console.error(err);
        msgEl.textContent = err?.message || "Booking failed";
      })
      .finally(() => {
        if (submitBtn) {
          submitBtn.disabled = false;
          submitBtn.textContent = prevBtnText || "Book appointment";
        }
      });
  });

  const existingDraft = loadDraft();
  if (existingDraft){
    if (existingDraft.service) serviceEl.value = existingDraft.service;
    if (existingDraft.date) dateEl.value = existingDraft.date;
    if (existingDraft.locationType) locationEl.value = existingDraft.locationType;
    if (existingDraft.name && nameEl) nameEl.value = existingDraft.name;
    if (existingDraft.phone && phoneEl) phoneEl.value = existingDraft.phone;
    if (existingDraft.email && emailEl) emailEl.value = existingDraft.email;
    if (existingDraft.note) noteEl.value = existingDraft.note;
  }

  // Load reservations from the API (filters by authenticated user)
  await fetchUserReservations();

  refreshTimeOptions();

  if (existingDraft && existingDraft.time){
    timeEl.value = existingDraft.time;
  }

  renderBookings();
  updateSummary();

  function pad(n){ return String(n).padStart(2,"0"); }
  function toISODate(d){
    const y = d.getFullYear();
    const m = String(d.getMonth()+1).padStart(2,"0");
    const day = String(d.getDate()).padStart(2,"0");
    return `${y}-${m}-${day}`;
  }
  function escapeHtml(str){
    return String(str ?? "").replace(/[&<>"']/g, (m) => ({
      "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"
    }[m]));
  }

  // Listen for page visibility to refetch data when user returns to tab
  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible") {
      renderBookings();
    }
  });

  // Also check login state every 3 seconds to catch changes
  setInterval(() => {
    renderBookings();
  }, 3000);
})();

// =====================
// DARK MODE TOGGLE
// =====================

const themeBtn = document.querySelector("#themeToggle");

function setTheme(mode) {
  const icon = themeBtn?.querySelector("ion-icon");

  if (mode === "dark") {
    document.body.classList.add("dark");
    localStorage.setItem("theme", "dark");
    if (icon) icon.setAttribute("name", "moon-outline");
  } else {
    document.body.classList.remove("dark");
    localStorage.setItem("theme", "light");
    if (icon) icon.setAttribute("name", "sunny-outline");
  }
}

// Betöltéskor nézzük meg mit választott a user
const savedTheme = localStorage.getItem("theme");
if (savedTheme) {
  setTheme(savedTheme);
}

// Kattintás
themeBtn?.addEventListener("click", () => {
  const isDark = document.body.classList.contains("dark");
  setTheme(isDark ? "light" : "dark");
});

// =====================
// Kosár oldal (cart.html) – lista + összegzés
// =====================

(function initCartPage() {
  const listEl = document.querySelector("#cartItems");
  if (!listEl) return;

  const summaryEl = document.querySelector("#cartSummary");
  const clearBtn = document.querySelector("#clearCart");
  const checkoutBtn = document.querySelector("#checkoutBtn");
  const emptyText = "Your cart is currently empty.";
  const API_BASE = "http://localhost:8000";
  const stockById = new Map();

  function isLoggedIn() {
    return window.Auth?.isLoggedIn?.() ?? false;
  }

  function formatFt(n) {
    return (Number(n) || 0).toLocaleString("hu-HU") + " Ft";
  }

  function updateBadge() {
    const items = loadCartItems();
    const count = getCartCountFromItems(items);
    badgeEls.forEach((el) => (el.textContent = String(count)));
  }

  async function refreshStockCache() {
    try {
      const res = await fetch(`${API_BASE}/products/all`);
      const payload = await res.json();
      if (!res.ok || payload?.success === false) return;
      const items = Array.isArray(payload?.items) ? payload.items : [];
      stockById.clear();
      items.forEach((p) => {
        stockById.set(String(p.id), normalizeStock(p.quantity));
      });
    } catch {
      // keep previously known stock values from cart items
    }
  }

  function getAvailableStock(item) {
    const fromCache = stockById.get(String(item.id));
    if (typeof fromCache === "number") return fromCache;
    const localStock = Number(item?.stock);
    if (Number.isFinite(localStock)) return Math.max(0, Math.floor(localStock));
    return null;
  }

  function reconcileCartStock(items) {
    let changed = false;
    const next = [];
    for (const it of items) {
      const stock = getAvailableStock(it);
      const qty = Math.max(0, Number(it.qty) || 0);
      if (stock === null) {
        next.push({ ...it, qty });
        continue;
      }
      if (stock <= 0) {
        changed = true;
        continue;
      }
      const cappedQty = Math.min(qty, stock);
      if (cappedQty !== qty || Number(it.stock) !== stock) changed = true;
      next.push({ ...it, qty: cappedQty, stock });
    }
    return { items: next, changed };
  }

  function render() {
    const loggedIn = isLoggedIn();
    const rawItems = loadCartItems();
    const reconciled = reconcileCartStock(rawItems);
    const items = reconciled.items;
    if (reconciled.changed) {
      saveCartItems(items);
      localStorage.setItem("cartCount", String(getCartCountFromItems(items)));
    }

    if (!items.length) {
      listEl.innerHTML = `<div class="muted">${emptyText}</div>`;
      if (summaryEl) {
        summaryEl.innerHTML = `
          <div class="muted small">No items to display.</div>
        `;
      }
      updateBadge();
      return;
    }

    const rows = items
      .map(
        (it) => `
      <div class="card p" style="box-shadow:none;margin-bottom:10px;">
        <div style="font-weight:950;">${it.name}</div>
        <div class="small muted">
          ${it.brand || ""}${it.brand ? " • " : ""}${it.category || ""}${
          it.subCategory ? " • " + it.subCategory : ""
        }
        </div>
        <div style="margin-top:6px;display:flex;justify-content:space-between;align-items:center;gap:10px;">
          <div>
            <div class="small muted" style="display:flex;align-items:center;gap:8px;">
              <span>Quantity:</span>
              <button class="btn" type="button" data-cart-minus="${it.id}" style="padding:2px 8px;min-height:auto;">-</button>
              <strong>${it.qty}</strong>
              <button class="btn" type="button" data-cart-plus="${it.id}" style="padding:2px 8px;min-height:auto;" ${
                (() => {
                  const stock = getAvailableStock(it);
                  if (stock === null) return "";
                  return (Number(it.qty) || 0) >= stock ? "disabled" : "";
                })()
              }>+</button>
              <span>pcs</span>
            </div>
            <div class="small muted">In stock: ${
              getAvailableStock(it) === null ? "loading..." : getAvailableStock(it)
            }</div>
            ${
              loggedIn
                ? `<div class="small muted">Unit price: ${formatFt(it.price)}</div>`
                : `<div class="small muted">Log in to see unit price</div>`
            }
          </div>
          ${
            loggedIn
              ? `<div style="font-weight:950;">${formatFt(
                  (Number(it.price) || 0) * (Number(it.qty) || 0),
                )}</div>`
              : `<div style="font-weight:950;"></div>`
          }
        </div>
      </div>
    `,
      )
      .join("");

    listEl.innerHTML = rows;

    const subtotal = items.reduce(
      (sum, it) => sum + (Number(it.price) || 0) * (Number(it.qty) || 0),
      0,
    );
    const shipping = subtotal > 0 ? 0 : 0;
    const total = subtotal + shipping;

    if (summaryEl) {
      if (!loggedIn) {
        summaryEl.innerHTML = `
          <div class="small muted">Log in to see prices and checkout.</div>
        `;
        updateBadge();
        return;
      }
      summaryEl.innerHTML = `
        <div class="small muted">Subtotal: <strong>${formatFt(
          subtotal,
        )}</strong></div>
        <div class="small muted">Shipping: <strong>${formatFt(
          shipping,
        )}</strong></div>
        <div style="margin-top:8px;font-weight:950;">Total: ${formatFt(
          total,
        )}</div>
      `;
    }

    updateBadge();
  }

  clearBtn?.addEventListener("click", () => {
    localStorage.removeItem("cartItems");
    localStorage.setItem("cartCount", "0");
    render();
  });

  listEl.addEventListener("click", (e) => {
    const plusBtn = e.target.closest("[data-cart-plus]");
    const minusBtn = e.target.closest("[data-cart-minus]");
    if (!plusBtn && !minusBtn) return;

    const id = plusBtn?.getAttribute("data-cart-plus") || minusBtn?.getAttribute("data-cart-minus");
    if (!id) return;

    const items = loadCartItems();
    const idx = items.findIndex((it) => String(it.id) === String(id));
    if (idx < 0) return;

    if (plusBtn) {
      const stock = getAvailableStock(items[idx]);
      const currentQty = Number(items[idx].qty) || 0;
      if (stock === null) {
        window.showCartBubble?.(
          "Stock is still loading. Please try again in a moment.",
          "warn",
          2600,
        );
        return;
      }
      if (stock <= 0) {
        window.showCartBubble?.("This item is out of stock.", "warn", 3200);
        render();
        return;
      }
      if (currentQty >= stock) {
        window.showCartBubble?.(
          `You can only add up to ${stock} pcs for this item.`,
          "warn",
          3400,
        );
        render();
        return;
      }
      items[idx].qty = currentQty + 1;
      items[idx].stock = stock;
    } else {
      items[idx].qty = Math.max(0, (Number(items[idx].qty) || 0) - 1);
      if (items[idx].qty === 0) {
        items.splice(idx, 1);
      }
    }

    saveCartItems(items);
    localStorage.setItem("cartCount", String(getCartCountFromItems(items)));
    render();
  });

  render();
  refreshStockCache().then(() => render());

  function syncCheckoutButton() {
    if (!checkoutBtn) return;
    const loggedIn = isLoggedIn();
    checkoutBtn.textContent = loggedIn ? "Checkout" : "Log in to checkout";
  }

  checkoutBtn?.addEventListener("click", () => {
    if (!isLoggedIn()) {
      window.location.href = "login.html?redirect=order.html";
      return;
    }
    window.location.href = "order.html";
  });

  syncCheckoutButton();

  // Session lejárat miatt frissítsük az ár-megjelenítést.
  let lastLoggedIn = isLoggedIn();
  setInterval(() => {
    const nowLoggedIn = isLoggedIn();
    if (nowLoggedIn !== lastLoggedIn) {
      lastLoggedIn = nowLoggedIn;
      render();
      syncCheckoutButton();
    }
  }, 30000);
})();

// textarea auto resize
const textarea = document.querySelector('#note');

if (textarea) {
  textarea.addEventListener('input', function () {
    this.style.height = 'auto';
    this.style.height = this.scrollHeight + 'px';
  });
}
function getAuthHeaders() {
  if (window.Auth?.getAuthHeaders) {
    return window.Auth.getAuthHeaders();
  }
  const token = localStorage.getItem("token");
  return {
    "Content-Type": "application/json",
    "Authorization": "Bearer " + token
  };
}