---
title: Correlação: o id do rastro em toda linha
version: 1
---

A aula 1 achou as linhas de log de um checkout lento em três serviços buscando pelo id do rastro.
Isso funciona porque o formatador acrescenta os ids do span corrente a toda linha escrita enquanto um
span é o corrente, o que num serviço que atende requisições é quase toda linha. **Quase**, e as
exceções valem ser conhecidas. A primeira linha do mailer depois de um reset:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix mailer | head -1 | jq -c .
{"time":"2026-10-02T10:41:29.824Z","level":"WARNING","service":"mailer","logger":"mailer","message":"rabbitmq not reachable, retrying in 2 s"}
```

Sem `trace_id`, e com razão: o mailer estava tentando conectar ao RabbitMQ na partida, e nenhuma
requisição estava sendo atendida. Contando toda linha dos quatro serviços que não tem id de rastro:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix storefront orders payments mailer | jq -r 'select(has("trace_id") | not) | .message' | sort | uniq -c
      2 rabbitmq not reachable, retrying in 2 s
      1 waiting for orders
```

Três linhas entre milhares, todas da partida. **Toda linha escrita enquanto se atende uma requisição
tem o id**, que é a propriedade que importa, e ela vale sem ninguém lembrar de passar o id ao logger,
porque o formatador o lê do mesmo span corrente que os rastros usam.

Essa é a vantagem de tirar o id do rastreamento em vez de inventar um id de requisição próprio. Um
`request_id` caseiro tem de ser gerado na borda, posto num cabeçalho, lido em todo serviço e passado
a toda chamada de log, e é mais uma coisa que a propagação da aula 4 tem de levar. O id do rastro já
é levado. **Onde um serviço não rastreia**, um id de requisição ainda é muito melhor que nada, e a
regra é a mesma: gere uma vez na borda, propague em toda chamada, escreva em toda linha.
