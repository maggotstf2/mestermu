/* =========================================================
   TORMA – products.js (DS-bolt jellegű lista + szűrők)
   ========================================================= */

let ALL_PRODUCTS = [];
const PRODUCT_IMAGE_STORAGE_KEY = "productImageById";
const PRODUCT_LIST_STATE_KEY = "productsListState";
const PRODUCT_IMAGE_FILES = [
  "products/Paradox proximity keypad + code.jpg",
  "products/Akuvox indoor audio unit.jpg",
  "products/Beninca parking barrier (keyed).jpg",
  "products/Paradox PIR motion detector (indoor).jpg",
  "products/Akuvox indoor monitor (10\").jpg",
  "products/Rosslare emergency release button (break glass).jpg",
  "products/LED reflektor 100W (IP65).jpg",
  "products/Inim isolator modul.jpg",
  "products/Paradox control panel 8 zone (expandable).jpg",
  "products/Camera mount (dome:turret).jpg",
  "products/Intercom rain shield.jpg",
  "products/Paradox LED keypad (keypad).jpg",
  "products/Wi‑Fi router (dual band) másolat.jpeg",
  "products/Came sliding gate kit (motor + 2 remote + photocell).jpg",
  "products/Outdoor siren strobeval.jpg",
  "products/Axis mikroSD card 128GB.png.webp",
  "products/Came shutter motor 40 Nm.jpg",
  "products/GSM communicator (alarm).jpg",
  "products/Hikvision turret camera (4MP) PoE.jpg",
  "products/Crimping pliers RJ45-hez.jpg",
  "products/UTP Cat6 cable (100 m) másolat.jpg",
  "products/Wi‑Fi router (dual band).jpeg",
  "products/APC power supply 12V 10A.jpg",
  "products/Akuvox standalone RFID reader + keypad.png",
  "products/Notifier siren strobeval (piros).jpg",
  "products/Nice parking barrier gate (3-4 m kar).jpg",
  "products/Bosch indoor sounder.jpg",
  "products/Paradox outdoor siren strobeval.jpg",
  "products/Uniview 4 camera PoE kit (NVR + cameras).jpg",
  "products/Generic maglock for gate 280 kg.jpg",
  "products/Hikvision FullColor camera (4MP).jpg.webp",
  "products/Fire-resistant cable (50 m).jpg",
  "products/BFT swing gate motor (2 leaf).png",
  "products/Hikvision DVR 16 channel (1080p).jpg",
  "products/Rosslare maglock kit for door.jpg",
  "products/Generic maglock 280 kg holding force.jpg",
  "products/Beninca maglock for gate.jpg",
  "products/HID auxreader, EM-Marine.jpg",
  "products/2N outdoor door station (1 apartment).jpg",
  "products/Fire-resistant cable 2x1.5 (50 m).jpg",
  "products/DSC microwave barrier gate (outdoor).jpg",
  "products/Bosch fire alarm panel 2 loop.jpg",
  "products/Pyronix hibrid control panel (wired + wireless).jpg",
  "products/Jablotron microwave barrier gate (outdoor).jpg",
  "products/Mean Well Surveillance HDD 1TB.jpg",
  "products/UTP Cat6 cable (100 m).jpg",
  "products/Wall plug + screw (50 db).jpg",
  "products/ZKTeco 2 door access control controller.png",
  "products/RFID key fob TAG (EM-Marine).jpg",
  "products/Gigabit switch (8 port).jpg",
  "products/Rack cabinet 9U wall-mount.jpg",
  "products/Honeywell heat detector.jpg",
  "products/Hikvision intercom kit (1 outdoor + 1 indoor).png",
  "products/Axis PTZ camera .jpg",
  "products/Gel battery 12V 26Ah.jpg",
  "products/Axis mikroSD card 128GB.png",
  "products/Gate opening push button.jpg",
];
const FALLBACK_PRODUCT_IMAGES = {
  "akuvox standalone rfid reader + keypad": "products/Akuvox standalone RFID reader + keypad.png",
  "hid auxiliary reader, em-marine": "products/HID auxreader, EM-Marine.jpg",
  "hid auxreader, em-marine": "products/HID auxreader, EM-Marine.jpg",
  "hid auxreader em-marine": "products/HID auxreader, EM-Marine.jpg",
  "jablotron microwave barrier gate (outdoor)": "products/Jablotron microwave barrier gate (outdoor).jpg",
  "jablotron microwave barrier (outdoor)": "products/Jablotron microwave barrier gate (outdoor).jpg",
  "paradox led keypad (keypad)": "products/Paradox LED keypad (keypad).jpg",
  "paradox led keypad (code keypad)": "products/Paradox LED keypad (keypad).jpg",
  "paradox pir motion detector (indoor)": "products/Paradox PIR motion detector (indoor).jpg",
  "paradox control panel 8 zone (expandable)": "products/Paradox control panel 8 zone (expandable).jpg",
  "paradox alarm control panel 8 zone (expandable)": "products/Paradox control panel 8 zone (expandable).jpg",
  "paradox outdoor siren strobeval": "products/Paradox outdoor siren strobeval.jpg",
  "paradox outdoor siren with strobe": "products/Paradox outdoor siren strobeval.jpg",
  "rfid key fob tag": "products/RFID key fob TAG (EM-Marine).jpg",
  "rfid key fob tag (em-marine)": "products/RFID key fob TAG (EM-Marine).jpg",
  "zkteco 2 door access control controller": "products/ZKTeco 2 door access control controller.png",
  "rosslare emergency release button (break glass)": "products/Rosslare emergency release button (break glass).jpg",
  "kamera konzol (dome/turret)": "products/Camera mount (dome:turret).jpg",
  "camera mount (dome:turret)": "products/Camera mount (dome:turret).jpg",
  "hikvision turret kamera (4mp) poe": "products/Hikvision turret camera (4MP) PoE.jpg",
  "hikvision turret camera (4mp) poe": "products/Hikvision turret camera (4MP) PoE.jpg",
  "hikvision dvr 16 channel (1080p)": "products/Hikvision DVR 16 channel (1080p).jpg",
  "generic electromagnetic lock 280 kg holding force": "products/Generic maglock 280 kg holding force.jpg",
  "generic maglock 280 kg holding force": "products/Generic maglock 280 kg holding force.jpg",
  "rosslare magnetic lock kit for door": "products/Rosslare maglock kit for door.jpg",
  "rosslare maglock kit for door": "products/Rosslare maglock kit for door.jpg",
  "uniview 4 camera poe kit (nvr + cameras)": "products/Uniview 4 camera PoE kit (NVR + cameras).jpg",
};

