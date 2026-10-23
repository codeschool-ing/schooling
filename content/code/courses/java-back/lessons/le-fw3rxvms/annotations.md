---
title: Saying what the code cannot, with annotations
version: 1
---

The controller has a Javadoc comment on every method, and springdoc used none of them. It is a
fair thing to expect the opposite, since the comments say exactly what the document is missing.
The reason is where each one looks.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"BookController.java feeds two paths. Along the top, the javadoc tool reads the source at build time and writes HTML pages to target/reports/apidocs, for a Java developer. Along the bottom, javac compiles it into BookController.class, which keeps the annotations and drops the comments; springdoc reads the running application and serves /v3/api-docs as JSON, for Swagger UI and HTTP clients.\"><defs><marker id=\"l17a-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"128\" width=\"170\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">BookController.java</text><text x=\"105.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">comments and annotations</text><rect x=\"260\" y=\"30\" width=\"150\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"335.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">javadoc</text><text x=\"335.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">at build time</text><rect x=\"480\" y=\"30\" width=\"200\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">HTML pages</text><text x=\"580.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">target/reports/apidocs</text><text x=\"580\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">read by a Java developer</text><rect x=\"225\" y=\"190\" width=\"110\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">javac</text><text x=\"280.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">at build time</text><rect x=\"365\" y=\"190\" width=\"160\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"445.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BookController.class</text><text x=\"445.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">comments are not in it</text><rect x=\"555\" y=\"190\" width=\"125\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"617.5\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">springdoc</text><text x=\"617.5\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">in the running application</text><rect x=\"555\" y=\"272\" width=\"125\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"617.5\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/v3/api-docs</text><text x=\"617.5\" y=\"303.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">JSON</text><text x=\"545\" y=\"294\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">read by Swagger UI and HTTP clients</text><path d=\"M 190 145 C 225 145, 225 58, 258 58\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17a-ah)\"></path><path d=\"M 410 58 L 478 58\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17a-ah)\"></path><path d=\"M 190 172 C 205 172, 205 218, 223 218\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17a-ah)\"></path><path d=\"M 335 218 L 363 218\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17a-ah)\"></path><path d=\"M 525 218 L 553 218\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17a-ah)\"></path><path d=\"M 617 246 L 617 270\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17a-ah)\"></path></svg>", "caption": "Comments reach the javadoc tool and stop at javac. What springdoc can read is what survives into the class file: the annotations."}
```

`javadoc` reads the **source**, at build time, and the comments are in the source. springdoc reads
the **running application**, and by then the comments are gone: `javac` does not copy them into
the class file. Annotations survive, because the ones springdoc reads are declared to be kept at run
time. The class file says so, for one comment and one annotation of the same method:

```
ana@vm:~/bookshop$ javap -v target/classes/com/example/bookshop/catalogue/BookController.class | grep -c 'One page of the catalogue'
0
ana@vm:~/bookshop$ javap -v target/classes/com/example/bookshop/catalogue/BookController.class | grep 'List the catalogue'
   #82 = Utf8               List the catalogue, a page at a time
          summary="List the catalogue, a page at a time"
