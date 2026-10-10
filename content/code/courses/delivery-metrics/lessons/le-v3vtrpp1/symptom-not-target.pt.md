---
title: A métrica é um sintoma
version: 1
---

A forma mais comum de usar mal as métricas DORA é também a mais natural: **um gestor lê que bons times fazem deploy com frequência e pede ao time que faça deploy com mais frequência**. O pedido parece um caminho direto até o resultado. É um caminho que contorna o resultado, e a aula 7 mostra aonde ele leva.

Os quatro números são **sintomas**, no sentido médico: coisas que você consegue observar e que dizem algo sobre o que você não consegue ver diretamente. O que você não consegue ver diretamente é como um time constrói e entrega software, as dezenas de hábitos que decidem se uma mudança é pequena, testada, revisada sem demora, posta em produção com segurança e fácil de desfazer. As métricas se movem quando esses hábitos mudam. Empurrar as métricas sem mudar os hábitos move os números e deixa o time onde estava.

## Os números do time de Billing se moveram sem ninguém mexer neles

Ninguém no time de Billing definiu uma meta para nenhuma das quatro métricas. A aula 5 mediu o que aconteceu mesmo assim: os deploys foram de cerca de um por semana para entre quatro e cinco, o lead time de mudanças de dois dias para algumas horas, a taxa de falha de um em cinco para um em vinte, o tempo para restaurar de mais de duas horas para menos de uma.

O que o time de fato mudou foi **quanto trabalho mantinha aberto e quem fazia as revisões**. Isso produziu lotes menores, e os lotes menores produziram cada uma das quatro melhoras. Se, em vez disso, alguém tivesse mandado o time fazer deploy diário em junho, o pipeline rodaria todo dia e levaria o que tivesse sido integrado: na maioria dos dias, nada; às quintas, a mesma pilha de antes, porque a pilha vinha da fila de revisão e a fila de revisão continuava intocada. A frequência de deploy teria melhorado no papel. Nada mais teria.

## Para que serve um sintoma

Um termômetro é muito útil, e ninguém trata uma febre esfriando o termômetro. As métricas DORA são úteis do mesmo jeito, para três tarefas:

- **perceber** que algo mudou, para melhor ou para pior, antes que alguém tenha opinião a respeito;
- **confirmar** que uma mudança de hábitos fez o que devia, como fez a do time de Billing;
- **começar uma conversa** sobre o porquê, que é onde está o trabalho.

O que elas não servem para ser é a meta. Um time a quem se pede que atinja um número vai achar o jeito mais barato de atingi-lo, e o jeito mais barato quase nunca é o hábito que o número deveria refletir. **Meça as quatro; mude os hábitos; leia as quatro de novo.** A próxima seção lista os hábitos.
