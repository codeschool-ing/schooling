---
title: One change per commit
version: 1
---

The hardest habit is the first one, because work does not arrive one change at a time. You fix one
thing, notice another, add a line to see what is happening. By the time you commit, the working tree
holds three changes, and *git add .* would make them one commit.

Here is loanbook at step 12, with the fix for a borrower made of spaces written, its test written,
and one line of debugging still in the code:

```
ana@laptop:~/loanbook$ git status --short
 M app.py
 M test_app.py
```

`git add -p` goes through the changes one **hunk** at a time and asks, for each, whether to stage it.
The first hunk is the fix; the answer is `y`. The second is the debugging line; the answer is `n`:

```
ana@laptop:~/loanbook$ printf 'y\nn\n' | git add -p app.py
diff --git a/app.py b/app.py
index e6039b6..f5d8924 100644
--- a/app.py
+++ b/app.py
@@ -71,6 +71,7 @@ def item_named(db, item_id):
 
 
 def lend(db, item_id, borrower, today):
+    borrower = (borrower or "").strip()
     if not borrower:
         raise Refused(HTTPStatus.BAD_REQUEST, "Say who is borrowing it.")
     item = item_named(db, item_id)
(1/2) Stage this hunk [y,n,q,a,d,j,J,g,/,e,?]? @@ -115,6 +116,7 @@ class Handler(BaseHTTPRequestHandler):
         item_id, action = int(m[1]), m[2]
         try:
             body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
+            print("DEBUG body", body)
             with closing(connect()) as db:
                 if action == "loan":
                     result = lend(db, item_id, body.get("borrower"), date.today())
(2/2) Stage this hunk [y,n,q,a,d,K,g,/,e,?]? 
```

What is left unstaged is exactly what should not be committed. `git diff` shows the working tree
against the stage, so it lists the debug line and the test, which has not been added yet. The debug
line is thrown away with `git restore`, the test is added, and the commit holds the fix and its test
and nothing else:

```
ana@laptop:~/loanbook$ git diff
diff --git a/app.py b/app.py
index e48521f..f5d8924 100644
--- a/app.py
+++ b/app.py
@@ -116,6 +116,7 @@ class Handler(BaseHTTPRequestHandler):
         item_id, action = int(m[1]), m[2]
         try:
             body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
+            print("DEBUG body", body)
             with closing(connect()) as db:
                 if action == "loan":
                     result = lend(db, item_id, body.get("borrower"), date.today())
diff --git a/test_app.py b/test_app.py
index f5885a4..9e1fe69 100644
--- a/test_app.py
+++ b/test_app.py
@@ -35,6 +35,11 @@ class LoanRules(unittest.TestCase):
             app.give_back(self.db, 1, TODAY)
         self.assertEqual(refused.exception.status, 409)
 
+    def test_a_borrower_made_of_spaces_is_refused(self):
+        with self.assertRaises(app.Refused) as refused:
+            app.lend(self.db, 1, "   ", TODAY)
+        self.assertEqual(refused.exception.status, 400)
+
     def test_a_loan_is_overdue_the_day_after_it_is_due(self):
         app.lend(self.db, 1, "Bruno", TODAY)
         due = TODAY + timedelta(days=app.LOAN_DAYS)
ana@laptop:~/loanbook$ git restore app.py
ana@laptop:~/loanbook$ git add test_app.py
ana@laptop:~/loanbook$ git commit -q -m 'Refuse a borrower made of spaces' -m 'The test came first, and it failed: "   " was accepted as a name.'
```

Two things make this worth the extra minute. **The debug line never reaches the history**, which is
lesson 10's first check done before lesson 10. And **the commit can be read, and reverted, as one
idea**: if the strip turns out to be wrong, one `git revert` removes it and its test, and nothing
unrelated goes with them.
