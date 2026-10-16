---
title: The search page, and its flaw
version: 1
---

The shop gets a second page: a box where you type the name of a fruit and a list of the fruit
that match. **It is built the way many real search boxes are built, and it has the flaw many real
search boxes have.** Every key you press sends a request, nothing cancels the requests already on
their way, and the page draws whichever answer reaches it last. Three files make it, and the shop
needs no other change: the server picks up the new route the next time it starts, as lesson 1
explained.

## The route

The search itself is one line: the products whose name contains what was typed, in lower case.
The line above it is the flaw. The server waits before answering, and it waits **longer for a
shorter question**: 900 milliseconds less 150 for each letter, so `p` waits 750 ms and `papaya`
does not wait at all. A real server is slow for real reasons, such as a short word matching more
rows, a cache that is cold, or a busier machine, and none of them promises that answers come back
in the order the questions left. This one makes the disorder certain, so you can watch it every
time. Save it as `app/routes/search.js`:

```javascript
import { send, pause } from '../http.js';
import { store } from '../store.js';

export const routes = [
  {
    method: 'GET', path: '/api/search',
    handle: async ({ res, url }) => {
      const q = (url.searchParams.get('q') ?? '').toLowerCase();
      // A known flaw, on purpose: a short query takes longer to answer, so
      // the answer to "p" arrives after the answer to "papaya".
      await pause(Math.max(0, 900 - 150 * q.length));
      send(res, 200, store.products.filter((p) => p.name.toLowerCase().includes(q)));
    },
  },
];
```

## The page

A label, the box, a line that reports how many fruit were found, and the list. Two attributes
matter to a test. `role="status"` on the count makes a screen reader announce it when it changes.
**`aria-busy` on the list says whether the page is still waiting for an answer**: the page sets it
to `true` when a question leaves and back to `false` when none is outstanding. It exists for
assistive technology, which should not read out a list that is about to change, and the same fact
is exactly what a test needs. Save it as `app/public/search.html`:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Search · Quitanda</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <main>
    <h1>Search</h1>
    <label for="q">Fruit</label>
    <input id="q" type="search" autocomplete="off">
    <p id="count" role="status"></p>
    <ul id="results" aria-busy="false"></ul>
  </main>
  <script src="/search.js"></script>
</body>
</html>
```

## The script

It listens for `input`, the event a text box fires every time its value changes, so once per key.
It counts the questions still waiting in `waiting`, and it draws every answer as it arrives, with
no check that the answer belongs to what is in the box now. Save it as `app/public/search.js`:

```javascript
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
```

`fetch` and `await` are the subject of `javascript` lessons 14 and 16; what matters here is what
`await` does to the order of things. Each call of the listener stops at its `await fetch(...)`
and carries on only when its own answer arrives, while the next key starts another call beside it.
Six keys, six calls in the air at once, and each one finishes when its answer lets it.

## Trying it by hand

Start the shop with `npm start`, open `http://localhost:3000/search.html` and type `papaya`. Then
clear the box and paste the word in one go. Both probably end on **Papaya** and *1 found*, which
is right.

Pasting is one change of value, so one request and one answer. Typing is six requests, and whether
their answers come back in order depends on how fast you typed. Forty words a minute, a common
typing speed, is about 200 characters a minute, or one key every 300 ms, and at that pace the
answers come back in order. **The result depends on the speed of the person typing**, which is the
first sign of a timing defect and the reason a person testing by hand can miss one entirely. The
next section types faster than you can and prints what happens.
