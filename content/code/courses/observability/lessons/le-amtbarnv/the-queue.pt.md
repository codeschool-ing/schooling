---
title: O rastro que atravessa uma fila
version: 2
---

A aula 4 levou o contexto pelo RabbitMQ e viu uma mensagem esperar 22,8 segundos. Um rastro mostra que
uma mensagem pode esperar. **Vários, lidos ao longo de uma parada, mostram como um acúmulo se comporta.**

O mailer é parado por trinta segundos enquanto os clientes continuam comprando, e depois volta:

```
ana@obs:~/shop$ docker compose stop mailer 2>&1 | tail -1
 Container shop-mailer-1 Stopped 
ana@obs:~/shop$ docker compose start mailer 2>&1 | tail -1
 Container shop-mailer-1 Started 
```

Vinte segundos depois, cinco das confirmações que o mailer mandou no último minuto são escolhidas em
passos iguais pelo log dele. Cada rastro responde a uma pergunta: quanto tempo entre o `UPDATE`,
depois do qual o `orders` publica, e o mailer tirar a mensagem? O laço abaixo faz as duas coisas; o
`awk` fica com um id de rastro a cada trinta, e a transcrição mostra cada `curl` que ele rodou:

```sh
for t in $(docker compose logs --no-log-prefix --since 60s mailer | grep 'confirmation sent' | jq -r .trace_id | awk 'NR % 30 == 1' | head -5); do
  curl -s localhost:16686/api/traces/$t | jq -r '.data[0].spans as $s | ($s[] | select(.operationName == "UPDATE") | .startTime + .duration) as $published | ($s[] | select(.operationName == "orders.placed process") | .startTime) as $taken | "waited in the queue: \(($taken - $published) / 1000 | floor) ms"'
done
```


```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/30062f0fab08e70ae9b00866cb0d05e4 | jq -r '.data[0].spans as $s | ($s[] | select(.operationName == "UPDATE") | .startTime + .duration) as $published | ($s[] | select(.operationName == "orders.placed process") | .startTime) as $taken | "waited in the queue: \(($taken - $published) / 1000 | floor) ms"'
waited in the queue: 11 ms
ana@obs:~/shop$ curl -s localhost:16686/api/traces/dc40e8a055aedfb7a12beeca85635427 | jq -r '.data[0].spans as $s | ($s[] | select(.operationName == "UPDATE") | .startTime + .duration) as $published | ($s[] | select(.operationName == "orders.placed process") | .startTime) as $taken | "waited in the queue: \(($taken - $published) / 1000 | floor) ms"'
waited in the queue: 7 ms
ana@obs:~/shop$ curl -s localhost:16686/api/traces/9499029b112afb087b7a231792a939d9 | jq -r '.data[0].spans as $s | ($s[] | select(.operationName == "UPDATE") | .startTime + .duration) as $published | ($s[] | select(.operationName == "orders.placed process") | .startTime) as $taken | "waited in the queue: \(($taken - $published) / 1000 | floor) ms"'
waited in the queue: 26666 ms
ana@obs:~/shop$ curl -s localhost:16686/api/traces/ed14b89a82ff9cdd4577a49b3c05ff89 | jq -r '.data[0].spans as $s | ($s[] | select(.operationName == "UPDATE") | .startTime + .duration) as $published | ($s[] | select(.operationName == "orders.placed process") | .startTime) as $taken | "waited in the queue: \(($taken - $published) / 1000 | floor) ms"'
waited in the queue: 20294 ms
ana@obs:~/shop$ curl -s localhost:16686/api/traces/70dc732d7302edaed283a9a2292e9a54 | jq -r '.data[0].spans as $s | ($s[] | select(.operationName == "UPDATE") | .startTime + .duration) as $published | ($s[] | select(.operationName == "orders.placed process") | .startTime) as $taken | "waited in the queue: \(($taken - $published) / 1000 | floor) ms"'
waited in the queue: 13716 ms
```

As duas primeiras foram publicadas antes da parada e esperaram milissegundos, que é a fila fazendo o
trabalho dela sem ninguém notar. **As outras três foram publicadas com o mailer parado**, e as
esperas delas caem em degraus. A mensagem mais antiga esperou mais, e cada uma depois dela menos,
porque todas foram tiradas numa rajada quando o mailer voltou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Quanto cinco confirmações esperaram na fila, na ordem em que foram publicadas. 11 ms, 7 ms, 26666 ms, 20294 ms, 13716 ms. As duas primeiras foram publicadas antes de o mailer parar; as três últimas durante a parada, e a mais antiga delas esperou mais.\"><defs><marker id=\"dq-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M110 230 L680 230\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"102\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><text x=\"102\" y=\"173.33333333333334\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10 s</text><text x=\"102\" y=\"116.66666666666667\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20 s</text><text x=\"102\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">30 s</text><rect x=\"140\" y=\"228\" width=\"60\" height=\"2\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">11 ms</text><rect x=\"250\" y=\"228\" width=\"60\" height=\"2\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7 ms</text><rect x=\"360\" y=\"78.89266666666666\" width=\"60\" height=\"151.10733333333334\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"68.89266666666666\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">26666 ms</text><rect x=\"470\" y=\"115.00066666666666\" width=\"60\" height=\"114.99933333333334\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"105.00066666666666\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20294 ms</text><rect x=\"580\" y=\"152.276\" width=\"60\" height=\"77.724\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"142.276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">13716 ms</text><text x=\"250\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">antes da parada</text><text x=\"470\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">publicadas com o mailer parado</text><text x=\"400\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tempo na fila, por ordem de publicação</text></svg>", "caption": "Um acúmulo esvazia do mais antigo para o mais novo. A espera de uma mensagem é o tempo entre a publicação dela e o momento em que o mailer, de volta, chegou a ela."}
```

Duas coisas sobre ler isso num armazenamento de rastros:

- **O comprimento do rastro não é o que alguém esperou.** Um armazenamento de rastros mede um rastro
  do início do primeiro span ao fim do último, então esses checkouts aparecem com vinte e poucos
  segundos. O cliente esperou uns 430 ms, a duração do span raiz. Busque pelo span raiz quando a
  pergunta é sobre o cliente, e pelo rastro quando ela é sobre o pedido.
- **A espera não tem span próprio.** Ela é a lacuna entre um span num serviço e um span em outro, medida
  nos relógios de duas máquinas. No laboratório os dois relógios são o do mesmo host; entre hosts reais,
  alguns milissegundos de diferença de relógio podem fazer uma espera curta parecer negativa, o que é
  ruído, enquanto uma espera de segundos é um achado.

As métricas da própria fila, a profundidade e os consumidores dela, dizem a mesma coisa pelo outro
lado: a aula 5 consultou as do RabbitMQ. A métrica diz que um acúmulo se formou. Os rastros dizem
quais pedidos estavam nele e com quanto atraso cada confirmação saiu.