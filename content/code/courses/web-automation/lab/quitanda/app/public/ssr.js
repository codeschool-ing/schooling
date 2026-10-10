// Until this file has run, the buttons on /ssr are drawn and do nothing.
for (const button of document.querySelectorAll('button[data-id]')) {
  button.addEventListener('click', async () => {
    const response = await fetch('/api/basket', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: button.dataset.id }),
    });
    const basket = await response.json();
    const count = basket.lines.reduce((n, line) => n + line.qty, 0);
    document.querySelector('[data-testid=basket-count]').textContent = count;
  });
}
document.body.dataset.ready = 'true';
