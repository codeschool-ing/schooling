#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the bookshop as lesson 19 left it, and a fresh bookshop database;
#   - pom.xml, the two versions of BooksApiIT.java and books.jmx are written
#     here from the lesson's own fences (the first BooksApiIT is taken from
#     the example in given-when-then.md, the final one and the plan from
#     tokens-in-a-test.md and a-test-plan.md), and every file the lesson shows
#     is then compared with this lesson's stage, byte for byte, by `shown`;
#   - the detour in given-when-then.md (a wrong media type) is the sed the
#     lesson shows, and the sed that puts it back;
#   - the JMeter download goes through this sandbox's HTTPS proxy, passed as
#     https_proxy for those two commands only; a student's machine needs none;
#   - "a new terminal" after the PATH line is added to ~/.bashrc: each command
#     here runs in a fresh non-interactive shell, which never reads .bashrc,
#     so the commands after it run with that PATH set in their environment;
#   - the application is started with java -jar in the background where the
#     student starts it in a second terminal, with a fixed BOOKSHOP_JWT_SECRET
#     (the student's comes from `openssl rand -base64 32`, as in lesson 15),
#     and stopped where the student presses Ctrl+C.
#
# The machine is shared: other work ran on it while these were recorded, so
# throughput and response times differ on every run, and so do ports, PIDs,
# dates and durations. The prose quotes one run and never promises the same
# numbers.
#
# Recorded on Ubuntu 24.04, 4 processors, OpenJDK 25.0.4, Maven 3.8.7,
# PostgreSQL 16.15, Docker Engine 29.8.2, JMeter 5.6.3, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"
LESSON=$(pwd)
STAGE=$COURSE/lab/stages/le-q3854jqh
BS=/home/ana/bookshop
IT=src/test/java/com/example/bookshop/BooksApiIT.java
PLAN=src/test/jmeter/books.jmx
PROXY="https_proxy=${HTTPS_PROXY:-${https_proxy:?the sandbox proxy is not set}}"
JPATH='PATH=/home/ana/opt/apache-jmeter-5.6.3/bin:/usr/local/bin:/usr/bin:/bin'
SECRET='BOOKSHOP_JWT_SECRET=q9mFZ3tL0YwKc1vN8rXe2hUaG5sB7dPj4oIyT6nRfVw='

# the code of the Nth schooling-example of an .md, written to a file of ~/bookshop
example_to() { python3 - "$1" "$2" > "$BS/$3" <<'PY'
import json, re, sys
md = open(sys.argv[1], encoding='utf-8').read()
ex = re.findall(r'```schooling-example\n(.*?)\n```', md, re.S)
print('\n'.join(p['code'] for p in json.loads(ex[int(sys.argv[2])])['parts']))
PY
chown ana:ana "$BS/$3"; }
fence_to() { python3 "$COURSE/lab/fence.py" extract "$1" "$2" > "$BS/$3"; chown ana:ana "$BS/$3"; }

stage le-7zncse9p           # the bookshop as lesson 19 left it
db
at '~/bookshop'

########################################################### through-the-port.md
fence_to through-the-port.md '<?xml' pom.xml
shown through-the-port.md pom.xml
block tree
run "mvn dependency:tree -Dincludes=io.rest-assured,org.apache.groovy,org.apache.httpcomponents,org.hamcrest | grep -E 'rest-assured|groovy|httpc|hamcrest'"
run 'grep groovy.version ~/.m2/repository/io/rest-assured/rest-assured-parent/6.1.0/rest-assured-parent-6.1.0.pom'

########################################################### given-when-then.md
mkdir -p $BS/src/test/java/com/example/bookshop
example_to given-when-then.md 0 $IT
block first
run "mvn verify -Dit.test=BooksApiIT | grep -E 'Tomcat started|Started BooksApiIT|Tests run:.*BooksApiIT|BUILD'"
block detour
run "sed -i 's|\"application/problem+json\"|\"application/json\"|' $IT"
run "mvn verify -Dit.test=BooksApiIT | grep -A9 '<<< FAILURE'"
block back
run "sed -i 's|contentType(\"application/json\")|contentType(\"application/problem+json\")|' $IT"
run "mvn verify -Dit.test=BooksApiIT | grep -E 'Tests run:.*BooksApiIT|BUILD'"

