---
title: Métricas com o Micrometer
version: 1
---

O health é um veredito sobre este instante. Uma **métrica** é um número que a aplicação mantém ao
longo do tempo: quantas requisições até agora, quanto tempo levaram, quantas conexões estão ocupadas
agora. A aula 16 apresentou o SLF4J, uma fachada pela qual o código registra logs enquanto um backend
decide para onde as linhas vão. O **Micrometer** é o mesmo arranjo para números. O código da livraria,
e toda biblioteca que o Boot configura, registra num `MeterRegistry`; qual sistema vai ler os números
no fim é uma dependência no pom, e o código não muda quando ela muda.

Todo número fica num **meter**, e três tipos cobrem quase tudo:

- um **counter** só sobe: requisições atendidas, pedidos feitos. O valor dele desde a inicialização
  raramente importa; o que importa é a velocidade com que cresce;
- um **gauge** é a leitura de alguma coisa neste momento, e pode subir ou descer: conexões em uso,
  memória usada;
- um **timer** conta eventos e soma quanto tempo eles levaram, então dá uma contagem, um total e um
  máximo de uma vez.

Um meter tem um nome e **tags**, pares de chave e valor. Um nome com valores de tag diferentes é uma
família de séries separadas, e é isso que deixa o mesmo meter responder "todas as requisições" e "só
os 404 em `/books/{id}`".

## O que já é medido

O código da própria livraria registra um meter, o counter da próxima seção. Peça a lista de nomes
mesmo assim, e são 99:

```
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/metrics | python3 -c 'import json,sys; print(len(json.load(sys.stdin)["names"]))'
98
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/metrics | python3 -c 'import json,sys; print(*json.load(sys.stdin)["names"], sep="\n")' | grep -E '^(http|hikaricp|jvm.memory|bookshop)'
bookshop.orders
hikaricp.connections
hikaricp.connections.acquire
hikaricp.connections.active
hikaricp.connections.creation
hikaricp.connections.idle
hikaricp.connections.max
hikaricp.connections.min
hikaricp.connections.pending
hikaricp.connections.timeout
hikaricp.connections.usage
jvm.memory.committed
jvm.memory.max
jvm.memory.usage.after.gc
jvm.memory.used
```

O segundo comando imprime os nomes um por linha e guarda as famílias do servidor HTTP, do pool de
conexões, da memória e da livraria. A do servidor HTTP não aparece: um timer é criado pela primeira
requisição que ele mede, e desde esta inicialização ninguém perguntou nada à porta 8080. O
`bookshop.orders` aparece antes de qualquer pedido, porque o `OrderService` o registra no construtor.
Os nomes que ficaram de fora cobrem as threads e o garbage collector da JVM, o processo, as sessões do
Tomcat, o Logback, que conta linhas de log por nível, e o Spring Security, que mede cada filtro da
chain da aula 15.

## Um timer, lido pelas tags

Faça algumas requisições, uma delas para um livro que não existe, e peça o timer por trás delas:

```
ana@vm:~/bookshop$ for path in /books /books /books/1 /books/2 /books/99; do curl -s -o /dev/null -w "%{http_code} $path\n" localhost:8080$path; done
200 /books
200 /books
200 /books/1
200 /books/2
404 /books/99
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/metrics/http.server.requests | python3 -m json.tool
{
    "availableTags": [
        {
            "tag": "exception",
            "values": [
                "none"
            ]
        },
        {
            "tag": "method",
            "values": [
                "GET"
            ]
        },
        {
            "tag": "error",
            "values": [
                "none"
            ]
        },
        {
            "tag": "uri",
            "values": [
                "/books/{id}",
                "/books"
            ]
        },
        {
            "tag": "outcome",
            "values": [
                "CLIENT_ERROR",
                "SUCCESS"
            ]
        },
        {
            "tag": "status",
            "values": [
                "404",
                "200"
            ]
        }
    ],
    "baseUnit": "seconds",
    "measurements": [
        {
            "statistic": "COUNT",
            "value": 5.0
        },
        {
            "statistic": "TOTAL_TIME",
            "value": 0.187019944
        },
        {
            "statistic": "MAX",
            "value": 0.12685655
        }
    ],
    "name": "http.server.requests"
}
```

`COUNT` é cinco, uma por requisição. `TOTAL_TIME` soma as durações, na `baseUnit`, segundos, e `MAX` é
a requisição isolada mais longa. Esse máximo cobre uma janela recente, e não o tempo todo desde a
inicialização, então uma requisição lenta de manhã não fica no topo o dia inteiro. `availableTags`
lista todos os valores que cada tag já teve: duas rotas, dois status, dois resultados. A `exception`
continua `none` até no 404, porque o handler da aula 7 transformou a `BookNotFoundException` numa
resposta antes que ela escapasse.

A tag `uri` é a linha que mais importa. Ela guarda o **template da rota**, `/books/{id}`, e nunca o
caminho que foi pedido. Se guardasse `/books/1`, `/books/2` e cada id que alguém já digitou, a família
ganharia uma série a cada caminho novo, e um registry que guarda todas as séries na memória cresceria
junto até o processo ficar sem memória. Uma requisição que não casou com rota nenhuma, como a anônima
para `/actuator/health` na 8080 da primeira seção, fica em `UNKNOWN` pelo mesmo motivo.

As tags podem ser escolhidas na consulta, como `tag=chave:valor`, uma vez por tag. As chaves do
template são escritas `%7B` e `%7D`, porque uma URL não pode levá-las cruas:

```
ana@vm:~/bookshop$ curl -s "localhost:8081/actuator/metrics/http.server.requests?tag=uri:/books/%7Bid%7D&tag=status:404" | python3 -m json.tool | tail -n 16
    "measurements": [
        {
            "statistic": "COUNT",
            "value": 1.0
        },
        {
            "statistic": "TOTAL_TIME",
            "value": 0.015200056
        },
        {
            "statistic": "MAX",
            "value": 0.015200056
        }
    ],
    "name": "http.server.requests"
}
```

## O pool, como a aula 14 prometeu

A aula 14 terminou num pool que se esgota. O HikariCP publica o próprio estado, e cada um destes é um
gauge:

```
ana@vm:~/bookshop$ for m in active idle pending max; do printf "%-8s" $m; curl -s localhost:8081/actuator/metrics/hikaricp.connections.$m | python3 -c "import json,sys; print(json.load(sys.stdin)[\"measurements\"][0][\"value\"])"; done
active  0.0
idle    10.0
pending 0.0
max     10.0
```

Em repouso, as dez conexões estão livres e ninguém espera. O **`hikaricp.connections.pending`** é o
que se vigia: ele conta as threads na fila por uma conexão, e uma requisição que espera ali tempo
demais falha depois do `connection-timeout`, como o `GET /books` falhou na seção anterior. Um pending
que fica acima de zero, com o `active` grudado no `max`, é a cara do esgotamento da aula 14, visto de
fora e antes de a primeira requisição estourar o tempo.
