---
title: A sonda que mente
version: 2
---

Todo serviço da loja tem um `/health` desde a aula 1, e cada um deles são três linhas que devolvem
`{"status": "ok"}`. O blackbox exporter pergunta ao da vitrine a cada quinze segundos desde a aula 5.
Eis quanto isso vale. Inicie o laboratório de novo do zero, ponha os clientes para rodar e dê a eles um
minuto:

```sh
docker compose run -d --rm loadgen python -m loadgen.load 5 1500
sleep 60
```

Depois o Postgres é parado, com clientes ainda comprando:

```
ana@obs:~/shop$ docker compose stop postgres 2>&1 | tail -1
 Container shop-postgres-1 Stopped 
ana@obs:~/shop$ curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d '{"sku": "kettle", "qty": 1, "card": "4111 1111 1111 1111"}' -w ' %{http_code}\n'
{"error":"try again later"}
 502
```

O checkout falha: o `orders` não consegue guardar o pedido, e a vitrine repassa a falha como um 502 com
um corpo educado. E o endpoint de saúde da mesma vitrine, um segundo depois:

```
ana@obs:~/shop$ curl -s localhost:8080/health
{"status":"ok"}
```

Quarenta e cinco segundos depois, a sonda de fora e a razão da aula 5:

```
ana@obs:~/shop$ ./promq 'probe_success'
__name__=probe_success instance=http://storefront:8080/health job=blackbox  1
ana@obs:~/shop$ ./promq 'sum(rate(http_server_requests_total{job="storefront",route="/checkout",code=~"5.."}[1m])) / sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[1m]))'
  1
```

**A sonda diz que a vitrine está no ar, e todo checkout do último minuto falhou.** Os dois números
estão corretos. A sonda respondeu à pergunta que lhe fizeram, *o processo da vitrine responde HTTP?*, e a
resposta é sim. Ninguém perguntou se um cliente consegue comprar uma chaleira.

Essa é a sonda que mente, e é a verificação de saúde mais comum que existe: uma rota que prova que o
framework web está rodando. Ela não é inútil, como as próximas seções mostram: é exatamente o que uma
sonda de liveness deve ser. **O que ela nunca pode ser é a coisa que decide se a loja está
funcionando**, numa página de status, num alerta ou na escolha de um balanceador sobre para onde
mandar um pedido.

Suba o Postgres de novo, e dê ao `orders` meio minuto para achá-lo, antes da próxima seção:

```sh
docker compose start postgres
sleep 30
```
