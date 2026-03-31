/* =========================================================
   TORMA – products.js (DS-bolt jellegű lista + szűrők)
   ========================================================= */

let ALL_PRODUCTS = [];

const $ = (sel) => document.querySelector(sel);

const elQ = () => $("#q");
const elSort = () => $("#sort");
const elGrid = () => $("#productsGrid");
const elMeta = () => $("#productsMeta");

const elCatList = () => $("#catList");
const elSubCatList = () => $("#subCatList");
const elBrand = () => $("#brand");
const elInStock = () => $("#inStock");
const elPriceMax = () => $("#priceMax");
const elClear = () => $("#clearFilters");
const elCategoriesDropdown = () => document.getElementById("categoriesDropdown");
const elAddToCartMsg = () => document.getElementById("addToCartMsg");

/* =======================
   FIX kategória struktúra
   ======================= */

const CATEGORY_TREE = {
  "Behatolásjelzők": ["Érzékelők", "Kezelők", "Riasztóközpontok", "Infra- és mikro sorompók", "Kiegészítők"],
  "Beléptetők": ["Vezérlők", "Önálló olvasók", "Segédolvasók", "Kártyák, tag-ek", "Síkmágnesek", "Mágneszárak", "Kiegészítők"],
  "CCTV": ["Kamerák", "Rögzítők", "Szettek", "Tartozékok", "Kiegészítők"],
  "Kaputechnika": ["Motorok", "Szettek", "Sorompók", "Parkolásgátlók", "Síkmágnesek", "Redőnymozgatás", "Kiegészítők"],
  "Kaputelefon": ["Beltéri egységek", "Kiegészítők", "Kültéri egységek", "Szettek"],
  "Kiegészítők": ["Akkumulátorok", "Hálózati eszközök", "Hang- fényjelzők", "Kommunikátorok", "LED reflektorok", "Merevlemezek", "Rack szekrények", "Segédanyagok", "Szerszámok", "Tápegységek", "Vezetékek"],
  "Tűzjelzők": ["Tűzközpontok", "Érzékelők", "Kézi jelzésadók", "Hang- fényjelzők", "Kiegészítők", "Tűzkábelek", "Táblák, naplók"]
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
  inStock: false,
  priceMax: "",
  q: "",
  sort: "relevance",
};

/* =======================
   Helpers
   ======================= */

const normalize = (s) => (s ?? "").toString().toLowerCase();
const uniq = (arr) => [...new Set(arr.filter(Boolean))];

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
    .filter(p => !state.inStock || (p.inStock && p.stock > 0))
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
          <div class="stock">${p.inStock && p.stock > 0 ? "In stock" : "Out of stock"}</div>
        </div>
        <div style="display:flex; gap:8px; align-items:center; flex-wrap:wrap; justify-content:flex-end;">
          <a class="btn" href="product.html?id=${encodeURIComponent(p.id)}">Details</a>
          <button class="btn btn--primary" type="button" data-add-to-cart>Add to cart</button>
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

  elInStock().addEventListener("change", () => {
    state.inStock = elInStock().checked;
    applyFilters();
  });

  elPriceMax().addEventListener("input", () => {
    state.priceMax = elPriceMax().value;
    applyFilters();
  });

  // Kosár gombok (event delegáció a productsGrid-en)
  elGrid().addEventListener("click", (e) => {
    const btn = e.target.closest("[data-add-to-cart]");
    if (!btn) return;

    const card = btn.closest("[data-product-id]");
    const pid = card?.getAttribute("data-product-id");
    const product = ALL_PRODUCTS.find(p => String(p.id) === String(pid));

    if (window.__addToCart) {
      window.__addToCart(product);
      showAddToCartMessage(translateProductText(product?.name || "Product"));
    }
  });

  elClear().addEventListener("click", () => {
    state = {
      category: "",
      subCategory: "",
      brand: "",
      inStock: false,
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
  const el = elAddToCartMsg();
  if (!el) return;
  el.textContent = `${productName} added to cart successfully.`;
  el.style.color = "var(--ok)";
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
      inStock: Boolean(p.in_stock),
      // A UI-hoz a demóban minden termék "active" volt.
      // Itt inkább mindig engedjük a megjelenítést, a "In stock" checkbox külön szűr.
      active: true,
      description: translateProductText(p.description || ""),
      imageUrl: p.image_url || "",
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
}

init();
