---
title: What a keyboard finds
version: 1
---

The second check is the one any reviewer can do without installing anything: **put the mouse away and
press Tab**. Each press moves the focus to the next thing you can act on, and a screen reader announces
its name. This script presses Tab through the page and prints what each stop is called, as a rough
stand-in for that announcement. Before:

```
$ node tab-walk.mjs
1. input: Borrower
2. button: Lend
3. button: Return
```

Three stops: a field called *Borrower*, a button *Lend*, a button *Return*. Now imagine forty items. A
screen-reader user hears *Borrower, Lend, Borrower, Lend, Return, Borrower…* and has no way to know which
projector any of them is for. **Every name is correct and none is useful.** After step 11:

```
$ node tab-walk.mjs
1. input: Lend Projector 1 to
2. button: Lend
3. button: Return Projector 2
```

*Lend Projector 1 to*, and *Return Projector 2*. The same three stops, and now each says what it acts on.
Here is the page's markup as that commit changed it:

```
ana@laptop:~/loanbook$ git diff v0.2.0 HEAD~1 -- static/index.html
diff --git a/static/index.html b/static/index.html
index 5b24d98..375de42 100644
--- a/static/index.html
+++ b/static/index.html
@@ -7,13 +7,16 @@
   <link rel="stylesheet" href="/style.css">
 </head>
 <body>
-  <h1>Equipment on loan</h1>
-  <table>
-    <thead><tr><th>Item</th><th>Status</th><th>Action</th></tr></thead>
-    <tbody id="items"></tbody>
-  </table>
-  <p id="empty" hidden>No equipment yet. Whoever runs this server adds it with
-    <code>python3 app.py add "Projector 1"</code>.</p>
+  <main>
+    <h1>Equipment on loan</h1>
+    <p id="message" role="status"></p>
+    <table>
+      <thead><tr><th scope="col">Item</th><th scope="col">Status</th><th scope="col">Action</th></tr></thead>
+      <tbody id="items"></tbody>
+    </table>
+    <p id="empty" hidden>No equipment yet. Whoever runs this server adds it with
+      <code>python3 app.py add "Projector 1"</code>.</p>
+  </main>
   <script src="/app.js"></script>
 </body>
 </html>
```

The table's content went inside `main`, the landmark a screen reader jumps to. A paragraph with
`role="status"` replaced `alert()` for results, because a status region is read out without taking the
focus away, and an alert box interrupts. The column headers got `scope="col"`, so each cell is announced
with its column's name. The labels themselves are built in `app.js`, one per row, naming the item.

None of this appeared in axe's report, before or after. **A tool is where checking starts, not where it
ends**, and the few minutes with a keyboard are what find the problems that matter most to the people
who have them.
