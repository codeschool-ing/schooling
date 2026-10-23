---
title: Um servidor HTTP no JDK
version: 1
---

**HTTP é uma conversa sobre um socket num formato fixo: o cliente manda um método, um caminho e alguns
cabeçalhos, o servidor responde com um código de status, cabeçalhos e um corpo.** Escrever esse formato à
mão sobre um socket é um bom exercício e uma má ideia. O JDK traz um pequeno servidor HTTP no pacote
`com.sun.net.httpserver`, o bastante para um teste, uma ferramenta ou esta aula:

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

Inicie-o num terminal e deixe-o rodando; ele imprime uma linha e espera:

```
ana@vm:~/fp/net$ java ShelfServer.java
listening on http://127.0.0.1:8080
```

## Como o servidor é montado

O `HttpServer.create` abriu o socket de escuta em `127.0.0.1`, porta 8080, e o `createContext` ligou um
**handler**, uma referência de método da aula 3, a todo caminho que começa com `/books`, e outro a `/slow`.
O handler recebe um `HttpExchange`, uma requisição e a sua resposta: ele lê o método e o caminho, decide, e
chama o `send`, que define o status, o `Content-Type` e o tamanho e escreve o corpo. Um handler que esquece
de enviar deixa o cliente esperando.

`setExecutor(Executors.newVirtualThreadPerTaskExecutor())` é a aula 17 numa linha: **cada requisição roda
numa thread virtual própria**, então o sono de três segundos em `/slow` não segura nada além daquela
requisição. A lista de livros é uma `CopyOnWriteArrayList` da aula 15 pelo mesmo motivo: duas requisições
podem chegar juntas, e uma pode acrescentar um livro enquanto outra lê a lista.

| status | quer dizer | este servidor o envia |
|---|---|---|
| 200 | OK, o corpo é a resposta | para uma lista ou um livro que existe |
| 201 | criado | depois de um `POST` acrescentar um livro |
| 404 | não encontrado | para um número de livro depois do fim, ou um caminho que ele não conhece |

O caminho `/books/\d+` é conferido com uma expressão regular, que é a aula 24; aqui quer dizer `/books/`
seguido de dígitos. Deixe o servidor rodando nas duas próximas seções, e pare-o com `Ctrl+C` no fim da
seção 05.
