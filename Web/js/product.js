/* =========================================================
   TORMA - product.js (single product landing)
   ========================================================= */

(function initProductLanding() {
  const API_BASE = "http://localhost:8000";
  const landing = document.getElementById("productLanding");
  if (!landing) return;

  const productId = new URLSearchParams(window.location.search).get("id");

  function formatFt(n) {
    return (Number(n) || 0).toLocaleString("hu-HU") + " Ft";
  }

  function esc(v) {
    return String(v ?? "").replace(/[&<>"']/g, (ch) => {
      if (ch === "&") return "&amp;";
      if (ch === "<") return "&lt;";
      if (ch === ">") return "&gt;";
      if (ch === '"') return "&quot;";
      return "&#39;";
    });
  }

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
    "Táblák, naplók": "Signs and logs",
  };

  function tr(v) {
    return HU_EN[v] || v;
  }

  function mapApiProduct(p) {
    return {
      id: p.id,
      name: p.name,
      brand: p.brand,
      category: p.cat,
      subCategory: p.subcat,
      description: p.description || "",
      tag1: p.tag1 || "",
      tag2: p.tag2 || "",
      price: p.price,
      imageUrl: p.image_url || "",
    };
  }

  function renderMissingId() {
    landing.innerHTML = `
      <h2 style="margin-top:0;">Product not selected</h2>
      <p class="muted">Missing query parameter: <code>id</code>.</p>
      <a class="btn btn--primary" href="products.html">Back to products</a>
    `;
  }

  function renderError(message) {
    landing.innerHTML = `
      <h2 style="margin-top:0;">Unable to load product</h2>
      <p class="muted">${esc(message || "Unknown error")}</p>
      <a class="btn btn--primary" href="products.html">Back to products</a>
    `;
  }

  function renderProduct(product) {
    const loggedIn = window.Auth?.isLoggedIn?.() ?? false;
    const imageContent = product.imageUrl
      ? `<img src="${esc(product.imageUrl)}" alt="${esc(product.name)}">`
      : `<div class="product-image-placeholder">[ Product image placeholder ]</div>`;

    landing.innerHTML = `
      <div class="product-landing__head">
        <a class="btn" href="products.html">Back to products</a>
      </div>

      <div class="product-landing__grid">
        <section>
          <div class="product-image-box">
            ${imageContent}
          </div>
        </section>

        <section>
          <div class="product-badges">
            <span class="pill">${esc(tr(product.category))}</span>
            <span class="pill">${esc(tr(product.subCategory))}</span>
            <span class="pill">${esc(product.brand)}</span>
          </div>

          <h1 class="product-landing__title">${esc(translateProductText(product.name))}</h1>
          <p class="product-landing__desc">${esc(translateProductText(product.description || "No description yet."))}</p>

          <div class="product-landing__meta">
            <div><strong>Tag 1:</strong> ${esc(product.tag1 || "-")}</div>
            <div><strong>Tag 2:</strong> ${esc(product.tag2 || "-")}</div>
          </div>

          <div class="product-landing__actions">
            <div class="product-landing__price">${
              loggedIn
                ? formatFt(product.price)
                : '<a href="login.html" class="small">Log in to see prices</a>'
            }</div>
            <button class="btn btn--primary" type="button" id="addToCartBtn">Add to cart</button>
          </div>
        </section>
      </div>
    `;

    const addBtn = document.getElementById("addToCartBtn");
    addBtn?.addEventListener("click", () => {
      if (window.__addToCart) {
        window.__addToCart(product);
      }
    });
  }

  async function loadProduct() {
    if (!productId) {
      renderMissingId();
      return;
    }

    try {
      const res = await fetch(`${API_BASE}/products/${encodeURIComponent(productId)}`);
      const data = await res.json();
      if (!res.ok || !data.success || !data.product) {
        throw new Error(data?.message || "Product not found");
      }

      renderProduct(mapApiProduct(data.product));
    } catch (err) {
      renderError(err?.message || "Failed to load product");
    }
  }

  loadProduct();
})();
