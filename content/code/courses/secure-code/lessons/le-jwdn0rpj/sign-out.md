---
title: Ended: signing out on the server
version: 1
---

The first version's sign-out:

```python
@app.post("/sign-out")
def sign_out():
    response = jsonify(signed_out=True)
    response.delete_cookie("sid")
    return response
```

It looks complete. The browser receives a `Set-Cookie` that expires the cookie, forgets the id,
and the next page asks the patient to sign in again. **But the session table still holds the id,
and the server still answers it.** Any copy made before sign-out, in a proxy's log, in a browser
profile somebody else opened, in the memory of a script, keeps working until the idle limit runs
out, or for ever if there is none. The patient pressed the button to end her session, and nothing
on the server ended.

The rule: **sign-out deletes the session where it is checked.** Deleting the cookie is a courtesy
to the browser; deleting the row is the security.

```
(.venv) ana@vm:~/sc/sessions$ git diff
diff --git a/app.py b/app.py
index 653aece..05c5ebc 100644
--- a/app.py
+++ b/app.py
@@ -69,6 +69,7 @@ def bookings():
 
 @app.post("/sign-out")
 def sign_out():
+    SESSIONS.pop(request.cookies.get("sid"), None)
     response = jsonify(signed_out=True)
     response.delete_cookie("sid")
     return response
```

```
(.venv) ana@vm:~/sc/sessions$ pytest -q
.......                                                                  [100%]
7 passed in 0.13s
```

**Seven of seven.** Commit the last fix, and look at the history:

```
(.venv) ana@vm:~/sc/sessions$ git commit -qam "End the session on the server at sign-out"
(.venv) ana@vm:~/sc/sessions$ git log --oneline
119d187 End the session on the server at sign-out
23b59a8 Issue a new id at sign-in, and expire idle and old sessions
7aab90c Draw session ids from secrets, and mark the cookie
2d69645 Sign patients in with a server-side session
```

The log is the lesson in four lines: one commit with the flaws and the tests that name them, and
one commit per moment, each turning some of those tests green.

### When else a session ends

Sign-out is the moment the patient chooses. Three more are the application's to choose, and each is
a deletion of one or more rows like the one above:

- **When the password changes, every other session of that account ends.** Otherwise the patient
  who changed it because she suspected somebody believes she locked them out, and did not.
  Lesson 11 writes that test.
- **When an account is disabled or a role is removed**, its sessions end at once. Removing access
  that keeps working until the idle limit is only scheduling its removal.
- **When something looks wrong**, the team can end one session, or all of them, without asking
  anybody to sign out. With sessions on the server that is a delete; with signed cookies it is
  changing `secret_key` and signing everybody out.

None of this is possible with a session the server does not keep. That is the reason this lesson's
portal keeps them, and the question to ask of any framework's session before trusting it: **can I
end one from the server?**