const $ = (sel) => document.querySelector(sel);

const elQ = () => $("#q");
const elSort = () => $("#sort");
const elGrid = () => $("#productsGrid");
const elMeta = () => $("#productsMeta");

const elCatList = () => $("#catList");
const elSubCatList = () => $("#subCatList");
const elBrand = () => $("#brand");
const elPriceMax = () => $("#priceMax");
const elClear = () => $("#clearFilters");
const elCategoriesDropdown = () => document.getElementById("categoriesDropdown");
const elAddToCartMsg = () => document.getElementById("addToCartMsg");

/* =======================
   FIX kategória struktúra
   ======================= */

const CATEGORY_TREE = {
  "Intrusion systems": ["Detectors", "Keypads", "Alarm panels", "Infra and microwave barriers", "Accessories"],
  "Access control": ["Controllers", "Standalone readers", "Slave readers", "Cards and tags", "Electromagnets", "Maglocks", "Accessories"],
  "CCTV": ["Cameras", "Recorders", "Kits", "Accessories", "Accessories"],
  "Gate automation": ["Motors", "Kits", "Barriers", "Parking blockers", "Electromagnets", "Shutter automation", "Accessories"],
  "Intercom": ["Indoor units", "Accessories", "Outdoor units", "Kits"],
  "Accessories": ["Batteries", "Network devices", "Sound and light signalers", "Communicators", "LED floodlights", "Hard drives", "Rack cabinets", "Supplies", "Tools", "Power supplies", "Cables"],
  "Fire alarms": ["Fire control panels", "Detectors", "Manual call points", "Sound and light signalers", "Accessories", "Fire cables", "Signs and logs"]
};

