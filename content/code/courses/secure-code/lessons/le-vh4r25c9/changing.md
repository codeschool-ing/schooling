---
title: A new password ends every other session
version: 1
---

A patient changes her password for one of two reasons. Either it is routine, or she suspects
somebody else knows it. In the second case, **the person she wants to lock out is very likely signed
in already**, and a password change that leaves their session alive changes nothing for them. The
patient believes she has locked them out; she has not. Lesson 10 listed this among the moments the
application must end sessions on its own.

The rule: **when a password changes, every other session of that account ends.** The session that
made the change stays, because the patient is using it and has just proved she knows the old
password.

```
(.venv) ana@vm:~/sc/passwords$ git diff
diff --git a/app.py b/app.py
index ed8634a..d42a549 100644
--- a/app.py
+++ b/app.py
@@ -71,4 +71,8 @@ def change_password():
     if problem:
         return jsonify(error=problem), 400
     set_password(name, new)
+    mine = request.cookies.get("sid")
+    for sid, owner in list(SESSIONS.items()):
+        if owner == name and sid != mine:
+            del SESSIONS[sid]
     return jsonify(changed=True)
```

```
(.venv) ana@vm:~/sc/passwords$ pytest -q
.........                                                                [100%]
9 passed in 1.31s
```

Nine of nine. Commit the fixes, one per rule, as in lesson 10:

```
(.venv) ana@vm:~/sc/passwords$ git commit -qam "End the other sessions when a password changes"
(.venv) ana@vm:~/sc/passwords$ git log --oneline
453bdfe End the other sessions when a password changes
c01686a Ask for length, and refuse guessable passwords
161b4dc Store passwords with Argon2id, and answer a stranger as a wrong password
e154abd Store passwords and check the policy
```

### What the portal now does, and what is left

The table that leaks one day holds Argon2id hashes with their own salts and parameters. The sign-in
form answers a stranger and a wrong password with the same words, at the same cost. The policy asks
for length and refuses the guessable, and a changed password ends the sessions it should.

Three things a real portal adds, each a lesson of its own somewhere in the catalogue:

- **A limit on attempts**: a sign-in form that answers a thousand guesses a minute is a guessing
  service. Slow the answers down per account and per address, rather than locking the account, which
  lets anybody lock any patient out.
- **A second factor**, the one control that makes a stolen password insufficient on its own.
- **A reset that is not a back door.** A reset link is a password in disguise: random, short-lived,
  single use, and, like the change above, it ends every session when it is used.
