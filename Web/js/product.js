/* =========================================================
   TORMA - product.js (single product landing)
   ========================================================= */

(function initProductLanding() {
  const API_BASE = "http://localhost:8000";
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
      const normalizedAlias = normalizeProductKey(alias);
      if (normalizedAlias === normalizedInput) return imagePath;
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

  function wireBackToProductsLink() {
    const backLink = document.getElementById("backToProductsLink");
    if (!backLink) return;

    backLink.addEventListener("click", (e) => {
      const fromProducts = /\/products\.html(?:[?#]|$)/i.test(document.referrer || "");
      if (fromProducts && window.history.length > 1) {
        e.preventDefault();
        window.history.back();
        return;
      }
      try {
        sessionStorage.setItem(
          PRODUCT_LIST_STATE_KEY,
          JSON.stringify({ y: 0, ts: Date.now() }),
        );
      } catch {}
    });
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
      stock: Number(p.quantity) || 0,
      imageUrl: getStoredProductImage(p.id) || p.image_url || getFallbackProductImage(p.name),
    };
  }

  function renderMissingId() {
    landing.innerHTML = `
      <h2 style="margin-top:0;">Product not selected</h2>
      <p class="muted">Missing query parameter: <code>id</code>.</p>
      <a class="btn btn--primary" id="backToProductsLink" href="products.html">Back to products</a>
    `;
    wireBackToProductsLink();
  }

  function renderError(message) {
    landing.innerHTML = `
      <h2 style="margin-top:0;">Unable to load product</h2>
      <p class="muted">${esc(message || "Unknown error")}</p>
      <a class="btn btn--primary" id="backToProductsLink" href="products.html">Back to products</a>
    `;
    wireBackToProductsLink();
  }

  function renderProduct(product) {
    const loggedIn = window.Auth?.isLoggedIn?.() ?? false;
    const imageContent = product.imageUrl
      ? `<img src="${esc(product.imageUrl)}" alt="${esc(product.name)}">`
      : `<div class="product-image-placeholder">[ Product image placeholder ]</div>`;

    landing.innerHTML = `
      <div class="product-landing__head">
        <a class="btn" id="backToProductsLink" href="products.html">Back to products</a>
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
            <button class="btn btn--primary" type="button" id="addToCartBtn" ${product.stock > 0 ? "" : "disabled"}>
              ${product.stock > 0 ? "Add to cart" : "Out of stock"}
            </button>
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
    wireBackToProductsLink();
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
