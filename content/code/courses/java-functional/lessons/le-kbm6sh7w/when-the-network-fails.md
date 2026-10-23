---
title: When the network fails
version: 1
---

**A method call either returns or throws; a request can also simply never be answered.** The network adds
ways to fail that a program on one machine never meets, and each one has to be decided in the code: how
long to wait to connect, how long to wait for an answer, and what to do with an answer that says no.
With the server still running:

```java
// Trouble.java: three ways a request goes wrong, and which of them throw
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

public class Trouble {
    public static void main(String[] args) throws InterruptedException {
        HttpClient client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(2)).build();

        attempt(client, "nobody listening", HttpRequest.newBuilder(URI.create("http://127.0.0.1:8081/books")).build());
        attempt(client, "too slow", HttpRequest.newBuilder(URI.create("http://127.0.0.1:8080/slow"))
                .timeout(Duration.ofSeconds(1))
                .build());
        attempt(client, "no such book", HttpRequest.newBuilder(URI.create("http://127.0.0.1:8080/books/9")).build());
    }

    static void attempt(HttpClient client, String label, HttpRequest request) throws InterruptedException {
        long start = System.nanoTime();
        try {
            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
            System.out.printf("%s: status %d after %d ms%n", label, response.statusCode(), ms(start));
        } catch (IOException e) {
            System.out.printf("%s: %s after %d ms%n", label, e.getClass().getSimpleName(), ms(start));
        }
    }

    static long ms(long start) {
        return (System.nanoTime() - start) / 1_000_000;
    }
}
```

```
ana@vm:~/fp/net$ java Trouble.java
nobody listening: ConnectException after 37 ms
too slow: HttpTimeoutException after 1002 ms
no such book: status 404 after 22 ms
```

## Three outcomes

**Nobody listening** on port 8081 failed at once with a `ConnectException`: the operating system answered
for the absent server that nothing was there. Against a machine that does not answer at all, the same
attempt would wait, and the `connectTimeout` of two seconds is what would end it.

**Too slow** connected and sent its request, and the server took three seconds to answer. The request's
own `timeout` of one second ended the wait with an `HttpTimeoutException` after 1,002 ms. **Without a
timeout, `send` waits as long as the server takes**, and a server that never answers holds the caller
forever; every request a program sends to another machine should say how long it is willing to wait.

**No such book** did not throw. A 404 is a complete answer, and `send` returned it with its status. The
code that receives a response decides what each status means, and code that only reads the body is
reading a "not found" page as if it were a book.

| outcome | how it arrives | decided by |
|---|---|---|
| nothing at that address | `ConnectException` | the operating system, at once |
| no answer in time | `HttpTimeoutException` | the request's `timeout` |
| an answer that says no | a response with status 4xx or 5xx | the code that reads `statusCode()` |

Back in the first terminal, the server had printed a line for every request it served. Stop it with
`Ctrl+C`:

```
ana@vm:~/fp/net$ java ShelfServer.java
listening on http://127.0.0.1:8080
GET /books
GET /books/9
POST /books
GET /books/0
GET /books/2
GET /books/1
GET /books/3
GET /slow
GET /books/9
```

The four `GET`s that `sendAsync` started arrived in an order nobody chose.

## HTTPS, and the setting never to change

A request to an `https://` address is encrypted, and **the client checks the server's certificate before
it sends anything**: that the certificate was issued for that host name and is signed by an authority the
JDK trusts. A failed check is an `SSLHandshakeException`, and it is the one exception here that means
"stop": the program may be talking to somebody pretending to be the server. Code found online that
installs a `TrustManager` accepting every certificate makes the error go away by removing the check, and
with it the reason for HTTPS. The fix for a certificate the JDK does not trust is to add that one
authority to the trust store the program uses.

One more difference from a browser: `HttpClient` does not use a proxy unless it is given one. On a
network where traffic must go through a proxy, build the client with `.proxy(ProxySelector.getDefault())`,
which follows the JVM's `https.proxyHost` and `https.proxyPort` settings.
