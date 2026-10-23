---
title: Javadoc, the comments a tool turns into pages
version: 1
---

Two kinds of people need to know how the bookshop works without reading all of it. One works inside
the code: a colleague who calls `BookService` or `Isbn` from a class of their own, and wants to know
what a method does before they call it. The other never sees the code at all, and calls the API over
HTTP. This section is for the first reader. The rest of the lesson is for the second.

**Javadoc** is how Java answers the first reader. Every page of the JDK's own documentation, the
page for `java.util.List` included, was produced by the `javadoc` tool from comments in the
JDK's source. Your IDE shows the same comments when you hover over a method.

## Which comments count

A common picture is that Javadoc reads every comment in a file. It reads one kind only: a comment
that opens with **`/**`** and sits immediately before a class, a field, a constructor or a method.
`//` and `/* */` are ignored, and so is a `/**` comment that is not directly in front of a
declaration. Annotations may sit between the two, as they do below.

Inside it, the first sentence is the **summary**, which the tool copies into the tables that list
every method. Anything after it is the description. Then come the **block tags**, one per line, and
anywhere in the text you can use **inline tags** in braces:

| tag | what it documents |
|---|---|
| `@param name` | one parameter, named exactly as in the code |
| `@return` | what the method gives back |
| `@throws Type` | an exception, and when it is thrown |
| `{@code text}` | code inside a sentence, set in monospace and never read as HTML |
| `{@link Type#member}` | a link to another documented element |

## The controller, documented

Replace `src/main/java/com/example/bookshop/catalogue/BookController.java` with this version. The
code is lesson 11's; what is new is the comments, and one import gone:

```schooling-example
{
  "language": "java",
  "file": "BookController.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\nimport java.net.URI;\nimport java.util.List;\n\nimport jakarta.validation.Valid;\n\nimport org.springframework.data.domain.Pageable;\nimport org.springframework.data.web.PageableDefault;\nimport org.springframework.data.web.PagedModel;\nimport org.springframework.http.ResponseEntity;\nimport org.springframework.web.bind.annotation.GetMapping;\nimport org.springframework.web.bind.annotation.PathVariable;\nimport org.springframework.web.bind.annotation.PostMapping;\nimport org.springframework.web.bind.annotation.RequestBody;\nimport org.springframework.web.bind.annotation.RequestMapping;\nimport org.springframework.web.bind.annotation.RequestParam;\nimport org.springframework.web.bind.annotation.RestController;\n",
      "note": "Lesson 11's imports, less `Sort`, which the class imported and never used."
    },
    {
      "code": "/**\n * The catalogue over HTTP: reading it is open to anyone, adding to it needs\n * the {@code catalogue:write} scope.\n */\n@RestController\n@RequestMapping(\"/books\")\npublic class BookController {\n",
      "note": "The comment on the class: one sentence of summary, with `{@code}` around the scope's name so that it is set as code. The annotations sit between the comment and the class, which is allowed."
    },
    {
      "code": "    private final BookService books;\n\n    public BookController(BookService books) {\n        this.books = books;\n    }\n",
      "note": "No comment on the constructor. Spring calls it and nobody else does; the end of this section counts what leaving such things out costs."
    },
    {
      "code": "    /**\n     * One page of the catalogue, in the order the {@code sort} parameter asks for.\n     *\n     * @param pageable page number, page size and sort, from the query string\n     * @return the page, with the total count in its metadata\n     */\n    @GetMapping\n    public PagedModel<BookResponse> list(@PageableDefault(size = 20, sort = \"id\") Pageable pageable) {\n        return new PagedModel<>(books.list(pageable));\n    }\n",
      "note": "`@param` names the parameter and then says what it carries. `@return` says what comes back, including the part a reader could not guess from the type: the total count is in the page's metadata."
    },
    {
      "code": "    /**\n     * Books whose title contains the text, ignoring case.\n     *\n     * @param q the text to look for\n     * @return the matching books, by title\n     */\n    @GetMapping(\"/search\")\n    public List<BookResponse> search(@RequestParam String q) {\n        return books.search(q);\n    }\n\n    /**\n     * Titles and prices of one author's books.\n     *\n     * @param name the author's name, exactly as stored\n     * @return title and price of each book, by title\n     */\n    @GetMapping(\"/by-author\")\n    public List<TitleAndPrice> byAuthor(@RequestParam String name) {\n        return books.titlesBy(name);\n    }\n",
      "note": "Each `@param` names its parameter exactly as the code does, `q` and `name`. Doclint checks that match, and the next part of this section breaks it on purpose."
    },
    {
      "code": "    /**\n     * One book.\n     *\n     * @param id the book's id\n     * @return the book\n     * @throws BookNotFoundException when no book has that id\n     */\n    @GetMapping(\"/{id}\")\n    public BookResponse get(@PathVariable long id) {\n        return books.get(id);\n    }\n",
      "note": "`@throws` documents an exception the signature does not declare. `BookNotFoundException` extends `RuntimeException`, so nothing else in the file says it can happen."
    },
    {
      "code": "    /**\n     * Adds a book to the catalogue, creating its author if the name is new.\n     *\n     * @param request the book, validated before this method runs\n     * @return 201 with the new book and its address in {@code Location}\n     * @throws DuplicateIsbnException when the ISBN is already in the catalogue\n     */\n    @PostMapping\n    public ResponseEntity<BookResponse> add(@Valid @RequestBody BookRequest request) {\n        BookResponse book = books.add(request);\n        return ResponseEntity.created(URI.create(\"/books/\" + book.id())).body(book);\n    }",
      "note": "Two things only a comment can say here: the 201 with its `Location` header, and the exception for an ISBN that is already in the catalogue."
    },
    {
      "code": "}"
    }
  ]
}
```

