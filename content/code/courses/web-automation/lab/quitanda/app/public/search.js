const input = document.querySelector('#q');
const results = document.querySelector('#results');
const count = document.querySelector('#count');
let waiting = 0;

// One request per key pressed, and nothing cancels the older ones.
input.addEventListener('input', async () => {
  waiting += 1;
  results.setAttribute('aria-busy', 'true');
  const response = await fetch('/api/search?q=' + encodeURIComponent(input.value));
  const found = await response.json();
  // A known flaw, on purpose: whichever answer arrives LAST is shown, even
  // when it answers an older question.
  results.replaceChildren(...found.map((p) => {
    const li = document.createElement('li');
    li.textContent = p.name;
    return li;
  }));
  count.textContent = `${found.length} found`;
  waiting -= 1;
  if (waiting === 0) results.setAttribute('aria-busy', 'false');
});
