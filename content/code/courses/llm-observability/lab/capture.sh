# Sourced by every lesson's captures.sh: the prompts, and the one way a file
# reaches ana's machine.
#
#   on CMD      ana typed CMD in ~/obs, with the environment active
#   home CMD    ana typed CMD in ~, with the environment active
#   bare CMD    ana typed CMD in ~ in a new terminal, without the environment
#   put FILE    stdin becomes ~/obs/FILE, refused unless some lesson shows
#               exactly that text as a fence, so no lesson can lean on a file
#               the student was never shown
#   stage FILE MD   ~/obs/FILE becomes the program lesson MD shows whole,
#               read out of the lesson rather than out of a copy of it
#   block NAME  a marker between transcripts, never quoted
#   quiet CMD   a step of the lab's, its output shown only if it fails
#
# Every command runs with stdin closed, as a terminal's would be when nobody
# types into it, and gives up after an hour.
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LAB_SH=${LAB_SH:-$COURSE/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
run_as() { lab exec "timeout 3600 bash -c $(printf '%q' "$*")"; }
on() { printf 'ana@dev:~/obs$ %s\n' "$*"; run_as "$*" 2>&1 < /dev/null || true; }
home() { printf 'ana@dev:~$ %s\n' "$*"; IN_HOME=1 run_as "$*" 2>&1 < /dev/null || true; }
bare() { printf 'ana@dev:~$ %s\n' "$*"; IN_HOME=1 BARE=1 run_as "$*" 2>&1 < /dev/null || true; }
put() {
  local text; text=$(cat; printf x); text=${text%x}
  printf '%s' "$text" | python3 "$COURSE/lab/fences.py" has "$COURSE" || exit 1
  printf '%s' "$text" | lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"
}
stage() {  # stage FILE LESSON_MD: the annotated example or plain fence naming FILE
  local md=$COURSE/lessons/$2
  { python3 "$COURSE/lab/fences.py" example "$md" "$1" 2>/dev/null \
      || python3 "$COURSE/lab/fences.py" named "$md" "$1"; } | put "$1"
}
# `ollama run` draws a spinner on stderr while the model loads, and a terminal
# erases it as soon as the reply starts; homeq drops it. It also wraps a long
# reply at 80 columns by printing part of a word, stepping back over it
# (ESC[nD), erasing it (ESC[K) and printing it again on the next line; screen
# applies those two codes the way a terminal does, and strips the trailing
# spaces and blank lines a terminal does not show. Nothing else is changed.
screen() {
  python3 -c '
import re, sys
lines = []
for raw in sys.stdin.read().split("\n"):
    out, cur = [], 0
    for tok in re.split(r"(\x1b\[\d*[DK])", raw):
        m = re.fullmatch(r"\x1b\[(\d*)([DK])", tok)
        if m and m.group(2) == "D":
            cur = max(0, cur - int(m.group(1) or 1))
        elif m:
            del out[cur:]
        else:
            for ch in tok:
                out[cur:cur + 1] = [ch]
                cur += 1
    lines.append("".join(out).rstrip())
while lines and not lines[-1]:
    lines.pop()
print("\n".join(lines))
'
}
homeq() { printf 'ana@dev:~$ %s\n' "$*"; IN_HOME=1 run_as "$*" 2>/dev/null < /dev/null | screen || true; }
block() { printf '##### %s\n' "$1"; }
quiet() { "$@" > /tmp/llmobs-capture-step.log 2>&1 || { cat /tmp/llmobs-capture-step.log; exit 1; }; }
