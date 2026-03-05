// Active nav link + mobile drawer + cart badge
const path = location.pathname.split("/").pop() || "index.html";

document.querySelectorAll('[data-nav-link]').forEach(a => {
  const href = a.getAttribute("href");
  if (href === path) a.classList.add("is-active");
});

const burger = document.querySelector("#burger");
const drawer = document.querySelector("#drawer");
const drawerClose = document.querySelector("#drawerClose");

function toggleDrawer(open){
  if (!drawer) return;
  if (open) drawer.classList.add("is-open");
  else drawer.classList.remove("is-open");
}
burger?.addEventListener("click", () => toggleDrawer(!drawer.classList.contains("is-open")));
drawerClose?.addEventListener("click", () => toggleDrawer(false));
drawer?.addEventListener("click", (e) => { if (e.target.matches("a")) toggleDrawer(false); });

const badgeEls = document.querySelectorAll("[data-cart-badge]");
const cartCount = Number(localStorage.getItem("cartCount") || "0");
badgeEls.forEach(el => el.textContent = String(cartCount));

window.__addToCart = function(){
  const next = Number(localStorage.getItem("cartCount") || "0") + 1;
  localStorage.setItem("cartCount", String(next));
  badgeEls.forEach(el => el.textContent = String(next));
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

  function refreshTimeOptions(){
    const d = dateEl.value;
    timeEl.innerHTML = "";
    if (!d){
      timeEl.innerHTML = `<option value="" selected disabled>Előbb válassz dátumot…</option>`;
      updateSummary();
      return;
    }

    const taken = new Set(loadBookings().filter(b => b.date === d).map(b => b.time));
    const opts = generateSlots().map(t => {
      const disabled = taken.has(t) ? "disabled" : "";
      const label = taken.has(t) ? `${t} (foglalt)` : t;
      return `<option value="${t}" ${disabled}>${label}</option>`;
    }).join("");

    timeEl.innerHTML = `<option value="" selected disabled>Válassz időt…</option>` + opts;
    updateSummary();
  }

  function updateSummary(){
    const s = serviceEl.value || "—";
    const d = dateEl.value || "—";
    const t = timeEl.value || "—";
    const loc = locationEl.value || "—";

    summaryEl.innerHTML = `
      <div><strong>Szolgáltatás:</strong> ${escapeHtml(s)}</div>
      <div><strong>Dátum:</strong> ${escapeHtml(d)}</div>
      <div><strong>Idő:</strong> ${escapeHtml(t)}</div>
      <div><strong>Helyszín:</strong> ${escapeHtml(loc)}</div>
    `;
  }

  function renderBookings(){
    const items = loadBookings().sort((a,b) => (a.date + a.time).localeCompare(b.date + b.time));
    if (items.length === 0){
      listEl.textContent = "Még nincs foglalás.";
      return;
    }

    listEl.innerHTML = items.map((b, idx) => `
      <div class="card p" style="box-shadow:none; margin-bottom:12px;">
        <div style="font-weight:950;">${escapeHtml(b.service)}</div>
        <div class="muted">${escapeHtml(b.date)} • ${escapeHtml(b.time)} • ${escapeHtml(b.locationType)}</div>
        <div class="muted" style="margin-top:6px;">${escapeHtml(b.name)} • ${escapeHtml(b.phone)} • ${escapeHtml(b.email)}</div>
        ${b.city ? `<div class="small muted">Város: ${escapeHtml(b.city)}</div>` : ""}
        ${b.note ? `<div class="small muted">Megjegyzés: ${escapeHtml(b.note)}</div>` : ""}
        <div style="margin-top:10px;">
          <button class="btn" type="button" data-del="${idx}">Törlés</button>
        </div>
      </div>
    `).join("");
  }

  dateEl.addEventListener("change", refreshTimeOptions);
  timeEl.addEventListener("change", updateSummary);
  serviceEl.addEventListener("change", updateSummary);
  locationEl.addEventListener("change", updateSummary);

  listEl.addEventListener("click", (e) => {
    const btn = e.target.closest("[data-del]");
    if (!btn) return;
    const idx = Number(btn.getAttribute("data-del"));
    const arr = loadBookings();
    arr.splice(idx, 1);
    saveBookings(arr);
    renderBookings();
    refreshTimeOptions();
    msgEl.textContent = "Foglalás törölve (demo).";
  });

  clearBtn.addEventListener("click", () => {
    localStorage.removeItem("bookings");
    renderBookings();
    refreshTimeOptions();
    msgEl.textContent = "Összes foglalás törölve (demo).";
  });

  form.addEventListener("submit", (e) => {
    e.preventDefault();
    msgEl.textContent = "";

    if (!serviceEl.value || !dateEl.value || !timeEl.value || !locationEl.value){
      msgEl.textContent = "Kérlek válassz szolgáltatást, dátumot és időpontot.";
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
      msgEl.textContent = "Név, telefonszám és e-mail kötelező.";
      return;
    }

    const arr = loadBookings();
    if (arr.some(b => b.date === booking.date && b.time === booking.time)){
      msgEl.textContent = "Ez az időpont már foglalt. Válassz másikat.";
      refreshTimeOptions();
      return;
    }

    arr.push(booking);
    saveBookings(arr);

    form.reset();
    refreshTimeOptions();
    renderBookings();
    updateSummary();

    msgEl.textContent = "Sikeres foglalás (demo) ✅";
  });

  refreshTimeOptions();
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

function setTheme(mode){
  if(mode === "dark"){
    document.body.classList.add("dark");
    localStorage.setItem("theme", "dark");
    themeBtn?.querySelector("i")?.classList.replace("bi-brightness-high","bi-moon-stars");
  } else {
    document.body.classList.remove("dark");
    localStorage.setItem("theme", "light");
    themeBtn?.querySelector("i")?.classList.replace("bi-moon-stars","bi-brightness-high");
  }
}

// Betöltéskor nézzük meg mit választott a user
const savedTheme = localStorage.getItem("theme");
if(savedTheme){
  setTheme(savedTheme);
}

// Kattintás
themeBtn?.addEventListener("click", () => {
  const isDark = document.body.classList.contains("dark");
  setTheme(isDark ? "light" : "dark");
});