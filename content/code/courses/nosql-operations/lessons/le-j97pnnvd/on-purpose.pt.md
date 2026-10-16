---
title: Abrir mão de uma garantia de propósito
version: 1
---

A pergunta útil nunca é "este banco é CP ou AP". É **"para esta operação, o que acontece com o
negócio se duas cópias discordarem por um tempo, e o que acontece se a operação falhar em vez
disso?"** Faça a pergunta por operação, porque as respostas mudam dentro de uma mesma aplicação.

## A loja, uma operação de cada vez

| operação | se duas cópias discordarem por um instante | se a operação for recusada | então |
|---|---|---|---|
| tirar do estoque o último monitor | ele é vendido duas vezes, e alguém recebe reembolso e um pedido de desculpas | o cliente vê um erro e tenta de novo | **consistência** |
| cobrar o cartão de um pedido | o cliente pode ser cobrado duas vezes | o pedido espera | **consistência** |
| pôr um item na cesta | a cesta mostra um item a menos por um segundo | o cliente não consegue comprar nada | **disponibilidade** |
| "quem comprou também levou" | sugestões um pouco velhas | uma caixa vazia na página | **disponibilidade** |
| contar uma visualização de página | a contagem fica algumas visualizações atrás | a visualização se perde, ou a página falha | **disponibilidade, e latência** |

Duas das cinco precisam de consistência e três preferem a resposta rápida. Nada disso é específico
de um produto; é uma propriedade do que a operação faz com dinheiro, estoque e confiança.

## De onde os três produtos partem, antes de você mudar qualquer coisa

Cada produto deste curso tem um padrão, e cada padrão é o palpite de alguém sobre o caso comum.
Estes são os pontos de partida que as aulas vão medir:

| | na configuração padrão | o que dá para mudar |
|---|---|---|
| **MongoDB** em replica set | escritas e leituras vão a um primário; uma escrita é confirmada quando a maioria dos membros a tem | aula 9: quantos membros precisam confirmar uma escrita, e se leituras podem ir a um secundário |
| **Cassandra** | o `cqlsh` lê e escreve com nível de consistência `ONE`: a resposta de uma réplica basta | aula 17: por comando, de `ONE` a `ALL` |
| **Redis** com réplicas | o primário responde na hora e replica em segundo plano | aula 15: `WAIT` faz o cliente esperar réplicas, e ainda assim não torna o Redis consistente no sentido do teorema |

Então, de fábrica, um replica set do MongoDB pende para **PC/EC**, e o Cassandra pelo `cqlsh` e o
Redis com réplicas pendem para **PA/EL**. A aula 9 faz o primário do MongoDB renunciar quando perde a
maioria, a aula 17 roda a mesma tabela do Cassandra dos dois jeitos e a aula 15 perde de propósito
uma escrita do Redis que já tinha sido confirmada. Essas três são o teorema acontecendo à sua frente.

## O custo de escolher para o lado errado

Abrir mão da consistência onde ela fazia falta custa **um incidente**: vendas duplas, cobranças
duplas, um número de estoque em que ninguém confia. Em geral aparece semanas depois, numa
conciliação, quando os logs que o explicariam já sumiram.

Abrir mão de disponibilidade ou de latência sem precisar custa **todo pedido**: páginas mais lentas
e erros a cada pequeno evento de rede, por uma garantia que a operação nunca usou. É mais barato por
dia e pago todo dia, e é o motivo de equipes tirarem operações de um banco único e estrito, para
começo de conversa.

Escolher de propósito é escrever a tabela acima para o seu próprio sistema antes de escolher
configurações. As aulas 3 e 4 fazem o mesmo para a forma dos dados, em vez das cópias.
