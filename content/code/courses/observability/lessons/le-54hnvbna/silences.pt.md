---
title: Silêncios: quietos de propósito, com um motivo
version: 1
---

Durante um trabalho planejado, um alerta pode estar certo e ser inútil: todo mundo já sabe que o
payments está fora, porque alguém o tirou do ar. **Um silêncio manda o Alertmanager parar de notificar
os alertas correspondentes por um tempo**, e é o único jeito aceitável de calar um alerta. Apagar a
regra, subir o limite ou silenciar o canal do pager sobrevivem à manutenção; um silêncio acaba sozinho.

O `amtool`, a ferramenta de linha de comando do Alertmanager, cria um enquanto o incidente acima ainda
está disparando:

```
ana@obs:~/shop$ docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence add alertname=CheckoutBudgetBurningFast --duration=20m --author=ana --comment='payments maintenance, ticket OPS-123'
54571fb2-98a1-4bbf-8160-d00b17c9f336
```

A resposta é o id do silêncio. O que ele guarda:

```
ana@obs:~/shop$ docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence query -o extended
ID                                    Matchers                                 Starts At                Ends At                  Updated At               Created By  Comment                               
54571fb2-98a1-4bbf-8160-d00b17c9f336  {alertname="CheckoutBudgetBurningFast"}  2026-10-02 20:24:53 UTC  2026-10-02 20:44:53 UTC  2026-10-02 20:24:53 UTC  ana         payments maintenance, ticket OPS-123  
```

**Um matcher, um fim, um autor e um comentário**, os quatro de propósito. O matcher é estreito: um
alerta pelo nome, não todo alerta da loja. O fim está a vinte minutos, então um silêncio esquecido não
esconde o incidente da semana seguinte. E o autor e o comentário respondem à pergunta que qualquer um
que olhe um pager quieto vai fazer: *quem fez isso, e por quê?* `OPS-123` aponta para o ticket da
mudança.

O alerta continua sendo avaliado e continua disparando; ele só não é mandado:

```
ana@obs:~/shop$ curl -s localhost:9093/api/v2/alerts | jq -c '.[] | {alertname: .labels.alertname, severity: .labels.severity, state: .status.state, inhibitedBy: .status.inhibitedBy, silencedBy: .status.silencedBy}'
{"alertname":"CheckoutBudgetBurningSlowly","severity":"ticket","state":"suppressed","inhibitedBy":["50e1ed8789a027ea"],"silencedBy":[]}
{"alertname":"CheckoutBudgetBurningFast","severity":"page","state":"suppressed","inhibitedBy":[],"silencedBy":["54571fb2-98a1-4bbf-8160-d00b17c9f336"]}
```

Os dois alertas estão `suppressed`, por motivos diferentes: o ticket pela inibição, e o page pelo
silêncio, cujo id ele nomeia.

Duas regras para silêncios numa equipe:

- **Silencie o page, não o problema.** Se a manutenção ia levar cinco minutos e a taxa de queima ainda
  está alta depois de vinte, o silêncio expira e o page chega, o que está certo.
- **Silêncios ficam visíveis.** Uma lista dos silêncios ativos pertence à passagem de plantão da aula 18,
  porque um silêncio feito por outra pessoa é a coisa mais surpreendente de descobrir durante um
  incidente.

Quando o trabalho acaba, a falha do payments é removida e o silêncio é expirado à mão, em vez de esperar
o fim. Quatro minutos depois:

```
ana@obs:~/shop$ docker compose exec alertmanager sh -c 'amtool --alertmanager.url=http://localhost:9093 silence expire $(amtool --alertmanager.url=http://localhost:9093 silence query -q)'
ana@obs:~/shop$ ./promq '{__name__=~"checkout:burn_rate:.*"}'
__name__=checkout:burn_rate:1m  0
__name__=checkout:burn_rate:5m  4.053000779423233
__name__=checkout:burn_rate:30m  4.15784887339723
ana@obs:~/shop$ docker compose logs --no-log-prefix pager | grep -E '"(PAGE|TICKET)"' | jq -c '{message, status, alertname, severity}'
{"message":"PAGE","status":"firing","alertname":"CheckoutBudgetBurningFast","severity":"page"}
{"message":"PAGE","status":"resolved","alertname":"CheckoutBudgetBurningFast","severity":"page"}
{"message":"TICKET","status":"firing","alertname":"CheckoutBudgetBurningSlowly","severity":"ticket"}
{"message":"PAGE","status":"firing","alertname":"CheckoutBudgetBurningFast","severity":"page"}
{"message":"PAGE","status":"resolved","alertname":"CheckoutBudgetBurningFast","severity":"page"}
```

A taxa de queima de um minuto voltou a 0 e **o page é resolvido**, a última linha do log do pager. O
ticket continua disparando: a janela de trinta minutos dele ainda guarda o incidente, em 4,2. É para
isso que serve um alerta lento. Ele diz que o mês está pior do que estava, e diz sem acordar ninguém.
