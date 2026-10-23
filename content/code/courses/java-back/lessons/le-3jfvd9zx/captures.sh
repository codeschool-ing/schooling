#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed: ~/bookshop as lesson 5 left it; every file
# the lesson shows, written here as ana (the two versions on the way with put,
# the final ones copied from this lesson's stage) and then compared with the
# lesson byte for byte by `shown`; the application, started with java -jar in
# the background where the student runs it in a second terminal, and
# restarted after each build where the student presses Ctrl+C and starts it
# again. The lines quoted from that second terminal are read out of its log,
# whole, and the prose says which ones were left out. Dates, PIDs, thread
# names and durations differ on every run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4.1, Maven 3.8.7, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"

STAGE="$COURSE/lab/stages/le-3jfvd9zx"
PKG=src/main/java/com/example/bookshop/catalogue
# A file of this lesson's stage, put where the student creates it.
final() { for f in "$@"; do install -o ana -g ana -m 644 -D "$STAGE/$f" "/home/ana/bookshop/$f"; done; }
# The application in the second terminal, and what it printed since last asked.
MARK=0
app() { stop; start "$@"; MARK=$(wc -l < /tmp/bookshop.log); }
mark() { sleep 0.5; MARK=$(wc -l < /tmp/bookshop.log); }
newlog() {
  sleep 0.5
  local n; n=$(wc -l < /tmp/bookshop.log)
  sed -n "$((MARK + 1)),${n}p" /tmp/bookshop.log | grep -E "$1"
  MARK=$n
}
C="curl -si -w '\n'"
J="-H 'Content-Type: application/json'"

stage le-1gxw12xb           # the bookshop as lesson 5 left it
at '~/bookshop'

########################################################### controllers.md
quiet 'mvn -q package'
app
block lesson5-404
run "$C localhost:8080/books"

final $PKG/BookResponse.java
put bookshop/$PKG/BookController.java <<'EOF'
package com.example.bookshop.catalogue;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/books")
public class BookController {

    private final BookService books;

    public BookController(BookService books) {
        this.books = books;
    }

    @GetMapping
    public List<BookResponse> list() {
        return books.list().stream().map(BookResponse::from).toList();
    }