```

The comment's words appear nowhere in `BookController.class`; the `summary` you are about to write
is there twice, as a string in the class's table of constants and as the value of the annotation.

So the second reader gets annotations from the `io.swagger.v3.oas.annotations` packages, which the
springdoc starter brought in. springdoc's own documentation describes an annotation processor,
therapi-runtime-javadoc, that keeps the comments where it can read them; this project keeps the two
apart instead, because the two readers want different sentences. A Java developer wants to know that
`get` throws `BookNotFoundException`. An HTTP client wants to know that it gets a 404.

## A name and a way in

Two things describe the API as a whole rather than one operation: what it is called, and how a
client proves who it is. Both go in one bean. Create
`src/main/java/com/example/bookshop/web/OpenApiConfig.java`:

```java
package com.example.bookshop.web;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityScheme;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    OpenAPI bookshopApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("Bookshop API")
                        .version("0.1.0")
                        .description("The catalogue and the orders of a small bookshop."))
                .components(new Components().addSecuritySchemes("bearer",
                        new SecurityScheme().type(SecurityScheme.Type.HTTP).scheme("bearer").bearerFormat("JWT")));
    }
}
```

springdoc uses an `OpenAPI` bean, when there is one, as the start of the document it builds. `Info`
replaces the placeholder title. The **security scheme** named `bearer` tells a client that this API
takes a token in the `Authorization` header, as `Bearer` followed by the token, and that the token
is a JWT. It says how to send a token. Which operations need one is said per operation, below.

## The controller, annotated

Replace `BookController.java` with its final version. The Javadoc is the previous section's,
untouched:

```schooling-example
{
  "language": "java",
  "file": "BookController.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\nimport java.net.URI;\nimport java.util.List;\n\nimport io.swagger.v3.oas.annotations.Operation;\nimport io.swagger.v3.oas.annotations.Parameter;\nimport io.swagger.v3.oas.annotations.media.Content;\nimport io.swagger.v3.oas.annotations.media.Schema;\nimport io.swagger.v3.oas.annotations.responses.ApiResponse;\nimport io.swagger.v3.oas.annotations.security.SecurityRequirement;\nimport io.swagger.v3.oas.annotations.tags.Tag;\nimport jakarta.validation.Valid;\n\nimport org.springdoc.core.annotations.ParameterObject;\nimport org.springframework.data.domain.Pageable;\nimport org.springframework.data.web.PageableDefault;\nimport org.springframework.data.web.PagedModel;\nimport org.springframework.http.ProblemDetail;\nimport org.springframework.http.ResponseEntity;\nimport org.springframework.web.bind.annotation.GetMapping;\nimport org.springframework.web.bind.annotation.PathVariable;\nimport org.springframework.web.bind.annotation.PostMapping;\nimport org.springframework.web.bind.annotation.RequestBody;\nimport org.springframework.web.bind.annotation.RequestMapping;\nimport org.springframework.web.bind.annotation.RequestParam;\nimport org.springframework.web.bind.annotation.RestController;\n",
      "note": "The `io.swagger.v3.oas.annotations` imports are the OpenAPI annotations. `ParameterObject` is springdoc's own, and `ProblemDetail` is the Spring class that lesson 7's error handler returns."
    },
    {
      "code": "/**\n * The catalogue over HTTP: reading it is open to anyone, adding to it needs\n * the {@code catalogue:write} scope.\n */\n@Tag(name = \"Catalogue\")\n@RestController\n@RequestMapping(\"/books\")\npublic class BookController {\n",
      "note": "`@Tag` names the group this controller's operations appear under. Without it, springdoc names the group after the class, as it did for the orders: `order-controller`."
    },
    {
      "code": "    private final BookService books;\n\n    public BookController(BookService books) {\n        this.books = books;\n    }\n"
    },
    {
      "code": "    /**\n     * One page of the catalogue, in the order the {@code sort} parameter asks for.\n     *\n     * @param pageable page number, page size and sort, from the query string\n     * @return the page, with the total count in its metadata\n     */\n    @Operation(summary = \"List the catalogue, a page at a time\")\n    @GetMapping\n    public PagedModel<BookResponse> list(@ParameterObject @PageableDefault(size = 20, sort = \"id\") Pageable pageable) {\n        return new PagedModel<>(books.list(pageable));\n    }\n",
      "note": "`@Operation(summary = ...)` is one line for the HTTP reader. `@ParameterObject` tells springdoc to describe the fields of `Pageable` as separate query parameters, which is how Spring reads them."
    },
    {
      "code": "    /**\n     * Books whose title contains the text, ignoring case.\n     *\n     * @param q the text to look for\n     * @return the matching books, by title\n     */\n    @Operation(summary = \"Search titles\")\n    @GetMapping(\"/search\")\n    public List<BookResponse> search(@RequestParam String q) {\n        return books.search(q);\n    }\n\n    /**\n     * Titles and prices of one author's books.\n     *\n     * @param name the author's name, exactly as stored\n     * @return title and price of each book, by title\n     */\n    @Operation(summary = \"Titles and prices by one author\")\n    @GetMapping(\"/by-author\")\n    public List<TitleAndPrice> byAuthor(@RequestParam String name) {\n        return books.titlesBy(name);\n    }\n",
      "note": "A summary each and nothing more: the query parameters `q` and `name` were right already."
    },
    {
      "code": "    /**\n     * One book.\n     *\n     * @param id the book's id\n     * @return the book\n     * @throws BookNotFoundException when no book has that id\n     */\n    @Operation(summary = \"Get one book\")\n    @ApiResponse(responseCode = \"200\", description = \"The book\")\n    @ApiResponse(responseCode = \"404\", description = \"No book has that id\",\n            content = @Content(mediaType = \"application/problem+json\", schema = @Schema(implementation = ProblemDetail.class)))\n    @GetMapping(\"/{id}\")\n    public BookResponse get(@Parameter(description = \"the book's id\") @PathVariable long id) {\n        return books.get(id);\n    }\n",
      "note": "Each `@ApiResponse` is an answer the operation can give. The 404 names its media type and its schema; without `content`, springdoc gives every response the method's return type, and a 404 does not carry a `BookResponse`. `@Parameter` describes one parameter."
    },
    {
      "code": "    /**\n     * Adds a book to the catalogue, creating its author if the name is new.\n     *\n     * @param request the book, validated before this method runs\n     * @return 201 with the new book and its address in {@code Location}\n     * @throws DuplicateIsbnException when the ISBN is already in the catalogue\n     */\n    @Operation(summary = \"Add a book\", security = @SecurityRequirement(name = \"bearer\"))\n    @ApiResponse(responseCode = \"201\", description = \"Added\")\n    @ApiResponse(responseCode = \"400\", description = \"The request failed validation\",\n            content = @Content(mediaType = \"application/problem+json\", schema = @Schema(implementation = ProblemDetail.class)))\n    @ApiResponse(responseCode = \"409\", description = \"The ISBN is already in the catalogue\",\n            content = @Content(mediaType = \"application/problem+json\", schema = @Schema(implementation = ProblemDetail.class)))\n    @PostMapping\n    public ResponseEntity<BookResponse> add(@Valid @RequestBody BookRequest request) {\n        BookResponse book = books.add(request);\n        return ResponseEntity.created(URI.create(\"/books/\" + book.id())).body(book);\n    }",
      "note": "`security` refers to the scheme by its name, `bearer`, from `OpenApiConfig`, and says that this operation needs it. The three error answers are problem details, like the 404."
    },
    {
      "code": "}"
    }
  ]
}
```

Build, restart, and save the new document over the old one:

```
ana@vm:~/bookshop$ curl -s localhost:8080/v3/api-docs | python3 -m json.tool > ~/api.json
```

The title, the description and the version are the ones `Info` gave:

```
ana@vm:~/bookshop$ python3 ~/oapi.py ~/api.json info
{
  "title": "Bookshop API",
  "description": "The catalogue and the orders of a small bookshop.",
  "version": "0.1.0"
}
```

`GET /books/{id}` has two responses now:

```
ana@vm:~/bookshop$ python3 ~/oapi.py ~/api.json paths /books/{id} get responses
{
  "200": {
    "description": "The book",
    "content": {
      "*/*": {
        "schema": {
          "$ref": "#/components/schemas/BookResponse"
        }
      }
    }
  },
  "404": {
    "description": "No book has that id",
    "content": {
      "application/problem+json": {
        "schema": {
          "$ref": "#/components/schemas/ProblemDetail"
        }
      }
    }
  }
}
```

The 404 is in the document now, as `application/problem+json` with a reference to a schema
called `ProblemDetail`. The 200 still says `*/*`: the controller declares no media type, and the
document does not invent one. The schema the 404 points to is new too:

```
ana@vm:~/bookshop$ python3 ~/oapi.py ~/api.json components schemas ProblemDetail
{
  "type": "object",
  "properties": {
    "type": {
      "type": "string",
      "format": "uri"
    },
    "title": {
      "type": "string"
    },
    "status": {
      "type": "integer",
      "format": "int32"
    },
    "detail": {
      "type": "string"
    },
    "instance": {
      "type": "string",
      "format": "uri"
    },
    "properties": {
      "type": "object",
      "additionalProperties": {}
    }
  }
}
```

springdoc built this schema from Spring's `ProblemDetail` class, and the first five members are
the ones RFC 9457 defines and lesson 7 used. The sixth is not what a client receives. `properties`
is the Java field that holds extra members, and Jackson writes those at the top level of the body:
lesson 7's 400 carries `errors` beside `title` and `detail`, not inside an object called
`properties`. Annotations make the document better, and reading what it says is still your job.

`@ParameterObject` replaced the one impossible parameter of `GET /books`:

```
ana@vm:~/bookshop$ python3 ~/oapi.py ~/api.json paths /books get parameters
[
  {
    "name": "page",
    "in": "query",
    "description": "Zero-based page index (0..N)",
    "required": false,
    "schema": {
      "type": "integer",
      "default": 0,
      "minimum": 0
    }
  },
  {
    "name": "size",
    "in": "query",
    "description": "The size of the page to be returned",
    "required": false,
    "schema": {
      "type": "integer",
      "default": 20,
      "minimum": 1
    }
  },
  {
    "name": "sort",
    "in": "query",
    "description": "Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.",
    "required": false,
    "schema": {
      "type": "array",
      "default": [
        "id,ASC"
      ],
      "items": {
        "type": "string"
      }
    }
  }
]
```

Three optional parameters, with the defaults from `@PageableDefault`, `size` 20 and `sort` `id,ASC`,
and descriptions that springdoc carries for `Pageable`. This is what a client can really send.

And the operation that adds a book, and the scheme it refers to:

```
ana@vm:~/bookshop$ python3 ~/oapi.py ~/api.json paths /books post security
[
  {
    "bearer": []
  }
]
ana@vm:~/bookshop$ python3 ~/oapi.py ~/api.json components securitySchemes
{
  "bearer": {
    "type": "http",
    "scheme": "bearer",
    "bearerFormat": "JWT"
  }
}
```

`POST /books` names the `bearer` scheme, and the scheme is the one `OpenApiConfig` declared. The
empty list after the name is where an OAuth 2.0 scheme would list scopes. This one lists none, so
the document says that a token is needed and not that it has to carry `catalogue:write`; that
sentence is in the class's Javadoc, where an HTTP reader will never see it. If clients need to
know, the `description` of `@Operation` is where to say it.

The orders are still as springdoc found them: a 200 where the code answers 201, and no `security`
where every call needs a token. Fixing them takes the same annotations on `OrderController`, and
the questions at the end of this lesson ask which ones.
