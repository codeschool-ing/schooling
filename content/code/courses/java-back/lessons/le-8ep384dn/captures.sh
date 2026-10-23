#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed: ~/bookshop as lesson 17 left it; every file
# the lesson shows, written as ana (the first IsbnTest taken from the lesson's
# own fence, the final pom and test classes copied from this lesson's stage)
# and compared with the lesson byte for byte by `shown`; ~/testng-look, written
# from the lesson's fences (ShelfTest.java from a heredoc here, compared with
# the lesson's example the same way). Every detour is a sed the lesson shows,
# undone by the sed or the copy the lesson shows after it. The first TestNG
# build runs once out of sight, so the transcript is a build and not the
# download of TestNG and surefire's TestNG provider; the console launcher jar
# was already in ~/.m2 and `-q` hides the copy. No database and no application
# run: these tests need neither. Times and dates differ on every run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4.1, Maven 3.8.7, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"

STAGE="$COURSE/lab/stages/le-8ep384dn"
T=src/test/java/com/example/bookshop
M=src/main/java/com/example/bookshop
# A file of this lesson's stage, written by ana where the student creates it.
final() { for f in "$@"; do put "bookshop/$f" < "$STAGE/$f"; done; }
LAUNCH='java -jar target/junit-platform-console-standalone-6.0.3.jar execute --disable-banner --disable-ansi-colors --details=testfeed --class-path "target/test-classes:target/classes:$(cat target/test.cp)"'

stage le-fw3rxvms           # the bookshop as lesson 17 left it
at '~/bookshop'

########################################################### junit-platform.md
block no-tests
run 'mvn test | tail -n 8'
final pom.xml
shown junit-platform.md pom.xml
block tree
run 'mvn -q dependency:tree -DoutputFile=/tmp/tree.txt && grep -E "junit|assertj|mockito|hamcrest|jsonpath|xmlunit|awaitility|starter-test|spring-test|boot-test" /tmp/tree.txt'
block surefire
run 'mvn help:effective-pom | grep -A1 "<artifactId>maven-surefire-plugin"'

########################################################### first-test.md
take first-test.md 'package com.example.bookshop.catalogue;' "bookshop/$T/catalogue/IsbnTest.java"
block first-run
run 'mvn test'
block reports
run 'ls target/surefire-reports'
run 'cat target/surefire-reports/com.example.bookshop.catalogue.IsbnTest.txt'
block quiet
run 'mvn -q test; echo "exit $?"'
run "mvn test -Dtest='IsbnTest#refusesNull' | grep 'Tests run'"
block badname
run "mv $T/catalogue/IsbnTest.java $T/catalogue/IsbnChecks.java && sed -i 's/class IsbnTest/class IsbnChecks/' $T/catalogue/IsbnChecks.java"
run 'mvn test | tail -n 12'
block badname-back
run "mv $T/catalogue/IsbnChecks.java $T/catalogue/IsbnTest.java && sed -i 's/class IsbnChecks/class IsbnTest/' $T/catalogue/IsbnTest.java"
shown first-test.md $T/catalogue/IsbnTest.java

########################################################### parameterized.md
final $T/catalogue/IsbnTest.java
shown parameterized.md $T/catalogue/IsbnTest.java
block param-run
run 'mvn test -Dtest=IsbnTest | grep -E "Running|Tests run|BUILD"'
block param-xml
run 'grep -o "testcase name=\"[^\"]*\"" target/surefire-reports/TEST-com.example.bookshop.catalogue.IsbnTest.xml'
block launcher-get
run 'mvn -q dependency:copy -Dartifact=org.junit.platform:junit-platform-console-standalone:6.0.3 -DoutputDirectory=target'
run 'mvn -q dependency:build-classpath -Dmdep.outputFile=target/test.cp'
block launcher-isbn
run "$LAUNCH --select-class com.example.bookshop.catalogue.IsbnTest | grep -v STARTED"

########################################################### when-it-fails.md
block break
run "sed -i 's/int check = (10 - sum % 10) % 10;/int check = 10 - sum % 10;/' $M/catalogue/Isbn.java && grep -n 'int check' $M/catalogue/Isbn.java"
block fail-run
run 'mvn test'
block no-frankenstein
run "sed -i 's/\"9786500000023\", \"9786500000030\", /\"9786500000023\", /' $T/catalogue/IsbnTest.java && grep -n '@ValueSource' $T/catalogue/IsbnTest.java"
run 'mvn test | grep -E "Tests run:|BUILD"'
block restore
run "sed -i 's/int check = 10 - sum % 10;/int check = (10 - sum % 10) % 10;/' $M/catalogue/Isbn.java"
run "sed -i 's/\"9786500000023\", /\"9786500000023\", \"9786500000030\", /' $T/catalogue/IsbnTest.java && grep -n '@ValueSource' $T/catalogue/IsbnTest.java"
run 'mvn -q test; echo "exit $?"'
shown parameterized.md $T/catalogue/IsbnTest.java

