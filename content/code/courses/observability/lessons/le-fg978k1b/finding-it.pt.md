---
title: Achando o label culpado
version: 1
---

No experimento o culpado era conhecido. Em produção não é: a memória sobe, as coletas ficam lentas,
e em algum lugar entre centenas de métricas uma começou a se multiplicar. **O Prometheus mantém
estatísticas sobre o seu próprio bloco ativo (head)**, e a API de status dele responde às duas
perguntas que o acham, que métricas têm mais séries e que labels têm mais valores:

```
ana@obs:~/shop$ curl -s localhost:9090/api/v1/status/tsdb | jq -r '.data.seriesCountByMetricName[:3][] | [.name, .value] | @tsv'
demo_logins_total	20003
demo_logins_created	20003
erlang_vm_allocators	496
ana@obs:~/shop$ curl -s localhost:9090/api/v1/status/tsdb | jq -r '.data.labelValueCountByLabelName[:3][] | [.name, .value] | @tsv'
user_id	20000
__name__	1225
le	113
```

`demo_logins_total` e `demo_logins_created` com cerca de vinte mil séries cada, muito acima de
qualquer outra coisa; a métrica seguinte, do RabbitMQ, tem 496. E o label com mais valores distintos
é `user_id`, com 20000, contra 1225 nomes de métrica no laboratório inteiro. **Duas requisições e o
culpado tem nome**: a métrica, o label e, pelos labels das próprias séries, o job que a manda.

A mesma visão existe na interface web do Prometheus, em *Status*, *TSDB Status*. Um hábito que vale
ter é olhá-la antes do problema, para que os números normais sejam conhecidos: neste laboratório,
alguns milhares de séries e nenhum label acima de algumas centenas de valores. Uma equipe que conhece
o seu normal vê um salto no dia em que ele acontece; uma que não conhece o vê no dia em que o
Prometheus é morto por falta de memória.
