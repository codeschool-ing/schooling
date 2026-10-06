---
title: localStorage: remembered between visits
version: 1
---

**`localStorage` is a small store of keys and values that a site keeps in the browser**, and it is
still there the next time the user opens the site. Its interface is four methods: `setItem`,
`getItem`, `removeItem` and `clear`.

```html
<!doctype html>
<script>
  const visits = Number(localStorage.getItem("visits") ?? 0) + 1;
  localStorage.setItem("visits", visits);
  console.log("visit number", visits);

  localStorage.setItem("lastBook", { title: "Iracema" });
  console.log(localStorage.getItem("lastBook"));

  localStorage.setItem("prefs", JSON.stringify({ theme: "dark", perPage: 50 }));
  const prefs = JSON.parse(localStorage.getItem("prefs"));
  console.log(prefs.perPage, typeof localStorage.getItem("visits"));

  console.log(localStorage.length, localStorage.getItem("nothing-here"));
</script>
```

```
ana@dev:~/js$ page shelf.html --fresh
visit number 1
[object Object]
50 string
3 null
ana@dev:~/js$ page shelf.html
visit number 2
[object Object]
50 string
3 null
ana@dev:~/js$ page shelf.html --do newtab
visit number 3
[object Object]
50 string
3 null
-- newtab
visit number 4
[object Object]
50 string
3 null
```

The browser's profile is kept between runs of `page`, so each run is a visit. **The counter went 1, 2,
3**, then 4 in a second tab of the same run: the value survived closing the browser, and both tabs saw
the same store.

## Everything becomes a string

The other lines show the rule that catches everybody:

- `setItem("lastBook", { title: "Iracema" })` stored **`[object Object]`**. The value was converted to
  a string, the way lesson 2 showed an object becoming text, and the title was lost;
- `typeof localStorage.getItem("visits")` is `string`. The code converted with `Number` when reading
  it back, which is why the counter worked;
- **`JSON.stringify` on the way in and `JSON.parse` on the way out** is how to store an object, as
  `prefs` does. Lesson 16's warning applies: what JSON cannot hold, such as a `Date` or a `Map`, comes
  back changed;
- a key that was never set gives `null`, not `undefined`.

## What it is for

Small things that make the next visit nicer: **a theme, a language, the last tab the user had open, a
draft not yet sent**. Things whose loss would be an inconvenience, because the user can clear site
data at any moment, private windows forget it when they close, and a browser under storage pressure
may evict it. Anything that has to be kept goes to a server.
