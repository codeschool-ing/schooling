#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - ~/bookshop as lesson 18 left it. Every file the lesson shows is written
#     here as ana from this lesson's stage and compared with the lesson byte
#     for byte by `shown`. pom.xml is never shown whole: the lesson shows its
#     <build> element twice and its <dependencies> element once, and `setpom`
#     puts each fence into the pom as the student replaces it. After the last
#     one the pom is compared with the stage's, whole.
#   - Docker Engine. The lab had Docker's own packages (29.8.2) installed and
#     running before the course began, so the installation commands of the
#     lesson were NOT run here; what is captured is how the result is checked.
#     The daemon pulls through mirror.gcr.io, Google's cache of Docker Hub
#     (the lab's own arrangement, see lab.sh); the names and digests are
#     Docker Hub's.
#   - The socket. The lab leaves /var/run/docker.sock at mode 666 so that
#     every lesson's captures can reach it; for the length of this script it is
#     put back to the mode Docker's own packages give it, root:docker 660, and
#     restored on exit. Everything here is therefore what a student's machine
#     answers.
#   - The shell that is not yet in the docker group. ana IS in the group; a
#     login shell started before `usermod` is not, and that shell is
#     reproduced with setpriv: ana's uid and gid, no supplementary groups.
#     `stale` prints ana's prompt and runs the command that way.
#   - ~/.testcontainers.properties is removed before the first integration
#     test, so the log is the one a first run prints. Testcontainers writes it
#     again on every successful run.
#   - The two detours (a stubbing removed, a stubbing for the wrong id) are
#     applied with sed, run, and the stage's file is put back.
# Container ids, ports, PIDs, timestamps and durations differ on every run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4.1, Maven 3.8.7, Docker Engine
# 29.8.2, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"

trap 'chmod 666 /var/run/docker.sock' EXIT
chmod 660 /var/run/docker.sock

STAGE="$COURSE/lab/stages/le-7zncse9p"
T=src/test/java/com/example/bookshop
# A file of this lesson's stage, put where the student creates it.
final() { for f in "$@"; do install -o ana -g ana -m 644 -D "$STAGE/$f" "/home/ana/bookshop/$f"; done; }
# Replace one top-level element of pom.xml (<build> or <dependencies>) with the
# fence of MD that starts with PREFIX, as the student does.
setpom() {
  python3 - "$COURSE/lab/fence.py" "$1" "$2" <<'PY'
import re, subprocess, sys
fence, md, prefix = sys.argv[1:4]
block = subprocess.run(['python3', fence, 'extract', md, prefix], capture_output=True,
                       text=True, check=True).stdout.rstrip('\n')
tag = re.match(r'\s*<(\w+)>', block).group(1)
p = '/home/ana/bookshop/pom.xml'
s = open(p).read()
new, n = re.subn(r'^  <%s>.*?^  </%s>' % (tag, tag), lambda m: block, s, count=1, flags=re.S | re.M)
assert n == 1, 'no <%s> in the pom' % tag
open(p, 'w').write(new)
PY
}
# ana's shell from before `usermod`: same user, no docker group.
stale() {
  printf 'ana@vm:%s$ %s\n' "$HERE" "$1"
  setpriv --reuid=ana --regid=ana --clear-groups \
    env -i HOME=/home/ana USER=ana LOGNAME=ana PATH=/usr/local/bin:/usr/bin:/bin \
    TZ=America/Sao_Paulo LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    bash -c "cd $(dir) && export PAGER=cat COLUMNS=100 && { $1 ; }" 2>&1 9>&- | sed 's/\x1b\[[0-9;]*m//g'
}

stage le-8ep384dn           # the bookshop as lesson 18 left it
at '~/bookshop'
quiet 'mvn -q test'         # compiled once, out of sight

########################################################### test-doubles.md
final $T/ordering/OrderServiceTest.java
shown test-doubles.md $T/ordering/OrderServiceTest.java
block first-run
run "mvn test | sed -n '/T E S T S/,\$p'"

# Detour 1: the second test without its stubbing.
block no-stub
run "sed -i '/void anOrderForMoreThanTheStockIsNeverSaved/{n;d}' $T/ordering/OrderServiceTest.java && sed -n '/void anOrderForMoreThanTheStockIsNeverSaved/,/^    }/p' $T/ordering/OrderServiceTest.java"
run "mvn test -Dtest=OrderServiceTest | grep -E 'Tests run:|ERROR|Expecting|to be an instance|but was|BookNotFound' | head -n 12"
final $T/ordering/OrderServiceTest.java

