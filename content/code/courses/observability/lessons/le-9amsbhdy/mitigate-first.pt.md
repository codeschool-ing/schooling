---
title: Mitigar primeiro, entender depois
version: 1
---

Há uma versão do payments com três minutos de vida, e o payments está falhando. **Qual é o bug ainda não
importa.** Os clientes precisam da loja de volta, e o caminho mais rápido é a versão que funcionava. A
reversão é marcada na hora em que acontece:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" -H 'Content-Type: application/json' -d '{"tags": ["deploy"], "text": "payments rolled back to 1.4.0"}' localhost:3000/api/annotations | jq -c .
{"id":3,"message":"Annotation added"}
```

O arquivo de falhas é removido, que é a reversão do laboratório, e noventa segundos depois:

```
ana@obs:~/shop$ ./promq '{__name__=~"checkout:burn_rate:.*"}'
__name__=checkout:burn_rate:1m  0
__name__=checkout:burn_rate:5m  18.720748829953227
__name__=checkout:burn_rate:30m  12.50921021855389
```

**A taxa de queima de um minuto é 0**: nenhum checkout falha há um minuto. A de cinco minutos ainda é
18,7, porque a janela ainda guarda os minutos de antes da reversão. A aula 7 chamou isso de atraso de
uma janela, e aqui é a diferença entre *consertado* e *parece consertado*.

Então o page é resolvido, e quem comanda espera a janela mais lenta antes de declarar o fim:

```
ana@obs:~/shop$ ./promq '{__name__=~"checkout:burn_rate:.*"}'
__name__=checkout:burn_rate:1m  0
__name__=checkout:burn_rate:5m  0.31201248049921304
__name__=checkout:burn_rate:30m  8.704804751988403
```

A taxa de cinco minutos é 0,3, abaixo de 1: as últimas falhas saíram da janela. A de trinta minutos
ainda é 8,7 e vai levar meia hora para cair, o que é trabalho do alerta lento e não motivo para manter o
incidente aberto. Quem comanda marca o fim:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" -H 'Content-Type: application/json' -d '{"tags": ["incident"], "text": "resolved: 5-minute burn rate below 1, checkouts normal"}' localhost:3000/api/annotations | jq -c .
{"id":4,"message":"Annotation added"}
ana@obs:~/shop$ docker compose logs --no-log-prefix pager | grep '"PAGE"' | jq -c '{time, status, alertname}'
{"time":"2026-10-02T20:49:58.986Z","status":"firing","alertname":"CheckoutBudgetBurningFast"}
{"time":"2026-10-02T20:51:58.987Z","status":"resolved","alertname":"CheckoutBudgetBurningFast"}
```

O page disparou uma vez e foi resolvido uma vez, um minuto depois da reversão.

**Reverter antes de entender é o padrão, não um atalho.** Três coisas o tornam seguro:

- **A versão pode ser desfeita.** Uma esteira de deploy que não reverte num passo transforma toda versão
  ruim numa sessão de depuração sob pressão.
- **O bug não se perde.** A versão 1.4.2 ainda existe, com o código e os logs dela. A investigação
  acontece amanhã, sem clientes esperando por ela.
- **A reversão também é uma mudança**, então é marcada como uma. Senão quem ler o gráfico depois vê os
  erros pararem sem motivo nenhum.

Quando não há o que reverter, o mesmo princípio vale para o que restaurar o serviço mais rápido: trocar
para outra região, desligar uma funcionalidade, aumentar a capacidade, ou tirar do caminho uma
dependência quebrada. **Restaure primeiro; a causa raiz é trabalho do postmortem.**
