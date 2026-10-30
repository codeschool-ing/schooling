# Sourced by the lessons' captures.sh. Not for the student, who has none of it.
#
# THE STUDENT'S LAB IS BUILT BY LESSON 1, OUT OF ITS OWN TEXT, and every other
# lesson is recorded in that lab: the home directory lesson 1's captures.sh
# filled, with the Azure CLI and the Azure Identity library in ~/azure/venv,
# Terraform in ~/.local/bin, the Bicep CLI in ~/azure/.azure/bin and
# ~/azure/env.sh.
#
# WHAT IS STAGED, and why, for every lesson (each captures.sh adds its own):
#   - the recording machine runs everything as root, so ana's home is the
#     directory LAB_HOME below (/home/ana), and HOME points at it. The prompt is
#     printed as ana@laptop:~/azure$;
#   - every AZURE_*, ARM_* and TF_* variable the recording machine's environment
#     carried is unset before ~/azure/env.sh is read, so nothing of the author's
#     reaches the tools;
#   - Terraform's colours are removed from what it prints, which is what a
#     terminal does with them on the screen;
#   - the captures take a lock, so two lessons recorded at once never share a
#     working directory;
#   - python3 is Ubuntu 24.04's own 3.12: PYTHON3_DIR names a directory holding
#     a `python3` link to python3.12, and it goes first on the path.
#
# THERE IS NO AZURE ACCOUNT ANYWHERE IN THIS LAB. Three things on the internet
# answer it, and each lesson's header says which ones it asks: Microsoft Entra
# ID's public sign-in endpoints at login.microsoftonline.com, which refuse the
# made-up tenant and application ids; the public DNS; and the GitHub copy of
# Microsoft's built-in policy definitions, which lesson 4 reads.
#
# Helpers:
#   lab                  enter the lab: HOME, PATH, env.sh, TZ, the lock
#   block NAME           a marker line the paste tool splits the output on
#   run CMD              print the prompt and CMD, run it, print what it printed
#   say TEXT             print a line into the block without running anything
#   at DIR               the directory the prompt shows (default ~/azure)
#   fences LANG FILE N   the Nth ```LANG fence of FILE, counted from 1
#   sh_fences FILE N     the same for ```sh
#   example FILE NAME    the code parts of the schooling-example whose file is NAME
#   put LANG FILE N DEST the Nth ```LANG fence of FILE, written to DEST

AZ_COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB_ROOT=${LAB_ROOT:-/opt/azlab}
LAB_HOME=${LAB_HOME:-/home/ana}
PROMPT_DIR='~/azure'

clean_env() {
  local v
  for v in $(compgen -e); do
    case "$v" in AZURE_*|ARM_*|TF_*|MSI_*|IDENTITY_*) unset "$v" ;; esac
  done
}

lab() {
  mkdir -p "$LAB_ROOT"
  exec 9>"$LAB_ROOT/capture.lock"
  flock 9
  clean_env
  export HOME=$LAB_HOME TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PYTHONDONTWRITEBYTECODE=1
  [ -n "${PYTHON3_DIR:-}" ] && export PATH="$PYTHON3_DIR:$PATH"
  [ -f "$HOME/azure/env.sh" ] || { echo "no lab: run lesson 1's captures.sh first"; exit 1; }
  # shellcheck disable=SC1091
  . "$HOME/azure/env.sh"
  cd "$HOME/azure" || exit 1
}

block() { printf '##### %s\n' "$1"; }
at() { PROMPT_DIR=$1; }
say() { printf '%s\n' "$*"; }
run() {
  printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"
  bash -c "$*" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true
}

fences() { # LANG FILE N: the Nth fence labelled LANG in FILE, counted from 1
  python3 - "$1" "$2" "$3" <<'PY'
import re, sys
lang, path, n = sys.argv[1], sys.argv[2], int(sys.argv[3])
found = re.findall(r'^```' + re.escape(lang) + r'\n(.*?)^```$', open(path).read(), re.S | re.M)
if not 1 <= n <= len(found):
    sys.exit(f'{path}: no {lang} fence number {n} (there are {len(found)})')
sys.stdout.write(found[n - 1])
PY
}
sh_fences() { fences sh "$1" "$2"; }
put() { fences "$1" "$2" "$3" > "$4" || exit 1; }

example() {
  python3 - "$1" "$2" <<'PY'
import json, re, sys
text = open(sys.argv[1]).read()
blocks = re.findall(r'^```schooling-example\n(.*?)\n```$', text, re.S | re.M)
found = [b for b in (json.loads(x) for x in blocks) if b.get('file') == sys.argv[2]]
if len(found) != 1:
    sys.exit(f'{sys.argv[1]}: expected one example for {sys.argv[2]}, found {len(found)}')
sys.stdout.write(''.join(p['code'] for p in found[0]['parts']))
PY
}