What is worth writing is what the signature does not already say. `get(long id)` says that it takes
a number; it cannot say that an unknown number throws, because `BookNotFoundException` is unchecked
and the compiler never sees it leave. "Returns the book" on a method called `get` that returns a
`BookResponse` would be a comment that adds nothing, and a reader learns to skip comments like that.

## The plugin

The `javadoc` tool comes with the JDK, and Maven runs it through `maven-javadoc-plugin`. Spring
Boot's parent already manages its version; what this project adds is its configuration. Replace the
`<build>` element at the end of `pom.xml` with this one:

```xml
  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-javadoc-plugin</artifactId>
        <configuration>
          <show>public</show>
          <doclint>all,-missing</doclint>
        </configuration>
      </plugin>
    </plugins>
  </build>
```

**`<show>public</show>`** documents only what is public. A package-private helper is nobody's API,
and pages for it would invite somebody to depend on it. **`<doclint>`** is the part of `javadoc`
that checks the comments themselves, and the next part of this section is about it.

The plugin is not bound to any phase in this pom, so `mvn package` does not run it. You ask for it
by its goal:

```
ana@vm:~/bookshop$ mvn javadoc:javadoc
[INFO] Scanning for projects...
[INFO] 
[INFO] ------------------------< com.example:bookshop >------------------------
[INFO] Building bookshop 0.1.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] >>> maven-javadoc-plugin:3.12.0:javadoc (default-cli) > generate-sources @ bookshop >>>
[INFO] 
[INFO] <<< maven-javadoc-plugin:3.12.0:javadoc (default-cli) < generate-sources @ bookshop <<<
[INFO] 
[INFO] 
[INFO] --- maven-javadoc-plugin:3.12.0:javadoc (default-cli) @ bookshop ---
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.616 s
[INFO] Finished at: 2026-10-22T20:22:49-03:00
[INFO] ------------------------------------------------------------------------
```

The two lines with `>>>` and `<<<` are the plugin asking Maven to run the lifecycle up to
`generate-sources` first, so that generated code would be documented too; this project has none.
The pages go to `target/reports/apidocs`:

