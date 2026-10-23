---
title: O formato do Prometheus, e o que merece alerta
version: 1
---

O `/actuator/metrics` é para uma pessoa com curl. Ninguém vigia um sistema em produção desse jeito: um
servidor de monitoramento pede a cada instância todos os números dela num intervalo fixo, guarda tudo
como séries temporais e dispara um alerta quando uma regra sobre elas fica verdadeira. O
**Prometheus** é a escolha comum, e ele **puxa**: a aplicação não envia nada para lugar nenhum, ela
responde quando perguntam. Esse é o trabalho do quarto endpoint, `/actuator/prometheus`, que a
dependência `micrometer-registry-prometheus` acrescentou. Instalar o próprio Prometheus, e a linguagem
de consulta dele, ficam para a aula 5 de `observability`; o que esta seção lê é o contrato entre os
dois, o texto que a livraria serve.

## O formato de texto

```
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/prometheus | wc -l
466
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/prometheus | grep -E "bookshop_orders|^hikaricp_connections_(active|pending)"
# HELP bookshop_orders_total  
# TYPE bookshop_orders_total counter
bookshop_orders_total{outcome="out-of-stock"} 1.0
bookshop_orders_total{outcome="placed"} 2.0
hikaricp_connections_active{pool="bookshop-pool"} 0.0
hikaricp_connections_pending{pool="bookshop-pool"} 0.0
```

Todo meter do registry está nessas linhas, escritas para um programa ler. Cada família começa com uma
linha `# HELP`, a descrição, vazia aqui porque o counter foi registrado sem uma, e uma linha `# TYPE`.
Depois vem uma linha por série: o nome, as tags entre chaves, agora chamadas de **labels**, e o valor
atual. Os nomes mudaram no caminho, por regras que o Micrometer aplica para este backend:

| no Micrometer | no Prometheus |
|---|---|
| `bookshop.orders`, um counter | `bookshop_orders_total` |
| `hikaricp.connections.active`, um gauge | `hikaricp_connections_active` |
| `http.server.requests`, um timer em segundos | `http_server_requests_seconds_count`, `_sum` e `_max` |

Pontos viram sublinhados, um counter ganha `_total`, e um timer vira três séries com a unidade no
nome. A contagem e a soma de um timer são counters elas mesmas:

```
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/prometheus | grep -E "^http_server_requests_seconds_(count|sum)" | grep "/books\""
http_server_requests_seconds_count{error="none",exception="none",method="GET",outcome="SUCCESS",status="200",uri="/books"} 2
http_server_requests_seconds_sum{error="none",exception="none",method="GET",outcome="SUCCESS",status="200",uri="/books"} 0.134895875
```

## Um counter se lê como taxa

`bookshop_orders_total{outcome="placed"}` é o número de pedidos desde que este processo subiu. Sozinho,
isso quase não responde nada: volta a zero a cada reinício, e um número grande pode só querer dizer
muito tempo no ar. O que um sistema de monitoramento lê é **a velocidade com que ele cresce**. Faça
duas leituras, com alguns pedidos no meio, e a conta é a mesma que o Prometheus faz:

```
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/prometheus | grep "^bookshop_orders_total"; date +%T
bookshop_orders_total{outcome="out-of-stock"} 1.0
bookshop_orders_total{outcome="placed"} 2.0
20:35:05
ana@vm:~/bookshop$ for book in 4 4 4 4 4 4 3 3; do curl -s -o /dev/null -w '%{http_code} ' -H "Authorization: Bearer $(cat ana.token)" -H 'Content-Type: application/json' -d "{\"lines\":[{\"bookId\":$book,\"quantity\":1}]}" localhost:8080/orders; done; echo
201 201 201 201 201 409 409 409 
ana@vm:~/bookshop$ sleep 15; curl -s localhost:8081/actuator/prometheus | grep "^bookshop_orders_total"; date +%T
bookshop_orders_total{outcome="out-of-stock"} 4.0
bookshop_orders_total{outcome="placed"} 7.0
20:35:20
```

Os oito códigos do meio dizem o que aconteceu: Persuasion tinha cinco exemplares, então o sexto pedido
foi recusado, e Frankenstein não tinha mais nenhum para os dois últimos. Com quinze segundos entre as
leituras, `placed` foi de 2 para 7 e `out-of-stock` de 1 para 4. Cinco pedidos em quinze segundos dão
um terço de pedido por segundo, e três recusas dão 0,2 por segundo. Essa divisão, repetida numa
janela deslizante de coletas, é o que o `rate()` do Prometheus devolve, e ela aguenta um reinício: um
counter que cai é lido como um processo que subiu de novo, nunca como pedidos devolvidos.

## O que deveria acordar alguém

Um alerta é uma regra sobre essas séries que manda uma mensagem para uma pessoa. Cada alerta que
dispara sem precisar de ninguém ensina quem está de plantão a ignorar o próximo, então uma boa regra
vigia o que o cliente sente, ou o que está prestes a fazê-lo sentir, e mais nada. Para a livraria,
quatro candidatas, escritas como um arquivo de regras do Prometheus. **Este arquivo não foi carregado
num Prometheus neste curso**, então nada aqui é resultado capturado; ele mostra como cada pergunta
vira uma expressão sobre as séries acima.

```yaml
groups:
  - name: bookshop
    rules:
      - alert: BookshopDown
        expr: up{job="bookshop"} == 0
        for: 1m
      - alert: BookshopServerErrors
        expr: |
          sum(rate(http_server_requests_seconds_count{job="bookshop", outcome="SERVER_ERROR"}[5m]))
            / sum(rate(http_server_requests_seconds_count{job="bookshop"}[5m])) > 0.05
        for: 5m
      - alert: BookshopPoolWaiting
        expr: hikaricp_connections_pending{job="bookshop", pool="bookshop-pool"} > 0
        for: 2m
      - alert: BookshopOrdersRefused
        expr: |
          sum(rate(bookshop_orders_total{job="bookshop", outcome="out-of-stock"}[1h]))
            / sum(rate(bookshop_orders_total{job="bookshop"}[1h])) > 0.2
        for: 30m
```

`up` é uma série que o próprio Prometheus escreve para cada alvo: `1` quando a última coleta teve
resposta, `0` quando não teve, o que cobre um processo que morreu, uma máquina que sumiu e uma porta
que parou de responder. A segunda regra é a fração de requisições que falharam no servidor, em cinco
minutos, que é o sintoma que o cliente encontra. A terceira é o esgotamento da aula 14, pego enquanto
as requisições ainda esperam, e não depois de estourarem o tempo. `job` é uma label que o Prometheus
acrescenta a toda série que coleta, a partir da configuração dele, para que uma regra cite uma
aplicação só.

A quarta é o counter da própria livraria, e é outro tipo de alerta. Mais de um quinto dos pedidos
recusados por falta de estoque, durante meia hora, é um problema de compras, e não uma queda. Ele cabe
num chamado para quem compra os livros, não no telefone de alguém às três da manhã.

Passe a falha da seção de health por essas regras. O `up` ficou em 1, porque o servidor de
gerenciamento continuou respondendo à coleta, então a primeira regra fica quieta: o processo estava
vivo, e é só isso que ela pergunta. A segunda dispara. O cliente recebeu 401, mas o timer registrou um
`500` com `SERVER_ERROR`, e, com toda requisição que precisa do banco falhando, a fração fica muito
acima de cinco por cento. A terceira dispara também, se a falha durar dois minutos com requisições
chegando, porque cada uma espera cinco segundos por uma conexão. Aqui os números foram mais verdadeiros
do que a resposta que o cliente recebeu.
