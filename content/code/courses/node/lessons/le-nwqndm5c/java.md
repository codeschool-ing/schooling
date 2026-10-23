---
title: Java
version: 1
---

**Java runs a large part of the world's business software**: banks, shops, airlines, and the
back ends of many apps. It compiles to *bytecode* that the **JVM**, the Java Virtual Machine, runs and
optimises while it runs, the way V8 does for JavaScript. Java 25 is the current long-term release:

```sh
sudo apt install openjdk-25-jdk-headless   # Ubuntu and WSL
brew install openjdk                        # a Mac, with Homebrew (not run for this course)
```

On the course's machine the package was installed by root before the session, as a person with
`sudo` would install it:

```
ana@dev:~/server/other/java$ java -version
openjdk version "25.0.4.1" 2026-08-18
OpenJDK Runtime Environment (build 25.0.4.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 25.0.4.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
```

```schooling-example
{"language": "java", "file": "Hello.java", "parts": [
 {"code": "// Hello.java: the same server in Java, with nothing but the standard library.\nimport com.sun.net.httpserver.HttpExchange;\nimport com.sun.net.httpserver.HttpServer;\nimport java.io.IOException;\nimport java.net.InetSocketAddress;\nimport java.net.URLDecoder;\nimport java.nio.charset.StandardCharsets;\nimport java.util.concurrent.Executors;\n\npublic class Hello {", "note": "**Everything lives in a class**, and the file is named after it. The imports are the JDK's own: `com.sun.net.httpserver` is a small HTTP server that ships with it."},
 {"code": "    static void send(HttpExchange ex, int status, String json) throws IOException {\n        byte[] data = json.getBytes(StandardCharsets.UTF_8);\n        ex.getResponseHeaders().set(\"content-type\", \"application/json\");\n        ex.sendResponseHeaders(status, data.length);\n        try (var out = ex.getResponseBody()) {\n            out.write(data);\n        }\n    }", "note": "**`throws IOException` is part of the signature**: Java makes a method declare the errors it may let through, and the compiler checks every caller handles them."},
 {"code": "    static String quote(String s) {\n        return \"\\\"\" + s.replace(\"\\\\\", \"\\\\\\\\\").replace(\"\\\"\", \"\\\\\\\"\") + \"\\\"\";\n    }", "note": "**There is no JSON in Java's standard library**, so this writes it by hand, escaping the two characters that matter here. A real service uses a library, Jackson almost always."},
 {"code": "    public static void main(String[] args) throws IOException {\n        int port = Integer.parseInt(System.getenv().getOrDefault(\"PORT\", \"3000\"));\n        var server = HttpServer.create(new InetSocketAddress(\"127.0.0.1\", port), 0);\n        server.createContext(\"/\", ex -> {\n            String path = ex.getRequestURI().getPath();\n            String query = ex.getRequestURI().getRawQuery();\n            if (path.equals(\"/hello\")) {\n                String name = \"world\";\n                if (query != null && query.startsWith(\"name=\")) {\n                    name = URLDecoder.decode(query.substring(5), StandardCharsets.UTF_8);\n                }\n                send(ex, 200, \"{\\\"hello\\\":\" + quote(name) + \"}\");", "note": "**No query-string parser either**: this one understands `name=` and nothing else, which is enough for the test and no more."},
 {"code": "            } else if (path.equals(\"/slow\")) {\n                try {\n                    Thread.sleep(1000);\n                } catch (InterruptedException e) {\n                    Thread.currentThread().interrupt();\n                }\n                send(ex, 200, \"{\\\"slept\\\":1000}\");\n            } else {\n                send(ex, 404, \"{\\\"error\\\":\" + quote(\"nothing at \" + path) + \"}\");\n            }\n        });", "note": "`Thread.sleep` blocks, and must say what happens if the thread is interrupted while asleep."},
 {"code": "        server.setExecutor(Executors.newVirtualThreadPerTaskExecutor());\n        server.start();\n        System.out.println(\"java on :\" + port);\n    }\n}", "note": "**A virtual thread per request.** Java 21 made threads that cost about as little as goroutines; before them, a server kept a pool of a few hundred real threads."}
]}
```

`java Hello.java` compiles the file in memory and runs it, which is how a single-file program is
tried; a project is compiled first, by a build tool.

```
ana@dev:~/server/other/java$ java Hello.java
java on :3000
^C
```

```
ana@dev:~/server/other/java$ curl -s 'http://127.0.0.1:3000/hello?name=ana'
{"hello":"ana"}
ana@dev:~/server/other/java$ curl -s -w ' %{http_code}\n' http://127.0.0.1:3000/nope
{"error":"nothing at /nope"} 404
ana@dev:~/server/other/java$ time (for i in $(seq 10); do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/slow & done; wait)
200 200 200 200 200 200 200 200 200 200 
real	0m1.020s
user	0m0.027s
sys	0m0.023s
```

**The same answers, after the most typing.** Java's standard library leaves JSON and query strings to
libraries, and the language asks for types, a class and a declared exception where JavaScript asks for
nothing. What that buys is a compiler that refuses a large class of mistakes before the program runs,
and it is why big teams keep choosing it.

| what | in Node terms |
|---|---|
| **Spring Boot**, the framework most Java services use | Express, with far more included |
| **Maven** or **Gradle**, and `pom.xml` or `build.gradle` | `npm` and `package.json` |
| **Jackson**, for JSON | `JSON.parse` and `JSON.stringify` |
| a `.jar` file, run with `java -jar` | the project folder, run with `node` |
