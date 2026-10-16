// Everything the shop knows lives here, in memory. reset() puts it back the
// way it started, which is what lets a test begin from a known state.
const products = [
  { id: 'banana', name: 'Banana', price: 590, unit: 'dozen' },
  { id: 'mango', name: 'Mango', price: 450, unit: 'each' },
  { id: 'papaya', name: 'Papaya', price: 790, unit: 'each' },
  { id: 'guava', name: 'Guava', price: 1290, unit: 'kg' },
  { id: 'cashew', name: 'Cashew fruit', price: 1590, unit: 'kg' },
  { id: 'passion', name: 'Passion fruit', price: 990, unit: 'kg' },
  { id: 'acerola', name: 'Acerola', price: 1890, unit: 'kg' },
  { id: 'pineapple', name: 'Pineapple', price: 690, unit: 'each' },
];

export const store = {};

export function reset() {
  store.products = products.map((p) => ({ ...p }));
  store.basket = [];
  store.offer = { id: 'mango', price: 390 };
  store.users = new Set();
}

reset();

export function total(basket) {
  return basket.reduce((sum, line) => {
    const product = store.products.find((p) => p.id === line.id);
    return sum + product.price * line.qty;
  }, 0);
}
