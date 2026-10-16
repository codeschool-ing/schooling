#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. What is STAGED rather
# than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`;
#   - the keyboard: the desk programs read commands from standard input, and
#     the lesson types them with `printf`, so every run sees the same lines.
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/presentation"

block separating-presentation
at presentation
put "$HERE/separating-presentation.md" tangled.py
run "printf 'lend B1 bia\nlend B2 bia\nlend B3 bia\nreturn B1\n' | python3 tangled.py"

block mvc
put "$HERE/mvc.md" desk_model.py
put "$HERE/mvc.md" mvc.py
run "printf 'lend B1 bia\nlend B2 bia\nlend B3 bia\nday 2026-03-20\nreturn B1\nreturn B1\n' | python3 mvc.py"

block mvc-on-the-server
put "$HERE/mvc-on-the-server.md" web.py
run python3 web.py

block mvp
put "$HERE/mvp.md" mvp.py
run python3 mvp.py
put "$HERE/mvp.md" test_presenter.py
run python3 -m unittest -v test_presenter.py

block mvvm
put "$HERE/mvvm.md" mvvm.py
run python3 mvvm.py

block comparing
run 'grep -n "^from desk_model" *.py'
run 'grep -c "print" desk_model.py'
run wc -l mvc.py web.py mvp.py mvvm.py
exit 0
