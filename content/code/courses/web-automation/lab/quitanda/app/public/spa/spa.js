// One HTML page, and the address bar changed by JavaScript rather than by
// loading another page.
const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });
const view = document.querySelector('#view');

const pages = {
  '/spa/': async () => {
    const products = await (await fetch('/api/products')).json();
    view.innerHTML = '<h1>Fruit</h1><ul></ul>';
    view.querySelector('ul').append(...products.map((p) => {
      const li = document.createElement('li');
      li.textContent = `${p.name}, ${money.format(p.price / 100)}`;
      return li;
    }));
  },
  '/spa/basket': async () => {
    const basket = await (await fetch('/api/basket')).json();
    view.innerHTML = `<h1>Basket</h1><p>Total: ${money.format(basket.total / 100)}</p>`;
  },
};

async function show(path) {
  view.setAttribute('aria-busy', 'true');
  await (pages[path] ?? (() => { view.innerHTML = '<h1>Not found</h1>'; }))();
  view.setAttribute('aria-busy', 'false');
  document.title = view.querySelector('h1').textContent + ' · Quitanda app';
}

document.addEventListener('click', (event) => {
  const link = event.target.closest('a');
  if (!link || !link.pathname.startsWith('/spa/')) return;
  event.preventDefault();
  history.pushState(null, '', link.pathname);
  show(link.pathname);
});
window.addEventListener('popstate', () => show(location.pathname));

show(location.pathname);
if ('serviceWorker' in navigator) navigator.serviceWorker.register('/spa/sw.js');
