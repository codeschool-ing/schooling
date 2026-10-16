---
title: Onde cada guarda fica
version: 1
---

A bilheteria tem todas as guardas no próprio código, que é o jeito mais claro de vê-las. Num sistema
maior cada uma costuma ter um lugar melhor, e a regra geral é que **quanto mais cedo um pedido é
recusado, mais barata é a recusa**.

- **Na borda**: limites de taxa por endereço ou por conta, e controle de admissão. O `limit_req` e o
  `limit_conn` do nginx, um gateway de API, as regras contra robôs de uma CDN. Um pedido recusado ali
  nunca chegou a um serviço.
- **Em cada serviço**: descarte de carga, porque só o serviço sabe do que está faltando, seja CPU,
  conexões ou memória.
- **Em volta de cada chamada a outro serviço**: o timeout e o disjuntor, porque eles tratam da saúde
  de quem é chamado, e quem chama é onde ela aparece. Bibliotecas fazem isso para a maioria das
  linguagens, como a resilience4j para Java e a Polly para .NET, e uma malha de serviços (*service
  mesh*) como o Envoy consegue fazer fora do código, com limites de conexão e *outlier detection*, que
  tira do conjunto uma cópia que se comporta mal.

## O que o comprador vê

Um `429` ou um `503` é um status para programas. Para uma pessoa, toda guarda precisa de uma frase:
*você está comprando rápido demais, espere um segundo*, *estamos muito ocupados, tente de novo daqui a
pouco*, *os pagamentos não estão funcionando agora, o seu lugar não foi reservado*. A venda de
ingressos tem uma resposta conhecida para as maiores aberturas: uma **sala de espera virtual**, que é
descarte de carga com boas maneiras. Em vez de recusar os compradores acima da capacidade, a borda dá
a cada um um lugar numa fila e os deixa entrar no ritmo que a bilheteria consegue atender, e a recusa
vira uma espera que o comprador consegue ver.

A aula 10 é o lado de quem chama em tudo isso: como tentar de novo sem piorar as coisas. A aula 11 é o
que responder, além de um erro, quando uma dependência está fora.
