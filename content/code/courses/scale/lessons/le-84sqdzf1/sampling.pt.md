---
title: Amostragem, e quais rastros guardar
version: 1
---

Um rastro por pedido cabe no bolso com as poucas centenas de pedidos por segundo da bilheteria num
laboratório. Com cem mil, é um segundo sistema maior que o primeiro: os spans precisam ser mandados,
processados e guardados, e quase todos descrevem pedidos que foram rápidos e corretos. A
**amostragem** (*sampling*) guarda alguns rastros e descarta o resto.

## Amostragem na cabeça

A decisão mais simples é tomada no começo do rastro, pelo primeiro serviço: guardar este rastro ou
não, com uma probabilidade. Todo serviço seguinte lê a decisão nas flags do `traceparent` da seção 08
e a segue, então um rastro é guardado inteiro ou descartado inteiro.

Os SDKs do OpenTelemetry leem o amostrador de variáveis padrão, que o `compose.yaml` passa à
bilheteria. Primeiro com o padrão, todo rastro guardado, depois de reiniciar o Jaeger para esvaziá-lo,
e duzentas leituras:

```
ana@lab:~/tickets$ docker compose restart jaeger
 Container tickets-jaeger-1 Restarting 
 Container tickets-jaeger-1 Started 
ana@lab:~/tickets$ for i in $(seq 200); do curl -s localhost:8080/events/1 >/dev/null; done
ana@lab:~/tickets$ sleep 7
ana@lab:~/tickets$ python3 trace.py --count 'GET /events/{id}'
200 traces of GET /events/{id}
```

**200 rastros para 200 leituras.** Depois a bilheteria reiniciada com `parentbased_traceidratio` em
0,1: guardar um rastro se o id dele cair no décimo mais baixo dos ids possíveis, a não ser que um pai
já tenha decidido:

```
ana@lab:~/tickets$ SAMPLER=parentbased_traceidratio SAMPLER_ARG=0.1 docker compose up -d app
 Container tickets-db-1 Running 
 Container tickets-replica-1 Running 
 Container tickets-app-1 Recreate 
 Container tickets-app-1 Recreated 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
ana@lab:~/tickets$ docker compose restart jaeger
 Container tickets-jaeger-1 Restarting 
 Container tickets-jaeger-1 Started 
ana@lab:~/tickets$ for i in $(seq 200); do curl -s localhost:8080/events/1 >/dev/null; done
ana@lab:~/tickets$ sleep 7
ana@lab:~/tickets$ python3 trace.py --count 'GET /events/{id}'
22 traces of GET /events/{id}
```

**22 rastros para 200 leituras**, cerca de um décimo, como pedido. A decisão é tomada a partir do id
do rastro, que é aleatório, então a contagem varia em torno de 20 de uma execução para outra; e como
ela vem do id e não de uma moeda, todo serviço que aplica a mesma proporção ao mesmo id toma a mesma
decisão.

## O que a amostragem na cabeça não consegue

Ela decide antes de qualquer coisa acontecer, então guarda um décimo dos pedidos lentos e um décimo
dos que falharam, os rastros que alguém de fato quer. Com uma proporção de 1%, o único pedido com
falha em dez mil quase nunca é rastreado.

A **amostragem na cauda** (*tail sampling*) decide no fim, quando o rastro inteiro já chegou: guardar
todo rastro com erro, todo rastro mais lento que 250 ms, e 1% do resto. Ela roda no Collector, no
processador `tail_sampling` da distribuição contrib do Collector, e tem um custo real: o Collector
precisa segurar na memória todo span de todo rastro recente até decidir, e todos os spans de um
rastro precisam chegar ao **mesmo** Collector, o que exige uma camada de Collectors que balanceia a
carga roteando pelo id do rastro.

O arranjo comum são as duas: uma amostragem generosa na cabeça, ou nenhuma, nos serviços, e
amostragem na cauda numa camada de Collectors que guarda o que interessa. Qualquer que seja a
política, **métricas nunca são amostradas**: os contadores da aula 7 contam todo pedido, então um
rastro amostrado é um detalhe de um número que continua exato.
