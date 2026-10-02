---
title: Indicadores, medidos do lado do cliente
version: 1
---

A aula 5 escreveu a expressão sobre a qual esta aula se constrói, eventos ruins sobre todos os eventos,
e prometeu um nome para ela. **Um indicador de nível de serviço, um SLI, é a fração dos eventos que
deram certo, medida onde o cliente encontra o serviço.** Para a loja, o evento que importa é um
checkout, e o lugar é a vitrine. Cinco minutos deles, por código de status:

```
ana@obs:~/shop$ ./promq 'sum by (code) (increase(http_server_requests_total{job="storefront",route="/checkout"}[5m]))'
code=201  1275.2889684210525
code=402  74.73684210526315
```

Uns 1350 checkouts: 1275 responderam `201`, pedido feito, e 75 responderam `402`, cartão recusado.
**Um cartão recusado é uma falha?** Para o cliente, talvez; para a loja, não. A rede de cartões disse
não e a vitrine avisou o cliente, que é o sistema funcionando. Um SLI de disponibilidade conta as
falhas que são nossas, então os eventos bons são tudo, menos um `5xx`:

```
ana@obs:~/shop$ ./promq 'sum(rate(http_server_requests_total{job="storefront",route="/checkout",code!~"5.."}[5m])) / sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[5m]))'
  1
```

Uma razão de 1: todo checkout da janela foi respondido sem falha nossa. O segundo indicador de que a
maioria dos serviços precisa é a **latência**, dita do mesmo jeito: a fração de checkouts respondidos
em até meio segundo, lida direto do bucket `le="0.5"` do histograma:

```
ana@obs:~/shop$ ./promq 'sum(rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout",le="0.5"}[5m])) / sum(rate(http_server_request_duration_seconds_count{job="storefront",route="/checkout"}[5m]))'
  1
```

Também 1. Duas escolhas nessa expressão são decisões, e não detalhes:

- **Um limite, não uma média.** *99% dos checkouts abaixo de 500 ms* é algo que um cliente sente e
  sobre o que se pode pôr um objetivo; *uma média de 180 ms* esconde o décimo lento, como a aula 7
  mostrou.
- **A fronteira do bucket é o limite.** Um histograma só responde pelas fronteiras que tem, então o
  limite que um SLI quer precisa ser um dos buckets que o `web.py` declara. Escolher o SLI primeiro e os
  buckets depois é a ordem certa.

**Onde o SLI é medido decide o que ele consegue ver.** Medido na vitrine, ele inclui todo serviço atrás
dela; medido no `orders`, perderia uma vitrine que falha sozinha. E medido por serviço, ele precisa
tomar cuidado com o que conta:

```
ana@obs:~/shop$ ./promq 'sum by (route) (rate(http_server_requests_total{job="orders"}[5m]))'
route=/orders  4.5014254035087715
```

Só `/orders`, porque o `web.py` pula o `/metrics` e nada sonda o `orders` neste laboratório. Se o
healthcheck da aula 14 tivesse ficado ligado, o `/ready` estaria nesta lista também, doze requisições
por minuto que dão certo sempre que o banco está no ar, e **um SLI sobre todas as rotas contaria sondas
como clientes satisfeitos**. Um indicador nomeia a rota, ou a operação, que um cliente de fato usa.
