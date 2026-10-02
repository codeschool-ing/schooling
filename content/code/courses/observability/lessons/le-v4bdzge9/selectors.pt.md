---
title: Primeiras consultas: selecionando séries
version: 1
---

O PromQL, a linguagem de consulta do Prometheus, é perguntado por uma API HTTP, e as respostas são
JSON. Um script curto, o `promq`, manda uma expressão e imprime cada série devolvida numa linha, os
labels dela e depois o valor:

```
ana@obs:~/shop$ cat promq
#!/bin/sh
# promq 'EXPRESSION': ask Prometheus for the value of an expression, now.
curl -sG localhost:9090/api/v1/query --data-urlencode "query=$1" |
  jq -r '.data.result[] | (.metric | to_entries | map("\(.key)=\(.value)") | join(" ")) + "  " + .value[1]'
```

A expressão mais simples é o nome de uma métrica com labels a casar, um **seletor**. `up` para um
job:

```
ana@obs:~/shop$ ./promq 'up{job="payments"}'
__name__=up instance=payments:8082 job=payments  1
```

E o contador de requisições da vitrine, todas as séries dele:

```
ana@obs:~/shop$ ./promq 'http_server_requests_total{job="storefront"}'
__name__=http_server_requests_total code=200 instance=storefront:8080 job=storefront method=GET route=/health  7
__name__=http_server_requests_total code=200 instance=storefront:8080 job=storefront method=GET route=/products  34
__name__=http_server_requests_total code=201 instance=storefront:8080 job=storefront method=POST route=/checkout  281
__name__=http_server_requests_total code=402 instance=storefront:8080 job=storefront method=POST route=/checkout  17
```

Quatro séries, uma por combinação de labels que a vitrine já respondeu. O resultado é um **vetor
instantâneo**: um valor por série, tomado no momento da consulta. Labels podem ser casados exatamente
com `=`, excluídos com `!=`, ou casados com uma expressão regular com `=~`, e é assim que se escreve
*todo 4xx*:

```
ana@obs:~/shop$ ./promq 'http_server_requests_total{job="storefront", code=~"4.."}'
__name__=http_server_requests_total code=402 instance=storefront:8080 job=storefront method=POST route=/checkout  17
```

**Esses números sozinhos quase não respondem nada.** 281 checkouts responderam `201` desde que a
vitrine começou, e esse começo pode ter sido há um minuto ou há um mês. Um contador só cresce, e o
valor dele depende sobretudo de há quanto tempo o processo está rodando. Um contador vira um número
útil quando se pergunta com que velocidade ele está crescendo, que é a seção seguinte.
