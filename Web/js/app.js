// Active nav link + mobile drawer + cart badge
const path = location.pathname.split("/").pop() || "index.html";

document.querySelectorAll("[data-nav-link]").forEach((a) => {
  const href = a.getAttribute("href");
  if (href === path) a.classList.add("is-active");
});

const burger = document.querySelector("#burger");
const drawer = document.querySelector("#drawer");
const drawerClose = document.querySelector("#drawerClose");

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

  if (id == null) {
    // visszaesés: csak darabszám növelés, ha valamiért nincs termék
    const fallbackNext = Number(localStorage.getItem("cartCount") || "0") + 1;
    localStorage.setItem("cartCount", String(fallbackNext));
    badgeEls.forEach((el) => (el.textContent = String(fallbackNext)));
    return;
  }

  const idx = items.findIndex((it) => String(it.id) === String(id));
  if (idx >= 0) {
    items[idx].qty = (Number(items[idx].qty) || 0) + 1;
  } else {
    items.push({
      id: product.id,
      name: product.name,
      price: product.price,
      brand: product.brand,
      category: product.category,
      subCategory: product.subCategory,
      qty: 1,
    });
  }

  saveCartItems(items);

  const nextCount = getCartCountFromItems(items);
  localStorage.setItem("cartCount", String(nextCount));
  badgeEls.forEach((el) => (el.textContent = String(nextCount)));
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

