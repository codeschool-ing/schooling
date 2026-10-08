---
title: Gastando o orçamento
version: 2
---

Durante quatro minutos, o payments recebe a ordem de falhar uma cobrança em vinte. Três minutos depois,
o SLI de cinco minutos e a velocidade com que ele gasta o orçamento:

```sh
echo '{"fail_every": 20}' > faults/payments.json
sleep 180
```


```
ana@obs:~/shop$ ./promq 'checkout:sli_availability:ratio_rate5m'
__name__=checkout:sli_availability:ratio_rate5m  0.9706438786432104
ana@obs:~/shop$ ./promq '(1 - checkout:sli_availability:ratio_rate5m) / (1 - 0.995)'
  5.871224271357906
```

**97% dos checkouts dos últimos cinco minutos deram certo**, o que soa saudável, e é **5,9 vezes a
taxa que o objetivo permite**. Esse segundo número é a **taxa de queima**: a taxa de erros dividida
pela taxa que o objetivo permite, aqui 0,5%. Uma taxa de queima de 1 gasta o orçamento em exatamente
uma janela. Uma taxa de queima de 5,9 gastaria o orçamento de uma hora em uns dez minutos, e um
orçamento de 28 dias em menos de cinco dias. A aula 16 alerta sobre ela.

A falha é removida depois do quarto minuto, e um minuto e meio depois a hora é lida de novo:

```sh
sleep 60
rm faults/payments.json
sleep 90
```


```
ana@obs:~/shop$ ./promq 'sum by (code) (increase(http_server_requests_total{job="storefront",route="/checkout"}[1h]))'
code=201  15245.523012552301
code=402  900.7531380753138
code=502  54.67989841269841
ana@obs:~/shop$ ./promq '{__name__=~"checkout:.*_1h|checkout:.*rate1h"}'
__name__=checkout:sli_availability:ratio_rate1h  0.9966718460154416
__name__=checkout:sli_latency:ratio_rate1h  1
__name__=checkout:error_budget_remaining:ratio_1h  0.3343692030883135
```

Cinquenta e cinco checkouts responderam `502` na hora, de uns dezesseis mil. O SLI de disponibilidade da
hora é 99,67%, folgado acima do objetivo, e **o orçamento restante é 0,33: dois terços do orçamento da
hora foram em quatro minutos.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O orçamento de erros da hora desenhado como uma barra. Uns 16 200 checkouts na hora, com objetivo de 99,5%, permitem 81 falhas. O incidente de quatro minutos causou 55 delas, dois terços da barra, deixando um terço: 26 falhas para o resto da hora.\"><defs><marker id=\"bg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma hora: 16 200 checkouts, 81 podem falhar</text><rect x=\"60\" y=\"70\" width=\"600\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"70\" width=\"407.4074074074074\" height=\"50\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"263.7037037037037\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">gasto pelo incidente: 55</text><text x=\"563.7037037037037\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">resta: 26</text><text x=\"60\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"660\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">81</text><text x=\"360\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">orçamento restante: 0,33</text></svg>", "caption": "Quatro minutos de uma cobrança em vinte falhando gastaram dois terços do orçamento de uma hora. Em 28 dias, os mesmos quatro minutos teriam gastado cerca de um décimo de um por cento dele."}
```

Há duas lições nesses números. **Um SLI de 99,7% ainda pode significar problema**: o objetivo foi
cumprido, e resta um terço do orçamento para o resto da janela. Outro incidente como este o
descumpriria. E **a janela decide quão dramático um incidente parece**: as mesmas 55 falhas contra
um orçamento de 28 dias de uns cinquenta mil seriam cerca de um décimo de um por cento dele. A
janela de uma hora do laboratório faz todo incidente parecer grande de propósito, para uma aula
poder ver o orçamento se mexer. Uma equipe real vê isso como uma pequena queda numa linha longa, e a
política da próxima seção decide o que essa queda significa.