---
title: rate(), e o contador que voltou a zero
version: 1
---

O `rate()` toma um contador numa janela e responde **quanto ele cresceu por segundo**, em média,
ao longo dessa janela. A janela vai entre colchetes, e `[1m]` quer dizer o último minuto de coletas:

```
ana@obs:~/shop$ ./promq 'rate(http_server_requests_total{job="storefront", route="/checkout"}[1m])'
code=201 instance=storefront:8080 job=storefront method=POST route=/checkout  4.222222222222221
code=402 instance=storefront:8080 job=storefront method=POST route=/checkout  0.2666666666666666
```

Cerca de 4,2 checkouts por segundo responderam `201` e 0,27 responderam `402`, um cartão recusado.
Os clientes simulados mandam cinco requisições por segundo, uma em dez delas uma listagem de
produtos, então 4,5 checkouts por segundo é o total. Somar as duas linhas dá 4,49. Para obter essa
soma do Prometheus, as séries são **agregadas**: `sum by (route)` soma toda série que compartilha
uma rota e mantém só esse label:

```
ana@obs:~/shop$ ./promq 'sum by (route) (rate(http_server_requests_total{job="storefront"}[1m]))'
route=/health  0.06666666666666665
route=/products  0.5111111111111111
route=/checkout  4.488888888888888
```

O `increase()` é a mesma conta expressa como contagem na janela em vez de taxa por segundo, o que
lê melhor num painel que diz *requisições no último minuto*:

```
ana@obs:~/shop$ ./promq 'sum(increase(http_server_requests_total{job="storefront"}[1m]))'
  304
```

304, perto de 60 segundos vezes as 5,07 requisições por segundo que as três rotas somam. **Os dois
são estimativas**, calculadas a partir das coletas que caíram dentro da janela e esticadas para
cobri-la toda. É por isso que o `increase()` pode devolver um número que não é uma contagem inteira.

O motivo para sempre passar pelo `rate()` em vez de subtrair dois valores à mão é o que acontece
quando um processo reinicia. A vitrine é reiniciada, e o contador dela é lido antes e depois:

```
ana@obs:~/shop$ ./promq 'sum(http_server_requests_total{job="storefront"})'
  339
ana@obs:~/shop$ docker compose restart storefront 2>&1 | tail -1
 Container shop-storefront-1 Started 
ana@obs:~/shop$ ./promq 'sum(http_server_requests_total{job="storefront"})'
  123
```

**O contador foi de 339 para 123.** Um processo reiniciado começa todo contador do zero, e um
ingênuo *valor agora menos valor um minuto atrás* diria que a vitrine respondeu menos duzentas
requisições. O `rate()` e o `increase()` sabem que um contador só pode crescer, então qualquer queda
é tratada como reinício e a contagem simplesmente continua a partir do zero:

```
ana@obs:~/shop$ ./promq 'sum(rate(http_server_requests_total{job="storefront"}[2m]))'
  4.79047619047619
ana@obs:~/shop$ ./promq 'resets(http_server_requests_total{job="storefront", route="/checkout", code="201"}[5m])'
code=201 instance=storefront:8080 job=storefront method=POST route=/checkout  1
```

A taxa através do reinício ainda é de cerca de cinco por segundo, e o `resets()` conta o reinício que
viu na janela. Essa é a regra para contadores: **nunca leia o valor bruto de um contador como
informação; pergunte a taxa.**
