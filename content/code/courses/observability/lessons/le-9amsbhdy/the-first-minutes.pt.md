---
title: Os primeiros minutos
version: 1
---

O laboratório encena um incidente com os alertas da aula 16 no lugar. Um robô de deploy marca uma
versão do payments no Grafana, como o da aula 7 fazia:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" -H 'Content-Type: application/json' -d '{"tags": ["deploy"], "text": "payments 1.4.2"}' localhost:3000/api/annotations | jq -c .
{"id":1,"message":"Annotation added"}
```

A versão é o arquivo de falhas mandando o payments falhar uma cobrança em oito. Nada mais acontece até o
alerta de taxa de queima decidir que vale um page:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix pager | grep '"PAGE"' | jq -c '{time, status, alertname, summary}'
{"time":"2026-10-02T20:49:58.986Z","status":"firing","alertname":"CheckoutBudgetBurningFast","summary":"Checkouts are failing fast enough to spend the month's error budget in two days"}
```

O page chega três minutos depois da marca da versão: o tempo que a janela de cinco minutos precisou para
se encher de falhas. Quem está de plantão lê o page e as três taxas de queima:

```
ana@obs:~/shop$ ./promq '{__name__=~"checkout:burn_rate:.*"}'
__name__=checkout:burn_rate:1m  24.752475247524753
__name__=checkout:burn_rate:5m  14.946663312584985
__name__=checkout:burn_rate:30m  12.473343961001747
```

24,8 em um minuto, 14,9 em cinco, 12,5 em trinta: os checkouts estão falhando a umas treze vezes a taxa
que o mês aguenta, e isso ainda está acontecendo agora. É um SEV-2 pela tabela da loja: uma parte
grande dos clientes não consegue comprar. **O primeiro ato é dizer isso**, onde todos possam ver, com o
nome de quem comanda:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" -H 'Content-Type: application/json' -d '{"tags": ["incident"], "text": "SEV-2 declared: checkouts failing, IC ana"}' localhost:3000/api/annotations | jq -c .
{"id":2,"message":"Annotation added"}
```

Declarar levou um comando. Numa equipe real é uma mensagem no canal do incidente e uma atualização na
página de status, e a marca no Grafana é o que liga as duas aos gráficos.

**Depois: onde?** Uma consulta, falhas como fração das requisições, por serviço:

```
ana@obs:~/shop$ ./promq 'sum by (job) (rate(http_server_requests_total{code=~"5.."}[2m])) / sum by (job) (rate(http_server_requests_total[2m]))'
job=storefront  0.11090225563909775
job=payments  0.12473572938689217
job=orders  0.125
```

11% das requisições da vitrine, 12,5% das do orders e das do payments. O payments falha mais, e todo
serviço acima dele falha na mesma proporção. É a mesma coluna de vermelho que a aula 11 leu num único
rastro, aqui em três números.

**E a pergunta que resolve a maioria dos incidentes: o que mudou?** As marcas da última meia hora:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" 'localhost:3000/api/annotations?from='$(date -d '-30 min' +%s000) | jq -r '.[] | [(.time/1000 | strftime("%H:%M:%S")), (.tags | join(",")), .text] | @tsv'
20:50:00	incident	SEV-2 declared: checkouts failing, IC ana
20:46:49	deploy	payments 1.4.2
```

Duas marcas: a declaração recém-escrita, e **uma versão do payments às 20:46:49**, três minutos antes do
page. Ninguém precisou lembrar quem fez deploy de quê, nem procurar num histórico de chat. A marca da
versão foi escrita por um robô, e nomeia o serviço que está falhando.
