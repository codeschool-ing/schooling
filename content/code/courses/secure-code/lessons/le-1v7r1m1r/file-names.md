---
title: Names the portal chooses, outside the web root
version: 1
---

The first version did three things with the name the browser sent. It **used it as a path**, so
`../escape.pdf` climbed out of the upload folder. It **kept it as the stored name**, so whoever
uploads chooses what the file is called on the server, including the name of a file that is already
there. And it saved into **`static/uploads`**, a folder Flask serves to anybody, under that name.

The safest name is one the sender does not choose at all. **The portal draws an id with `secrets`,
stores the file as `<id>.pdf` in a folder that is not served, and hands the id back.** The sender's
name never touches the filesystem, so there is nothing to clean: no `../`, no reserved names on other
operating systems, no two patients' `scan.pdf` overwriting each other.

The download changes to match. `send_from_directory` already refuses a path that leaves its folder,
which is why it is the right function to serve files with. Three arguments make the answer explicit:

- **`mimetype="application/pdf"`** says what the file is, instead of guessing from a name.
- **`as_attachment=True`** sends `Content-Disposition: attachment`, so the browser downloads the
  file instead of rendering it inside the portal's origin, where its scripts would run with the
  portal's cookies if the file were HTML.
- **`X-Content-Type-Options: nosniff`** tells the browser to believe the declared type and not to
  guess one from the bytes.

```
(.venv) ana@vm:~/sc/upload$ git diff
diff --git a/app.py b/app.py
index e80510c..b3a3e6a 100644
--- a/app.py
+++ b/app.py
@@ -2,12 +2,13 @@
 import base64
 import binascii
 import json
+import secrets
 from pathlib import Path
 
 from flask import Flask, abort, jsonify, request, send_from_directory
 
 app = Flask(__name__)
-app.config["UPLOADS"] = Path("static/uploads")
+app.config["UPLOADS"] = Path("uploads")
 TEXT_SIZES = {"normal", "large"}
 
 
@@ -16,13 +17,22 @@ def upload():
     exam = request.files["exam"]
     folder = app.config["UPLOADS"]
     folder.mkdir(parents=True, exist_ok=True)
-    exam.save(folder / exam.filename)
-    return jsonify(id=exam.filename), 201
-
-
-@app.get("/exams/<name>")
-def download(name):
-    return send_from_directory(app.config["UPLOADS"], name)
+    exam_id = secrets.token_hex(8)
+    exam.save(folder / f"{exam_id}.pdf")
+    return jsonify(id=exam_id), 201
+
+
+@app.get("/exams/<exam_id>")
+def download(exam_id):
+    response = send_from_directory(
+        app.config["UPLOADS"],
+        f"{exam_id}.pdf",
+        mimetype="application/pdf",
+        as_attachment=True,
+        download_name="exam.pdf",
+    )
+    response.headers["X-Content-Type-Options"] = "nosniff"
+    return response
 
 
 @app.post("/preferences")
```

```
(.venv) ana@vm:~/sc/upload$ pytest -q --tb=no
..FF....                                                                 [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_a_file_that_is_not_a_pdf_is_refused - AssertionError...
FAILED test_app.py::test_a_large_file_is_refused - AssertionError: assert 201...
2 failed, 6 passed in 0.24s
```

**Six of eight.** Commit:

```
(.venv) ana@vm:~/sc/upload$ git commit -qam "Store uploads under ids, outside static, and serve them as downloads"
```

Two things this fix does not do, and a real portal needs. **Whose exam is it?** Any patient with an
id can download it; the id is random, and lesson 13 explained why random ids are not an access check.
The upload records the owner, and the download checks it. And **what was it called?** Patients like
to see their own file names. Keep the name as text beside the id, run it through
`werkzeug.utils.secure_filename` if it will ever be used in a header, and never as a path.
