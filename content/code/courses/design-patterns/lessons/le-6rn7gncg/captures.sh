#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. What is STAGED rather
# than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`;
#   - the national catalogue in adapter.py is a stand-in with two made-up
#     records; nothing reaches the network.
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/gof"

block factory-and-builder
at gof
put "$HERE/factory-and-builder.md" factory.py
run python3 factory.py
put "$HERE/factory-and-builder.md" builder.py
run python3 builder.py

block singleton
put "$HERE/singleton.md" catalogue.py
put "$HERE/singleton.md" singleton.py
run python3 singleton.py

block adapter-and-facade
put "$HERE/adapter-and-facade.md" adapter.py
run python3 adapter.py
put "$HERE/adapter-and-facade.md" facade.py
run python3 facade.py

block decorator-and-proxy
put "$HERE/decorator-and-proxy.md" decorator.py
run python3 decorator.py
put "$HERE/decorator-and-proxy.md" proxy.py
run python3 proxy.py

block strategy-and-observer
put "$HERE/strategy-and-observer.md" strategy.py
run python3 strategy.py
put "$HERE/strategy-and-observer.md" observer.py
run python3 observer.py

block command-and-state
put "$HERE/command-and-state.md" command.py
run python3 command.py
put "$HERE/command-and-state.md" state.py
run python3 state.py

block template-method-and-iterator
put "$HERE/template-method-and-iterator.md" template.py
run python3 template.py
put "$HERE/template-method-and-iterator.md" iterator.py
run python3 iterator.py

block built-into-the-language
put "$HERE/built-into-the-language.md" vanish.py
run python3 vanish.py
exit 0
