#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine, with every tool of the course
# installed (gitleaks built from the v8.30.1 source, because the lesson's
# download from GitHub could not be reached); account.py from lesson 16, and
# settings.ini and payment.env from this lesson, copied out of the lessons by
# `shown` rather than pasted into nano; the pre-commit hook, copied out of "A
# hook that refuses the commit" by the few lines of Python below, because its
# first line has to be `#!/bin/sh` and `shown` looks for a path there. The
# git identity and dates the lesson exports once are also appended to
# ~/.profile, because every command here runs in a fresh shell and a real
# terminal keeps an export. The account service runs in the background, where
# the lesson has the student run it in a second terminal. Process ids, and
# the times and durations gitleaks logs, differ on every run; the commit
# hashes do not, because the author, committer and dates are fixed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L16="$HERE_DIR/../le-eyhjtrtz"

machine l18
shown "$L16/the-account-service.md" "$HERE_DIR/gitleaks.md" 2>/dev/null
IDENTITY='export GIT_AUTHOR_NAME=ana GIT_AUTHOR_EMAIL=ana@nft.test GIT_COMMITTER_NAME=ana GIT_COMMITTER_EMAIL=ana@nft.test'
DATES='export GIT_AUTHOR_DATE=2026-10-01T10:00:00-03:00 GIT_COMMITTER_DATE=2026-10-01T10:00:00-03:00'
quiet "printf '%s\n' '$IDENTITY' '$DATES' >> ~/.profile"

block version
run 'gitleaks version'

block repo
run 'mkdir -p ~/leaky && cd ~/leaky'
at '~/leaky'
run 'git init -q -b main'
run "$IDENTITY"
run "$DATES"
block commit1
run 'git add settings.ini && git commit -q -m "payment settings"'
run 'git log --oneline'

block delete
run "sed -i '/payment_api_key/d' settings.ini"
run 'git commit -q -am "take the key out of the settings"'
run 'git log --oneline'

block scan-dir
run 'gitleaks dir --no-banner --no-color; echo "exit $?"'

block scan-git
run 'gitleaks git --no-banner --no-color --verbose; echo "exit $?"'
run 'git show HEAD~1:settings.ini | grep key'

block stdin
run "echo 'payment_api_key = \"fake-7Zq2vRmX9kLp4Tn8Wc3Yb6Hd1Jf5G\"' | gitleaks stdin --no-banner --no-color"
run "echo 'payment_api_key = \"lesson18-7Zq2vRmX9kLp4Tn8Wc3Yb6Hd\"' | gitleaks stdin --no-banner --no-color"

shown "$HERE_DIR/environment.md" 2>/dev/null
block ignore
run "echo '*.env' > .gitignore"
run 'git status --short'
run 'git check-ignore -v payment.env'
run 'git add .gitignore && git commit -q -m "keep env files out of the repository"'
run 'gitleaks dir --no-banner --no-color --redact --verbose'

at '~/boxoffice'
PORT=8001 serve 'bash -c "set -a; . ~/leaky/payment.env; set +a; exec python3 account.py"' account
block environ
run "pgrep -f '^python3 account.py'"
run "tr '\\0' '\\n' < /proc/\$(pgrep -f '^python3 account.py')/environ | grep KEY"
run "ps eww -p \$(pgrep -f '^python3 account.py') | grep -o 'PAYMENT_API_KEY=[^ ]*'"
run "sudo -u nobody cat /proc/\$(pgrep -f '^python3 account.py')/environ"
block acc-serve
echo 'ana@nft:~/boxoffice$ set -a; . ~/leaky/payment.env; set +a'
echo 'ana@nft:~/boxoffice$ python3 account.py'
log account
stop account

python3 - "$HERE_DIR/pre-commit.md" <<'PY' | lab as "$MACHINE" 'cat > ~/leaky/.git/hooks/pre-commit'
import re, sys
for body in re.findall(r'^```sh\n(.*?)^```$', open(sys.argv[1]).read(), re.S | re.M):
    if body.split('\n')[1] == '# leaky/.git/hooks/pre-commit':
        sys.stdout.write(body)
PY
at '~/leaky'
block hook
run 'chmod +x .git/hooks/pre-commit'
run 'grep KEY payment.env >> settings.ini'
run 'git commit -am "try the payment provider"'
run 'git status --short'
run 'git restore settings.ini'

block bypass
run 'grep KEY payment.env >> settings.ini'
run 'git commit -q --no-verify -am "try the payment provider"'
run 'gitleaks git --no-banner --no-color --redact'
run 'git reset -q --hard HEAD~1'
run 'git log --oneline'

block ignorefile
run "printf '%s\\n' '# The payment key of ad0a6bc was revoked and replaced on 2026-10-01 (ana).' 'ad0a6bc9d70d4677797a3da73054ec968696f1b0:settings.ini:generic-api-key:7' > .gitleaksignore"
run 'cat .gitleaksignore'
run 'git add .gitleaksignore && git commit -q -m "record the revoked payment key"'
run 'gitleaks git --no-banner --no-color; echo "exit $?"'
