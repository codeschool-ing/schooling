---
title: Timeouts, e uma cadeia que espera para sempre
version: 1
---

Um serviço fora do ar falha rápido: o nome não resolve ou a conexão é recusada, e o erro volta em
milissegundos. **Um serviço de pé e lento é pior**, porque nada falha; cada chamador simplesmente
espera.

Faça o estoque levar cinco segundos por requisição. `STOCK_DELAY_MS` é lido pelo `compose.yaml`, e
`docker compose up -d stock` recria só esse serviço com o valor novo:

```
ana@vm:~/lab/chain$ STOCK_DELAY_MS=5000 docker compose up -d stock
 Container chain-stock-1 Recreate 
 Container chain-stock-1 Recreated 
 Container chain-stock-1 Starting 
 Container chain-stock-1 Started 
ana@vm:~/lab/chain$ curl -s -w "%{http_code} after %{time_total} s\n" localhost:8000/
{"name": "checkout", "next": {"name": "pricing", "next": {"name": "stock", "took_ms": 5000}, "took_ms": 5104}, "took_ms": 5207}
200 after 5.208926 s
```

O checkout respondeu `200`, corretamente, depois de mais de cinco segundos. O preço esperou o estoque, o
checkout esperou o preço, e o cliente esperou todos. O `hop.py` não define timeout a não ser que
`TIMEOUT_S` seja dado, então **um serviço de estoque que nunca respondesse teria segurado cada elo da
cadeia para sempre**, cada um com uma conexão aberta e uma thread.

## Dando um limite ao preço

Defina `PRICING_TIMEOUT_S` como um segundo e recrie o preço, com o estoque ainda lento:

```
ana@vm:~/lab/chain$ PRICING_TIMEOUT_S=1 STOCK_DELAY_MS=5000 docker compose up -d pricing
 Container chain-pricing-1 Recreate 
 Container chain-pricing-1 Recreated 
 Container chain-pricing-1 Starting 
 Container chain-pricing-1 Started 
ana@vm:~/lab/chain$ curl -s -w "%{http_code} after %{time_total} s\n" localhost:8000/
{"name": "checkout", "error": "http://pricing:8000/ answered 504", "next": {"name": "pricing", "error": "http://stock:8000/ did not answer within 1.0 s", "took_ms": 1128}, "took_ms": 1232}
502 after 1.233608 s
```

Agora o preço desiste do estoque depois de um segundo e diz isso com `504 Gateway Timeout`; o checkout
repassa isso como `502`, e o cliente tem uma resposta depois de um segundo e um quarto, mais ou menos,
em vez de cinco. **A resposta é uma falha, e uma rápida**, que é algo com que quem chama consegue
trabalhar: mostrar um erro, tentar uma alternativa, ou tentar de novo depois.

## Quanto esperar

Não existe um número universal, mas existe um método. Um timeout deve ficar um pouco acima do que é a
ponta lenta do normal para aquela chamada, o tempo em que, digamos, 99 requisições em 100 terminam, e
bem abaixo do que o chamador do seu chamador vai esperar. **Os timeouts precisam encolher à medida que se
desce uma cadeia**: se o checkout desiste depois de dois segundos e o preço espera cinco pelo estoque, o
preço continua trabalhando em requisições pelas quais ninguém espera mais.

Esse último ponto tem nome. **Propagação de prazo** (*deadline propagation*) passa o tempo restante junto
com a requisição, para cada elo saber quanto pode gastar, e o gRPC faz isso com um prazo que viaja com
cada chamada. Com HTTP simples um serviço pode mandar um cabeçalho com o orçamento restante, e cada elo
subtrai o que usou antes de chamar o próximo.

Ponha o estoque de volta ao normal e o preço de volta a sem timeout:

```
ana@vm:~/lab/chain$ docker compose up -d pricing stock
 Container chain-pricing-1 Recreate 
 Container chain-stock-1 Recreate 
 Container chain-pricing-1 Recreated 
 Container chain-stock-1 Recreated 
 Container chain-stock-1 Starting 
 Container chain-pricing-1 Starting 
 Container chain-stock-1 Started 
 Container chain-pricing-1 Started 
ana@vm:~/lab/chain$ curl -s -w "%{http_code} after %{time_total} s\n" localhost:8000/
{"name": "checkout", "next": {"name": "pricing", "next": {"name": "stock", "took_ms": 100}, "took_ms": 228}, "took_ms": 332}
200 after 0.334787 s
```

Um timeout transforma uma falha lenta numa rápida. O que fazer depois, tentar de novo ou parar de
perguntar, é a aula 11, e ela tem o seu próprio jeito de piorar as coisas.
