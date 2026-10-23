#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds and starts from no
# ~/sc/exams-convert. app.py, test_app.py and pytest.ini are taken from the
# lesson's own listings by lab/extract.py. Each fix is the change its section
# describes, applied by an exact string replacement, and `git diff` shows it.
# Every value shown is one a receptionist could type: a file name with a
# space, a star, a name with parentheses, a note with braces. The LDAP
# directory is ldap3's own mock server, in memory; nothing leaves the machine.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - Before "install", ldap3 and pyasn1 are removed without printing
#     anything, so the install shown is a first install.
#   - The commits carry fixed dates, so their hashes repeat.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

D=/home/ana/sc/exams-convert
rm -rf "$D"
( . /home/ana/sc/.venv/bin/activate && flock /var/tmp/secure-code-pip.lock pip uninstall -q -y ldap3 pyasn1 ) >/dev/null 2>&1

block setup
run /home/ana/sc 'mkdir exams-convert'
run /home/ana/sc 'cd exams-convert'
run $D 'git init -b main'
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example

block install
run $D 'pip install --progress-bar off ldap3==2.9.1'

put the-console.md app.py $D/app.py
put the-console.md test_app.py $D/test_app.py
put the-console.md pytest.ini $D/pytest.ini

block red
run $D 'pytest -q --tb=no'
block commit
export GIT_AUTHOR_DATE='2026-11-06 09:00:00 -0300' GIT_COMMITTER_DATE='2026-11-06 09:00:00 -0300'
run $D 'git add app.py test_app.py pytest.ini'
run $D 'git commit -q -m "Exam types, staff lookup and reminder preview"'

block spaces
run $D 'pytest -q --tb=short -k spaces'

fix() {  # fix 'old' 'new': one exact replacement in app.py, which must match once
  python3 - "$1" "$2" <<'PY'
import sys
p = '/home/ana/sc/exams-convert/app.py'
s = open(p).read()
old, new = sys.argv[1], sys.argv[2]
assert s.count(old) == 1, old
open(p, 'w').write(s.replace(old, new))
PY
}

fix '    result = subprocess.run(
        f"file --brief --mime-type exams/{name}", shell=True, capture_output=True, text=True
    )' '    result = subprocess.run(
        ["file", "--brief", "--mime-type", "--", str(EXAMS / name)],
        capture_output=True,
        text=True,
    )'
block diff-commands
run $D 'git diff'
block green-commands
run $D 'pytest -q --tb=no'
block commit-commands
export GIT_AUTHOR_DATE='2026-11-06 09:20:00 -0300' GIT_COMMITTER_DATE='2026-11-06 09:20:00 -0300'
run $D 'git commit -qam "Run file with a list of arguments, without a shell"'

block star
run $D 'pytest -q --tb=short -k star'
block parens
run $D "pytest -q --tb=short -k parentheses 2>&1 | grep -E '^E |^ldap3|passed|failed'"

fix 'from ldap3 import MOCK_SYNC, Connection, Server
' 'from ldap3 import MOCK_SYNC, Connection, Server
from ldap3.utils.conv import escape_filter_chars
'
fix 'f"(cn={request.args['"'"'name'"'"']})"' 'f"(cn={escape_filter_chars(request.args['"'"'name'"'"'])})"'
block diff-ldap
run $D 'git diff'
block green-ldap
run $D 'pytest -q --tb=no'
block commit-ldap
export GIT_AUTHOR_DATE='2026-11-06 09:40:00 -0300' GIT_COMMITTER_DATE='2026-11-06 09:40:00 -0300'
run $D 'git commit -qam "Escape the name in the LDAP filter"'

block note
run $D "pytest -q --tb=short -k note 2>&1 | grep -E '^E |^jinja2|passed|failed'"

fix '    page = render_template_string(
        "<p>Hello {{ patient }}, see you on {{ day }}.</p><p>" + note + "</p>",
        patient="lucia",
        day="Monday 16 November",
    )' '    page = render_template_string(
        "<p>Hello {{ patient }}, see you on {{ day }}.</p><p>{{ note }}</p>",
        patient="lucia",
        day="Monday 16 November",
        note=note,
    )'
block diff-template
run $D 'git diff'
block green-template
run $D 'pytest -q'
block commit-fix
export GIT_AUTHOR_DATE='2026-11-06 10:00:00 -0300' GIT_COMMITTER_DATE='2026-11-06 10:00:00 -0300'
run $D 'git commit -qam "Pass the note to the template as a variable"'
run $D 'git log --oneline'
