---
title: How much fits, and what never goes in
version: 1
---

Web storage is small and simple on purpose. **It holds a few megabytes per origin, and every call is
synchronous**, so the page waits while the browser reads or writes:

```html
<!doctype html>
<script>
  const chunk = "x".repeat(1024 * 1024);
  let stored = 0;
  try {
    for (let i = 0; i < 20; i++) {
      localStorage.setItem(`chunk${i}`, chunk);
      stored = i + 1;
    }
  } catch (err) {
    console.log(err.name, "after", stored, "items of", chunk.length, "characters");
  }
  for (let i = 0; i < stored; i++) localStorage.removeItem(`chunk${i}`);
</script>
```

```
ana@dev:~/js$ page full.html --fresh
QuotaExceededError after 4 items of 1048576 characters
```

Chromium refused the fifth item of a million characters with a **`QuotaExceededError`**. The limit
differs between browsers and is counted in different ways, so **a page that stores anything large
must expect `setItem` to throw**, and catch it where it can do something sensible, such as dropping
an old cache entry. The test cleans up after itself, removing what it stored.

## When it is the wrong tool

- **a lot of data**, or files: the browser has a database for that, IndexedDB, with an asynchronous
  interface and far more room. This course does not cover it; the frameworks' offline chapters do;
- **anything secret**. Any script running on the page can read `localStorage`, including a script that
  should never have run there. A session token kept in it is exposed to every such script, which is why
  `front-quality` lesson 6, "Storing tokens safely in the browser", is about where tokens should live
  instead. Passwords never belong in the browser's storage at all;
- **anything that must be true**. The user can open the browser's developer tools and edit any value,
  so a price, a permission or a score read from `localStorage` is whatever the user wants it to be. The
  server decides those, every time.
