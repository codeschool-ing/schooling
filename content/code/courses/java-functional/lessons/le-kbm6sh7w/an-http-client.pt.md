---
title: HttpClient
version: 1
---

**O `java.net.http.HttpClient`, no JDK desde o Java 11, envia uma requisição e devolve uma resposta,
esperando por ela ou como um `CompletableFuture`.** Com o servidor da seção anterior rodando, abra um
segundo terminal e rode isto:

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

## Três objetos e dois jeitos de esperar

Tudo é montado com três objetos imutáveis. **O `HttpClient`** guarda os ajustes, aqui um timeout de conexão
de dois segundos, e é feito uma vez e compartilhado: ele mantém conexões abertas entre requisições. **Um
`HttpRequest`** é o método, o endereço, os cabeçalhos e o corpo, montado com um builder, `GET` a menos que
mandem outro. **Um body handler** diz o que fazer com os bytes da resposta; o `ofString()` os decodifica com
o charset que a resposta indica, aqui o `charset=utf-8` que o servidor mandou.

O `send` esperou cada resposta, e as quatro linhas mostram o que voltou: um 200 com a lista, **um 404 com o
seu próprio corpo**, e um 201 para o livro novo. O 404 não lançou. Ele é uma resposta, e o código leu o seu
status como o de qualquer outra.

O `sendAsync` não esperou. Ele devolveu um `CompletableFuture<HttpResponse<String>>` na hora, então o stream
iniciou quatro requisições antes de qualquer uma responder, e o `thenApply` da aula 16 transformou cada
resposta futura num título futuro. Só o `join`, no fim, esperou. **Os títulos voltaram na ordem em que foram
pedidos**, porque a lista de futures estava nessa ordem, fosse qual fosse a ordem em que as respostas
chegaram; o terminal do próprio servidor, no fim da seção 05, mostra a ordem em que ele de fato as atendeu.

O cliente não usou um pool de threads próprio. O `sendAsync` roda num executor dentro do cliente, e o
`HttpClient.newBuilder().executor(...)` pode trocá-lo, a mesma escolha do `supplyAsync` com e sem executor
na aula 16.
