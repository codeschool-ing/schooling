#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of apis, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine itself, built by `lab.sh up`
# with every package of lesson 1's section "The packages" already installed;
# lesson 1's `db.py` and `rest.py`, and this lesson's `hashrate.py` and
# `passwords.py`, copied out of the sections that print them by `shown` rather
# than pasted into nano. A password reaches `passwords.py` through a pipe, which
# the lesson says, where a student at a terminal types it. Every timing, every
# rate, every salt, hash, ciphertext and random key differs on every run; the
# lesson quotes one run and says the reader's numbers will differ.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)

machine l10

shown "$HERE_DIR/../le-f6652c1w/the-shelf.md" "$HERE_DIR/why-fast-is-bad.md" \
  "$HERE_DIR/store-and-verify.md"

block wrong
run 'printf %s sunshine | openssl enc -aes-256-cbc -pbkdf2 -pass pass:the-server-key -base64 > stored.txt && cat stored.txt'
run 'openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:the-server-key -base64 -in stored.txt; echo'

at '~/shelf'
block rate
run 'python3 hashrate.py'

block salt
run 'for user in ana bia; do printf %s sunshine | sha256sum; done'
run "python3 -c 'import bcrypt; print(bcrypt.hashpw(b\"sunshine\", bcrypt.gensalt()).decode())'"
run "python3 -c 'import bcrypt; print(bcrypt.hashpw(b\"sunshine\", bcrypt.gensalt()).decode())'"

block bcrypt
run "python3 -c 'import bcrypt; print(bcrypt.hashpw(b\"correct horse battery staple\", bcrypt.gensalt(12)).decode())'"
run "python3 -c 'import bcrypt; h = bcrypt.hashpw(b\"a\" * 72 + b\"X\", bcrypt.gensalt()); print(bcrypt.checkpw(b\"a\" * 72 + b\"Y\", h))'"
run "python3 -c 'p = \"canção\"; print(len(p), len(p.encode()))'"
run "python3 -c 'from argon2 import PasswordHasher; ph = PasswordHasher(); h = ph.hash(\"a\" * 72 + \"X\"); print(ph.verify(h, \"a\" * 72 + \"Y\"))'"

block scrypt
run "python3 -c 'import hashlib, os; print(hashlib.scrypt(b\"correct horse battery staple\", salt=os.urandom(16), n=2**17, r=8, p=1).hex())'"
run "python3 -c 'import hashlib, os; print(hashlib.scrypt(b\"correct horse battery staple\", salt=os.urandom(16), n=2**17, r=8, p=1, maxmem=2**28, dklen=32).hex())'"
run "$(cat <<'EOF'
for e in 14 15 16 17; do python3 -c "import hashlib, resource; hashlib.scrypt(b'x', salt=bytes(16), n=2**$e, r=8, p=1, maxmem=2**28); print('N=2^$e', resource.getrusage(resource.RUSAGE_SELF).ru_maxrss // 1024, 'MiB')"; done
EOF
)"

block argon2
run "python3 -c 'from argon2 import PasswordHasher; ph = PasswordHasher(); print(ph.memory_cost, ph.time_cost, ph.parallelism)'"
run "python3 -c 'from argon2 import PasswordHasher; print(PasswordHasher(memory_cost=19456, time_cost=2, parallelism=1).hash(\"correct horse battery staple\"))'"
run "$(cat <<'EOF'
for m in 19456 47104 102400; do python3 -c "import resource; from argon2 import PasswordHasher; PasswordHasher(memory_cost=$m, time_cost=2, parallelism=1).hash('x'); print('m=$m', resource.getrusage(resource.RUSAGE_SELF).ru_maxrss // 1024, 'MiB')"; done
EOF
)"

block tune
run 'python3 hashrate.py argon2'

block passwords
run 'ls'
run "echo 'sunshine' | python3 passwords.py register ana"
run "echo 'correct horse battery staple' | python3 passwords.py register ana"
run "echo 'correct horse battery staple' | python3 passwords.py register ana"
run "echo 'correct horse battery staple' | python3 passwords.py login ana"
run "echo 'correct horse battery stapler' | python3 passwords.py login ana"
run "sqlite3 shelf.db 'SELECT * FROM users'"
run "sed -i 's/memory_cost=19456/memory_cost=47104/' passwords.py && grep -n 'HASHER =' passwords.py"
run "echo 'correct horse battery staple' | python3 passwords.py login ana"
run "sqlite3 shelf.db 'SELECT * FROM users'"

block timing
run "$(cat <<'EOF'
for name in ana nobody ana nobody; do python3 -c "import time, passwords; t = time.perf_counter(); passwords.login('$name', 'not her password'); print('$name', round((time.perf_counter() - t) * 1000), 'ms')"; done
EOF
)"
run "$(cat <<'EOF'
python3 -c "import time, passwords; t = time.perf_counter(); passwords.accounts().execute('SELECT * FROM users WHERE name = ?', ('nobody',)).fetchone(); print(round((time.perf_counter() - t) * 1000, 1), 'ms')"
EOF
)"

at '~'
block pepper
run 'openssl rand -base64 32 > pepper.key && chmod 600 pepper.key && ls -l pepper.key'
run "printf %s 'correct horse battery staple' | openssl dgst -sha256 -hmac \"\$(cat pepper.key)\""
run "printf %s 'correct horse battery staple' | openssl dgst -sha256 -hmac 'a different key'"
run 'printf %s sunshine | sha1sum'
