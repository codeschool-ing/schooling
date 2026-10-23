---
title: A query that cannot return the wrong row
version: 1
---

The fix is not a check added after the query: *fetch the exam, then compare its owner with the
session.* That works, and it puts the access decision one forgotten `if` away from every route that
fetches an exam. **The safer shape puts the owner inside the query**, so the database never returns a
row the patient may not see:

```sql
SELECT id, title, taken FROM exams WHERE id = ? AND patient = ?
```

With the owner taken from the session, that query has only two outcomes for lucia: her exam, or
nothing. It cannot return marta's row, whatever number arrives in the address.

The fix puts that query in one function, `own_exam`, and every route that acts on a single exam goes
through it. Reading and deleting both use it, so **the delete can only ever delete a row the patient
owns**, because it deletes by the id of the row `own_exam` returned.

```
(.venv) ana@vm:~/sc/exams$ git diff
diff --git a/app.py b/app.py
index 8995e3a..aa1244d 100644
--- a/app.py
+++ b/app.py
@@ -52,6 +52,16 @@ def signed_in():
     return name
 
 
+def own_exam(exam_id):
+    row = db().execute(
+        "SELECT id, title, taken FROM exams WHERE id = ? AND patient = ?",
+        (exam_id, signed_in()),
+    ).fetchone()
+    if row is None:
+        abort(404)
+    return row
+
+
 @app.get("/exams")
 def list_exams():
     name = request.args.get("patient", signed_in())
@@ -61,16 +71,12 @@ def list_exams():
 
 @app.get("/exams/<int:exam_id>")
 def read_exam(exam_id):
-    signed_in()
-    row = db().execute("SELECT id, title, taken FROM exams WHERE id = ?", (exam_id,)).fetchone()
-    if row is None:
-        abort(404)
-    return jsonify(dict(row))
+    return jsonify(dict(own_exam(exam_id)))
 
 
 @app.delete("/exams/<int:exam_id>")
 def delete_exam(exam_id):
-    signed_in()
-    db().execute("DELETE FROM exams WHERE id = ?", (exam_id,))
+    exam = own_exam(exam_id)
+    db().execute("DELETE FROM exams WHERE id = ?", (exam["id"],))
     db().commit()
     return "", 204
```

```
(.venv) ana@vm:~/sc/exams$ pytest -q --tb=no
...F...                                                                  [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_the_list_shows_only_her_own_exams - AssertionError: ...
1 failed, 6 passed in 0.16s
(.venv) ana@vm:~/sc/exams$ git commit -qam "Read and delete an exam only for its owner"
```

**Five failures are gone at once**: the read, the delete and all three rows of the grid. One remains,
and it is a different shape of the same flaw, in the next section.

### 404, not 403

`own_exam` answers `404 Not Found` for an exam that exists and belongs to somebody else, the same
answer as for an exam that does not exist. Lesson 1 made the same choice for bookings, and promised
this lesson would say why.

A `403 Forbidden` would be accurate, and it would tell lucia that exam 2 **exists**. Counting up the
numbers and noting which answer `403` and which `404` then tells her how many exams the portal holds
and which ids are in use, and on some portals that a particular person has one. **The safe answer
says nothing a stranger could not already know.** The test holds it exactly: the status *and* the body
of the two answers must be the same.

`403` is right where the existence of the thing is not a secret and the person needs to know they lack
permission: the staff console of lesson 12, where bruno knows clinical notes exist and needs to know
he is not allowed to read them.