// =========================
// Booking (contact.html) – demo (localStorage)
// =========================
(function initBooking(){
  const form = document.querySelector("#bookingForm");
  if (!form) return;

  const serviceEl = document.querySelector("#service");
  const dateEl = document.querySelector("#date");
  const timeEl = document.querySelector("#time");
  const locationEl = document.querySelector("#locationType");
  const nameEl = document.querySelector("#name");
  const phoneEl = document.querySelector("#phone");
  const emailEl = document.querySelector("#email");
  const cityEl = document.querySelector("#city");
  const noteEl = document.querySelector("#note");
  const summaryEl = document.querySelector("#summary");
  const listEl = document.querySelector("#bookingsList");
  const msgEl = document.querySelector("#formMsg");
  const clearBtn = document.querySelector("#clearBookings");

  const DRAFT_KEY = "bookingDraft";

  const today = new Date();
  const tomorrow = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1);
  dateEl.min = toISODate(tomorrow);

  function generateSlots(){
    const slots = [];
    for (let h = 9; h <= 16; h++){
      slots.push(`${pad(h)}:00`);
      slots.push(`${pad(h)}:30`);
    }
    slots.push("17:00");
    return slots;
  }

  function loadBookings(){
    try { return JSON.parse(localStorage.getItem("bookings") || "[]"); }
    catch { return []; }
  }
  function saveBookings(arr){ localStorage.setItem("bookings", JSON.stringify(arr)); }

  function loadDraft(){
    try { return JSON.parse(localStorage.getItem(DRAFT_KEY) || "null"); }
    catch { return null; }
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
      city: cityEl ? (cityEl.value || "") : "",
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

    const taken = new Set(loadBookings().filter(b => b.date === d).map(b => b.time));
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
    const items = loadBookings().sort((a,b) => (a.date + a.time).localeCompare(b.date + b.time));
    if (items.length === 0){
      listEl.textContent = "No bookings yet.";
      return;
    }

    listEl.innerHTML = items.map((b, idx) => `
      <div class="card p" style="box-shadow:none; margin-bottom:12px;">
        <div style="font-weight:950;">${escapeHtml(b.service)}</div>
        <div class="muted">${escapeHtml(b.date)} • ${escapeHtml(b.time)} • ${escapeHtml(b.locationType)}</div>
        <div class="muted" style="margin-top:6px;">${escapeHtml(b.name)} • ${escapeHtml(b.phone)} • ${escapeHtml(b.email)}</div>
        ${b.city ? `<div class="small muted">City: ${escapeHtml(b.city)}</div>` : ""}
        ${b.note ? `<div class="small muted">Note: ${escapeHtml(b.note)}</div>` : ""}
        <div style="margin-top:10px;">
          <button class="btn" type="button" data-del="${idx}">Delete</button>
        </div>
      </div>
    `).join("");
  }

  dateEl.addEventListener("change", () => {
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

  [nameEl, phoneEl, emailEl, cityEl, noteEl].forEach(el => {
    el?.addEventListener("input", saveDraftFromForm);
  });

  listEl.addEventListener("click", (e) => {
    const btn = e.target.closest("[data-del]");
    if (!btn) return;
    const idx = Number(btn.getAttribute("data-del"));
    const arr = loadBookings();
    arr.splice(idx, 1);
    saveBookings(arr);
    renderBookings();
    refreshTimeOptions();
    msgEl.textContent = "Booking deleted (demo).";
  });

  clearBtn.addEventListener("click", () => {
    localStorage.removeItem("bookings");
    renderBookings();
    refreshTimeOptions();
    msgEl.textContent = "All bookings deleted (demo).";
  });

  form.addEventListener("submit", (e) => {
    e.preventDefault();
    msgEl.textContent = "";

    if (!serviceEl.value || !dateEl.value || !timeEl.value || !locationEl.value){
      msgEl.textContent = "Please choose a service, date and time.";
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
      city: cityEl.value.trim(),
      note: noteEl.value.trim(),
      createdAt: new Date().toISOString()
    };

    if (!booking.name || !booking.phone || !booking.email){
      msgEl.textContent = "Name, phone and email are required.";
      return;
    }

    const arr = loadBookings();
    if (arr.some(b => b.date === booking.date && b.time === booking.time)){
      msgEl.textContent = "This time slot is already booked. Please choose another.";
      refreshTimeOptions();
      return;
    }

    arr.push(booking);
    saveBookings(arr);

    clearDraft();

    form.reset();
    refreshTimeOptions();
    renderBookings();
    updateSummary();

    msgEl.textContent = "Booking successful (demo) ✅";
  });

  const existingDraft = loadDraft();
  if (existingDraft){
    if (existingDraft.service) serviceEl.value = existingDraft.service;
    if (existingDraft.date) dateEl.value = existingDraft.date;
    if (existingDraft.locationType) locationEl.value = existingDraft.locationType;
    if (existingDraft.name && nameEl) nameEl.value = existingDraft.name;
    if (existingDraft.phone && phoneEl) phoneEl.value = existingDraft.phone;
    if (existingDraft.email && emailEl) emailEl.value = existingDraft.email;
    if (existingDraft.city && cityEl) cityEl.value = existingDraft.city;
    if (existingDraft.note) noteEl.value = existingDraft.note;
  }

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
  const emptyText = "Your cart is currently empty.";

  function formatFt(n) {
    return (Number(n) || 0).toLocaleString("hu-HU") + " Ft";
  }

  function updateBadge() {
    const items = loadCartItems();
    const count = getCartCountFromItems(items);
    badgeEls.forEach((el) => (el.textContent = String(count)));
  }

  function render() {
    const items = loadCartItems();

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
            <div class="small muted">Quantity: ${it.qty} pcs</div>
            <div class="small muted">Unit price: ${formatFt(it.price)}</div>
          </div>
          <div style="font-weight:950;">${formatFt(
            (Number(it.price) || 0) * (Number(it.qty) || 0),
          )}</div>
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
      summaryEl.innerHTML = `
        <div class="small muted">Subtotal: <strong>${formatFt(
          subtotal,
        )}</strong></div>
        <div class="small muted">Shipping (demo): <strong>${formatFt(
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

  render();
})();

// textarea auto resize
const textarea = document.querySelector('#note');

if (textarea) {
  textarea.addEventListener('input', function () {
    this.style.height = 'auto';
    this.style.height = this.scrollHeight + 'px';
  });
}