---
title: A requisição que não pode se repetir
version: 1
---

**Uma nova tentativa supõe que a requisição que falhou não fez nada. Quando a resposta se perde
depois de o servidor ter feito o trabalho, essa suposição está errada, e a nova tentativa faz o
trabalho uma segunda vez.** Tudo antes nesta aula é seguro para requisições em que fazer duas vezes é
o mesmo que fazer uma. Criar uma sessão não é uma delas.

O caso é comum, não exótico. Um celular envia um `POST`, o servidor salva a sessão e escreve a
resposta, e a resposta se perde: o celular entrou num túnel, trocou do Wi-Fi para a rede móvel, ou
bateu no tempo limite um instante antes de a resposta chegar. Do celular, os três parecem
exatamente uma requisição que nunca chegou.

## Vendo acontecer

O `drop` do servidor faz isso de propósito: salva a sessão e fecha a conexão antes de responder.
Suba-o como `node server.ts drop`, envie e pergunte ao servidor o que ele tem:

```
ana@dev:~/planner/retry$ node retry.ts
attempt 1: no answer, waiting 2 ms
attempt 2: 201, saved as n2
ana@dev:~/planner/retry$ curl -s http://127.0.0.1:8009/sessions
[{"course":"guitar","date":"2026-10-23","minutes":25,"id":"n1"},{"course":"guitar","date":"2026-10-23","minutes":25,"id":"n2"}]
```

**Um toque, duas sessões.** A primeira tentativa foi salva como `n1` e a resposta dela nunca saiu do
servidor, então o cliente viu `no answer` e fez o que a tabela do começo desta aula mandou. A segunda
foi salva como `n2`, e essa resposta chegou. A semana da pessoa agora tem 50 minutos de violão em 23
de outubro onde ela planejou 25, e nada em nenhum dos lados registrou um erro.

O terminal do servidor viu duas requisições parecidas:

```
ana@dev:~/planner/retry$ node server.ts drop
listening on 8009
POST /sessions drop
POST /sessions ok
```

## Por que o cliente não resolve sozinho

O cliente poderia parar de repetir `POST`. Aí uma resposta perdida deixa a sessão no celular e o
servidor na dúvida, que é o `pending` da aula 7 para sempre. Ele poderia perguntar antes ao
servidor, "você salvou uma sessão de violão no dia 23?", e o servidor não tem como distinguir esta
sessão de uma segunda que a pessoa quis mesmo acrescentar.

O que falta aos dois lados é um jeito de dizer *esta* operação, em vez de *uma* operação com o mesmo
corpo. **Isso é uma identidade para a requisição, escolhida pelo cliente antes da primeira tentativa
e enviada em toda nova tentativa**, e a aula 10 a constrói: a chave de idempotência, e o pagamento
que ensinou o setor a usar uma.
