---
title: O plano, antes de mexer em qualquer coisa
version: 1
---

Um ensaio é planejado primeiro no papel, e o papel é curto:

| | para o ensaio desta lição |
|---|---|
| **o que falha** | o líder do Patroni, morto como se a máquina tivesse morrido (lição 16) |
| **o que esperamos** | um novo líder em cerca de 30 segundos; os pedidos falham nesse meio-tempo e passam depois, pela porta 5000; nenhum pedido dado como salvo some |
| **o que medimos** | segundos sem pedidos; pedidos que falharam; linhas na tabela contra pedidos dados como `ok` |
| **critérios de aborto** | o cluster não está inteiro e atualizado antes de começar: três membros, todos running ou streaming, sem atraso |
| **o caminho de volta** | ligar de novo o nó morto; ele volta como réplica (lição 16) |
| **quem é avisado** | todo mundo que veria as falhas, antes, e depois com os resultados |

A expectativa é escrita **antes** do ensaio, como um número. Um ensaio cujo resultado não é comparado
com nada confirma o que quer que tenha acontecido; um comparado com uma expectativa escrita pode
surpreender você, e a surpresa é o achado.

Os critérios de aborto são o que mais importa. Um ensaio é seguro porque o cluster aguenta perder um
nó; começado num cluster que já perdeu um, ele tira o segundo, e o ensaio vira o incidente. Por isso a
primeira coisa que o plano faz é olhar, e recusar.

Em produção o plano cresce: um horário combinado com o negócio, uma pessoa cuja única função é
cancelar tudo, e os primeiros ensaios numa cópia da produção, e não na produção em si. A ordem não
muda.
