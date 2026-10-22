---
title: HttpClient
version: 1
---

**`java.net.http.HttpClient`, in the JDK since Java 11, sends a request and hands back a response, either
waiting for it or as a `CompletableFuture`.** With the server of the last section running, open a second
terminal and run this:

```java
// Client.java: requests to the shelf server, one at a time and then all at once
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.stream.IntStream;

public class Client {
    static final String BASE = "http://127.0.0.1:8080";

    public static void main(String[] args) throws IOException, InterruptedException {
        HttpClient client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(2)).build();

        HttpResponse<String> all = client.send(get("/books"), HttpResponse.BodyHandlers.ofString());
        System.out.println(all.statusCode() + " " + all.headers().firstValue("Content-Type").orElse("?"));
        System.out.print(all.body());

        HttpResponse<String> missing = client.send(get("/books/9"), HttpResponse.BodyHandlers.ofString());
        System.out.print(missing.statusCode() + " " + missing.body());

        HttpRequest post = HttpRequest.newBuilder(URI.create(BASE + "/books"))
                .POST(HttpRequest.BodyPublishers.ofString("Neuromancer"))
                .build();
        HttpResponse<String> added = client.send(post, HttpResponse.BodyHandlers.ofString());
        System.out.print(added.statusCode() + " " + added.body());

        List<CompletableFuture<String>> titles = IntStream.range(0, 4)
                .mapToObj(n -> client.sendAsync(get("/books/" + n), HttpResponse.BodyHandlers.ofString())
                        .thenApply(HttpResponse::body)
                        .thenApply(String::strip))
                .toList();
        System.out.println(titles.stream().map(CompletableFuture::join).toList());
    }

    static HttpRequest get(String path) {
        return HttpRequest.newBuilder(URI.create(BASE + path)).build();
    }
}
```

```
ana@vm:~/fp/net$ java Client.java
200 text/plain; charset=utf-8
Dune
Emma
Dom Casmurro
404 no book 9
201 added Neuromancer
[Dune, Emma, Dom Casmurro, Neuromancer]
```

## Three objects and two ways to wait

Everything is built from three immutable objects. **The `HttpClient`** holds the settings, here a connect
timeout of two seconds, and is made once and shared: it keeps connections open between requests. **An
`HttpRequest`** is the method, the address, the headers and the body, built with a builder, `GET` unless
told otherwise. **A body handler** says what to make of the response's bytes; `ofString()` decodes them
with the charset the response names, here the `charset=utf-8` the server sent.

`send` waited for each answer, and the four lines show what came back: a 200 with the list, **a 404 with
its own body**, and a 201 for the new book. The 404 did not throw. It is an answer, and the code read its
status like any other.

`sendAsync` did not wait. It returned a `CompletableFuture<HttpResponse<String>>` at once, so the stream
started four requests before any of them had answered, and `thenApply` of lesson 16 turned each future
response into a future title. Only `join`, at the end, waited. **The titles came back in the order they
were asked for**, because the list of futures was in that order, whatever order the answers arrived in;
the server's own terminal, at the end of section 05, shows the order it actually served them.

The client used no thread pool of its own. `sendAsync` runs on an executor inside the client, and
`HttpClient.newBuilder().executor(...)` can replace it, the same choice as `supplyAsync` with and without
an executor in lesson 16.