```
ana@vm:~/bookshop$ ls target/reports/apidocs
allclasses-index.html
allpackages-index.html
com
element-list
help-doc.html
index-all.html
index.html
legal
member-search-index.js
module-search-index.js
overview-summary.html
overview-tree.html
package-search-index.js
resource-files
script-files
search.html
serialized-form.html
tag-search-index.js
type-search-index.js
ana@vm:~/bookshop$ ls target/reports/apidocs/com/example/bookshop/catalogue
Author.html
AuthorRepository.html
Book.html
BookController.html
BookNotFoundException.html
BookRepository.html
BookRequest.html
BookResponse.html
BookService.html
CatalogueReport.html
DuplicateIsbnException.html
Isbn.html
IsbnValidator.html
OutOfStockException.html
TitleAndPrice.html
ValidIsbn.html
class-use
package-summary.html
package-tree.html
package-use.html
```

Open `target/reports/apidocs/index.html` in a browser. It is a website with no server behind it:
the package list, a page per class with its summary table, an index of every name, and a search
box. `BookController.html` carries the comments you just wrote, with `{@code catalogue:write}` in
monospace.

## Doclint, and a check that did not run

Doclint reads every comment the tool documents and complains about what it finds wrong: HTML that
does not close, a `{@link}` to nothing, an `@param` that names no parameter. Some of those are
**errors**, and an error fails the build. Try one. In the comment above `search`, change
`@param q` to `@param query`, a name the method does not have, and run the goal again:

```
ana@vm:~/bookshop$ mvn -q javadoc:javadoc
```

Nothing, and that is wrong. The plugin keeps a record of the command line it gave `javadoc` last
time, in `target/maven-javadoc-plugin-stale-data.txt`, and **skips the run when that command line
has not changed**. Editing a comment does not change it, so the check you asked for never ran.
`clean` deletes `target`, record included:

```
ana@vm:~/bookshop$ mvn -q clean javadoc:javadoc | head -6
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-javadoc-plugin:3.12.0:javadoc (default-cli) on project bookshop: An error has occurred in Javadoc report generation: 
[ERROR] Exit code: 1
[ERROR] /home/ana/bookshop/src/main/java/com/example/bookshop/catalogue/BookController.java:48: error: @param name not found
[ERROR]      * @param query the text to look for
[ERROR]               ^
[ERROR] 1 error
```

`-q` hides everything but errors, and `head -6` keeps the error and leaves out Maven's advice
underneath it. Line 48 is the `@param` you changed. Put `@param q` back before going on.

`clean` also deletes the jar, so the next `mvn package` builds it again. Whenever a Javadoc check
has to mean something, in a script or before a release, run it after `clean`.

## Why `-missing`

`all` switches on every group of checks, and `-missing` takes one back out: the group that warns
about every public element with no comment at all. Switch it back on by changing the line to
`<doclint>all</doclint>`, and count what it finds. The pom changed, so this time the plugin runs:

```
ana@vm:~/bookshop$ mvn javadoc:javadoc | grep 'warning: no comment' > ~/missing.txt
ana@vm:~/bookshop$ wc -l < ~/missing.txt
92
ana@vm:~/bookshop$ head -3 ~/missing.txt
[WARNING] /home/ana/bookshop/src/main/java/com/example/bookshop/web/ApiErrorHandler.java:24: warning: no comment
[WARNING] /home/ana/bookshop/src/main/java/com/example/bookshop/web/ApiErrorHandler.java:32: warning: no comment
[WARNING] /home/ana/bookshop/src/main/java/com/example/bookshop/web/ApiErrorHandler.java:27: warning: no comment
ana@vm:~/bookshop$ grep BookController ~/missing.txt
[WARNING] /home/ana/bookshop/src/main/java/com/example/bookshop/catalogue/BookController.java:30: warning: no comment
```

Ninety-two public elements with no comment. The first three are in lesson 7's `ApiErrorHandler`:
the class itself, on line 24, and two of its handlers. The controller's constructor is in the list
too, on line 30. They are public because Spring finds and calls them, and nobody who reads a page of Javadoc will ever call them
directly. A sentence on each would be exactly the kind of comment the previous part warned about.
`-missing` keeps every check on the comments that exist and drops the demand for a comment on
everything. Put `<doclint>all,-missing</doclint>` back.

A library is the opposite case. Code that other projects depend on is read through its Javadoc,
Maven Central requires a jar of it, built by `mvn javadoc:jar`, beside every library it publishes,
and there `missing` belongs switched on.
