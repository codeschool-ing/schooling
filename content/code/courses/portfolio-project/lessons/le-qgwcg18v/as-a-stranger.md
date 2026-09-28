---
title: Reading the diff as a stranger
version: 1
---

A self-review starts by looking at the change the way somebody else will: **as a diff**, not as the
files in your editor. Your editor shows what the code is; the diff shows what you changed, which is
what a reviewer reads first.

Here is loanbook's empty-state change, made on its own branch:

```
ana@laptop:~/loanbook$ git switch -c empty-state
Switched to a new branch 'empty-state'
ana@laptop:~/loanbook$ git add -A
ana@laptop:~/loanbook$ git commit -q -m 'Say what to do when there is nothing to lend'
```

Start with the size. `--stat` gives the files and how much of each changed:

```
ana@laptop:~/loanbook$ git diff --stat main...empty-state
 static/app.js     | 2 ++
 static/index.html | 3 +++
 2 files changed, 5 insertions(+)
```

Five lines in two files, which is the right size for one idea. **A diff you cannot read in one sitting
is a diff nobody will read carefully**, including you, and the first review comment on a large one is
usually *can you split this?*

Then the whole diff. The three dots in `main...empty-state` mean *what this branch changed since it
left main*, which is exactly what a pull request shows:

```
ana@laptop:~/loanbook$ git diff main...empty-state
diff --git a/static/app.js b/static/app.js
index 40feb12..59a99d4 100644
--- a/static/app.js
+++ b/static/app.js
@@ -24,7 +24,9 @@ function row(item) {
 async function load() {
   const res = await fetch("/api/items");
   const items = await res.json();
+  console.log("items", items);
   list.innerHTML = items.map(row).join("");
+  document.getElementById("empty").hidden = items.length > 0;
   for (const form of list.querySelectorAll("form")) {
     form.onsubmit = (e) => {
       e.preventDefault();
diff --git a/static/index.html b/static/index.html
index d3c0805..dfadd4b 100644
--- a/static/index.html
+++ b/static/index.html
@@ -12,6 +12,9 @@
     <thead><tr><th>Item</th><th>Status</th><th>Action</th></tr></thead>
     <tbody id="items"></tbody>
   </table>
+  <p id="empty" hidden>No equipment yet. Whoever runs this server adds it with
+    <code>python3 app.py add "Projector 1"</code>.</p>
+  <!-- TODO: nicer empty state -->
   <script src="/app.js"></script>
 </body>
 </html>
```

Read it top to bottom, slowly, as if somebody else had written it. Two lines should not be there: a
`console.log` left from checking what the server returned, and a `TODO` that is a note to yourself in
a file every visitor downloads. Neither breaks anything, and each tells a reviewer the change was
committed without being read.
