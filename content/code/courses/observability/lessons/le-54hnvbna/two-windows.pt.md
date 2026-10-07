---
title: Duas janelas ao mesmo tempo
version: 2
---

Uma taxa de queima precisa de uma janela, e toda janela é um meio-termo. **Uma janela longa demora a
perceber e demora a esquecer**: uma janela de uma hora leva muitos minutos para passar de um limite, e
continua disparando por uma hora depois de o problema ser corrigido. **Uma janela curta é rápida nos
dois sentidos**, e por isso dispara em todo pico.

A resposta, do workbook de SRE do Google, é exigir as duas: a taxa de queima precisa estar alta numa
janela longa, que diz que o estrago é grande, e numa curta, que diz que ele ainda está acontecendo. Em
produção o page rápido usa uma hora e cinco minutos; o laboratório usa cinco minutos e um, para a aula
poder vê-lo funcionar. A loja está comprando há meia hora, então toda janela tem tráfego real.

Para ter a mesma meia hora, inicie o laboratório de novo do zero, ponha os clientes para rodar por
setenta minutos e provoque uma única cobrança com falha logo de cara. A última parte desta seção diz
por que essa importa:

```sh
docker compose run -d --rm loadgen python -m loadgen.load 5 4200
sleep 20
echo '{"fail_every": 50}' > faults/payments.json
sleep 12
rm faults/payments.json
```

Depois salve os três arquivos que esta aula escreve, que as seções seguintes explicam:
`prometheus/rules/burn.yml`, de *Escrevendo a regra*, e `alertmanager/routes.yml` e
`compose.override.yaml`, de *Roteamento*. Carregue-os, e deixe a loja comprar por trinta minutos:

```sh
curl -s -X POST localhost:9090/-/reload
docker compose up -d alertmanager
sleep 1800
```


Primeiro, um pico. Durante quarenta segundos, o payments falha uma cobrança em quatro. Cinco segundos
depois de parar:

```sh
echo '{"fail_every": 4}' > faults/payments.json
sleep 40
rm faults/payments.json
sleep 5
```


```
ana@obs:~/shop$ ./promq '{__name__=~"checkout:burn_rate:.*"}'
__name__=checkout:burn_rate:1m  34.591993584174304
__name__=checkout:burn_rate:5m  5.923616523772379
__name__=checkout:burn_rate:30m  0.9460973484376911
```

A taxa de queima de um minuto é 34,6, muito acima de 14,4: naquele minuto, os checkouts falharam a
trinta e cinco vezes a taxa que o objetivo aguenta. A taxa de cinco minutos é 5,9, abaixo do limite, e
a de trinta minutos é 0,95.

```
ana@obs:~/shop$ curl -s localhost:9093/api/v2/alerts | jq -c '.[] | {alertname: .labels.alertname, severity: .labels.severity, state: .status.state, inhibitedBy: .status.inhibitedBy, silencedBy: .status.silencedBy}'
```

**Nenhum alerta.** A janela curta sozinha teria acordado alguém por quarenta segundos de problema que já
tinham acabado. A longa diz que o estrago foi pequeno, e a regra precisa das duas.

Depois, dois minutos mais tarde, uma falha real: uma cobrança em dez falha, e continua falhando.
Quatro minutos e meio depois:

```sh
sleep 120
echo '{"fail_every": 10}' > faults/payments.json
sleep 270
```


```
ana@obs:~/shop$ ./promq '{__name__=~"checkout:burn_rate:.*"}'
__name__=checkout:burn_rate:1m  19.70443349753692
__name__=checkout:burn_rate:5m  18.082618862042075
__name__=checkout:burn_rate:30m  4.008465081538648
```

As três janelas estão altas: 19,7 em um minuto e 18,1 em cinco, as duas acima de 14,4, e 4,0 em
trinta, acima dos 3 do alerta lento.

```
ana@obs:~/shop$ curl -s localhost:9093/api/v2/alerts | jq -c '.[] | {alertname: .labels.alertname, severity: .labels.severity, state: .status.state, inhibitedBy: .status.inhibitedBy, silencedBy: .status.silencedBy}'
{"alertname":"CheckoutBudgetBurningSlowly","severity":"ticket","state":"suppressed","inhibitedBy":["50e1ed8789a027ea"],"silencedBy":[]}
{"alertname":"CheckoutBudgetBurningFast","severity":"page","state":"active","inhibitedBy":[],"silencedBy":[]}
```

**O page está ativo**, e o ticket está `suppressed`, o que a próxima seção explica. Cada alerta chegou ao
pager:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix pager | grep -E '"(PAGE|TICKET)"' | jq -c '{message, status, alertname, severity}'
{"message":"PAGE","status":"firing","alertname":"CheckoutBudgetBurningFast","severity":"page"}
{"message":"PAGE","status":"resolved","alertname":"CheckoutBudgetBurningFast","severity":"page"}
{"message":"TICKET","status":"firing","alertname":"CheckoutBudgetBurningSlowly","severity":"ticket"}
{"message":"PAGE","status":"firing","alertname":"CheckoutBudgetBurningFast","severity":"page"}
```

Lido em ordem, o log mostra algo que a lista de alertas não mostra. **O page disparou, foi resolvido e
disparou de novo.** Uma cobrança em dez falhando é uma taxa de queima de uns 20, e em um minuto esse
número varia com o acaso. Por um momento ele caiu abaixo de 14,4, a condição quebrou, e o Alertmanager
anunciou uma resolução. Nessa brecha o page deixou de segurar o ticket, então o ticket saiu também.

Isso é **oscilação** (flapping), e acontece sempre que a taxa real fica perto de um limite. A correção de
costume é um `for:` curto na regra rápida, um ou dois minutos. Ele atrasa o page um pouco e impede que
uma única queda o resolva.

Vale conhecer uma armadilha, porque esta aula caiu nela enquanto era escrita. **Uma série
de contador que ainda não existe não pode mostrar uma taxa.** A vitrine cria o contador `code="502"` no
primeiro checkout com falha, e o `rate()` precisa de duas amostras de uma série para vê-la crescer. Um
pico que é a primeira falha de todas pode, então, passar quase despercebido por todas as janelas. A
montagem desta aula evita isso com a cobrança com falha que provoca trinta minutos antes; no código, a correção é
criar as séries dos códigos esperados com valor zero, quando o serviço inicia.
