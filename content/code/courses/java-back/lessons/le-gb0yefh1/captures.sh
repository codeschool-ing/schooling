#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the starting point: the bookshop as lesson 11 left it, and a database
#     that lesson 11's schema.sql and data.sql filled by one start;
#   - every file the student writes is taken from the lesson's own fences
#     (take), and every bookshop file the lesson prints is compared with
#     lesson 13's stage (shown);
#   - `sudo -u postgres dropdb/createdb`, which the lesson shows as a plain
#     sh fence, is the lab's `db` (ana has no sudo in the lab);
#   - the application started "in the second terminal" is `start`, writing
#     /tmp/bookshop.log; `applog` prints the line the student types there,
#     `java -jar ... | grep -E PATTERN`, and the lines of that log the same
#     grep keeps. A start that FAILS is run for real with `run`, pipe included;
#   - the detour without flyway-database-postgresql deletes that dependency
#     from the pom with sed, quietly, and puts the stage's pom back after.
#
# Times, PIDs and connection hashes differ on every run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4, Maven 3.8.7, PostgreSQL 16.15,
# TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"
STAGES=$COURSE/lab/stages
PSQL='psql postgresql://bookshop:bookshop@localhost/bookshop'
JAR='java -jar target/bookshop-0.1.0.jar'
applog() {   # applog PATTERN [ARGS]: the second terminal, filtered as typed
  printf 'ana@vm:%s$ %s%s | grep -E %s\n' "$HERE" "$JAR" "${2:+ $2}" "'$1'"
  grep -E "$1" /tmp/bookshop.log
}
build() { quiet 'mvn -B -q package -DskipTests'; }

# Where the lesson starts: lesson 11's bookshop, started once on a fresh
# database, so schema.sql and data.sql have made the tables and rows.
stage le-95z47qtq
db
at '~/bookshop'
build
start; stop

block schemasql
take schema-sql-every-start.md 'CREATE TABLE IF NOT EXISTS author' bookshop/src/main/resources/schema.sql
run 'mvn -B -q package -DskipTests'
start
applog 'Started|Catalogue'
stop
run "$PSQL -c '\d book'"

# Lesson 13's changes, as the student makes them. Book.java stays lesson 11's
# until the validate section.
quiet 'rm src/main/resources/schema.sql src/main/resources/data.sql'
take flyway-takes-over.md '<?xml' bookshop/pom.xml
take flyway-takes-over.md 'CREATE TABLE author' bookshop/src/main/resources/db/migration/V1__catalogue.sql
take flyway-takes-over.md 'INSERT INTO author' bookshop/src/main/resources/db/migration/V2__first_titles.sql
take flyway-takes-over.md 'spring.application.name' bookshop/src/main/resources/application.properties

block files
run 'mvn -B -q package -DskipTests'
run 'jar tf target/bookshop-0.1.0.jar | grep db/migration'

block nonempty
run "$JAR | grep FlywayException"

block baseline
start --spring.flyway.baseline-on-migrate=true --spring.flyway.baseline-version=2
applog 'o\.f\.|Started' '--spring.flyway.baseline-on-migrate=true --spring.flyway.baseline-version=2'
stop
run "$PSQL -c 'select installed_rank, version, description, type, success from flyway_schema_history'"

db
block migrate
start
applog 'o\.f\.|Started'
stop

block nopg
quiet "perl -0pi -e 's#    <dependency>\n      <groupId>org\.flywaydb</groupId>\n.*?</dependency>\n##s' pom.xml"
run 'mvn -B -q package -DskipTests'
run "$JAR | grep 'Caused by: org.flywaydb'"
take flyway-takes-over.md '<?xml' bookshop/pom.xml
build

block validate
take validate-the-mapping.md 'spring.application.name' bookshop/src/main/resources/application.properties
run 'mvn -B -q package -DskipTests'
run "$JAR | grep 'Caused by: org.hibernate'"

block started
asroot "install -o ana -g ana -m 644 $STAGES/le-gb0yefh1/src/main/java/com/example/bookshop/catalogue/Book.java /home/ana/bookshop/src/main/java/com/example/bookshop/catalogue/Book.java"
run 'mvn -B -q package -DskipTests'
start
printf 'ana@vm:%s$ %s\n' "$HERE" "$JAR"
cat /tmp/bookshop.log

block history
run "$PSQL -c 'select installed_rank, version, description, script, checksum, success from flyway_schema_history'"

block uptodate
stop
start
applog 'o\.f\.'
stop

block mismatch
run "sed -i 's/3500/3600/' src/main/resources/db/migration/V2__first_titles.sql"
run 'mvn -B -q package -DskipTests'
run "$JAR | grep -m1 -A3 'checksum mismatch'"

block reverted
run "sed -i 's/3600/3500/' src/main/resources/db/migration/V2__first_titles.sql"
run 'mvn -B -q package -DskipTests'
start
applog 'o\.f\.|Started'
stop

block failing
take the-next-migration.md 'CREATE TABLE publisher' bookshop/src/main/resources/db/migration/V3__publisher.sql
run 'mvn -B -q package -DskipTests'
run "$JAR | grep -m4 -E 'DbMigrate|^Message'"

block afterfail
run "$PSQL -c '\dt'"
run "$PSQL -c 'select installed_rank, version, description, success from flyway_schema_history'"

block removed
run 'rm src/main/resources/db/migration/V3__publisher.sql'
run 'mvn -B -q package -DskipTests'

# Everything the lesson printed of the bookshop is the stage, byte for byte.
shown flyway-takes-over.md pom.xml src/main/resources/db/migration/V1__catalogue.sql src/main/resources/db/migration/V2__first_titles.sql
shown validate-the-mapping.md src/main/resources/application.properties src/main/java/com/example/bookshop/catalogue/Book.java
quiet "diff -r $STAGES/le-gb0yefh1/src ~/bookshop/src > /tmp/le-gb0yefh1.diff"

# Liquibase, in a project of its own, against a schema of its own.
quiet 'rm -rf ~/liquibase-look'
quiet "$PSQL -c 'DROP SCHEMA IF EXISTS look CASCADE'"
take liquibase.md '<?xml' liquibase-look/pom.xml
take liquibase.md 'databaseChangeLog:' liquibase-look/changelog.yaml
at '~/liquibase-look'

block lqupdate
run "$PSQL -c 'CREATE SCHEMA look'"
run 'mvn -B -q liquibase:update'
run 'mvn -B -q liquibase:update'

block lqtable
run "$PSQL -c 'select id, author, filename, md5sum, exectype, orderexecuted from look.databasechangelog'"

block lqrollback
run 'mvn -B -q liquibase:rollback -Dliquibase.rollbackCount=2'
run "$PSQL -c 'select id from look.databasechangelog'"
run "$PSQL -c '\dt look.*'"
run "$PSQL -c 'select count(*) from look.author'"

block lqdrop
run "$PSQL -c 'DROP SCHEMA look CASCADE'"

block lqlicence
at '~'
run "grep -A1 '<license>' .m2/repository/org/flywaydb/flyway-parent/12.4.0/flyway-parent-12.4.0.pom .m2/repository/org/liquibase/liquibase-maven-plugin/5.0.3/liquibase-maven-plugin-5.0.3.pom"
