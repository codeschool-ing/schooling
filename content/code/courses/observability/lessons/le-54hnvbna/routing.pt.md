---
title: Roteamento: pages, tickets e inibição
version: 1
---

O Prometheus decide que um alerta está disparando. **O Alertmanager decide quem fica sabendo**, com que
frequência e junto com o quê. A configuração da aula 5 mandava tudo para o pager. A nova do
laboratório, `alertmanager/routes.yml`, separa as duas severidades:

```
ana@obs:~/shop$ cat alertmanager/routes.yml
# Pages and tickets go to different places, and a page silences the ticket
# about the same objective.
route:
  receiver: tickets
  group_by: [alertname, slo]
  group_wait: 10s
  group_interval: 1m
  repeat_interval: 4h
  routes:
    - matchers: ['severity="page"']
      receiver: pager

inhibit_rules:
  - source_matchers: ['severity="page"']
    target_matchers: ['severity="ticket"']
    equal: [slo]

receivers:
  - name: pager
    webhook_configs:
      - url: http://pager:8090/page
  - name: tickets
    webhook_configs:
      - url: http://pager:8090/ticket
```

Três partes, cada uma com um trabalho:

- **A árvore de rotas.** Todo alerta entra pelo topo, cujo receptor é `tickets`. Uma rota filha pega
  `severity="page"` e o manda para o pager. As rotas são comparadas de cima para baixo e a primeira que
  casa vence, a não ser que uma rota diga para continuar.
- **Agrupamento.** Alertas com o mesmo `alertname` e o mesmo `slo` viram uma notificação, mandada dez
  segundos depois de o primeiro chegar (`group_wait`), para que alertas que disparam juntos cheguem
  juntos. Uma repetição sai a cada quatro horas enquanto o alerta continuar disparando.
- **Inibição.** Enquanto um `page` dispara, qualquer `ticket` com o mesmo `slo` é segurado. A pessoa já
  acordada por checkouts falhando rápido não precisa de uma segunda mensagem sobre checkouts falhando
  devagar.

Um override aponta o Alertmanager para o arquivo novo:

```
ana@obs:~/shop$ docker compose up -d alertmanager 2>&1 | tail -1
 Container shop-alertmanager-1 Started 
```

No incidente acima, os dois alertas dispararam. O page foi para o pager. O ticket chegou ao `/ticket`
uma vez, no momento em que o page oscilou para resolvido, e foi segurado no resto do tempo. Na API o
ticket aparece como `suppressed`, com o id da regra que o inibiu em `inhibitedBy`.

**Os labels são o contrato entre os dois programas.** O Prometheus escreve `severity` e `slo` no alerta,
e o Alertmanager roteia e inibe por eles. Uma regra escrita sem `severity` cai no receptor padrão. É
por isso que o receptor padrão é a fila de tickets e não o pager: um alerta que ninguém classificou não
deve acordar ninguém.
