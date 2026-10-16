---
title: Um retry que funciona
version: 1
---

Faça o serviço falhar uma resposta em cada cinco, como um serviço atrás de um balanceador instável
poderia, e chame-o num ritmo tranquilo de 20 requisições por segundo:

```
ana@vm:~/lab/resilience$ curl -s -X POST localhost:8001/fail/0.2
fail 0.2
ana@vm:~/lab/resilience$ $C --rate 20 --seconds 6
 second      ok  failed   calls
  0-2        34       6      40
  2-4        31       9      40
  4-6        30      10      40
the stock service answered 120 calls, 0 of them after the caller had given up
```

Mais ou menos uma requisição em cada cinco falhou, como esperado. Agora o mesmo, com até dois retries:

```
ana@vm:~/lab/resilience$ $C --rate 20 --seconds 6 --retries 2
 second      ok  failed   calls
  0-2        39       1      55
  2-4        40       0      49
  4-6        40       0      48
the stock service answered 152 calls, 0 of them after the caller had given up
```

Uma falha em 120 em vez de 25. Uma requisição agora só falha se três chamadas seguidas falharem, e com
cada uma falhando uma vez em cinco isso é 0,2 × 0,2 × 0,2, menos de uma em cem. O custo está na última
coluna: **152 chamadas para 120 requisições**, uns 27% a mais de trabalho para o serviço, que tinha
capacidade de sobra.

É o caso para o qual os retries existem: **falhas independentes umas das outras, num serviço com folga
para responder**. Cada retry é um novo sorteio, e o segundo sorteio costuma ganhar. A próxima seção
quebra as duas condições de uma vez.

Ponha o serviço de volta ao normal antes de seguir:

```sh
curl -s -X POST localhost:8001/fail/0
```
