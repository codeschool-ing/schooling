# Sourced by every lesson's captures.sh in bi-techniques: the few functions
# that turn a lesson's programs into a transcript.
#
# THE PROGRAMS ARE READ OUT OF THE LESSON'S OWN PAGES. `save PAGE FILE` writes
# the schooling-example whose "file" is FILE, its parts joined with a newline
# exactly as the page's copy button joins them, into ana's ~/bi. So the
# program a student copies and the program a capture ran are one text.
#
# Every transcript is printed as `ana@vm:~/bi$ COMMAND` followed by what the
# command wrote, stdout and stderr together, under a `##### NAME` line that
# says which fence of the lesson it belongs to.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB_SH=${LAB_SH:-$COURSE/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@vm:~/bi$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
save() {
  python3 - "$1" "$2" <<'PY' | lab exec "cat > '$2'"
import json, re, sys
page, name = sys.argv[1], sys.argv[2]
text = open(page, encoding="utf-8").read()
for body in re.findall(r"^```schooling-example\n(.*?)\n```$", text, re.S | re.M):
    ex = json.loads(body)
    if ex.get("file") == name:
        print("\n".join(p["code"] for p in ex["parts"]))
        break
else:
    sys.exit(f"{page}: no example writes {name}")
PY
}