# Detour 2: a stubbing for the wrong id.
block wrong-id
run "sed -i '0,/findByIdForUpdate(3L)/s//findByIdForUpdate(4L)/' $T/ordering/OrderServiceTest.java && grep -n 'findByIdForUpdate' $T/ordering/OrderServiceTest.java"
run "mvn test -Dtest=OrderServiceTest | sed -n '/Strict stubbing/,/^  - /p' | head -n 14"
final $T/ordering/OrderServiceTest.java

########################################################### the-mockito-agent.md
block agent-jar
run 'ls ~/.m2/repository/org/mockito/mockito-core/5.23.0/'
setpom the-mockito-agent.md '  <build>'
block agent-run
run "mvn test | sed -n '/T E S T S/,\$p'"

########################################################### unit-and-integration.md
setpom unit-and-integration.md '  <build>'
block verify-empty
run "mvn verify | grep -E '^\[INFO\] --- |Tests run:|No tests|BUILD'"

########################################################### installing-docker.md
block docker-version
run 'docker version'
block hello
run 'docker run --rm hello-world'
block groups
run 'id -nG'
run 'ls -l /var/run/docker.sock'

########################################################### when-docker-fails.md
block stale-ps
stale 'id -nG'
stale 'docker ps'
block no-daemon
run 'DOCKER_HOST=unix:///run/not-running.sock docker ps'

########################################################### testcontainers.md
setpom testcontainers.md '  <dependencies>'
diff /home/ana/bookshop/pom.xml "$STAGE/pom.xml" >/dev/null \
  || { echo '!!! the pom the lesson builds is not the stage pom' >&2; exit 1; }
final $T/TestcontainersConfiguration.java $T/BookshopApplicationIT.java \
  $T/catalogue/BookRepositoryIT.java src/test/resources/application-test.properties
shown testcontainers.md $T/TestcontainersConfiguration.java $T/BookshopApplicationIT.java \
  $T/catalogue/BookRepositoryIT.java src/test/resources/application-test.properties
asroot 'rm -f /home/ana/.testcontainers.properties'

block tc-verify
run "mvn verify | tee /tmp/verify.log | grep -E 'Running |Tests run:|BUILD|Total time'"
block tc-log-docker
run "grep -E 'DockerClientProviderStrategy|DockerClientFactory   : (Testcontainers|Docker host|Connected)|ryuk|Ryuk' /tmp/verify.log"
block tc-log-postgres
run "grep -m 4 -E 'tc.postgres|FlywayExecutor|Successfully applied' /tmp/verify.log"
block tc-log-flyway
run "grep -E 'FlywayExecutor|DbMigrate|Started BookshopApplicationIT|Catalogue opened' /tmp/verify.log | head -n 8"
block tc-log-slice
run "grep -E 'BookRepositoryIT  : (Started|No active)|tc.postgres.*(started in|JDBC URL)|^Hibernate:' /tmp/verify.log | tail -n 6"
block tc-ps
run "docker ps -a --filter label=org.testcontainers=true --format '{{.Image}}  {{.Status}}'"
run "sleep 15; docker ps -a --filter label=org.testcontainers=true --format '{{.Image}}  {{.Status}}'"

########################################################### when-docker-fails.md (Testcontainers)
block stale-verify
stale "mvn verify | grep -E 'DockerClientProviderStrategy|valid Docker environment for|Tests run:|BUILD'"

########################################################### what-it-costs.md
block cost-test
run "mvn test | grep -E 'Tests run:|Total time'"
block cost-verify
run "mvn verify | grep -E 'Tests run:|Total time|started in PT|Started .*IT in'"
block cost-images
run "docker image ls --format '{{.Repository}}:{{.Tag}}  {{.Size}}' | grep -E 'postgres|ryuk'"

########################################################### the end state is the stage
block end-state
rm -rf /tmp/l19-built && mkdir -p /tmp/l19-built && cp -a /home/ana/bookshop/pom.xml /home/ana/bookshop/src /tmp/l19-built/
stage le-7zncse9p
diff -r /tmp/l19-built/src /home/ana/bookshop/src && diff /tmp/l19-built/pom.xml /home/ana/bookshop/pom.xml \
  && echo 'the lesson ends where the stage ends' || echo '!!! the lesson does not end at the stage'
shown test-doubles.md $T/ordering/OrderServiceTest.java
shown testcontainers.md $T/TestcontainersConfiguration.java $T/BookshopApplicationIT.java \
  $T/catalogue/BookRepositoryIT.java src/test/resources/application-test.properties
