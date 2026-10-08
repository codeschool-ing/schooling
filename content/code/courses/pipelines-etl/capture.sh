# The helpers every lesson's captures.sh sources. Not run on its own.
#
#   on 'COMMAND'     what ana typed in ~/etl, and what it printed
#   root 'ARGS'      ana running the shop's command with sudo: `sudo shop ARGS`
#   put PATH         a file ana wrote under ~/etl, from stdin
#   code NAME PATH   that file printed as a block of the lesson
#   block NAME       the start of the next block
#
# Every block is marked `##### NAME` in the output, and the lesson quotes the
# lines between one mark and the next exactly as they came out.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@vm:~/etl$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
root() { printf 'ana@vm:~/etl$ sudo shop %s\n' "$*"; lab $* 2>&1 || true; }
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
code() { printf '##### %s\n' "$1"; lab exec "cat '$2'"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/etl-capture.lock; flock 9