const HU_EN = {
  "Behatolásjelzők": "Intrusion systems",
  "Érzékelők": "Detectors",
  "Kezelők": "Keypads",
  "Riasztóközpontok": "Alarm panels",
  "Infra- és mikro sorompók": "Infra and microwave barriers",
  "Kiegészítők": "Accessories",
  "Beléptetők": "Access control",
  "Vezérlők": "Controllers",
  "Önálló olvasók": "Standalone readers",
  "Segédolvasók": "Slave readers",
  "Kártyák, tag-ek": "Cards and tags",
  "Síkmágnesek": "Electromagnets",
  "Mágneszárak": "Maglocks",
  "Kamerák": "Cameras",
  "Rögzítők": "Recorders",
  "Szettek": "Kits",
  "Tartozékok": "Accessories",
  "Kaputechnika": "Gate automation",
  "Motorok": "Motors",
  "Sorompók": "Barriers",
  "Parkolásgátlók": "Parking blockers",
  "Redőnymozgatás": "Shutter automation",
  "Kaputelefon": "Intercom",
  "Beltéri egységek": "Indoor units",
  "Kültéri egységek": "Outdoor units",
  "Akkumulátorok": "Batteries",
  "Hálózati eszközök": "Network devices",
  "Hang- fényjelzők": "Sound and light signalers",
  "Kommunikátorok": "Communicators",
  "LED reflektorok": "LED floodlights",
  "Merevlemezek": "Hard drives",
  "Rack szekrények": "Rack cabinets",
  "Segédanyagok": "Supplies",
  "Szerszámok": "Tools",
  "Tápegységek": "Power supplies",
  "Vezetékek": "Cables",
  "Tűzjelzők": "Fire alarms",
  "Tűzközpontok": "Fire control panels",
  "Kézi jelzésadók": "Manual call points",
  "Tűzkábelek": "Fire cables",
  "Táblák, naplók": "Signs and logs"
};

const tr = (s) => HU_EN[s] || s;

function translateProductText(value) {
  const text = String(value || "");
  if (!text) return "";
  const replacements = [
    [/mozgásérzékelő/gi, "motion detector"],
    [/kamera/gi, "camera"],
    [/beltéri/gi, "indoor"],
    [/kültéri/gi, "outdoor"],
    [/egység/gi, "unit"],
    [/tűzjelző/gi, "fire alarm"],
    [/központ/gi, "control panel"],
    [/riasztó/gi, "alarm"],
  ];

  return replacements.reduce((acc, [pattern, replacement]) => acc.replace(pattern, replacement), text);
}

const CATEGORY_ORDER = Object.keys(CATEGORY_TREE);

let state = {
  category: "",
  subCategory: "",
  brand: "",
  priceMax: "",
  q: "",
  sort: "relevance",
};

/* =======================
   Helpers
   ======================= */

const normalize = (s) => (s ?? "").toString().toLowerCase();
const uniq = (arr) => [...new Set(arr.filter(Boolean))];

