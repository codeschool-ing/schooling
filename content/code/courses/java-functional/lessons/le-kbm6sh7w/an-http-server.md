---
title: An HTTP server in the JDK
version: 1
---

**HTTP is a conversation over a socket in a fixed shape: the client sends a method, a path and some
headers, the server answers with a status code, headers and a body.** Writing that shape by hand over a
socket is a good exercise and a bad idea. The JDK carries a small HTTP server in the package
`com.sun.net.httpserver`, enough for a test, a tool or this lesson:

```java
// ShelfServer.java: a small HTTP server for the books of this lesson, on this machine only
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.Executors;

public class ShelfServer {
    static final List<String> BOOKS = new CopyOnWriteArrayList<>(List.of("Dune", "Emma", "Dom Casmurro"));

    public static void main(String[] args) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", 8080), 0);
        server.createContext("/books", ShelfServer::books);
        server.createContext("/slow", ShelfServer::slow);
        server.setExecutor(Executors.newVirtualThreadPerTaskExecutor());
        server.start();
        System.out.println("listening on http://127.0.0.1:8080");
    }

    static void books(HttpExchange exchange) throws IOException {
        String method = exchange.getRequestMethod();
        String path = exchange.getRequestURI().getPath();
        System.out.println(method + " " + path);
        if (method.equals("GET") && path.equals("/books")) {
            send(exchange, 200, String.join("\n", BOOKS) + "\n");
        } else if (method.equals("GET") && path.matches("/books/\\d+")) {
            int n = Integer.parseInt(path.substring("/books/".length()));
            if (n < BOOKS.size()) {
                send(exchange, 200, BOOKS.get(n) + "\n");
            } else {
                send(exchange, 404, "no book " + n + "\n");
            }
        } else if (method.equals("POST") && path.equals("/books")) {
            String title = new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8).strip();
            BOOKS.add(title);
            send(exchange, 201, "added " + title + "\n");
        } else {
            send(exchange, 404, "nothing here\n");
        }
    }

    static void slow(HttpExchange exchange) throws IOException {
        System.out.println(exchange.getRequestMethod() + " /slow");
        try {
            Thread.sleep(3000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        send(exchange, 200, "finally\n");
    }

    static void send(HttpExchange exchange, int status, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "text/plain; charset=utf-8");
        exchange.sendResponseHeaders(status, bytes.length);
        try (OutputStream out = exchange.getResponseBody()) {
            out.write(bytes);
        }
    }
}
```

Start it in one terminal and leave it running; it prints one line and waits:

```
ana@vm:~/fp/net$ java ShelfServer.java
listening on http://127.0.0.1:8080
```

## How the server is put together

`HttpServer.create` opened the listening socket on `127.0.0.1` port 8080, and `createContext` attached a
**handler**, a method reference of lesson 3, to every path that starts with `/books`, and another to
`/slow`. The handler receives an `HttpExchange`, one request and its answer: it reads the method and the
path, decides, and calls `send`, which sets the status, the `Content-Type` and the length and writes the
body. A handler that forgets to send leaves the client waiting.

`setExecutor(Executors.newVirtualThreadPerTaskExecutor())` is lesson 17 in one line: **every request
runs on a virtual thread of its own**, so the three-second sleep in `/slow` holds nothing but that one
request. The list of books is a `CopyOnWriteArrayList` from lesson 15 for the same reason: two requests
can arrive at once, and one may add a book while another reads the list.

| status | means | this server sends it |
|---|---|---|
| 200 | OK, the body is the answer | for a list or a book that exists |
| 201 | created | after a `POST` adds a book |
| 404 | not found | for a book number past the end, or a path it does not know |

The path `/books/\d+` is matched with a regular expression, which is lesson 24; here it means `/books/`
followed by digits. Leave the server running for the next two sections, and stop it with `Ctrl+C` at the
end of section 05.
