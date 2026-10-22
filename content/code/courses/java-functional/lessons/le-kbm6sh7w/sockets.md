---
title: A socket is a pipe of bytes
version: 1
---

**A TCP socket is a connection between two programs that carries bytes both ways, in order, with none
lost.** One program listens on a port with a `ServerSocket`; another connects to that port with a
`Socket`; each end then has an `InputStream` and an `OutputStream`, the byte streams of lesson 19, and
what travels over them is up to the two programs. This one plays both parts, a server on a virtual thread
and a client in `main`, so a single command shows the whole conversation:

```java
// Echo.java: a server and a client talking over a TCP socket on this machine
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.UncheckedIOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.List;

public class Echo {
    public static void main(String[] args) throws IOException, InterruptedException {
        try (ServerSocket server = new ServerSocket(0)) {
            Thread serving = Thread.ofVirtual().start(() -> serve(server));
            try (Socket socket = new Socket("127.0.0.1", server.getLocalPort());
                 PrintWriter out = new PrintWriter(socket.getOutputStream(), true, StandardCharsets.UTF_8);
                 BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8))) {
                for (String line : List.of("hello", "sertão", "bye")) {
                    out.println(line);
                    System.out.println("client: sent " + line + ", got " + in.readLine());
                }
            }
            serving.join();
        }
    }

    static void serve(ServerSocket server) {
        try (Socket client = server.accept();
             BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream(), StandardCharsets.UTF_8));
             PrintWriter out = new PrintWriter(client.getOutputStream(), true, StandardCharsets.UTF_8)) {
            System.out.println("server: a client connected");
            String line;
            while ((line = in.readLine()) != null) {
                out.println(line.toUpperCase());
            }
            System.out.println("server: the client closed the connection");
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
```

```
ana@vm:~/fp/net$ java Echo.java
server: a client connected
client: sent hello, got HELLO
client: sent sertão, got SERTÃO
client: sent bye, got BYE
server: the client closed the connection
```

## What crossed the connection

`new ServerSocket(0)` asked the operating system for any free port, and `getLocalPort` told the client
which one it got. **`accept` waited until a client connected** and returned a `Socket` for that one
client; a real server calls it in a loop and hands each socket to a thread of its own, which is exactly
the work virtual threads were made for in lesson 17.

The socket carried bytes, and each end wrapped them as lesson 19 said it would have to: an
`InputStreamReader` for reading and a `PrintWriter` for writing, **with UTF-8 named on both ends**. So `sertão` crossed as seven bytes and a line break, and came back as `SERTÃO`. Had the two ends named different
encodings, the word would have crossed just as quietly and come back wrong.

Two details keep the conversation from hanging. The `true` in `new PrintWriter(..., true, ...)` flushes
after every `println`, so a line is sent when it is written rather than when a buffer fills; without it
the client would wait for an answer to a line still sitting in its own buffer. And the server's loop ends
when `readLine` returns `null`, which is what happens **when the other end closes the connection**:
closing the client's socket at the end of its `try` is how the server learned the conversation was over.

Everything here stayed on `127.0.0.1`, the address every machine has for itself, which no other machine
can reach. A server that should be reachable from elsewhere listens on another address, and that is the
moment it needs the care the rest of this lesson and the last three lessons are about.
