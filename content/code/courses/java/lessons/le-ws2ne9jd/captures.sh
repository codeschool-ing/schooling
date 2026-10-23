#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program and
# both versions of pom.xml are lifted out of the lesson's own .md by
# ../../lab.sh, so the file built here is the block the student copies.
#
# What is STAGED rather than typed:
#   - the local Maven repository, ~/.m2/repository, is emptied before the
#     first build, so that build downloads what a student's first build
#     downloads. The recording computer reaches Maven Central through a proxy
#     named in ~/.m2/settings.xml (see ../../lab.sh); the student needs none.
#   - that first build is retried, up to three times, when the proxy drops a
#     download; only the attempt that succeeded is printed. The number of
#     downloads and the times Maven reports differ on every run.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4 and maven
# 3.8.7-2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh turns -e on; a failing build is a capture, not a reason to stop

block compile
fresh pkgs
put "$HERE/packages.md" src/com/example/library/Book.java
put "$HERE/packages.md" src/com/example/library/app/Main.java
run 'javac -d out src/com/example/library/Book.java src/com/example/library/app/Main.java'
run 'find out -type f'
run 'java -cp out com.example.library.app.Main'
run 'java -cp out Main'
run 'cd out/com/example/library/app && java Main'

block sourcepath
run 'rm -rf out && javac -d out -sourcepath src src/com/example/library/app/Main.java && find out -type f'
run 'mv src/com/example/library/Book.java src/Book.java'
run 'rm -rf out && javac -d out -sourcepath src src/com/example/library/app/Main.java'
run 'mv src/Book.java src/com/example/library/Book.java'

block ambiguous
put "$HERE/imports.md" src/com/example/library/app/Dates.java 1
run 'javac -d out src/com/example/library/app/Dates.java'

block single
put "$HERE/imports.md" src/com/example/library/app/Dates.java 2
run 'javac -d out src/com/example/library/app/Dates.java && java -cp out com.example.library.app.Dates'

block module-import
put "$HERE/imports.md" Modules.java
run 'java Modules.java'
run 'javac --release 21 -d /tmp/m21 Modules.java'

block layout
fresh library
put "$HERE/maven-project.md" pom.xml
put "$HERE/maven-project.md" src/main/java/com/example/library/App.java
run 'mkdir -p src/main/java/com/example/library && cp ~/pkgs/src/com/example/library/Book.java src/main/java/com/example/library/'
run 'find . -type f | sort'

block first-build
# The first build downloads Maven's plugins through the recording computer's
# proxy, which now and then drops a connection ("Attempted read from closed
# stream"). Up to three attempts are made, each from an empty local
# repository, and only the attempt that succeeded is printed.
for attempt in 1 2 3; do
  quiet 'rm -rf ~/.m2/repository first-build.log target'
  out=$(run 'mvn -B clean package > first-build.log; echo $?')
  [ "$(printf '%s\n' "$out" | tail -1)" = 0 ] && break
done
printf '%s\n' "$out"
run 'grep -c "Downloaded from" first-build.log'
run 'tail -5 first-build.log'

block build
run 'mvn clean package'
run 'find target -name "*.class" -o -name "*.jar" | sort'
run 'java -cp target/classes com.example.library.App'

block jar
run 'java -jar target/library-1.0-SNAPSHOT.jar'
put "$HERE/building.md" pom.xml
run 'mvn -q package'
run 'java -jar target/library-1.0-SNAPSHOT.jar'
run 'jar tf target/library-1.0-SNAPSHOT.jar'
run 'jar xf target/library-1.0-SNAPSHOT.jar META-INF/MANIFEST.MF && cat META-INF/MANIFEST.MF'

block java-home
run 'JAVA_HOME=/usr/lib/jvm/default-java mvn -q clean package'
run 'mvn -q clean package && echo built'
exit 0
