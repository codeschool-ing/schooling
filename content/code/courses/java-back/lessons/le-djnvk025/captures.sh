#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed: ~/bookshop is written from this lesson's
# stage (the pom, BookshopApplication and the two properties files the lesson
# shows; `shown` proves each is the file in the lesson, byte for byte). The
# application is started by the lab in the background, as ana, from
# ~/bookshop, with its output in /tmp/bookshop.log: the lesson shows that as
# the student's SECOND terminal, where the same `java -jar` runs in the
# foreground, or with its output sent to /tmp/bookshop.log when the first
# terminal searches it. `second` prints that terminal's prompt and command.
# The detour without the web starter edits pom.xml with sed and compares the
# result with the block the lesson prints; the stage's pom is restored and
# rebuilt after it. ~/.m2 is warm, so no transcript shows a download.
# PIDs, timestamps and start-up times differ on every run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4, Maven 3.8.7, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"

second() { printf 'ana@vm:~/bookshop$ %s\n' "$1"; }
log() { sed 's/\x1b\[[0-9;]*m//g' /tmp/bookshop.log; }
JAR='java -jar target/bookshop-0.1.0.jar'
TOFILE='> /tmp/bookshop.log 2>&1'

stage le-djnvk025
shown starters.md pom.xml
shown the-application-class.md src/main/java/com/example/bookshop/BookshopApplication.java src/main/resources/application.properties
shown profiles.md src/main/resources/application.properties src/main/resources/application-dev.properties
at '~/bookshop'
quiet 'mvn -q dependency:tree'          # the plugin is resolved once, out of sight
quiet 'mvn -q help:evaluate -Dexpression=java.version -DforceStdout'

block tree
run 'mvn -q dependency:tree -DoutputFile=/tmp/tree.txt && cat /tmp/tree.txt'
run "grep -c ':compile' /tmp/tree.txt"

block starter-jar
run 'unzip -l ~/.m2/repository/org/springframework/boot/spring-boot-starter-webmvc/4.1.1/spring-boot-starter-webmvc-4.1.1.jar'

block managed
run "grep -c '\\.version>' ~/.m2/repository/org/springframework/boot/spring-boot-dependencies/4.1.1/spring-boot-dependencies-4.1.1.pom"
run 'mvn -q help:evaluate -Dexpression=tomcat.version -DforceStdout; echo'
run 'mvn -q help:evaluate -Dexpression=jackson-bom.version -DforceStdout; echo'

block annotation
run "javap -v -cp ~/.m2/repository/org/springframework/boot/spring-boot-autoconfigure/4.1.1/spring-boot-autoconfigure-4.1.1.jar org.springframework.boot.autoconfigure.SpringBootApplication | sed -n '/^RuntimeVisibleAnnotations:/,/^InnerClasses:/p' | grep -E '^    [a-z]'"

block package
run 'mvn -B package | tail -n 8'
run 'ls -l target/*.jar*'
run "jar tf target/bookshop-0.1.0.jar | grep -c '^BOOT-INF/lib/.*\\.jar\$'"
run "jar tf target/bookshop-0.1.0.jar | grep -E '^BOOT-INF/lib/spring-boot-(starter|jarmode)'"

block first-run
second "$JAR"
start
log

block curl
run 'curl -s localhost:8080/; echo'
stop

block imports
run 'unzip -p ~/.m2/repository/org/springframework/boot/spring-boot-webmvc/4.1.1/spring-boot-webmvc-4.1.1.jar META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports'

block debug-start
second "$JAR --debug $TOFILE"
start --debug

block debug-grep
run "grep -A2 -E '^   (TomcatServletWebServerAutoConfiguration#tomcatServletWebServerFactory|GsonHttpMessageConvertersConfiguration|WebMvcAutoConfiguration.ProblemDetailsErrorHandlingConfiguration)( matched)?:' /tmp/bookshop.log"

block debug-count
run "grep -cE '^   [A-Za-z0-9.#]+ matched:\$' /tmp/bookshop.log"
run "sed -n '/^Negative matches:/,/^Exclusions:/p' /tmp/bookshop.log | grep -cE '^   [A-Za-z0-9.#]+:\$'"
stop

block no-web
quiet "sed -i 's/spring-boot-starter-webmvc/spring-boot-starter/' pom.xml"
take without-a-web-server.md '  <dependencies>' l4-deps.xml
sed -n '/^  <dependencies>/,/^  <\/dependencies>/p' /home/ana/bookshop/pom.xml | cmp -s - /home/ana/l4-deps.xml \
  || { echo '!!! the detour pom is not the block the lesson shows' >&2; exit 1; }
rm -f /home/ana/l4-deps.xml
run 'mvn -B -q package'
run "$JAR"

block no-web-tree
run "mvn -q dependency:tree -DoutputFile=/tmp/tree.txt && grep -c ':compile' /tmp/tree.txt"
stage le-djnvk025
quiet 'mvn -B -q package'

block profiles
second "$JAR --spring.profiles.active=dev"
start --spring.profiles.active=dev
log
stop

block env-start
second "SPRING_PROFILES_ACTIVE=dev $JAR $TOFILE"
EXTRA_ENV='SPRING_PROFILES_ACTIVE=dev' start
block env-grep
run "grep -E 'profile|Tomcat started' /tmp/bookshop.log"
stop

block typo-start
second "$JAR --spring.profiles.active=dve $TOFILE"
start --spring.profiles.active=dve
block typo-grep
run "grep -E 'profile|Tomcat started' /tmp/bookshop.log"
stop

block env-port-start
second "SPRING_PROFILES_ACTIVE=dev SERVER_PORT=9090 $JAR $TOFILE"
EXTRA_ENV='SPRING_PROFILES_ACTIVE=dev SERVER_PORT=9090' start
block env-port-grep
run "grep -E 'profile|Tomcat started' /tmp/bookshop.log"
stop

block arg-port-start
second "SPRING_PROFILES_ACTIVE=dev SERVER_PORT=9090 $JAR --server.port=9091 $TOFILE"
EXTRA_ENV='SPRING_PROFILES_ACTIVE=dev SERVER_PORT=9090' start --server.port=9091
block arg-port-grep
run "grep -E 'profile|Tomcat started' /tmp/bookshop.log"
stop
