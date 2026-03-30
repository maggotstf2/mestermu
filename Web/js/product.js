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
      stock: p.quantity,
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
      : `<div class="product-image-placeholder">Product image placeholder (upload later)</div>`;

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
            <span class="pill">${esc(product.category)}</span>
            <span class="pill">${esc(product.subCategory)}</span>
            <span class="pill">${esc(product.brand)}</span>
          </div>

          <h1 class="product-landing__title">${esc(product.name)}</h1>
          <p class="product-landing__desc">${esc(product.description || "No description yet.")}</p>

          <div class="product-landing__meta">
            <div><strong>Stock:</strong> ${product.stock > 0 ? "In stock" : "Available to order"}</div>
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
