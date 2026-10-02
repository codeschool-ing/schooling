---
title: Decidindo na cabeça
version: 1
---

**A amostragem na cabeça decide quando o rastro começa**, no serviço que o inicia, e todo serviço
depois dele faz o que mandaram. O SDK toma a decisão com um *amostrador* (sampler), e o mais comum
guarda uma fração fixa. Um script na sandbox inicia oito checkouts sob um amostrador que guarda metade:

```
ana@obs:~/shop$ docker compose run --rm sandbox python flags.py
 Container shop-otel-collector-1 Running 
 Container shop-sandbox-run-6e3ae4e8d198 Creating 
 Container shop-sandbox-run-6e3ae4e8d198 Created 
00-54199263ed3ad5ffbb58df35a67aa053-c9195a44cfd2c2a8-02 dropped
00-c6db9fe128d3a99ac5f915234528b71e-61d22abfc6cb43b2-02 dropped
00-36c6ffd2ee255dd7693caacddcc25651-202a72d84f6fa68e-03 recorded
00-edaa875d1f8177f50f0b20753f99a1d4-44b919efcfb39b7b-03 recorded
00-8a5d4e4a91fd6fda14ff1770afdd2bd8-8523f6532382cf90-03 recorded
00-67f0d72edf5f168ebf2a7aedfefadfda-679245edb0a4c2cb-02 dropped
00-0c891ce3f92c9efedafd8bc245e6d78e-1ceb2015333608e9-02 dropped
00-78389170ad267c7309c8b6b3e668f664-29b99cefc9378fe5-03 recorded
```

Cada linha é um `traceparent`, o cabeçalho que a aula 4 desmontou, e a resposta está no último
campo. **`03` diz que o rastro está sendo registrado**, `02` que não está. O `2` nos dois é o flag
que a aula 4 mencionou, dizendo que os bits do trace id são aleatórios, a propriedade de que este
amostrador depende. O `TraceIdRatioBased` não joga dado: ele lê o trace id como um número e guarda o
rastro se esse número cai abaixo da fração. Dois serviços com o mesmo id e a mesma fração chegam à
mesma resposta sem conversar.

A loja não precisa de código para isso. O SDK lê o amostrador do ambiente, então a vitrine, onde
começa o rastro de todo checkout, ganha um num override, guardando um rastro em dez:

```
ana@obs:~/shop$ cat compose.override.yaml
services:
  storefront:
    environment:
      OTEL_TRACES_SAMPLER: parentbased_traceidratio
      OTEL_TRACES_SAMPLER_ARG: "0.1"
```

`parentbased_traceidratio` são duas regras: **se chegou um pai, faça o que ele diz; se este é a raiz,
guarde a fração dada.** Os outros serviços ficam com o padrão, `parentbased_always_on`, que segue um
pai e guarda tudo quando não há nenhum. Então a vitrine decide e todos os outros obedecem. Um minuto
depois, o que chega ao Collector:

```
ana@obs:~/shop$ ./promq 'sum(rate(otelcol_receiver_accepted_spans[1m]))'
  4.9111111111111105
```

4,9 spans por segundo em vez de 35,5, mais perto de um sétimo que de um décimo: um em dez é uma
probabilidade, não uma cota, e um minuto tem só uns 270 checkouts.

E, para os dez últimos checkouts no log da vitrine, o que o Jaeger tem:

```
ana@obs:~/shop$ for t in $(docker compose logs --no-log-prefix --since 40s --until 15s storefront | grep "checkout finished" | jq -r .trace_id | tail -10); do printf "%s  " $t; curl -s localhost:16686/api/traces/$t | jq -r 'if .data then (.data[0] as $d | ($d.spans | map(.spanID)) as $ids | $d.spans | "\(length) spans, top: " + (map(select(.references == [] or (.references[0].spanID | IN($ids[]) | not))) | map($d.processes[.processID].serviceName + " " + .operationName) | join(", "))) else .errors[0].msg end'; done
f014826b4c5845d99dd84557c0137401  trace not found
e58969d1ab8e7bd1bbfdca4dae9da118  trace not found
a8a985b1dcd8de687aa9cdba4f0e5c6b  trace not found
809b434e8e1a4c1a745633af675e53a4  trace not found
a94508d611d901b89f5786e32cdf1549  trace not found
89f7d213f373cbf7b8d4cf76b074bd28  trace not found
3c7a870b82e3afe23825fe0310dc4260  trace not found
c93cc02fad1a827cee4603a967989fec  trace not found
cea0990a2b7b980d4e2464447e909c9d  trace not found
7d199f333e9aa3e8317b43b2c5ae6009  trace not found
```

Nenhum dos dez foi guardado. A um em dez isso acontece mais ou menos uma vez em três, e a seção
seguinte mostra rastros guardados inteiros. Todo checkout ainda escreveu a linha de log dele, com o
trace id, fosse qual fosse a decisão. Um trace id num log não é promessa de que o rastro foi
guardado: lembre disso na próxima vez que um clique de uma linha de log para o Jaeger não achar
nada.

A amostragem na cabeça é barata naquilo que mais importa: **um rastro descartado não custa quase nada
desde o primeiro span**. Os SDKs não o exportam, a rede não o carrega e o armazenamento nunca o vê. A
fraqueza dela é decidir às cegas. O checkout lento e o que falhou são descartados exatamente tão
frequentemente quanto o rápido, no mesmo um em dez.
