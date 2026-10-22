#!/usr/bin/env bash
# The terminal sessions quoted in lesson 40 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every source file
# is lifted out of the lesson's own .md by ../../lab.sh, at the path its first
# line names, so the tree compiled here is the one the student copies.
#
# What is STAGED rather than typed: nothing but the files. Shortcut.java is
# written into the tree only for the block that shows it refused, and removed
# afterwards, as the lesson tells the student to do.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e

fresh modules
for f in src/com.example.library/module-info.java \
         src/com.example.library/com/example/library/api/Catalogue.java \
         src/com.example.library/com/example/library/internal/Index.java \
         src/com.example.app/module-info.java \
         src/com.example.app/com/example/app/Main.java; do
  put "$HERE/module-info.md" "$f"
done

block tree
run 'find src -name "*.java" | sort'

block compile
run 'javac -d out --module-source-path src -m com.example.library,com.example.app'
run 'find out -name "*.class" | sort'
run 'java --module-path out -m com.example.app/com.example.app.Main'

block shortcut
put "$HERE/module-info.md" src/com.example.app/com/example/app/Shortcut.java
run 'javac -d out --module-source-path src -m com.example.library,com.example.app'
run 'rm src/com.example.app/com/example/app/Shortcut.java'

block jar
run 'mkdir -p lib && jar --create --file lib/library.jar -C out/com.example.library .'
run 'jar --describe-module --file lib/library.jar'

block peek
put "$HERE/strong-encapsulation.md" src/com.example.app/com/example/app/Peek.java
run 'javac -d out --module-source-path src -m com.example.library,com.example.app'
run 'java --module-path out -m com.example.app/com.example.app.Peek'
run 'java --module-path out --add-opens com.example.library/com.example.library.internal=com.example.app -m com.example.app/com.example.app.Peek'

block classpath
run 'java -cp out/com.example.library:out/com.example.app com.example.app.Peek'

block bytes
put "$HERE/strong-encapsulation.md" Bytes.java
run 'java Bytes.java'

block list
run 'java --list-modules | wc -l'
run 'java --list-modules | head -5'
run 'jdeps --module-path out -s -m com.example.app'

block jlink
run 'jlink --module-path out --add-modules com.example.app --output image'
run 'image/bin/java --list-modules'
run 'image/bin/java -m com.example.app/com.example.app.Main'
run 'du -sh image /usr/lib/jvm/java-25-openjdk-amd64'
exit 0