########################################################### fixtures-and-assertj.md
final $T/catalogue/BookTest.java
shown fixtures-and-assertj.md $T/catalogue/BookTest.java
block beforeall-edit
run "sed -i 's/import org.junit.jupiter.api.BeforeEach;/import org.junit.jupiter.api.BeforeAll;/; s/    private Book book;/    private static Book book;/; s/    @BeforeEach/    @BeforeAll/; s/    void aBookWithTwoCopies/    static void aBookWithTwoCopies/' $T/catalogue/BookTest.java && sed -n '11,18p' $T/catalogue/BookTest.java"
block beforeall-run
run "mvn test -Dtest='BookTest*'"
block beforeall-back
run "sed -i 's/import org.junit.jupiter.api.BeforeAll;/import org.junit.jupiter.api.BeforeEach;/; s/    private static Book book;/    private Book book;/; s/    @BeforeAll/    @BeforeEach/; s/    static void aBookWithTwoCopies/    void aBookWithTwoCopies/' $T/catalogue/BookTest.java && sed -n '11,18p' $T/catalogue/BookTest.java"
shown fixtures-and-assertj.md $T/catalogue/BookTest.java
final $T/ordering/OrderTest.java
shown fixtures-and-assertj.md $T/ordering/OrderTest.java
block all-run
run 'mvn test'
block launcher-book
run "$LAUNCH --select-class com.example.bookshop.catalogue.BookTest | grep -v STARTED"
block assertj-order
run "sed -i 's/containsExactly(2, 1)/containsExactly(1, 2)/' $T/ordering/OrderTest.java"
run 'mvn test -Dtest=OrderTest'
block assertj-total
run "sed -i 's/containsExactly(1, 2)/containsExactly(2, 1)/; s/isEqualTo(11670)/isEqualTo(11680)/' $T/ordering/OrderTest.java"
run 'mvn test -Dtest=OrderTest | grep -A3 "AssertionFailedError"'
block assertj-back
run "sed -i 's/isEqualTo(11680)/isEqualTo(11670)/' $T/ordering/OrderTest.java"
run 'mvn test | grep -E "Tests run:|BUILD"'
shown fixtures-and-assertj.md $T/ordering/OrderTest.java

########################################################### the end state is the stage
block end-state
rm -rf /tmp/l18-built && mkdir -p /tmp/l18-built && cp -a /home/ana/bookshop/pom.xml /home/ana/bookshop/src /tmp/l18-built/
stage le-8ep384dn
diff -r /tmp/l18-built/src /home/ana/bookshop/src && diff /tmp/l18-built/pom.xml /home/ana/bookshop/pom.xml \
  && echo 'the lesson ends where the stage ends' || echo '!!! the lesson does not end at the stage'

########################################################### testng.md
quiet 'rm -rf ~/testng-look'
take testng.md '<?xml' testng-look/pom.xml
take testng.md '<!DOCTYPE suite' testng-look/testng.xml
take testng.md 'package look;

import java.util' testng-look/src/main/java/look/Shelf.java
put testng-look/src/test/java/look/ShelfTest.java <<'EOF'
package look;

import static org.testng.Assert.assertEquals;

import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

public class ShelfTest {

    private final Shelf shelf = new Shelf();

    @Test
    public void startsEmpty() {
        assertEquals(shelf.count("Dom Casmurro"), 0);
    }

    @Test(dependsOnMethods = "startsEmpty")
    public void addsCopies() {
        shelf.add("Dom Casmurro", 2);
        assertEquals(shelf.count("Dom Casmurro"), 2);
    }

    @Test(dependsOnMethods = "addsCopies")
    public void takesOne() {
        shelf.take("Dom Casmurro");
        assertEquals(shelf.count("Dom Casmurro"), 1);
    }

    @DataProvider
    public Object[][] deliveries() {
        return new Object[][] {
                {1, 0, 1},
                {2, 3, 5},
                {0, 0, 0}
        };
    }

    @Test(dataProvider = "deliveries")
    public void addsUpTwoDeliveries(int first, int second, int expected) {
        Shelf fresh = new Shelf();
        fresh.add("Iracema", first);
        fresh.add("Iracema", second);
        assertEquals(fresh.count("Iracema"), expected);
    }

    @Test(groups = "stress")
    public void holdsAMillionCopies() {
        Shelf big = new Shelf();
        for (int i = 0; i < 1_000_000; i++) {
            big.add("Senhora", 1);
        }
        assertEquals(big.count("Senhora"), 1_000_000);
    }
}
EOF
TNGMD=$(realpath testng.md)
( cd /home/ana/testng-look && python3 "$COURSE/lab/fence.py" check "$TNGMD" src/test/java/look/ShelfTest.java ) \
  || { echo '!!! ShelfTest.java is not the file testng.md shows' >&2; exit 1; }
at '~/testng-look'
quiet 'mvn -q test'
block tng-run
run 'mvn test'
block tng-skip
run "sed -i 's/assertEquals(shelf.count(\"Dom Casmurro\"), 2);/assertEquals(shelf.count(\"Dom Casmurro\"), 3);/' src/test/java/look/ShelfTest.java"
run 'mvn test | grep -E "Tests run:|FAILURE!|expected|BUILD"'
block tng-results
run "grep -o '<test-method [^>]*status=\"[A-Z]*\"' target/surefire-reports/testng-results.xml | grep -o 'name=\"[^\"]*\"\\|status=\"[A-Z]*\"' | paste - -"
block tng-skip-back
run "sed -i 's/assertEquals(shelf.count(\"Dom Casmurro\"), 3);/assertEquals(shelf.count(\"Dom Casmurro\"), 2);/' src/test/java/look/ShelfTest.java"
block tng-groups
run "sed -i 's/<exclude name=\"stress\"\\/>/<include name=\"stress\"\\/>/' testng.xml && grep -n 'stress' testng.xml"
run 'mvn test | grep -E "Tests run:|BUILD"'
run "sed -i 's/<include name=\"stress\"\\/>/<exclude name=\"stress\"\\/>/' testng.xml && mvn test | grep -E \"Tests run:|BUILD\""
