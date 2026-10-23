---
title: A policy people can follow
version: 1
---

The first version's policy is the one most people have met: at least eight characters, an
uppercase letter, a digit, a symbol. It refused `lilac river morning tea` for having no capital, and
accepted `Vereda2026!`. **Both answers are wrong, and the second is the dangerous one.**

Composition rules do not produce random passwords. They produce the same few patterns over and over:
a word with a capital first letter, a year, an exclamation mark at the end. Every guessing tool
tries those patterns first. Meanwhile a password of four unrelated words is long, easy to remember
and type, and refused because it lacks a symbol.

### What NIST asks for now

The US National Institute of Standards and Technology publishes the guideline most policies are now
written against, SP 800-63B, revised in 2025. For passwords it asks for this:

- **Length is the requirement.** At least 15 characters when the password is the only factor, as on
  this portal; at least 8 when it is used with a second factor. Accept at least 64.
- **No composition rules.** No required mix of upper case, digits and symbols.
- **Check against a blocklist**: passwords known from earlier breaches, dictionary words, repeated or
  sequential characters, and words specific to the service, such as its name.
- **No forced periodic change.** Change a password when there is evidence it was compromised, not
  every 90 days; scheduled changes produce `Vereda2026!` followed by `Vereda2027!`.
- **Allow pasting** and password managers, and say why a password was refused.

### The fix

```
(.venv) ana@vm:~/sc/passwords$ git diff
diff --git a/app.py b/app.py
index b8ce3c5..ed8634a 100644
--- a/app.py
+++ b/app.py
@@ -8,6 +8,7 @@ from flask import Flask, abort, jsonify, request
 app = Flask(__name__)
 USERS = {}
 SESSIONS = {}
+COMMON = {"passwordpassword", "123456789012345", "qwertyuiopasdfgh"}
 HASHER = PasswordHasher()
 DECOY = HASHER.hash("a password nobody has")
 
@@ -29,14 +30,10 @@ def password_is_right(name, password):
 
 
 def policy_problem(password):
-    if len(password) < 8:
-        return "use at least 8 characters"
-    if not any(c.isupper() for c in password):
-        return "add an uppercase letter"
-    if not any(c.isdigit() for c in password):
-        return "add a digit"
-    if password.isalnum():
-        return "add a symbol"
+    if len(password) < 15:
+        return "use at least 15 characters: a few unrelated words are enough"
+    if password.lower() in COMMON or "vereda" in password.lower():
+        return "that password is too easy to guess: choose another"
     return None
 
 
```

The blocklist here is three entries, so the page stays readable, plus a check for the company's name
in any form. **In production the list is long**: tens or hundreds of thousands of passwords from real
breaches. Some services offer the check as an API that sees only the first characters of a hash of
the password, so the password itself never leaves the server.

```
(.venv) ana@vm:~/sc/passwords$ pytest -q --tb=no
........F                                                                [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_changing_the_password_ends_the_other_sessions - Asse...
1 failed, 8 passed in 1.48s
(.venv) ana@vm:~/sc/passwords$ git commit -qam "Ask for length, and refuse guessable passwords"
```

The refusal says what to do, not only what was wrong: *a few unrelated words are enough.* A policy
people can follow is one that tells them how.
