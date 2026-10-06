---
title: Catching only what you can handle
version: 1
---

Catching is a decision: **this code knows what to do about this failure**. The commonest mistake is
catching everything and doing nothing useful with it:

```javascript
function loadSettings(text) {
  try {
    return JSON.parse(text);
  } catch {
    return {};
  }
}

const settings = loadSettings('{"perPage": 50,}');
console.log(settings.perPage ?? 20);
```

```
ana@dev:~/js$ node swallow.js
20
```

The settings text had a trailing comma, which JSON does not allow. `loadSettings` caught the
`SyntaxError`, returned `{}`, and the program carried on with **the default of 20 instead of the 50
somebody wrote**. Nothing printed, no log recorded it, and the next person to wonder why their setting
is ignored will spend an afternoon finding a comma. That is a **swallowed error**, and it is worse
than a crash, because a crash at least says where.

## Catch the expected, rethrow the rest

```javascript
class NotFound extends Error {
  name = "NotFound";
}

function findBook(id) {
  if (id === 9) throw new NotFound(`no book ${id}`);
  if (id === 13) throw new TypeError("Cannot read properties of undefined (reading 'shelf')");
  return { id, title: "Iracema" };
}

function titleOrPlaceholder(id) {
  try {
    return findBook(id).title;
  } catch (err) {
    if (err instanceof NotFound) return "(no such book)";
    throw err;
  }
}

console.log(titleOrPlaceholder(7));
console.log(titleOrPlaceholder(9));
console.log(titleOrPlaceholder(13));
```

```
ana@dev:~/js$ node rethrow.js 2>&1 | head -n 9
Iracema
(no such book)
/home/ana/js/rethrow.js:16
    throw err;
    ^

TypeError: Cannot read properties of undefined (reading 'shelf')
    at findBook (/home/ana/js/rethrow.js:7:24)
    at titleOrPlaceholder (/home/ana/js/rethrow.js:13:12)
```

`titleOrPlaceholder` knows what to do about one thing: **a book that does not exist gets a
placeholder.** It checks the kind with `instanceof`, handles that kind, and **rethrows everything
else unchanged**. Book 13 hit a genuine bug, a `TypeError`, which went past the `catch` and stopped
the program with its stack intact, pointing at `findBook` line 7. Had the `catch` returned a
placeholder for every error, that bug would have shown up as a missing title on some screen, with no
trace of where it came from.

## A short checklist

- **catch where you can do something**: show a message, use a fallback that is genuinely right, retry
  (lesson 16), or add context and rethrow;
- **check the kind** before handling it, with `instanceof` or `name`;
- **never leave a `catch` empty** without a comment saying why silence is the right answer, and log
  what you caught when it is not;
- let the rest travel. An error that reaches the top of the program, loudly, is a bug that gets
  fixed.
