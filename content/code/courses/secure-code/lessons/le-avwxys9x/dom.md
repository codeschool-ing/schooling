---
title: DOM-based: the page's own script
version: 1
---

The heading "Replying to lucia" is written by `static/inbox.js`, in the browser, from the part of the
address after `#`. The fragment is **never sent to the server**: no template saw it, no log recorded
it, and no server-side test could find the flaw by reading responses. That is what DOM-based means.

The script writes with `innerHTML`, which **parses its value as HTML** and builds whatever elements
it describes. That is what put the second bold element on the page. The fix is the DOM's own version
of escaping: **`textContent` sets text and parses nothing**.

```
(.venv) ana@vm:~/sc/messages$ git diff
diff --git a/static/inbox.js b/static/inbox.js
index ff1b83c..8703ae8 100644
--- a/static/inbox.js
+++ b/static/inbox.js
@@ -1,5 +1,5 @@
 // static/inbox.js
 const replyTo = new URLSearchParams(location.hash.slice(1)).get("reply");
 if (replyTo) {
-  document.getElementById("reply").innerHTML = "Replying to " + replyTo;
+  document.getElementById("reply").textContent = "Replying to " + replyTo;
 }
```

```
(.venv) ana@vm:~/sc/messages$ pytest -q
.....                                                                    [100%]
5 passed in 0.11s
```

Five of five. Restart the portal, and run `look.py` again:

```
(.venv) ana@vm:~/sc/messages$ python3 look.py
heading: Replying to lucia <b>D'Ávila</b>
first message: lucia: Knee <b>much</b> better since Monday.
See you Thursday.
bold elements: 0
```

**No bold elements.** The heading and the message show the tags as characters, which is exactly what
lucia and the address contained. Commit, and look at the history:

```
(.venv) ana@vm:~/sc/messages$ git commit -qam "Write the reply heading with textContent"
(.venv) ana@vm:~/sc/messages$ git log --oneline
ffaaa7e Write the reply heading with textContent
0e487e9 Write the no-match sentence through the template
dbf9b46 Show messages as text, with line breaks kept by CSS
6d36ae8 Staff inbox, search and reply heading
```

### The DOM's dangerous functions

DOM-based XSS lives in a short list of browser functions that turn a string into markup or code.
Searching a front-end codebase for them is the review:

| writes markup or runs code | the safe counterpart |
|---|---|
| `element.innerHTML = …`, `outerHTML`, `insertAdjacentHTML` | `textContent`, or build elements with `createElement` |
| `document.write(…)` | build elements; never write the document |
| `eval(…)`, `new Function(…)`, `setTimeout("…")` with a string | call a function; parse data with `JSON.parse` |
| `location = …`, `a.href = …` with a value that could be `javascript:` | check the scheme against an allowlist, as lesson 4 did for links |

Two more defences sit behind these. **Lesson 8's Content Security Policy** stops an injected script
from running even when a mistake like this one gets through. And browsers now offer **Trusted Types**, a
policy that makes `innerHTML` and its relatives refuse plain strings altogether, so that this whole
class of mistake fails loudly in development instead of quietly in production.
