---
title: Preferences in a format that holds only data
version: 1
---

The preferences cookie is written with `pickle.dumps` and read back with `pickle.loads`. Run the test
that sends a pickled cookie on its own:

```
(.venv) ana@vm:~/sc/upload$ pytest -q --tb=short -k pickled
F                                                                        [100%]
=================================== FAILURES ===================================
_______________________ test_a_pickled_cookie_is_refused _______________________
/home/ana/sc/upload/test_app.py:64: in test_a_pickled_cookie_is_refused
    assert client.get("/preferences").status_code == 400
E   AssertionError: assert 200 == 400
E    +  where 200 = <WrapperTestResponse streamed [200 OK]>.status_code
E    +    where <WrapperTestResponse streamed [200 OK]> = get('/preferences')
E    +      where get = <FlaskClient <Flask 'app'>>.get
=========================== short test summary info ============================
FAILED test_app.py::test_a_pickled_cookie_is_refused - AssertionError: assert...
1 failed, 7 deselected in 0.12s
```

`assert 200 == 400`: **the portal unpickled the cookie and answered normally.** It would unpickle any
cookie, from any browser, built by anyone, and the first section said what that means for `pickle`.
The other failing preferences test shows the same thing from the other side: the cookie the portal
writes is not readable as anything but a pickle.

The fix changes three things, and the first is the one that matters:

- **JSON instead of pickle.** `json.loads` builds strings, numbers, lists and dictionaries, and
  nothing else, whatever the bytes contain. The cookie is base64 so its quotes and braces travel
  safely in a cookie header.
- **Validation of what came back**, lesson 2's allowlist: the value must be a dictionary whose
  `text_size` is one of the sizes the portal offers. A cookie that is not base64, not JSON or not
  that shape is `400`.
- **Validation on the way in too**, so the portal never writes a size it would refuse to read.

```
(.venv) ana@vm:~/sc/upload$ git diff
diff --git a/app.py b/app.py
index 9806374..e80510c 100644
--- a/app.py
+++ b/app.py
@@ -1,12 +1,14 @@
 # app.py
 import base64
-import pickle
+import binascii
+import json
 from pathlib import Path
 
-from flask import Flask, jsonify, request, send_from_directory
+from flask import Flask, abort, jsonify, request, send_from_directory
 
 app = Flask(__name__)
 app.config["UPLOADS"] = Path("static/uploads")
+TEXT_SIZES = {"normal", "large"}
 
 
 @app.post("/exams")
@@ -26,13 +28,22 @@ def download(name):
 @app.post("/preferences")
 def save_preferences():
     prefs = {"text_size": request.form.get("text_size", "normal")}
+    if prefs["text_size"] not in TEXT_SIZES:
+        abort(400)
     response = jsonify(prefs)
-    response.set_cookie("prefs", base64.b64encode(pickle.dumps(prefs)).decode())
+    response.set_cookie("prefs", base64.urlsafe_b64encode(json.dumps(prefs).encode()).decode())
     return response
 
 
 @app.get("/preferences")
 def read_preferences():
     raw = request.cookies.get("prefs")
-    prefs = pickle.loads(base64.b64decode(raw)) if raw else {"text_size": "normal"}
-    return jsonify(prefs)
+    if raw is None:
+        return jsonify(text_size="normal")
+    try:
+        prefs = json.loads(base64.urlsafe_b64decode(raw))
+    except (binascii.Error, ValueError):
+        abort(400)
+    if not isinstance(prefs, dict) or prefs.get("text_size") not in TEXT_SIZES:
+        abort(400)
+    return jsonify(text_size=prefs["text_size"])
```

```
(.venv) ana@vm:~/sc/upload$ pytest -q --tb=no
.FFFF...                                                                 [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_a_name_cannot_leave_the_upload_folder - AssertionErr...
FAILED test_app.py::test_a_file_that_is_not_a_pdf_is_refused - AssertionError...
FAILED test_app.py::test_a_large_file_is_refused - AssertionError: assert 201...
FAILED test_app.py::test_a_download_is_an_attachment - AssertionError: assert...
4 failed, 4 passed in 0.16s
```

**Both preference tests pass**, and four upload tests still fail. Commit:

```
(.venv) ana@vm:~/sc/upload$ git commit -qam "Keep preferences as validated JSON, not pickle"
```

### When the value must not be changed

The text size can be anything the patient likes, so nothing is lost if somebody edits the cookie.
When a value must not be editable by the client, a price, a role, a patient's id, there are two
answers. Keep it **on the server**, in the session table of lesson 10, which is the better one. Or
**sign** it, as Flask's own session cookie does with `itsdangerous`: the server can then tell whether
the bytes are the ones it wrote. Signing protects integrity and nothing else; the format inside still
has to be a data format, because a signed pickle is only as safe as the key that signed it.
