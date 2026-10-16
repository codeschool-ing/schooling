---
title: A primeira coisa a quebrar
version: 1
---

A correção é uma configuração. Aumente as conexões de cada trabalhador do nginx para 4.096, no
`nginx.conf`, e reinicie o balanceador de carga:

```conf
# nginx.conf
events {
  worker_connections 4096;
}

http {
  upstream app {
    server app:8000;
    keepalive 64;
  }

  server {
    listen 80;
    location / {
      proxy_pass http://app;
      proxy_http_version 1.1;
      proxy_set_header Connection "";
    }
  }
}
```

Depois 400 por segundo de novo:

```
ana@lab:~/tickets$ docker compose restart lb
 Container tickets-lb-1 Restarting 
 Container tickets-lb-1 Started 
ana@lab:~/tickets$ docker run --rm -i --network host grafana/k6:2.3.0 run -q --log-output=none -e RATE=400 -e DURATION=15s - < sale.js
asked     400 a second for 15s
answered  3804 = 180.9 a second
latency   p50 2895.1 ms  p95 8894.4 ms  p99 12486.8 ms  max 18205.8 ms
sold 3367  refused 437  failed 0  never sent 2197
```

**Nenhuma falha.** Todo pedido que chegou à bilheteria foi respondido: 3367 vendidos e 437 recusados
na porta. E agora os números dizem o que de fato acontece a 400 por segundo: a bilheteria respondeu
**181 por segundo**, que é a capacidade dela nesta máquina, e toda venda esperou na fila por ela, com
mediana de 2,9 s.

Há um número novo também: **2197 nunca mandados**. Com respostas levando segundos, os 1.000 usuários
virtuais do k6 estavam todos esperando ao mesmo tempo, e as chegadas que ele não conseguiu começar
foram descartadas. Esse é o teste atingindo um limite próprio, e quer dizer que esta execução, na
prática, pediu menos que 400 por segundo. Um teste de carga precisa olhar o próprio gerador tão de
perto quanto o sistema: uma execução cujo gargalo foi o gerador mediu o gerador.

O que a correção não fez foi deixar a bilheteria mais rápida. Ela moveu a falha de *descartada pelo
nginx, sem nada registrado em lugar algum onde uma pessoa olharia* para *respondida pela bilheteria*,
com um ingresso ou com um `503` que diz que ela estava ocupada. Essa é a regra da aula 11 aplicada à
infraestrutura: **a falha que você quer é a que diz o que aconteceu**. E esse é o resultado geral de
um teste de estresse: o limite que você acha primeiro raramente é o que planejou, e o segundo muitas
vezes é.

