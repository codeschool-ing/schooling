#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - The JDK and Maven are already installed (lab.sh up), so the two apt
#     commands in the-chain-so-far.md are shown and not run here.
#   - ~/.mavenrc is moved aside for the first `mvn -v`, so the four Unsafe
#     warnings a fresh install prints are real; the line the lesson types then
#     writes it again, and a trap puts the lab's own copy back on any exit.
#   - The older JDK on the path is JDK 21 (openjdk-21-jdk, installed in the
#     lab), selected with JAVA_HOME passed in the environment: it stands for an
#     `export JAVA_HOME=...` line in ~/.bashrc, which is how a student meets it.
#   - `sudo update-java-alternatives -s ...` is SHOWN AND NOT RUN: it changes
#     the machine-wide java, which every other lesson's capture depends on. Its
#     listing form (-l) is run, with Ubuntu's default PATH, because the lab
#     runs ana with a PATH that has no sbin directory.
#   - "command not found" is a fresh ubuntu:24.04 container (pulled through
#     the lab's Docker mirror), because the lab machine has Maven installed.
#   - ~/isbn-check is written from this lesson's own .md files (take, and the
#     schooling-example pom), and checked against lab/projects/isbn-check,
#     which lessons 2 and 3 build again.
#   - Every Maven artifact comes from the lab's warm ~/.m2 and Google's mirror
#     of Central; no transcript shows a download.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4.1, Maven 3.8.7, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"
PROJECT="$COURSE/lab/projects/isbn-check"
MAVENRC='MAVEN_OPTS="--sun-misc-unsafe-memory-access=allow"'
restore_mavenrc() { printf '%s\n' "$MAVENRC" | put .mavenrc; }
trap restore_mavenrc EXIT

# The pom of a schooling-example in MD whose file is FILE, as the copy button
# hands it over: its parts joined with newlines.
example() {
  python3 - "$1" "$2" <<'PY'
import json, sys
md, name = sys.argv[1], sys.argv[2]
blocks = []
cur = None
for line in open(md, encoding='utf-8').read().split('\n'):
    if line.startswith('```'):
        if cur is None:
            cur, info = [], line[3:].strip()
        else:
            if info == 'schooling-example':
                ex = json.loads('\n'.join(cur))
                if ex.get('file') == name:
                    blocks.append('\n'.join(p['code'] for p in ex['parts']))
            cur = None
    elif cur is not None:
        cur.append(line)
if len(blocks) != 1:
    sys.exit('example: %d examples of %s in %s' % (len(blocks), name, md))
sys.stdout.write(blocks[0] + '\n')
PY
}
same() {  # same LAB-FILE HOME-FILE: what ana has is the lab's project file
  lab exec "cat ~/$2" | cmp -s - "$1" || echo "!!! ~/$2 differs from $1" >&2
}

quiet 'rm -rf ~/isbn-check ~/.m2/repository/com/example/isbn-check'

block versions
run 'java -version'
run 'javac -version'

block unsafe
quiet 'mv ~/.mavenrc ~/.mavenrc.lab'
run 'mvn -v'
run "echo '$MAVENRC' >> ~/.mavenrc"
quiet 'rm -f ~/.mavenrc.lab'
run 'cat ~/.mavenrc'

block mvn-v
run 'mvn -v'

block not-found
run "docker run --rm ubuntu:24.04 bash -c 'java -version; mvn -v'"

block old-jdk
EXTRA_ENV='JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' run 'echo $JAVA_HOME'
EXTRA_ENV='JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' run 'mvn -v'
EXTRA_ENV='PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' run 'update-java-alternatives -l'

block project
quiet 'mkdir -p ~/isbn-check/src/main/java/com/example/isbn ~/isbn-check/src/test/java/com/example/isbn'
example a-project-by-hand.md pom.xml | put isbn-check/pom.xml
take a-project-by-hand.md $'package com.example.isbn;\n\nimport org.apache' isbn-check/src/main/java/com/example/isbn/IsbnCheck.java
take a-project-by-hand.md $'package com.example.isbn;\n\nimport static' isbn-check/src/test/java/com/example/isbn/IsbnCheckTest.java
same "$PROJECT/src/main/java/com/example/isbn/IsbnCheck.java" isbn-check/src/main/java/com/example/isbn/IsbnCheck.java
same "$PROJECT/src/test/java/com/example/isbn/IsbnCheckTest.java" isbn-check/src/test/java/com/example/isbn/IsbnCheckTest.java
at '~/isbn-check'
run 'find . -type f | sort'
run 'mvn compile'
run 'ls target/classes/com/example/isbn'

block old-jdk-build
EXTRA_ENV='JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' run 'mvn -q compile'

block tree
run 'mvn dependency:tree'
run 'mvn dependency:tree -Dverbose -Dincludes=commons-logging,commons-beanutils'
run 'ls ~/.m2/repository/commons-validator/commons-validator/1.11.0'

block lifecycle
run 'mvn package'
run 'mvn -q test'
run 'mvn install | tail -n 8'
run 'ls ~/.m2/repository/com/example/isbn-check/1.0.0'

block defaults
run 'cp pom.xml pom.xml.keep'
run "sed -i '/<build>/,/<\\/build>/d' pom.xml"
run 'mvn -q package'
run "mvn package -Dmaven.compiler.source=25 -Dmaven.compiler.target=25 | grep -E 'plugin:|Tests run|BUILD'"
run 'mv pom.xml.keep pom.xml'

block pin
lab exec 'cat ~/isbn-check/pom.xml' | python3 -c '
import re, subprocess, sys
pom = sys.stdin.read()
build = subprocess.run(["python3", sys.argv[1], "extract", sys.argv[2], "  <build>"],
                       capture_output=True, text=True, check=True).stdout
new = re.sub(r"  <build>.*</build>\n", lambda m: build, pom, flags=re.S)
sys.stdout.write(new)' "$COURSE/lab/fence.py" plugins-and-repositories.md > /tmp/l1-pom.xml
put isbn-check/pom.xml < /tmp/l1-pom.xml
rm -f /tmp/l1-pom.xml
same "$PROJECT/pom.xml" isbn-check/pom.xml
run 'mvn dependency:tree | grep maven-dependency-plugin'

block run
run 'jar tf target/isbn-check-1.0.0.jar'
run 'java -cp target/isbn-check-1.0.0.jar com.example.isbn.IsbnCheck 978-0-306-40615-7'
run 'mvn -q dependency:build-classpath -Dmdep.includeScope=runtime -Dmdep.outputFile=classpath.txt'
run "tr ':' '\\n' < classpath.txt"
run 'java -cp target/isbn-check-1.0.0.jar:$(cat classpath.txt) com.example.isbn.IsbnCheck 978-0-306-40615-7 0-306-40615-2 978-0-306-40615-8'
