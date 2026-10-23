---
title: What a file is, and how big it may be
version: 1
---

Two tests still fail. A file of plain text named `scan.pdf` is accepted, and so is a file of six
megabytes. Both are values the sender chose: the extension says nothing about the bytes, and a request
can be as long as the sender likes unless the server says otherwise.

### Look at the bytes

Many file formats begin with a fixed **signature**, a few bytes that say what the format is. Every
PDF begins with `%PDF-`. The fix reads those five bytes from the uploaded stream before saving
anything, refuses the file with `400` if they are not there, and rewinds the stream so the file is
saved whole.

A signature is a **minimum**, not a proof: a file can begin with `%PDF-` and be broken, or carry
something else after it. Where the content matters more, the next steps are to parse the file with a
library that knows the format, and to convert or re-render it, so what the portal stores is a file it
produced. For exams a physiotherapist opens on a clinic computer, scanning uploads with an antivirus
engine before anybody opens them is common practice too.

### Limit the size

`MAX_CONTENT_LENGTH` makes Flask refuse any request body larger than the limit with
`413 Request Entity Too Large`, **before the view runs** and before the file is held anywhere. Five
megabytes is generous for a scanned exam; the number is a decision, written where the next person
can see it.

```
(.venv) ana@vm:~/sc/upload$ git diff
diff --git a/app.py b/app.py
index b3a3e6a..17071b6 100644
--- a/app.py
+++ b/app.py
@@ -9,12 +9,16 @@ from flask import Flask, abort, jsonify, request, send_from_directory
 
 app = Flask(__name__)
 app.config["UPLOADS"] = Path("uploads")
+app.config["MAX_CONTENT_LENGTH"] = 5 * 1024 * 1024
 TEXT_SIZES = {"normal", "large"}
 
 
 @app.post("/exams")
 def upload():
     exam = request.files["exam"]
+    if exam.stream.read(5) != b"%PDF-":
+        abort(400)
+    exam.stream.seek(0)
     folder = app.config["UPLOADS"]
     folder.mkdir(parents=True, exist_ok=True)
     exam_id = secrets.token_hex(8)
```

```
(.venv) ana@vm:~/sc/upload$ pytest -q
........                                                                 [100%]
8 passed in 0.15s
```

Eight of eight. Commit, and look at the history:

```
(.venv) ana@vm:~/sc/upload$ git commit -qam "Accept only PDFs, up to 5 MB"
(.venv) ana@vm:~/sc/upload$ git log --oneline
fc5c71c Accept only PDFs, up to 5 MB
c69cdf0 Store uploads under ids, outside static, and serve them as downloads
be3b310 Keep preferences as validated JSON, not pickle
c3ee918 Exam uploads and text-size preferences
```

### The upload checklist

What the portal now does, in the order a request meets it, is the checklist for any upload:

| check | in this portal |
|---|---|
| a size limit, enforced before the view | `MAX_CONTENT_LENGTH`, 5 MB |
| the type from the bytes, not the name | the `%PDF-` signature |
| a name the server chooses | `secrets.token_hex(8)` |
| storage outside anything the web server serves | `uploads/`, not `static/` |
| served as a download, with a declared type | `as_attachment`, `mimetype`, `nosniff` |
| the owner checked on download | lesson 13, still to add |
