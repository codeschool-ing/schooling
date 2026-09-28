---
title: On a phone
version: 1
---

The other half of the floor is width. At 320 pixels, a narrow phone, loanbook's table was wider than the
screen, so the page scrolled sideways, and axe reported a button too small to press reliably. Step 12
fixed both with one block of CSS:

```
ana@laptop:~/loanbook$ git show --format=%s HEAD -- static/style.css
Fit the table on a phone

diff --git a/static/style.css b/static/style.css
index 937365a..5659798 100644
--- a/static/style.css
+++ b/static/style.css
@@ -9,3 +9,9 @@ input, button { font: inherit; padding: 0.25rem 0.5rem; }
 #message:empty { display: none; }
 #message { padding: 0.5rem; border-left: 4px solid #1a5fb4; background: #eef3fb; }
 
+@media (max-width: 36rem) {
+  thead { display: none; }
+  tr, th, td { display: block; }
+  tr { border-bottom: 1px solid #767676; padding: 0.5rem 0; }
+  th, td { border: 0; padding: 0.25rem 0; }
+}
```

Below 36rem, about 576 pixels at the default font size, the table stops being a table. The header row is
hidden, and every row and cell becomes a block, so each item is a small card: its name, its status, its
action, one under the other. Nothing scrolls sideways, and the buttons get the full width of the screen.

Two things about how this was done are worth copying. **The breakpoint is in `rem`, not pixels**, so a
reader who has set a larger font gets the phone layout sooner, which is what they need. And **the HTML did
not change**: the same `table` serves both layouts, so the screen reader of the previous section still
announces a table with its headers on a large screen.

The check is quick. Open the browser's developer tools, choose a device width of 320, and use the page.
Then do the same on a real phone, if you have one, because a real thumb finds what a simulated one does not.
For loanbook, the brief of lesson 4 required it: *a teacher can lend an item from a phone.*
