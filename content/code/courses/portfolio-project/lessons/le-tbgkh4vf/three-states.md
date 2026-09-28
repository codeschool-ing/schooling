---
title: The three states of every list
version: 1
---

The server's errors are half the story. The page has its own unhappy paths, and every page that shows
a list meets the same three, besides the list itself:

- **Empty.** There is nothing yet. A table with only its header looks broken; a sentence that says
  *nothing yet, and here is how to add something* looks finished. For loanbook the sentence has to
  name the command, because adding equipment is the stand-in of lesson 6.
- **Error.** The server did not answer. Without handling, the page shows an empty table, which looks
  exactly like the empty state, and tells a teacher there is no equipment when the truth is that the
  server is down.
- **Loading.** The request has not come back yet. On a slow connection this is the state people see
  longest.

loanbook's page handles the first two:

```schooling-example
{"language": "javascript", "file": "static/app.js", "parts": [{"code": "async function load() {\n  const items = await send(\"GET\", \"/api/items\");\n  list.replaceChildren(...items.map(row));", "note": "The loaded state: one row per item."}, {"code": "  document.getElementById(\"empty\").hidden = items.length > 0;\n}", "note": "The empty state. The paragraph in the page says what to do; this line only decides whether it shows."}, {"code": "load().catch(() => {\n  message.textContent = \"The server did not answer. Reload the page to try again.\";\n});", "note": "The error state. Without this, a server that is down leaves an empty table, which looks exactly like the empty state and is not."}]}
```

It does not handle the third. The list comes from a small server with a few dozen rows, and on the
lab network it arrives before the page has finished drawing. On a phone with a weak signal it might
not, and a *Loading…* line in the table is the obvious fix. It is in the *could* bucket, and saying so
is better than pretending the state does not exist.

The test for all three is the same and takes a minute: **open the page with an empty database, with
the server stopped, and with the network throttled** in the browser's developer tools. A reviewer will
try at least the first.
