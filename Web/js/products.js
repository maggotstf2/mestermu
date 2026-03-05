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
      <span>Összes</span>
      <ion-icon name="chevron-forward-outline"></ion-icon>
    </button>`,
    ...CATEGORY_ORDER.map(cat => `
      <button class="catbtn ${state.category === cat ? "is-active" : ""}" data-cat="${cat}">
        <span>${cat}</span>
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
      <span>${sub}</span>
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
    `<option value="">Összes</option>` +
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
    .filter(p => !state.inStock || p.stock > 0)
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
  elMeta().textContent = `${list.length} termék találat`;

  elGrid().innerHTML = list.map(p => `
    <article class="product-card">
      <div class="product-badges">
        <span class="pill">${p.category}</span>
        <span class="pill">${p.subCategory}</span>
        <span class="pill">${p.brand}</span>
      </div>

      <h3>${p.name}</h3>
      <p>${p.description || ""}</p>

      <div class="product-bottom">
        <div>
          <div class="product-price">${formatFt(p.price)}</div>
          <div>${p.stock > 0 ? "Készleten" : "Rendelhető"}</div>
        </div>
        <button class="btn btn--primary">Kosárba</button>
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

async function init() {
  const res = await fetch("./data/products.json");
  ALL_PRODUCTS = await res.json();

  buildCategoryList();
  buildSubCategoryList();
  rebuildBrandOptions();
  wireEvents();
  applyFilters();
}

init();