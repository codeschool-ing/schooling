---
title: Quando a rede falha
version: 1
---

**Uma chamada de método ou retorna ou lança; uma requisição pode também simplesmente nunca ser
respondida.** A rede traz jeitos de falhar que um programa numa máquina só nunca encontra, e cada um tem de
ser decidido no código: quanto esperar para conectar, quanto esperar por uma resposta, e o que fazer com uma
resposta que diz não. Com o servidor ainda rodando:

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

## Três desfechos

**Ninguém escutando** na porta 8081 falhou na hora com uma `ConnectException`: o sistema operacional
respondeu pelo servidor ausente que não havia nada ali. Contra uma máquina que não responde de jeito nenhum,
a mesma tentativa esperaria, e o `connectTimeout` de dois segundos é o que a encerraria.

**Lento demais** conectou e enviou a requisição, e o servidor levou três segundos para responder. O próprio
`timeout` da requisição, de um segundo, encerrou a espera com uma `HttpTimeoutException` depois de 1.002 ms.
**Sem timeout, o `send` espera o quanto o servidor levar**, e um servidor que nunca responde segura quem
chamou para sempre; toda requisição que um programa manda a outra máquina deve dizer quanto aceita esperar.

**Livro que não existe** não lançou. Um 404 é uma resposta completa, e o `send` a devolveu com o seu status.
O código que recebe uma resposta decide o que cada status quer dizer, e um código que só lê o corpo está
lendo uma página de "não encontrado" como se fosse um livro.

| desfecho | como chega | quem decide |
|---|---|---|
| nada naquele endereço | `ConnectException` | o sistema operacional, na hora |
| nenhuma resposta a tempo | `HttpTimeoutException` | o `timeout` da requisição |
| uma resposta que diz não | uma resposta com status 4xx ou 5xx | o código que lê o `statusCode()` |

De volta ao primeiro terminal, o servidor tinha impresso uma linha para cada requisição que atendeu. Pare-o
com `Ctrl+C`:

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

Os quatro `GET`s que o `sendAsync` iniciou chegaram numa ordem que ninguém escolheu.

## HTTPS, e o ajuste que nunca se muda

Uma requisição para um endereço `https://` é cifrada, e **o cliente confere o certificado do servidor antes
de enviar qualquer coisa**: que o certificado foi emitido para aquele nome de host e é assinado por uma
autoridade em que o JDK confia. Uma conferência que falha é uma `SSLHandshakeException`, e é a única exceção
aqui que quer dizer "pare": o programa pode estar falando com alguém que finge ser o servidor. Código achado
na internet que instala um `TrustManager` que aceita qualquer certificado faz o erro sumir tirando a
conferência, e com ela o motivo de existir HTTPS. A saída para um certificado em que o JDK não confia é
acrescentar aquela única autoridade ao trust store que o programa usa.

Mais uma diferença em relação a um navegador: o `HttpClient` não usa proxy a menos que lhe deem um. Numa rede
onde o tráfego tem de passar por um proxy, monte o cliente com `.proxy(ProxySelector.getDefault())`, que
segue os ajustes `https.proxyHost` e `https.proxyPort` da JVM.
