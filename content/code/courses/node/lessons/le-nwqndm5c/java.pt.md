---
title: Java
version: 1
---

**O Java roda uma parte grande do software de empresas do mundo**: bancos, lojas, companhias aéreas, e
o back end de muitos apps. Ele compila para *bytecode*, que a **JVM**, a Java Virtual Machine, roda e
otimiza enquanto roda, do jeito que o V8 faz com o JavaScript. O Java 25 é a versão atual de longo
prazo:

```sh
sudo apt install openjdk-25-jdk-headless   # Ubuntu and WSL
brew install openjdk                        # a Mac, with Homebrew (not run for this course)
```

Na máquina do curso o pacote foi instalado pelo root antes da sessão, como uma pessoa com `sudo` o
instalaria:

```
ana@dev:~/server/other/java$ java -version
openjdk version "25.0.4.1" 2026-08-18
OpenJDK Runtime Environment (build 25.0.4.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 25.0.4.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
```

```schooling-example
{"language": "java", "file": "Hello.java", "parts": [
 {"code": "// Hello.java: the same server in Java, with nothing but the standard library.\nimport com.sun.net.httpserver.HttpExchange;\nimport com.sun.net.httpserver.HttpServer;\nimport java.io.IOException;\nimport java.net.InetSocketAddress;\nimport java.net.URLDecoder;\nimport java.nio.charset.StandardCharsets;\nimport java.util.concurrent.Executors;\n\npublic class Hello {", "note": "**Tudo mora numa classe**, e o arquivo tem o nome dela. Os imports são do próprio JDK: o `com.sun.net.httpserver` é um servidor HTTP pequeno que vem com ele."},
 {"code": "    static void send(HttpExchange ex, int status, String json) throws IOException {\n        byte[] data = json.getBytes(StandardCharsets.UTF_8);\n        ex.getResponseHeaders().set(\"content-type\", \"application/json\");\n        ex.sendResponseHeaders(status, data.length);\n        try (var out = ex.getResponseBody()) {\n            out.write(data);\n        }\n    }", "note": "**O `throws IOException` faz parte da assinatura**: o Java obriga um método a declarar os erros que pode deixar passar, e o compilador confere se cada chamador os trata."},
 {"code": "    static String quote(String s) {\n        return \"\\\"\" + s.replace(\"\\\\\", \"\\\\\\\\\").replace(\"\\\"\", \"\\\\\\\"\") + \"\\\"\";\n    }", "note": "**Não há JSON na biblioteca padrão do Java**, então este o escreve à mão, escapando os dois caracteres que importam aqui. Um serviço de verdade usa uma biblioteca, o Jackson quase sempre."},
 {"code": "    public static void main(String[] args) throws IOException {\n        int port = Integer.parseInt(System.getenv().getOrDefault(\"PORT\", \"3000\"));\n        var server = HttpServer.create(new InetSocketAddress(\"127.0.0.1\", port), 0);\n        server.createContext(\"/\", ex -> {\n            String path = ex.getRequestURI().getPath();\n            String query = ex.getRequestURI().getRawQuery();\n            if (path.equals(\"/hello\")) {\n                String name = \"world\";\n                if (query != null && query.startsWith(\"name=\")) {\n                    name = URLDecoder.decode(query.substring(5), StandardCharsets.UTF_8);\n                }\n                send(ex, 200, \"{\\\"hello\\\":\" + quote(name) + \"}\");", "note": "**Também não há leitor de query string**: este entende `name=` e nada mais, o que basta para o teste e não para mais nada."},
 {"code": "            } else if (path.equals(\"/slow\")) {\n                try {\n                    Thread.sleep(1000);\n                } catch (InterruptedException e) {\n                    Thread.currentThread().interrupt();\n                }\n                send(ex, 200, \"{\\\"slept\\\":1000}\");\n            } else {\n                send(ex, 404, \"{\\\"error\\\":\" + quote(\"nothing at \" + path) + \"}\");\n            }\n        });", "note": "O `Thread.sleep` bloqueia, e precisa dizer o que acontece se a thread for interrompida enquanto dorme."},
 {"code": "        server.setExecutor(Executors.newVirtualThreadPerTaskExecutor());\n        server.start();\n        System.out.println(\"java on :\" + port);\n    }\n}", "note": "**Uma virtual thread por pedido.** O Java 21 trouxe threads que custam quase tão pouco quanto goroutines; antes delas, um servidor mantinha um pool de umas centenas de threads de verdade."}
]}
```

O `java Hello.java` compila o arquivo na memória e o roda, que é como se experimenta um programa de um
arquivo só; um projeto é compilado antes, por uma ferramenta de build.

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

**As mesmas respostas, com o maior trabalho de digitação.** A biblioteca padrão do Java deixa JSON e
query strings para bibliotecas, e a linguagem pede tipos, uma classe e uma exceção declarada onde o
JavaScript não pede nada. O que isso compra é um compilador que recusa uma classe grande de erros antes
de o programa rodar, e é por isso que equipes grandes continuam escolhendo o Java.

| o quê | em termos de Node |
|---|---|
| **Spring Boot**, o framework que a maioria dos serviços Java usa | Express, com muito mais incluído |
| **Maven** ou **Gradle**, e o `pom.xml` ou `build.gradle` | `npm` e `package.json` |
| **Jackson**, para JSON | `JSON.parse` e `JSON.stringify` |
| um arquivo `.jar`, rodado com `java -jar` | a pasta do projeto, rodada com `node` |
