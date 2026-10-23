#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds and starts from no ~/sc/passwords.
# app.py and test_app.py are taken from the-portal.md by lab/extract.py, so
# the program the lesson prints is the program that ran. Each fix is the
# change its section describes, applied by an exact string replacement, and
# `git diff` shows it.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - Before "install" and "bcrypt", argon2-cffi, its bindings, cffi,
#     pycparser and bcrypt are removed without printing anything, so each
#     install shown is a first install.
#   - The commits carry fixed dates, so their hashes repeat.
#   - The hashes in "phc" and "bcrypt" carry a random salt and differ on
#     every run; the timings in "timeit" are this machine's on that run.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

D=/home/ana/sc/passwords
rm -rf "$D"
( . /home/ana/sc/.venv/bin/activate && flock /var/tmp/secure-code-pip.lock pip uninstall -q -y argon2-cffi argon2-cffi-bindings cffi pycparser bcrypt ) >/dev/null 2>&1

block setup
run /home/ana/sc 'mkdir passwords'
run /home/ana/sc 'cd passwords'
run $D 'git init -b main'
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example

put the-portal.md app.py $D/app.py
put the-portal.md test_app.py $D/test_app.py

block red
run $D 'pytest -q --tb=no'

block commit
export GIT_AUTHOR_DATE='2026-11-10 09:00:00 -0300' GIT_COMMITTER_DATE='2026-11-10 09:00:00 -0300'
run $D 'git add app.py test_app.py'
run $D 'git commit -q -m "Store passwords and check the policy"'

block install
run $D 'pip install --progress-bar off argon2-cffi==25.1.0'

block phc
run $D "python3 -c 'from argon2 import PasswordHasher; ph = PasswordHasher(); h = ph.hash(\"lilac river morning tea\"); print(h); print(ph.verify(h, \"lilac river morning tea\")); ph.verify(h, \"lilac river morning coffee\")'"

block timeit
run $D "python3 -m timeit -s 'import hashlib' 'hashlib.sha256(b\"lilac river morning tea\").hexdigest()'"
run $D "python3 -m timeit -s 'from argon2 import PasswordHasher; ph = PasswordHasher()' 'ph.hash(\"lilac river morning tea\")'"

fix() {  # fix 'old' 'new': one exact replacement in app.py, which must match once
  python3 - "$1" "$2" <<'PY'
import sys
p = '/home/ana/sc/passwords/app.py'
s = open(p).read()
old, new = sys.argv[1], sys.argv[2]
assert s.count(old) == 1, old
open(p, 'w').write(s.replace(old, new))
PY
}

# Argon2id, a decoy, and one answer.
fix 'import hashlib
import secrets

from flask import Flask, abort, jsonify, request
' 'import secrets

from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
from flask import Flask, abort, jsonify, request
'
fix 'SESSIONS = {}
' 'SESSIONS = {}
HASHER = PasswordHasher()
DECOY = HASHER.hash("a password nobody has")
'
fix '    USERS[name] = hashlib.sha256(password.encode()).hexdigest()
' '    USERS[name] = HASHER.hash(password)
'
fix '    return USERS[name] == hashlib.sha256(password.encode()).hexdigest()
' '    try:
        HASHER.verify(USERS.get(name, DECOY), password)
    except VerifyMismatchError:
        return False
    if name not in USERS:
        return False
    if HASHER.check_needs_rehash(USERS[name]):
        set_password(name, password)
    return True
'
fix '    if name not in USERS:
        return jsonify(error="no such patient"), 404
    if not password_is_right(name, request.form.get("password", "")):
        return jsonify(error="wrong password"), 401
' '    if not password_is_right(name, request.form.get("password", "")):
        return jsonify(error="wrong name or password"), 401
'
block diff-argon2
run $D 'git diff'
block green-argon2
run $D 'pytest -q --tb=no'
export GIT_AUTHOR_DATE='2026-11-10 09:40:00 -0300' GIT_COMMITTER_DATE='2026-11-10 09:40:00 -0300'
run $D 'git commit -qam "Store passwords with Argon2id, and answer a stranger as a wrong password"'

block bcrypt
run $D 'pip install --progress-bar off bcrypt==5.0.0'
run $D "python3 -c 'import bcrypt; print(bcrypt.hashpw(b\"lilac river morning tea\", bcrypt.gensalt())); bcrypt.hashpw(b\"x\" * 73, bcrypt.gensalt())'"

# The policy.
fix 'SESSIONS = {}
' 'SESSIONS = {}
COMMON = {"passwordpassword", "123456789012345", "qwertyuiopasdfgh"}
'
fix '    if len(password) < 8:
        return "use at least 8 characters"
    if not any(c.isupper() for c in password):
        return "add an uppercase letter"
    if not any(c.isdigit() for c in password):
        return "add a digit"
    if password.isalnum():
        return "add a symbol"
    return None
' '    if len(password) < 15:
        return "use at least 15 characters: a few unrelated words are enough"
    if password.lower() in COMMON or "vereda" in password.lower():
        return "that password is too easy to guess: choose another"
    return None
'
block diff-policy
run $D 'git diff'
block green-policy
run $D 'pytest -q --tb=no'
export GIT_AUTHOR_DATE='2026-11-10 10:10:00 -0300' GIT_COMMITTER_DATE='2026-11-10 10:10:00 -0300'
run $D 'git commit -qam "Ask for length, and refuse guessable passwords"'

# A new password ends the other sessions.
fix '    set_password(name, new)
    return jsonify(changed=True)
' '    set_password(name, new)
    mine = request.cookies.get("sid")
    for sid, owner in list(SESSIONS.items()):
        if owner == name and sid != mine:
            del SESSIONS[sid]
    return jsonify(changed=True)
'
block diff-sessions
run $D 'git diff'
block green-sessions
run $D 'pytest -q'

block commit-fix
export GIT_AUTHOR_DATE='2026-11-10 10:30:00 -0300' GIT_COMMITTER_DATE='2026-11-10 10:30:00 -0300'
run $D 'git commit -qam "End the other sessions when a password changes"'
run $D 'git log --oneline'
