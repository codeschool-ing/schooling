---
title: Retry-After, e quando parar
version: 1
---

**Quando o servidor diz quanto esperar, o cliente espera esse tanto, e o recuo calculado sai da
frente.** O cabeçalho é o `Retry-After`, definido pelo HTTP para 429 Too Many Requests e 503 Service
Unavailable, e ele carrega um número de segundos ou uma data. O servidor sabe o quanto está
carregado; a fórmula do cliente é um palpite sobre isso.

O `retry.ts` lê o cabeçalho depois de toda resposta que vale repetir e, se ele traz um número
positivo de segundos, esse número substitui a espera que a fórmula escolheu, ainda limitado por
`CAP`. Suba o servidor como `node server.ts 429` e envie:

```
ana@dev:~/planner/retry$ node retry.ts
attempt 1: 429, waiting 2000 ms as Retry-After asks
attempt 2: 201, saved as n1
```

O 429 do servidor disse dois segundos, e o cliente esperou exatamente 2000 milissegundos em vez dos
poucos que teria escolhido sozinho. A segunda tentativa deu certo.

Vale levar dois detalhes daqui. **O teto continua valendo**: um servidor que responde
`Retry-After: 86400` por engano não deve manter a caixa de saída de um celular fechada por um dia,
então o cliente fica com o menor dos dois. E a outra forma do cabeçalho, uma data HTTP, precisa de um
relógio, que é justamente o que a aula 11 diz que o de um celular não é; a forma em segundos é a
preferível quando é você quem escreve o servidor.

## Desistir, por enquanto

Um laço de novas tentativas precisa de um fim, porque uma operação que falhou cinco vezes seguidas
está dizendo algo ao cliente sobre a rede ou o servidor, e um celular martelando ali é um celular
esvaziando a bateria. Suba o servidor como `node server.ts 503 503 503 503 503`, cinco falhas
seguidas, e envie:

```
ana@dev:~/planner/retry$ node retry.ts
attempt 1: 503, waiting 2 ms
attempt 2: 503, waiting 24 ms
attempt 3: 503, waiting 781 ms
attempt 4: 503, waiting 1118 ms
attempt 5: 503
giving up for now; the operation stays in the outbox
```

Cinco tentativas, quatro esperas e uma parada. **Desistir aqui não é apagar.** A operação continua
na caixa de saída, e a próxima drenagem, quando o app for aberto ou a rede voltar, a recomeça da
tentativa 1. Um 503 nunca vai para a `dead`, porque não é a resposta do servidor sobre a operação; é
o servidor dizendo que ainda não consegue responder.

| | o que encerra | o que acontece com a operação |
|---|---|---|
| um sucesso | o servidor a aceitou | sai da caixa de saída |
| um 4xx | o servidor a recusou | vai para a `dead`, para a pessoa (aula 8) |
| tentativas esgotadas | o cliente parou de pedir | fica na caixa de saída, para a próxima drenagem |

Os números do `retry.ts`, cinco tentativas a partir de uma base de 200 milissegundos, servem a uma
drenagem que a pessoa está esperando. Uma drenagem em segundo plano pode bancar uma base maior e
menos tentativas, já que ninguém está olhando. Nenhum dos dois é lei: são uma política, e escrevê-los
como constantes com nome no topo do arquivo é o que os torna uma política que alguém pode mudar.