function normalizeProductKey(value) {
  return String(value || "")
    .toLowerCase()
    .replace(/kamera/gi, "camera")
    .replace(/konzol/gi, "mount")
    .replace(/auxiliary/gi, "auxreader")
    .replace(/magnetic lock/gi, "maglock")
    .replace(/alarm control panel/gi, "control panel")
    .replace(/with strobe/gi, "strobeval")
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

function tokenizeProductKey(value) {
  return normalizeProductKey(value)
    .split(" ")
    .filter((part) => part && part.length > 1 && !["for", "with", "and", "the"].includes(part));
}

function getStoredProductImage(productId) {
  try {
    const raw = localStorage.getItem(PRODUCT_IMAGE_STORAGE_KEY);
    if (!raw) return "";
    const map = JSON.parse(raw);
    if (!map || typeof map !== "object") return "";
    return String(map[String(productId)] || "");
  } catch (err) {
    console.warn("Failed to parse product image map:", err);
    return "";
  }
}

function getFallbackProductImage(productName) {
  const directKey = String(productName || "").trim().toLowerCase();
  if (FALLBACK_PRODUCT_IMAGES[directKey]) return FALLBACK_PRODUCT_IMAGES[directKey];

  const normalizedInput = normalizeProductKey(productName);
  if (!normalizedInput) return "";

  for (const [alias, imagePath] of Object.entries(FALLBACK_PRODUCT_IMAGES)) {
    if (normalizeProductKey(alias) === normalizedInput) {
      return imagePath;
    }
  }

  const productTokens = tokenizeProductKey(productName);
  if (!productTokens.length) return "";
  let bestScore = 0;
  let bestPath = "";
  for (const imagePath of PRODUCT_IMAGE_FILES) {
    const fileName = imagePath.split("/").pop() || imagePath;
    const fileTokens = new Set(tokenizeProductKey(fileName));
    if (!fileTokens.size) continue;
    let matched = 0;
    for (const token of productTokens) {
      if (fileTokens.has(token)) matched += 1;
    }
    const score = matched / Math.max(productTokens.length, 1);
    if (score > bestScore) {
      bestScore = score;
      bestPath = imagePath;
    }
  }
  if (bestScore >= 0.5) return bestPath;
  return "";
}

function saveListScrollState() {
  try {
    sessionStorage.setItem(
      PRODUCT_LIST_STATE_KEY,
      JSON.stringify({
        y: window.scrollY || window.pageYOffset || 0,
        ts: Date.now(),
      }),
    );
  } catch (err) {
    console.warn("Failed to save product list scroll position:", err);
  }
}

function restoreListScrollState() {
  try {
    const raw = sessionStorage.getItem(PRODUCT_LIST_STATE_KEY);
    if (!raw) return;
    const parsed = JSON.parse(raw);
    const y = Number(parsed?.y);
    const ts = Number(parsed?.ts);
    if (!Number.isFinite(y) || !Number.isFinite(ts)) return;
    if (Date.now() - ts > 10 * 60 * 1000) {
      sessionStorage.removeItem(PRODUCT_LIST_STATE_KEY);
      return;
    }
    requestAnimationFrame(() => {
      window.scrollTo(0, Math.max(0, y));
      sessionStorage.removeItem(PRODUCT_LIST_STATE_KEY);
    });
  } catch (err) {
    console.warn("Failed to restore product list scroll position:", err);
  }
}

function formatFt(n) {
  return (Number(n) || 0).toLocaleString("hu-HU") + " Ft";
}

function decodeHash() {
  return normalize(decodeURIComponent((location.hash || "").replace("#", "")));
}

/* =======================
   Kategória lista
   ======================= */

function buildCategoryList() {
  const html = [
    `<button class="catbtn ${state.category ? "" : "is-active"}" data-cat="">
      <span>All</span>
      <ion-icon name="chevron-forward-outline"></ion-icon>
    </button>`,
    ...CATEGORY_ORDER.map(cat => `
      <button class="catbtn ${state.category === cat ? "is-active" : ""}" data-cat="${cat}">
        <span>${tr(cat)}</span>
        <ion-icon name="chevron-forward-outline"></ion-icon>
      </button>
    `)
  ].join("");

  elCatList().innerHTML = html;

  elCatList().onclick = (e) => {
    const btn = e.target.closest(".catbtn");
    if (!btn) return;

    state.category = btn.dataset.cat || "";
    state.subCategory = "";

    buildCategoryList();
    buildSubCategoryList();
    rebuildBrandOptions();
    applyFilters();
  };
}

function buildSubCategoryList() {
  if (!state.category) {
    elSubCatList().innerHTML = "";
    return;
  }

  const subs = CATEGORY_TREE[state.category] || [];

  elSubCatList().innerHTML = subs.map(sub => `
    <button class="subbtn ${state.subCategory === sub ? "is-active" : ""}" data-sub="${sub}">
      <span>${tr(sub)}</span>
      <ion-icon name="chevron-forward-outline"></ion-icon>
    </button>
  `).join("");

  elSubCatList().onclick = (e) => {
    const btn = e.target.closest(".subbtn");
    if (!btn) return;

    state.subCategory = btn.dataset.sub;
    buildSubCategoryList();
    rebuildBrandOptions();
    applyFilters();
  };
}

/* =======================
   Brand select
   ======================= */

function rebuildBrandOptions() {
  const list = ALL_PRODUCTS
    .filter(p => p.active)
    .filter(p => !state.category || p.category === state.category)
    .filter(p => !state.subCategory || p.subCategory === state.subCategory);

  const brands = uniq(list.map(p => p.brand)).sort((a,b)=>a.localeCompare(b,"hu"));

  elBrand().innerHTML =
    `<option value="">All</option>` +
    brands.map(b => `<option value="${b}">${b}</option>`).join("");

  state.brand = "";
}

/* =======================
   Szűrés
   ======================= */

function applyFilters() {
  const q = normalize(state.q);
  const hash = decodeHash();

  let list = ALL_PRODUCTS
    .filter(p => p.active)
    .filter(p => !state.category || p.category === state.category)
    .filter(p => !state.subCategory || p.subCategory === state.subCategory)
    .filter(p => !state.brand || p.brand === state.brand)
    .filter(p => !state.priceMax || p.price <= Number(state.priceMax));

  if (q) {
    list = list.filter(p =>
      normalize(
        p.name + " " +
        p.brand + " " +
        p.category + " " +
        p.subCategory + " " +
        (p.description || "") + " " +
        (p.tags || []).join(" ")
      ).includes(q)
    );
  }

  if (hash) {
    list = list.filter(p =>
      normalize(
        p.name + " " +
        p.brand + " " +
        p.category + " " +
        p.subCategory + " " +
        (p.tags || []).join(" ")
      ).includes(hash)
    );
  }

  if (state.sort === "priceAsc") list.sort((a,b)=>a.price-b.price);
  if (state.sort === "priceDesc") list.sort((a,b)=>b.price-a.price);
  if (state.sort === "nameAsc") list.sort((a,b)=>a.name.localeCompare(b.name,"hu"));

  render(list);
}

/* =======================
   Render
   ======================= */

function render(list) {
  const loggedIn = window.Auth?.isLoggedIn?.() ?? false;
  elMeta().textContent = `${list.length} product results`;

  elGrid().innerHTML = list.map(p => `
    <article class="product-card" data-product-id="${p.id}">
      ${
        p.imageUrl
          ? `<div class="product-card__image"><img src="${p.imageUrl}" alt="${translateProductText(p.name)}"></div>`
          : ""
      }
      <div class="product-badges">
        <span class="pill">${tr(p.category)}</span>
        <span class="pill">${tr(p.subCategory)}</span>
        <span class="pill">${p.brand}</span>
      </div>

      <h3 class="product-title">${translateProductText(p.name)}</h3>
      <p class="product-desc">${p.description || ""}</p>

      <div class="product-bottom">
        <div>
          <div class="product-price">${
            loggedIn
              ? formatFt(p.price)
              : '<a href="login.html" class="small">Log in to see prices</a>'
          }</div>
        </div>
        <div style="display:flex; gap:8px; align-items:center; flex-wrap:wrap; justify-content:flex-end;">
          <button class="btn btn--primary" type="button" data-add-to-cart ${Number(p.stock) > 0 ? "" : "disabled"}>
            ${Number(p.stock) > 0 ? "Add to cart" : "Out of stock"}
          </button>
        </div>
      </div>
    </article>
  `).join("");
}

/* =======================
   Events + Init
   ======================= */

function wireEvents() {
  elQ().addEventListener("input", () => {
    state.q = elQ().value;
    applyFilters();
  });

  elSort().addEventListener("change", () => {
    state.sort = elSort().value;
    applyFilters();
  });

  elBrand().addEventListener("change", () => {
    state.brand = elBrand().value;
    applyFilters();
  });

  elPriceMax().addEventListener("input", () => {
    state.priceMax = elPriceMax().value;
    applyFilters();
  });

  // Kosár gombok (event delegáció a productsGrid-en)
  elGrid().addEventListener("click", (e) => {
    const card = e.target.closest("[data-product-id]");
    if (!card) return;

    const btn = e.target.closest("[data-add-to-cart]");
    const pid = card.getAttribute("data-product-id");
    const product = ALL_PRODUCTS.find((p) => String(p.id) === String(pid));
    if (!product) return;

    if (btn) {
      if (window.__addToCart) {
        window.__addToCart(product);
      }
      return;
    }

    saveListScrollState();
    window.location.href = `product.html?id=${encodeURIComponent(product.id)}`;
  });

  elClear().addEventListener("click", () => {
    state = {
      category: "",
      subCategory: "",
      brand: "",
      priceMax: "",
      q: "",
      sort: "relevance"
    };

    buildCategoryList();
    buildSubCategoryList();
    rebuildBrandOptions();
    applyFilters();
  });

  window.addEventListener("hashchange", applyFilters);
}

function showAddToCartMessage(productName) {
  if (window.showCartBubble) {
    window.showCartBubble(`${productName} added to cart.`, "ok", 2200);
    return;
  }
  const el = elAddToCartMsg();
  if (!el) return;
  el.textContent = `${productName} added to cart.`;
  clearTimeout(showAddToCartMessage._timer);
  showAddToCartMessage._timer = setTimeout(() => {
    el.textContent = "";
  }, 2200);
}

function wireCategoryDropdown() {
  const container = elCategoriesDropdown();
  if (!container) return;

  const title = container.querySelector(".shop__title");
  if (!title) return;

  // Hoverre kinyílik
  title.addEventListener("mouseenter", () => {
    container.classList.add("is-open");
  });

  container.addEventListener("mouseleave", () => {
    container.classList.remove("is-open");
  });

  // Kattintásra nyitva marad / záródik
  title.addEventListener("click", (e) => {
    e.preventDefault();
    container.classList.toggle("is-open");
  });
}

async function init() {
  const API_BASE = "http://localhost:8000";

  function toFrontendProduct(p) {
    const tags = [p.tag1, p.tag2].filter(Boolean);
    return {
      id: p.id,
      name: p.name,
      brand: p.brand,
      category: p.cat,
      subCategory: p.subcat,
      tags: tags,
      price: p.price,
      stock: p.quantity,
      active: true,
      description: translateProductText(p.description || ""),
      imageUrl: getStoredProductImage(p.id) || p.image_url || getFallbackProductImage(p.name),
    };
  }

  const res = await fetch(`${API_BASE}/products/all`);
  const data = await res.json();
  if (!data.success) {
    throw new Error(data.message || "Failed to load products");
  }

  ALL_PRODUCTS = (data.items || []).map(toFrontendProduct);

  buildCategoryList();
  buildSubCategoryList();
  rebuildBrandOptions();
  wireEvents();
  applyFilters();
  restoreListScrollState();
}

init();
