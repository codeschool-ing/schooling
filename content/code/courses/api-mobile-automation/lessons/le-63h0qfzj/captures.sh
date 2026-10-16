#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of api-mobile-automation, as the
# script that produces them. Every transcript in the lesson was copied from its
# output, where each block starts with a line `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON. Section `java-and-maven`
# installs openjdk-21-jdk-headless and maven with apt-get, which is how this
# machine has them; boxoffice.mjs is lesson 1's, and every file under
# restassured/ is a block of this lesson, written by ../../lab.sh. What is
# STAGED rather than typed:
#   - the project as each section leaves it. lab.sh writes the files of the
#     whole lesson; this script sets aside the test classes and brings each one
#     back when its section has the student save it. OrdersTest.java is saved
#     twice, and section `extracting`'s version is read from that section;
#   - Maven's downloads. ~/.m2 already held every artifact of the pom.xml when
#     this ran, so no transcript shows the `Downloading from central` lines a
#     first run prints. Maven reached Maven Central through this sandbox's
#     proxy, named in ~/.m2/settings.xml (see ../../lab.sh);
#   - the servers, started in the background where the lesson has the student
#     start them in a terminal of their own: boxoffice on 8080 and, in
#     "other-port", a second one on 8081 whose log is printed;
#   - in "shows-fail", the student's edit of hasSize(3) to hasSize(4), made
#     with sed and undone afterwards;
#   - in "no-surefire", "no-build" and "no-build-clean", the pom.xml with the Surefire block, and
#     then the whole <build> block, removed, and put back afterwards.
# Times, dates and the order JUnit runs methods in are those of the recording.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with OpenJDK 21.0.12.1, Maven 3.8.7,
# Node 22.22.0, REST Assured 6.0.1, JUnit 6.1.3, TZ=America/Sao_Paulo, as user
# ana. See ../../lab.sh for the rest.

source "$(dirname "$0")/../../lab.sh"
LESSON=$(cd "$(dirname "$0")" && pwd)
project 7 /home/ana/boxoffice
RA=/home/ana/boxoffice/restassured
T=$RA/src/test/java/boxoffice
STASH=/tmp/lab-07-stash
rm -rf $STASH && mkdir -p $STASH && mv $T/*.java $STASH/ && cp $RA/pom.xml $STASH/
rm -f /tmp/lab-07-rc
bring() { for f; do cp "$STASH/$f" "$T/"; done; chown -R ana:ana $RA; }

# run_rc CMD: run it like `run`, then show `echo $?` with the code CMD exited
# with. Each `run` is a shell of its own, so a typed `echo $?` would only ever
# report the shell that ran it.
run_rc() {
  prompt; printf '%s\n' "$1"
  as_ana "script -qec $(printf '%q' "$1; echo \$? > /tmp/lab-07-rc") /dev/null" 2>&1 | strip
  prompt; echo 'echo $?'; cat /tmp/lab-07-rc
}

# saved_in MD PATH: the block section MD of this lesson hands the student as PATH.
saved_in() {
  python3 - "$LESSON/$1" "$2" <<'PY'
import re, sys
lines = open(sys.argv[1]).read().split("\n")
for i, l in enumerate(lines):
    if re.search(r"[Ss]ave it as `" + re.escape(sys.argv[2]) + r"`:\s*$", l):
        j = i + 1
        while not lines[j].startswith("```"):
            j += 1
        k = j + 1
        while not lines[k].startswith("```"):
            k += 1
        print("\n".join(lines[j + 1:k]))
        break
else:
    sys.exit("no block for " + sys.argv[2])
PY
}

here /home/ana
block setup-java
run 'java -version'
run 'mvn -version'

here /home/ana/boxoffice
serve api 'node boxoffice.mjs'

bring HealthTest.java
block layout
run 'find restassured -type f'

block first-run
go restassured
run 'mvn test'

bring ShowsTest.java
block shows-run
run_rc 'mvn -q test -Dtest=ShowsTest'

block shows-fail
sed -i 's/hasSize(3)/hasSize(4)/' $T/ShowsTest.java
run 'mvn -q test -Dtest=ShowsTest'
bring ShowsTest.java

saved_in extracting.md restassured/src/test/java/boxoffice/OrdersTest.java > $T/OrdersTest.java
chown ana:ana $T/OrdersTest.java
block orders-run
n=$(wc -l < /tmp/lab-api.log)
run 'mvn -q test -Dtest=OrdersTest'
block orders-log
tail -n +$((n + 1)) /tmp/lab-api.log

bring Api.java OrdersTest.java
here /home/ana/boxoffice
serve second 'PORT=8081 node boxoffice.mjs'
here $RA
block other-port
run 'mvn -q test -Dtest=OrdersTest -Dboxoffice.url=http://localhost:8081'
block other-port-log
cat /tmp/lab-second.log
halt second

bring HeadTest.java
block full-run
run_rc 'mvn -q test'

block reports
run 'ls target/surefire-reports'
run "grep '<testcase' target/surefire-reports/TEST-boxoffice.OrdersTest.xml"

block one-test
run_rc "mvn -q test -Dtest='OrdersTest#sevenSeatsAreRefused'"

block no-surefire
python3 - $RA/pom.xml <<'PY'
import re, sys
t = open(sys.argv[1]).read()
t = re.sub(r"      <plugin>\n        <groupId>org.apache.maven.plugins</groupId>\n        <artifactId>maven-surefire-plugin</artifactId>.*?</plugin>\n", "", t, flags=re.S)
open(sys.argv[1], "w").write(t)
PY
run_rc 'mvn test'

block no-build
python3 - $RA/pom.xml <<'PY'
import re, sys
t = open(sys.argv[1]).read()
t = re.sub(r"\n  <build>.*?</build>\n", "\n", t, flags=re.S)
open(sys.argv[1], "w").write(t)
PY
run 'mvn -q test'
block no-build-clean
run_rc 'mvn -q clean test'
cp $STASH/pom.xml $RA/pom.xml
halt api
