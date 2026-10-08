---
title: Severidade, prioridade e a ordem da fila
version: 1
---

A **severidade** é a afirmação da regra, escrita de antemão: o que este alerta significa se for verdadeiro
(aula 6). A **prioridade** é a decisão do analista, tomada agora: em que ordem trabalhar a fila. Elas são
diferentes porque a prioridade usa o que a regra não tinha como saber: qual ativo, quais dados, o que está
acontecendo neste momento.

Um jeito comum de definir a prioridade é **impacto contra urgência**:

| | urgência baixa: contido, ou acabado há tempo | urgência alta: ainda acontecendo, ou prestes a se espalhar |
|---|---|---|
| **impacto alto**: dados ou sistemas importantes | P2 | **P1** |
| **impacto baixo**: uma máquina de teste, sem dado sensível | P4 | P3 |

A escalação de quinta fica no canto superior direito. **O impacto é alto**: o `files` guarda os arquivos
fiscais dos clientes, que são dados pessoais, e uma cópia pode ter saído. **A urgência é alta**: uma chave foi
acrescentada à conta do bruno às 03:05, então quem a usou pode voltar, e nada nos logs diz que parou. Isso
faz dela **P1**: alguém trabalha nela agora, e as pessoas que a aula 11 nomeia são chamadas.

A prioridade também se move. O mesmo incidente cai para P2 no momento em que a chave é removida e o endereço
bloqueado, e sobe de novo se um segundo host mostrar o mesmo padrão. Uma prioridade definida uma vez e nunca
revista é um rótulo, não uma decisão.
