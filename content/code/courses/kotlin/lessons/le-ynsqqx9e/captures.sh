#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of kotlin, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every .kt file
# compiled here is lifted out of this lesson's .md by ../../lab.sh, so the
# file compiled is the block the student copies.
#
# What is STAGED rather than typed:
#   - the-lab and when-setup-fails run on the BARE machine, a stock Ubuntu
#     24.04 before anything of this course was installed, and throw it away
#     between failures with `rebare`, so each one starts from the machine the
#     lesson says it starts from;
#   - fail-path runs `kotlinc` with the PATH a terminal had before ~/.bashrc
#     gained its line (PLAIN_PATH=1), which is the terminal that was already
#     open when the line was added;
#   - fail-zip cuts the downloaded zip to 40 MB with `truncate`, which is
#     what a connection that dropped halfway leaves behind.
#
# Recorded on Ubuntu 24.04 with openjdk-21-jdk-headless 21.0.12.1, Kotlin
# 2.4.21 and Gradle 9.8.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
K=https://github.com/JetBrains/kotlin/releases/download/v2.4.21
G=https://services.gradle.org/distributions

block install
rebare
bare 'java -version; echo $?'
bare 'sudo apt install -y openjdk-21-jdk-headless unzip curl 2>&1 | grep -E "^(Need to get|After this operation|Setting up (openjdk-21|unzip|curl))"'

block download
bare 'mkdir -p ~/downloads ~/.local/share && cd ~/downloads'
BARE_D=downloads
bare "curl -fsSLO $K/kotlin-compiler-2.4.21.zip"
bare "curl -fsSLO $K/kotlin-compiler-2.4.21.zip.sha256"
bare 'echo "$(cat kotlin-compiler-2.4.21.zip.sha256)  kotlin-compiler-2.4.21.zip" | sha256sum -c'
bare "curl -fsSLO $G/gradle-9.8.2-bin.zip"
bare 'sha256sum gradle-9.8.2-bin.zip'
bare 'ls -lh'

block unpack
bare 'unzip -q kotlin-compiler-2.4.21.zip -d ~/.local/share'
bare 'unzip -q gradle-9.8.2-bin.zip -d ~/.local/share'
bare "echo 'export PATH=\"\$HOME/.local/share/kotlinc/bin:\$HOME/.local/share/gradle-9.8.2/bin:\$PATH\"' >> ~/.bashrc"
bare 'source ~/.bashrc'
bare 'ls ~/.local/share'
bare 'du -sh ~/.local/share/kotlinc ~/.local/share/gradle-9.8.2 /usr/lib/jvm/java-21-openjdk-amd64'
unset BARE_D

block check
bare 'java -version'
bare 'javac -version'
bare 'kotlinc -version'
bare 'gradle --version'

block fail-path
rebare
bare_quiet 'sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openjdk-21-jdk-headless unzip curl'
bare_quiet "mkdir -p ~/downloads ~/.local/share && cd ~/downloads && curl -fsSLO $K/kotlin-compiler-2.4.21.zip && unzip -q kotlin-compiler-2.4.21.zip -d ~/.local/share"
export PLAIN_PATH=1
bare 'kotlinc -version; echo $?'
bare '~/.local/share/kotlinc/bin/kotlinc -version'
bare 'echo $PATH'
unset PLAIN_PATH

block fail-java
rebare
bare_quiet 'sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq unzip curl'
bare_quiet "mkdir -p ~/downloads ~/.local/share && cd ~/downloads && curl -fsSLO $K/kotlin-compiler-2.4.21.zip && unzip -q kotlin-compiler-2.4.21.zip -d ~/.local/share"
bare 'kotlinc -version; echo $?'

block fail-zip
rebare
bare_quiet 'sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq unzip curl'
bare_quiet "mkdir -p ~/downloads && cd ~/downloads && curl -fsSLO $K/kotlin-compiler-2.4.21.zip && curl -fsSLO $K/kotlin-compiler-2.4.21.zip.sha256 && truncate -s 40M kotlin-compiler-2.4.21.zip"
BARE_D=downloads
bare 'echo "$(cat kotlin-compiler-2.4.21.zip.sha256)  kotlin-compiler-2.4.21.zip" | sha256sum -c'
bare 'unzip -q kotlin-compiler-2.4.21.zip -d ~/.local/share; echo $?'
bare 'ls -l kotlin-compiler-2.4.21.zip'
unset BARE_D

MD=$HERE/first-program.md
block hello
fresh kt/l01
put "$MD" Hello.kt
run 'kotlinc Hello.kt -include-runtime -d hello.jar'
run 'ls -lh hello.jar'
run 'java -jar hello.jar'

block small
run 'kotlinc Hello.kt -d small.jar'
run 'ls -lh small.jar'
run 'unzip -l small.jar'
run 'java -jar small.jar'

block courses
put "$MD" Courses.kt
run 'kotlinc Courses.kt -d courses-small.jar'
run 'java -jar courses-small.jar 2>&1 | head -2'
run 'kotlin courses-small.jar 2>&1 | head -2'
run 'kotlin -cp courses-small.jar CoursesKt'
run 'java -cp courses-small.jar:$HOME/.local/share/kotlinc/lib/kotlin-stdlib.jar CoursesKt'

block typo
put "$MD" Typo.kt
run 'kotlinc Typo.kt -include-runtime -d typo.jar; echo $?'
run 'ls typo.jar'

MD=$HERE/val-and-var.md
block week
put "$MD" Week.kt
run 'kotlinc Week.kt -include-runtime -d week.jar && java -jar week.jar'
block reassign
put "$MD" Reassign.kt
run 'kotlinc Reassign.kt -include-runtime -d reassign.jar'
block sessions
put "$MD" Sessions.kt
run 'kotlinc Sessions.kt -include-runtime -d sessions.jar && java -jar sessions.jar'

MD=$HERE/inference.md
block types
put "$MD" Types.kt
run 'kotlinc Types.kt -include-runtime -d types.jar && java -jar types.jar'
block declared
put "$MD" Declared.kt
run 'kotlinc Declared.kt -include-runtime -d declared.jar'
block converted
put "$MD" Converted.kt
run 'kotlinc Converted.kt -include-runtime -d converted.jar && java -jar converted.jar'

MD=$HERE/templates.md
block report
put "$MD" Report.kt
run 'kotlinc Report.kt -include-runtime -d report.jar && java -jar report.jar'
block upper
put "$MD" Upper.kt
run 'kotlinc Upper.kt -include-runtime -d upper.jar && java -jar upper.jar'
block compare
put "$MD" Compare.kt
run 'kotlinc Compare.kt -include-runtime -d compare.jar && java -jar compare.jar'
