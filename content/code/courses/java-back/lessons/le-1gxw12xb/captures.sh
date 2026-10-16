#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed: ~/bookshop as this lesson leaves it (the
# six files the lesson shows, checked below with `shown`); the two single-file
# programs, written to ~ from the fences the lesson shows; and, inside each
# detour, the edits the prose describes in words (adding @Primary, @Qualifier
# or @Scope and its import, renaming a parameter), applied with sed and then
# shown with `sed -n` or `grep`. Between detours the stage is laid down again
# and rebuilt, where the student undoes the detour by hand. Every run that
# succeeds uses --spring.main.web-application-type=none, so the application
# exits after its runners instead of serving; nothing here needs port 8080.
# Timestamps, PIDs and the number of beans Boot creates can differ between
# runs.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4.1, Maven 3.8.7, Spring Boot 4.1.1,
# TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"

P=src/main/java/com/example/bookshop
C=$P/catalogue
APP='java -jar target/bookshop-0.1.0.jar --spring.main.web-application-type=none'
DEBUG='--logging.level.org.springframework.beans.factory.support.DefaultListableBeanFactory=debug'
CP='java -cp target/classes:$(cat target/classpath.txt)'
restore() {
  stage le-1gxw12xb
  quiet 'mvn -B -q package && mvn -B -q dependency:build-classpath -Dmdep.outputFile=target/classpath.txt'
}

stage le-1gxw12xb
take by-hand.md '// Wiring.java' Wiring.java
take bean-methods.md '// FixedClock.java' FixedClock.java
at '~/bookshop'

block by-hand
run 'mvn -B -q package'
run 'mvn -B -q dependency:build-classpath -Dmdep.outputFile=target/classpath.txt'
run "$CP ~/Wiring.java"

block beans
run "$APP $DEBUG | grep -E \"'(bookshopApplication|bookService|inMemoryBookRepository|catalogueReport|clock|clockConfig)'|Catalogue opened\""
block count
run "$APP $DEBUG | grep -c 'Creating shared instance'"

# Field injection: the version the lesson shows, then the one-line change to
# Wiring.java the student types.
take constructor-injection.md 'package com.example.bookshop.catalogue;' "bookshop/$C/BookService.java"
block field-a
run "mvn -B -q package && $APP | grep Catalogue"
run "$CP ~/Wiring.java"
block field-b
run "sed -i 's/new BookService(repository)/new BookService()/' ~/Wiring.java"
run "$CP ~/Wiring.java"
quiet "sed -i 's/new BookService()/new BookService(repository)/' ~/Wiring.java"
restore

block fixed
run "$CP ~/FixedClock.java"

# Two candidates, and the three ways a tie is broken.
take when-wiring-fails.md 'package com.example.bookshop.catalogue;' "bookshop/$C/EmptyBookRepository.java"
block two
run "mvn -B -q package && $APP | tail -n 23"
quiet "sed -i 's/^@Repository\$/@Repository\n@Primary/; s/^import org.springframework.stereotype.Repository;/import org.springframework.context.annotation.Primary;\nimport org.springframework.stereotype.Repository;/' $C/InMemoryBookRepository.java"
block primary
run "sed -n '9,14p' $C/InMemoryBookRepository.java"
run "mvn -B -q package && $APP | grep Catalogue"
quiet "sed -i '/^@Primary\$/d; /^import org.springframework.context.annotation.Primary;\$/d' $C/InMemoryBookRepository.java"
quiet "sed -i 's/public BookService(BookRepository books) {/public BookService(@Qualifier(\"inMemoryBookRepository\") BookRepository books) {/; s/^import org.springframework.stereotype.Service;/import org.springframework.beans.factory.annotation.Qualifier;\nimport org.springframework.stereotype.Service;/' $C/BookService.java"
block qualifier
run "sed -n '6,16p' $C/BookService.java"
run "mvn -B -q package && $APP | grep Catalogue"
quiet "sed -i '/^import org.springframework.beans.factory.annotation.Qualifier;\$/d; s/@Qualifier(\"inMemoryBookRepository\") BookRepository books) {/BookRepository inMemoryBookRepository) {/; s/this.books = books;/this.books = inMemoryBookRepository;/' $C/BookService.java"
block paramname
run "grep -n -A2 'public BookService' $C/BookService.java"
run "mvn -B -q package && $APP | grep Catalogue"
restore

# Nothing to inject: a missing stereotype, then a class outside the scan.
block missing
run "sed -i '/^@Repository\$/d' $C/InMemoryBookRepository.java"
run "mvn -B -q package && $APP | tail -n 15"
restore
block outside
run 'mkdir src/main/java/com/example/clock'
run "mv $P/config/ClockConfig.java src/main/java/com/example/clock/"
run "sed -i 's/^package com.example.bookshop.config;/package com.example.clock;/' src/main/java/com/example/clock/ClockConfig.java"
run "mvn -B -q package && $APP | tail -n 15"
restore

# A constructor cycle, with and without the property that cannot break it.
block cycle
run "sed -i 's/public BookService(BookRepository books) {/public BookService(BookRepository books, CatalogueReport report) {/' $C/BookService.java"
run "mvn -B -q package && $APP | tail -n 21"
block cycle-flag
run "$APP --spring.main.allow-circular-references=true | tail -n 21"
restore

# Scopes: a runner that compares, then BookService as a prototype.
take scopes.md 'package com.example.bookshop;' "bookshop/$P/ScopeCheck.java"
block scope
run "mvn -B -q package && $APP | grep -E 'Catalogue|object'"
quiet "sed -i 's/^@Service\$/@Service\n@Scope(\"prototype\")/; s/^import org.springframework.stereotype.Service;/import org.springframework.context.annotation.Scope;\nimport org.springframework.stereotype.Service;/' $C/BookService.java"
block prototype
run "sed -n '6,12p' $C/BookService.java"
run "mvn -B -q package && $APP | grep -E 'Catalogue|object'"

stage le-1gxw12xb
quiet 'rm -f ~/Wiring.java ~/FixedClock.java'
shown by-hand.md $C/Book.java $C/BookRepository.java $C/InMemoryBookRepository.java \
  $C/BookService.java $C/CatalogueReport.java $P/config/ClockConfig.java
shown constructor-injection.md $C/BookService.java
shown bean-methods.md $P/config/ClockConfig.java
echo '##### end'
