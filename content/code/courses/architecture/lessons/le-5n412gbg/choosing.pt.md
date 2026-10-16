---
title: Escolhendo entre os dois
version: 1
---

| | orquestração | coreografia |
| --- | --- | --- |
| onde mora o plano | num lugar só, o orquestrador | em lugar nenhum; na soma dos ouvintes |
| "o que aconteceu com este pedido?" | o registro do orquestrador | logs de todo serviço, juntados por um id de correlação |
| acrescentar um passo | mudar o orquestrador | acrescentar um ouvinte; nada mais muda |
| acoplamento | o orquestrador conhece todo serviço | cada serviço conhece os eventos aos quais reage |
| um ciclo ou uma compensação esquecida | visível num arquivo | possível, e achado em produção |
| um novo ponto único de falha | o orquestrador, a não ser que seja replicado | nenhum |

O conselho de costume, de quem já rodou os dois: **coreografia para poucos passos que mudam pouco, e
orquestração quando um processo tem mais de três ou quatro passos, ramificações, ou compensações**. Um
checkout em geral já passou dessa linha. A coreografia de três passos do laboratório já é mais difícil de
acompanhar que a gêmea orquestrada, e cada passo acrescentado aumenta a diferença.

Os dois também se misturam bem. Uma forma comum é um orquestrador para o checkout, o processo com que o
negócio se importa e sobre o qual o suporte pergunta, que publica `OrderCompleted` quando termina; e
coreografia para tudo o que só reage a isso, como pontos de fidelidade, recomendações e o e-mail.

Seja quem for que a rode, a saga precisa do que aulas anteriores construíram: passos idempotentes da aula
7, para um passo repetido não fazer nada duas vezes; timeouts, retries e breakers da aula 11, para um
serviço lento não deixar sagas esperando para sempre; e um outbox, para a mudança de um passo e o evento
que a anuncia serem gravados juntos.

Quando terminar, pare o laboratório:

```sh
docker compose down
```