########################################################### tokens-in-a-test.md
example_to tokens-in-a-test.md 0 $IT
shown tokens-in-a-test.md $IT
block all
run "mvn verify | grep -E 'postgres:16-alpine started|Tomcat started|Tests run:.*[a-z]IT|BUILD'"

########################################################### installing-jmeter.md
at '~'
quiet 'rm -rf ~/opt/apache-jmeter-5.6.3 ~/apache-jmeter-5.6.3.tgz ~/apache-jmeter-5.6.3.tgz.sha512'
quiet "sed -i '/apache-jmeter/d' ~/.bashrc"
block apt
run 'apt-cache policy jmeter | head -n 3'
block download
EXTRA_ENV=$PROXY run 'curl -sLO https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.6.3.tgz'
EXTRA_ENV=$PROXY run 'curl -sLO https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.6.3.tgz.sha512'
run 'ls -l apache-jmeter-5.6.3.tgz*'
block checksum
run 'cat apache-jmeter-5.6.3.tgz.sha512'
run 'sha512sum -c apache-jmeter-5.6.3.tgz.sha512'
block unpack
run 'mkdir -p ~/opt && tar -xzf apache-jmeter-5.6.3.tgz -C ~/opt'
run 'ls ~/opt/apache-jmeter-5.6.3'
block path
run "echo 'export PATH=\"\$HOME/opt/apache-jmeter-5.6.3/bin:\$PATH\"' >> ~/.bashrc"
block version
EXTRA_ENV=$JPATH run 'command -v jmeter'
EXTRA_ENV=$JPATH run 'jmeter --version'

########################################################### a-test-plan.md
at '~/bookshop'
mkdir -p $BS/src/test/jmeter
example_to a-test-plan.md 0 $PLAN
shown a-test-plan.md $PLAN
block package
run 'mvn -q package -DskipTests'
EXTRA_ENV=$SECRET start
block cold
EXTRA_ENV=$JPATH run 'jmeter -n -t src/test/jmeter/books.jmx -l target/jmeter/results.jtl -j target/jmeter/jmeter.log -e -o target/jmeter/report'
block again
EXTRA_ENV=$JPATH run 'jmeter -n -t src/test/jmeter/books.jmx -l target/jmeter/results.jtl -j target/jmeter/jmeter.log -e -o target/jmeter/report'
block setenv
run "echo 'JVM_ARGS=\"\$JVM_ARGS --sun-misc-unsafe-memory-access=allow\"' > ~/opt/apache-jmeter-5.6.3/bin/setenv.sh"
block warm
EXTRA_ENV=$JPATH run 'time jmeter -n -t src/test/jmeter/books.jmx -l target/jmeter/results.jtl -j target/jmeter/jmeter.log -f -e -o target/jmeter/report'
block report
run 'ls target/jmeter target/jmeter/report'

########################################################### reading-the-numbers.md
block total
run "python3 -c 'import json; print(json.dumps(json.load(open(\"target/jmeter/report/statistics.json\"))[\"Total\"], indent=1))'"
run 'grep aggregate_rpt_pct ~/opt/apache-jmeter-5.6.3/bin/jmeter.properties'
block sweep
EXTRA_ENV=$JPATH run 'for t in 1 5 10 20 50 100; do printf "%3d threads  " $t; jmeter -n -t src/test/jmeter/books.jmx -Jthreads=$t -Jloops=$((10000 / t)) -l target/jmeter/sweep.jtl -j target/jmeter/sweep.log -f | grep "summary ="; done'
block nproc
run 'nproc'
stop
block down
EXTRA_ENV=$JPATH run 'jmeter -n -t src/test/jmeter/books.jmx -Jloops=50 -l target/jmeter/down.jtl -j target/jmeter/down.log -f | grep "summary ="'
run 'cut -d, -f4,5 target/jmeter/down.jtl | sort | uniq -c'

########################################################### the end state is the stage
block end-state
for f in pom.xml $IT $PLAN; do
  cmp -s "$STAGE/$f" "$BS/$f" || echo "!!! $f differs from the stage"
done
rm -rf /tmp/l20-built && mkdir -p /tmp/l20-built && cp -a $BS/pom.xml $BS/src /tmp/l20-built/
stage le-q3854jqh
diff -r /tmp/l20-built/src $BS/src && diff /tmp/l20-built/pom.xml $BS/pom.xml \
  && echo 'the lesson ends where the stage ends' || echo '!!! the lesson does not end at the stage'
rm -rf /tmp/l20-built
