#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Hello.java is
# lifted out of bytecode.md by ../../lab.sh, so the file compiled here is the
# block the student copies.
#
# What is STAGED rather than typed:
#   - the-lab and when-setup-fails run on the BARE machine, a stock Ubuntu
#     24.04 before anything of this course was installed, and throw it away
#     between failures with `rebare`, so each failure starts from the machine
#     the lesson says it starts from;
#   - the empty package lists of "Unable to locate package" are made by
#     deleting /var/lib/apt/lists, which is the state a machine is in before
#     its first `apt update`.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4 and maven
# 3.8.7-2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

block install
rebare
bare 'java -version; echo $?'
bare 'sudo apt install -y openjdk-25-jdk maven 2>&1 | grep -E "^(Need to get|After this operation|Setting up openjdk-25|Setting up maven)"'
bare 'java -version'
bare 'javac -version'
bare 'mvn -v'

block installed
bare 'ls -l /usr/lib/jvm'
bare 'apt-cache depends default-jre-headless | head -2'
bare 'update-alternatives --display java | head -3'
bare 'ls -C -T 0 /usr/lib/jvm/java-25-openjdk-amd64/bin'
bare 'du -sh /usr/lib/jvm/java-25-openjdk-amd64 /usr/lib/jvm/java-21-openjdk-amd64'
bare 'jshell --version'
bare 'jshell --version'

block fail-locate
rebare
bare 'sudo rm -rf /var/lib/apt/lists/*'
bare 'sudo apt install -y openjdk-25-jdk 2>&1 | tail -3; echo $?'
bare 'sudo apt update 2>&1 | tail -1'
bare 'apt-cache policy openjdk-25-jdk | head -3'

block fail-jre
rebare
bare 'sudo apt install -y openjdk-25-jre-headless >/dev/null 2>&1; java -version'
bare 'javac -version; echo $?'

block compile
fresh jvm
put "$HERE/bytecode.md" Hello.java
run 'javac Hello.java'
run 'ls -l'
run 'java Hello'
run 'file Hello.class'
run 'od -A d -t x1 -N 8 Hello.class'
run 'javap -c Hello'

block release8
run 'javac --release 8 Hello.java'
run 'javap -v Hello.class | grep major'
run 'java Hello'
run 'javac --release 7 Hello.java; echo $?'
run 'javac --release 25 Hello.java && javap -v Hello.class | grep major'

block fail-two
run '/usr/lib/jvm/java-21-openjdk-amd64/bin/java Hello; echo $?'
run 'JAVA_HOME=/usr/lib/jvm/default-java mvn -v | grep "Java version"'
run 'mvn -v | grep "Java version"'

block version
run 'java -version'
run 'java -XshowSettings:properties -version 2>&1 | grep -E "java.(version|vendor|specification.version) ="'
exit 0