    @GetMapping("/{id}")
    public ResponseEntity<BookResponse> get(@PathVariable long id) {
        return books.find(id)
                .map(BookResponse::from)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
EOF
shown controllers.md $PKG/BookResponse.java $PKG/BookController.java

block build
run 'mvn -q package'
app
block get-one
run "$C localhost:8080/books/1"
run "$C localhost:8080/books/99"
block list
run "curl -s -w '\n' localhost:8080/books"
block not-mapped
run "$C -X DELETE localhost:8080/books/1"
run "$C localhost:8080/authors"
mark
block path-abc
run "$C localhost:8080/books/abc"
block path-abc-log
newlog WARN

########################################################### dispatcher.md
app --spring.profiles.active=dev
block dev-curl
run "curl -s -w '\n' localhost:8081/books/2"
block dev-log
sed -n '/mappings in/p; /Initializing Servlet/p; /GET "\/books\/2"/,/Completed 200/p' /tmp/bookshop.log

########################################################### json.md
app
block json-list
run 'curl -s localhost:8080/books | python3 -m json.tool'
block jackson-tree
run "mvn dependency:tree -Dincludes=tools.jackson.core,com.fasterxml.jackson.core | grep jackson"

########################################################### dtos.md + creating.md
put bookshop/$PKG/BookRequest.java <<'EOF'
package com.example.bookshop.catalogue;

public record BookRequest(String isbn, String title, String author, int priceCents) {
}
EOF
shown dtos.md $PKG/BookRequest.java
put bookshop/$PKG/BookController.java <<'EOF'
package com.example.bookshop.catalogue;

import java.net.URI;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/books")
public class BookController {

    private final BookService books;

    public BookController(BookService books) {
        this.books = books;
    }

    @GetMapping
    public List<BookResponse> list() {
        return books.list().stream().map(BookResponse::from).toList();
    }

    @GetMapping("/{id}")
    public ResponseEntity<BookResponse> get(@PathVariable long id) {
        return books.find(id)
                .map(BookResponse::from)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<BookResponse> add(@RequestBody BookRequest request) {
        Book book = books.add(request.isbn(), request.title(), request.author(), request.priceCents());
        return ResponseEntity.created(URI.create("/books/" + book.id())).body(BookResponse.from(book));
    }
}
EOF
shown creating.md $PKG/BookController.java

quiet 'mvn -q package'
app
block post-201
run "$C $J -d '{\"isbn\":\"9786500000047\",\"title\":\"Iracema\",\"author\":\"José de Alencar\",\"priceCents\":2800}' localhost:8080/books"
run "$C localhost:8080/books/4"
block post-id
run "curl -s -w '\n' $J -d '{\"id\":1,\"isbn\":\"9786500000054\",\"title\":\"Senhora\",\"author\":\"José de Alencar\",\"priceCents\":3100}' localhost:8080/books"
run "curl -s -w '\n' localhost:8080/books/1"
block post-415
run "$C -d '{\"isbn\":\"9786500000054\",\"title\":\"Senhora\",\"author\":\"José de Alencar\",\"priceCents\":3100}' localhost:8080/books"
block post-junk
run "curl -s -w '\n' $J -d '{\"isbn\":\"12345\",\"title\":\"\",\"author\":\"José de Alencar\",\"priceCents\":-5}' localhost:8080/books"

########################################################### validation.md
mark
block no-price-int
run "$C $J -d '{\"isbn\":\"9786500000061\",\"title\":\"Lucíola\",\"author\":\"José de Alencar\"}' localhost:8080/books"
block no-price-int-log
newlog WARN

final pom.xml
put bookshop/$PKG/BookRequest.java <<'EOF'
package com.example.bookshop.catalogue;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

public record BookRequest(
        @NotNull String isbn,
        @NotBlank @Size(max = 200) String title,
        @NotBlank @Size(max = 120) String author,
        @NotNull @PositiveOrZero Integer priceCents) {
}
EOF
shown validation.md pom.xml $PKG/BookRequest.java

quiet 'mvn -q package'
app
block constraints-alone
run "curl -s -w '\n' $J -d '{\"isbn\":\"12345\",\"title\":\"\",\"author\":\"José de Alencar\",\"priceCents\":-5}' localhost:8080/books"

final $PKG/BookController.java
shown validation.md $PKG/BookController.java

quiet 'mvn -q package'
app
block junk-400
run "$C $J -d '{\"isbn\":\"12345\",\"title\":\"\",\"author\":\"José de Alencar\",\"priceCents\":-5}' localhost:8080/books"
block junk-400-log
newlog WARN
block no-price-null
run "curl -s -w '\n' $J -d '{\"isbn\":\"9786500000061\",\"title\":\"Lucíola\",\"author\":\"José de Alencar\"}' localhost:8080/books"
block no-price-null-log
newlog WARN
block malformed
run "curl -s -w '\n' $J -d '{\"isbn\":\"9786500000061\",' localhost:8080/books"
block malformed-log
newlog WARN
block wrong-check-201
run "curl -s -w '\n' $J -d '{\"isbn\":\"9786500000048\",\"title\":\"Senhora\",\"author\":\"José de Alencar\",\"priceCents\":3100}' localhost:8080/books"

########################################################### custom-constraint.md
final $PKG/Isbn.java $PKG/ValidIsbn.java $PKG/IsbnValidator.java $PKG/BookRequest.java
shown custom-constraint.md $PKG/Isbn.java $PKG/ValidIsbn.java $PKG/IsbnValidator.java $PKG/BookRequest.java

quiet 'mvn -q package'
app
block wrong-check-400
run "$C $J -d '{\"isbn\":\"9786500000048\",\"title\":\"Senhora\",\"author\":\"José de Alencar\",\"priceCents\":3100}' localhost:8080/books"
block wrong-check-400-log
newlog WARN
block no-isbn
run "curl -s -w '\n' $J -d '{\"title\":\"Senhora\",\"author\":\"José de Alencar\",\"priceCents\":3100}' localhost:8080/books"
block no-isbn-log
newlog WARN
block valid-201
run "curl -s -w '\n' $J -d '{\"isbn\":\"9786500000047\",\"title\":\"Iracema\",\"author\":\"José de Alencar\",\"priceCents\":2800}' localhost:8080/books"

# A detour: @Target without FIELD. Applied, built, run, and put back.
block no-field
run "sed -i 's/ElementType.FIELD, //' $PKG/ValidIsbn.java && grep -n '@Target' $PKG/ValidIsbn.java"
run 'mvn -q package'
app
block no-field-201
run "curl -s -w '\n' $J -d '{\"isbn\":\"9786500000048\",\"title\":\"Senhora\",\"author\":\"José de Alencar\",\"priceCents\":3100}' localhost:8080/books"
block field-back
run "sed -i 's/@Target({ElementType.PARAMETER/@Target({ElementType.FIELD, ElementType.PARAMETER/' $PKG/ValidIsbn.java && grep -n '@Target' $PKG/ValidIsbn.java"
quiet 'mvn -q package'
stop

########################################################### the end state is the stage
block end-state
rm -rf /tmp/l6-built && mkdir -p /tmp/l6-built && cp -a /home/ana/bookshop/pom.xml /home/ana/bookshop/src /tmp/l6-built/
stage le-3jfvd9zx
diff -r /tmp/l6-built/src /home/ana/bookshop/src && diff /tmp/l6-built/pom.xml /home/ana/bookshop/pom.xml \
  && echo 'the lesson ends where the stage ends' || echo '!!! the lesson does not end at the stage'
shown controllers.md $PKG/BookResponse.java
shown validation.md pom.xml $PKG/BookController.java
shown custom-constraint.md $PKG/Isbn.java $PKG/ValidIsbn.java $PKG/IsbnValidator.java $PKG/BookRequest.java
