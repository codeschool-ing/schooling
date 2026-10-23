---
title: Moving the portal's own scripts into a file
version: 1
---

Both reports name code the portal wrote. The fix is not to loosen the policy around them; it is to
move them where the policy allows scripts to come from, **a file on the portal's own origin**.

Flask serves anything in a folder called `static` beside `app.py`, at `/static/…`. Create the folder
and the file:

```
(.venv) ana@vm:~/sc/csp$ mkdir static
```

```javascript
// static/portal.js
document.title = "Vereda: " + document.getElementById("when").textContent;
document.getElementById("larger").addEventListener("click", () => {
  document.getElementById("when").classList.toggle("large");
});
```

The first line is the inline script, unchanged. The rest replaces the `onclick` attribute: the button
gets an `id`, and the file **attaches the handler** with `addEventListener`, which is code in a file
rather than code in an attribute. The page now loads the file with `<script src>`:

```
(.venv) ana@vm:~/sc/csp$ git diff
diff --git a/app.py b/app.py
index 278aa93..59e3fbf 100644
--- a/app.py
+++ b/app.py
@@ -12,10 +12,8 @@ PAGE = """<!doctype html>
 <body>
 <h1>Your next session</h1>
 <p id="when">Monday 16 November, 09:00, with carla</p>
-<button onclick="document.getElementById('when').classList.toggle('large')">Larger text</button>
-<script>
-  document.title = "Vereda: " + document.getElementById("when").textContent;
-</script>
+<button id="larger">Larger text</button>
+<script src="/static/portal.js"></script>
 </body>
 </html>
 """
```

```
(.venv) ana@vm:~/sc/csp$ pytest -q --tb=no
.FF...                                                                   [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_every_page_sends_an_enforced_policy - assert 'Conten...
FAILED test_app.py::test_scripts_come_only_from_the_portal - assert None == "...
2 failed, 4 passed in 0.13s
```

**The inline-code test passes, and so does the script file's.** Restart and look:

```
(.venv) ana@vm:~/sc/csp$ python3 look.py
title: Vereda: Monday 16 November, 09:00, with carla
larger text: True
```

No messages. Everything the page does now comes from a file the policy allows, so the report-only
policy has nothing left to report. Commit the move:

```
(.venv) ana@vm:~/sc/csp$ git add static/portal.js
(.venv) ana@vm:~/sc/csp$ git commit -qam "Move the page's scripts into a file"
```

### When an inline script cannot move

Sometimes a page needs a value only the server knows at render time, and the habit is an inline
`<script>` that writes it into a variable. Two ways keep that out of the policy's way:

- **Put the value in the HTML as data**, `<main data-patient-id="…">`, and let the script file read it
  with `dataset`. Data is not code, and the escaping of lesson 4 covers attributes.
- **A nonce**: the server draws a random value for each response, puts it in the policy,
  `script-src 'self' 'nonce-…'`, and on the one `<script nonce="…">` it trusts. A script injected into
  the page cannot know the value. The nonce has to be new on every response, or it is only a
  password written in the page.

Never `'unsafe-inline'`: it allows the portal's inline scripts and everybody else's, which is to say
it switches off the line that matters.
