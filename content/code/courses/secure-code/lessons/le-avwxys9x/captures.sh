#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds and starts from no ~/sc/messages.
# app.py, static/inbox.js, test_app.py and look.py are taken from the
# lesson's own listings by lab/extract.py. Each fix is the change its section
# describes, applied by an exact string replacement, and `git diff` shows it.
# The only markup used to show the flaws is <b> and <i>; no script is
# injected anywhere.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - Playwright is the one lesson 8 installs, already in the environment;
#     PLAYWRIGHT_BROWSERS_PATH points it at the machine's Chromium build, as
#     lesson 8's captures.sh says.
#   - "look-before", "curl-reflected" and "look-after" ran with the portal
#     started in the background by serve(), as from a second terminal.
#   - The commits carry fixed dates, so their hashes repeat.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
export PLAYWRIGHT_BROWSERS_PATH=/var/tmp/pwb
mkdir -p $PLAYWRIGHT_BROWSERS_PATH/chromium_headless_shell-1194/chrome-linux
ln -sfn /opt/pw-browsers/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell \
  $PLAYWRIGHT_BROWSERS_PATH/chromium_headless_shell-1194/chrome-linux/headless_shell

D=/home/ana/sc/messages
rm -rf "$D"

block setup
run /home/ana/sc 'mkdir messages'
run /home/ana/sc 'cd messages'
run $D 'git init -b main'
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example

put the-inbox.md app.py $D/app.py
block mkdir
run $D 'mkdir static'
put the-inbox.md static/inbox.js $D/static/inbox.js
put the-inbox.md test_app.py $D/test_app.py
put the-inbox.md look.py $D/look.py

block red
run $D 'pytest -q --tb=no'
block commit
export GIT_AUTHOR_DATE='2026-11-07 09:00:00 -0300' GIT_COMMITTER_DATE='2026-11-07 09:00:00 -0300'
run $D 'git add app.py static/inbox.js test_app.py look.py'
run $D 'git commit -q -m "Staff inbox, search and reply heading"'

serve $D 'flask --app app run'
block look-before
run $D 'python3 look.py'
unserve

fix() {  # fix 'old' 'new' [file]: one exact replacement, which must match once
  python3 - "$1" "$2" "/home/ana/sc/messages/${3:-app.py}" <<'PY'
import sys
p = sys.argv[3]
s = open(p).read()
old, new = sys.argv[1], sys.argv[2]
assert s.count(old) == 1, old
open(p, 'w').write(s.replace(old, new))
PY
}

# Stored.
fix '<head><meta charset="utf-8"><title>Inbox</title></head>' '<head>
<meta charset="utf-8"><title>Inbox</title>
<style>.message { white-space: pre-line; }</style>
</head>'
fix '{{ m.text|replace("\\n", "<br>")|safe }}' '{{ m.text }}'
block diff-stored
run $D 'git diff'
block green-stored
run $D 'pytest -q --tb=no'
block commit-stored
export GIT_AUTHOR_DATE='2026-11-07 09:20:00 -0300' GIT_COMMITTER_DATE='2026-11-07 09:20:00 -0300'
run $D 'git commit -qam "Show messages as text, with line breaks kept by CSS"'

# Reflected.
serve $D 'flask --app app run'
block curl-reflected
run $D "curl -s -w '\n' -G --data-urlencode 'q=<i>knee</i>' http://127.0.0.1:5000/search"
unserve
fix '        return f"<p>No messages match {term}.</p>"' '        return render_template_string("<p>No messages match {{ term }}.</p>", term=term)'
block diff-reflected
run $D 'git diff'
block green-reflected
run $D 'pytest -q --tb=no'
block commit-reflected
export GIT_AUTHOR_DATE='2026-11-07 09:40:00 -0300' GIT_COMMITTER_DATE='2026-11-07 09:40:00 -0300'
run $D 'git commit -qam "Write the no-match sentence through the template"'

# DOM-based.
fix '.innerHTML = ' '.textContent = ' static/inbox.js
block diff-dom
run $D 'git diff'
block green-dom
run $D 'pytest -q'
serve $D 'flask --app app run'
block look-after
run $D 'python3 look.py'
unserve
block commit-fix
export GIT_AUTHOR_DATE='2026-11-07 10:00:00 -0300' GIT_COMMITTER_DATE='2026-11-07 10:00:00 -0300'
run $D 'git commit -qam "Write the reply heading with textContent"'
run $D 'git log --oneline'
