#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of architecture-modeling, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in this
# lesson was copied from running it, so the next person can run it and see what moved.
#
#   sudo bash ../../lab.sh up          # once: the user ana, Docker, the Structurizr image
#   sudo bash captures.sh > out.txt    # every block, marked with ##### name
#
# THE FILES THE STUDENT SAVES ARE TAKEN OUT OF THE LESSON ITSELF. Each one follows a
# line saying "Save this as `name`" in a section of this lesson, and `put` copies that
# fence, byte for byte, into ana's folder. Saving them is the one thing staged rather
# than typed: a student does it in an editor. So a transcript here always ran the
# file the reader was given, never a copy that could drift.
#
# Everything else after a prompt was typed as shown, as ana, in a login shell; each
# line under it is what the command printed. Timings, dates and the sizes npm and
# the browser download report will differ on another machine and another day.
#
# Recorded with Node.js 22, OpenJDK 21 and Docker 29, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB_SH=${LAB_SH:-$HERE/../../lab.sh}
bash "$LAB_SH" reset

# on DIR 'command': what ana typed at her prompt in DIR (~ or ~/diagrams), and what it printed.
on() {
  local d=$1; shift
  local path=${d/#\~/\/home\/ana}
  printf 'ana@vm:%s$ %s\n' "$d" "$*"
  su - ana -c "cd $path && $*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

# put FILE: the fence after "Save this as `FILE`" in this lesson's sections, into ~ana/diagrams.
put() {
  python3 - "$HERE" "$1" > "/home/ana/diagrams/$1" <<'PY'
import glob, re, sys
here, name = sys.argv[1], sys.argv[2]
for md in sorted(glob.glob(here + '/*.md')):
    if md.endswith('.pt.md'):
        continue
    text = open(md, encoding='utf-8').read()
    m = re.search(r'Save this as `' + re.escape(name) + r'`[^\n]*\n(?:[^\n]*\n)*?```[a-z]*\n(.*?)\n```', text, re.S)
    if m:
        sys.stdout.write(m.group(1) + '\n')
        sys.exit(0)
sys.exit('no fence for ' + name)
PY
  chown ana "/home/ana/diagrams/$1"
}

block versions
on '~' 'mkdir diagrams'
on '~/diagrams' 'node --version'
on '~/diagrams' 'java -version'
on '~/diagrams' 'docker --version'

block mermaid-install
on '~/diagrams' 'npm install --no-audit --no-fund @mermaid-js/mermaid-cli@11.17.0'

block mermaid-render
put ticket.mmd
on '~/diagrams' 'npx mmdc -i ticket.mmd -o ticket.svg'
on '~/diagrams' 'ls -l ticket.svg'

block mermaid-error
sed 's/Paid --> Boarded/Paid -> Boarded/' /home/ana/diagrams/ticket.mmd > /home/ana/diagrams/broken.mmd
chown ana /home/ana/diagrams/broken.mmd
on '~/diagrams' 'npx mmdc -i broken.mmd -o broken.svg 2>&1 | head -5'
on '~/diagrams' 'npx mmdc -i broken.mmd -o broken.svg > /dev/null 2>&1; echo $?'

block plantuml-get
on '~/diagrams' 'curl -sSLO https://repo1.maven.org/maven2/net/sourceforge/plantuml/plantuml/1.2026.9/plantuml-1.2026.9.jar'
on '~/diagrams' 'java -jar plantuml-1.2026.9.jar -version | head -1'

block plantuml-svg
put purchase.puml
on '~/diagrams' 'java -jar plantuml-1.2026.9.jar -tsvg purchase.puml'
on '~/diagrams' 'ls -l purchase.svg'

block plantuml-txt
put hold.puml
on '~/diagrams' 'java -jar plantuml-1.2026.9.jar -tutxt hold.puml'
on '~/diagrams' 'cat hold.utxt'

block plantuml-syntax
sed 's/API -> Holds/API -> -> Holds/' /home/ana/diagrams/hold.puml > /home/ana/diagrams/broken.puml
chown ana /home/ana/diagrams/broken.puml
on '~/diagrams' 'java -jar plantuml-1.2026.9.jar -syntax < hold.puml'
on '~/diagrams' 'java -jar plantuml-1.2026.9.jar -syntax < broken.puml'

block structurizr
put workspace.dsl
on '~/diagrams' 'docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/usr/local/structurizr structurizr/structurizr:2026.09.19 validate -w workspace.dsl'
on '~/diagrams' 'mkdir c4'
on '~/diagrams' 'docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/usr/local/structurizr structurizr/structurizr:2026.09.19 export -w workspace.dsl -f mermaid -o c4'

block structurizr-render
on '~/diagrams' 'ls c4'
on '~/diagrams' 'npx mmdc -i c4/structurizr-Containers.mmd -o c4/containers.svg'
on '~/diagrams' 'grep -c "Charges payments through" c4/*.mmd'

block pipeline-fail
put check-diagrams.sh
on '~/diagrams' 'sh check-diagrams.sh; echo "exit status $?"'

block pipeline-pass
on '~/diagrams' 'rm broken.mmd broken.puml'
on '~/diagrams' 'sh check-diagrams.sh; echo "exit status $?"'
