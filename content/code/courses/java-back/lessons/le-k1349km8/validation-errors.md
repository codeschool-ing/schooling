---
title: The validation errors map
version: 1
---

A 400 that says "invalid request" and stops is half an answer. The client sent several fields and some
of them were wrong, and what it needs is which ones and why: a form puts each message beside its field,
and a script logs the field it got wrong. Bean Validation knows all of that when it rejects a request
(lesson 6). The bookshop's job is to pass it on.

When `@Valid` fails on a `@RequestBody`, Spring MVC raises **`MethodArgumentNotValidException`**, which
carries a binding result with one error for each constraint that failed. `ResponseEntityExceptionHandler`
answers that exception in a method of its own, `handleMethodArgumentNotValid`, and `ApiErrorHandler`
overrides it:

```java
    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException e, HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        Map<String, String> errors = new TreeMap<>();
        e.getBindingResult().getFieldErrors()
                .forEach(f -> errors.put(f.getField(), f.getDefaultMessage()));
        ProblemDetail body = problem(HttpStatus.BAD_REQUEST, "invalid-request", "Invalid request",
                errors.size() + " field(s) failed validation");
        body.setProperty("errors", errors);
        return ResponseEntity.badRequest().body(body);
    }
```

`getFieldErrors()` gives one `FieldError` per failed constraint. `getField()` is the name of the record
component, which is also the JSON property the client sent, and `getDefaultMessage()` is the
constraint's message. **`setProperty`** adds a member the RFC does not define, an extension, and Jackson
writes it beside the standard five. The method returns a `ResponseEntity` rather than a bare
`ProblemDetail` only because the method it overrides is declared that way.

## Why override, and not a handler of your own

The obvious alternative is one more `@ExceptionHandler` in `ApiErrorHandler`. Try it as a detour: add
this method above the override, build and restart.

```java
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail invalid(MethodArgumentNotValidException e) {
        return problem(HttpStatus.BAD_REQUEST, "invalid-request", "Invalid request", "the request is not valid");
    }
```

It compiles. The application does not start, and the last cause in the second terminal says why:

```
Caused by: java.lang.IllegalStateException: Ambiguous @ExceptionHandler method mapped for [ExceptionHandler{exceptionType=org.springframework.web.bind.MethodArgumentNotValidException, mediaType=*/*}]: {public org.springframework.http.ProblemDetail com.example.bookshop.web.ApiErrorHandler.invalid(org.springframework.web.bind.MethodArgumentNotValidException), public final org.springframework.http.ResponseEntity org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler.handleException(java.lang.Exception,org.springframework.web.context.request.WebRequest) throws java.lang.Exception}
```

The class now has two handlers for one exception, the inherited one and the new one, and Spring refuses
to pick between them rather than letting a choice nobody wrote down decide the answer. Delete the method
again. Every exception the base class handles has a `protected` method like `handleMethodArgumentNotValid`,
called by the inherited handler, and overriding that method is how you change the answer.

## What the client gets

Build, restart, and send lesson 6's bad book again. `python3 -m json.tool` prints the JSON one member
per line:

```
ana@vm:~/bookshop$ curl -s localhost:8080/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000017", "title": "", "priceCents": -1}' | python3 -m json.tool
{
    "detail": "4 field(s) failed validation",
    "instance": "/books",
    "status": 400,
    "title": "Invalid request",
    "type": "https://bookshop.example/problems/invalid-request",
    "errors": {
        "author": "must not be blank",
        "isbn": "must be a valid ISBN-13",
        "priceCents": "must be greater than or equal to 0",
        "title": "must not be blank"
    }
}
```

Four fields, four messages, and a client that can act on each. The keys arrive in alphabetical order
because the map is a **`TreeMap`**. Bean Validation reports violations in no particular order, so a
`HashMap` could list the same four fields differently on two runs. A program would not care. A person
comparing two responses would, and so would a test that compares a whole body.

The messages are the constraints' own, and three of them come from Hibernate Validator, the
implementation the validation starter brings. They follow the language the request asks for:

```
ana@vm:~/bookshop$ curl -s localhost:8080/books -H 'Content-Type: application/json' -H 'Accept-Language: pt-BR' -d '{"isbn": "9786500000017", "title": "", "priceCents": -1}' | python3 -m json.tool
{
    "detail": "4 field(s) failed validation",
    "instance": "/books",
    "status": 400,
    "title": "Invalid request",
    "type": "https://bookshop.example/problems/invalid-request",
    "errors": {
        "author": "n\u00e3o deve estar em branco",
        "isbn": "must be a valid ISBN-13",
        "priceCents": "deve ser maior ou igual a 0",
        "title": "n\u00e3o deve estar em branco"
    }
}
```

`python3 -m json.tool` writes the `ã` of `não` as `\u00e3`, which is the same character in JSON; a
browser or a JSON library shows it as `ã`.

`must be a valid ISBN-13` stayed in English because `@ValidIsbn` declares its message as a plain
sentence. The standard constraints declare theirs as keys in braces, such as
`{jakarta.validation.constraints.NotBlank.message}`, which Hibernate Validator looks up in a bundle per
language, and Spring hands it the request's `Accept-Language`.

## One message per field

A map from a field to one message keeps one message per field. A title of 201 spaces is blank and too
long at the same time, and the rest of this book is valid:

```
ana@vm:~/bookshop$ python3 -c 'import json; print(json.dumps({"isbn": "9786500000078", "title": " " * 201, "author": "Jane Austen", "priceCents": 2500}))' | curl -s localhost:8080/books -H 'Content-Type: application/json' -d @- | python3 -m json.tool
{
    "detail": "1 field(s) failed validation",
    "instance": "/books",
    "status": 400,
    "title": "Invalid request",
    "type": "https://bookshop.example/problems/invalid-request",
    "errors": {
        "title": "must not be blank"
    }
}
```

Two constraints failed and one message reached the client; `detail` says one field, because it counts
the map's entries. Which of the two messages wins is not defined, and that is not a manner of speaking:
another run of this same request, made while this lesson was recorded, kept the other one. For a form that is
enough: the person fixes the title, sends it again, and meets the other message if it still applies. A
client that must show every reason at once needs a list per field, `Map<String, List<String>>`, which is
a small change the bookshop does not need.
