const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });

async function getJson(url, options) {
  const response = await fetch(url, options);
  return response.json();
}

function showBasket(basket) {
  const count = basket.lines.reduce((n, line) => n + line.qty, 0);
  document.querySelector('[data-testid=basket-count]').textContent = count;
  document.querySelector('.basket-total').textContent = money.format(basket.total / 100);
}

function card(product) {
  const li = document.createElement('li');
  li.className = 'card';
  // A known flaw, on purpose: the id changes every time the page loads.
  li.id = 'card-' + Math.floor(Math.random() * 10000);
  li.dataset.testid = 'product-' + product.id;
  li.innerHTML = `<h2>${product.name}</h2>
    <p class="price">${money.format(product.price / 100)} <small>/ ${product.unit}</small></p>
    <button type="button">Add to basket</button>`;
  li.querySelector('button').addEventListener('click', async () => {
    const basket = await getJson('/api/basket', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: product.id }),
    });
    showBasket(basket);
    const toast = document.querySelector('.toast');
    toast.textContent = `Added ${product.name}`;
    setTimeout(() => { toast.textContent = ''; }, 2000);
  });
  return li;
}

async function load() {
  const products = await getJson('/api/products');
  const list = document.querySelector('#products');
  list.append(...products.map(card));
  list.setAttribute('aria-busy', 'false');
  showBasket(await getJson('/api/basket'));
}

document.querySelector('.menu-toggle').addEventListener('click', (event) => {
  const open = event.target.getAttribute('aria-expanded') === 'true';
  event.target.setAttribute('aria-expanded', String(!open));
  document.querySelector('nav').classList.toggle('open', !open);
});

load();
