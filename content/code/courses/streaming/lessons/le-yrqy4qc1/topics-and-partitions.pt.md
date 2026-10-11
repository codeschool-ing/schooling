---
title: Um tópico é um nome para vários logs
version: 1
---

**Um tópico não é um log. É um nome para um conjunto de logs, chamados partições, e cada partição é
um log exatamente como o que a lição 2 construiu**: registros anexados numa ponta, numerados a partir
de 0, lidos sem ser removidos. O tópico `sales` da lição 1 tem três partições, então são três logs,
cada um com o seu offset 0, o seu offset 1 e assim por diante. "O offset 5 de `sales`" não quer dizer
nada até você dizer de qual partição.

A imagem errada de costume é uma fila única de mensagens, com as partições como algum detalhe interno
de armazenamento. Elas não são detalhe. **A partição é a unidade que o Kafka mantém em ordem, a
unidade que ele espalha pelas máquinas, e a unidade que um consumidor lê.** Quase todo comportamento
desta lição e da próxima é uma propriedade de uma partição, e o tópico é só a etiqueta do grupo.

@@fig:l3-topic@@

## Criando um e olhando para ele

Comece de um cluster vazio de um nó: pare o que você tem, crie um novo e inicie.

@@fence@@

O `new` apaga tudo o que o cluster guardava, inclusive as cinco vendas da lição 1, e é isso que você
quer aqui: todo número abaixo começa do zero.

Agora crie `sales` de novo, com três partições, e peça ao Kafka para descrevê-lo:

@@fence@@

A primeira linha da descrição é sobre o tópico: um id que o Kafka deu a ele, que é como o cluster de
fato o conhece (o nome pode ser reutilizado depois de um delete; o id não), o número de partições, e
o **fator de replicação**, o número de cópias de cada partição. Ele é 1 aqui porque só há um nó para
guardar cópias. Depois, uma linha por partição, numeradas a partir de 0:

- **`Leader`** é o nó que guarda a partição e recebe as escritas e as leituras dela. O nó 1, para as
  três, porque o nó 1 é tudo o que existe.
- **`Replicas`** lista todo nó com uma cópia, e **`Isr`** os que têm a cópia em dia.
- **`Elr`** e **`LastKnownElr`** estão vazios, e continuam vazios até a lição 5 ter três nós e
  derrubar alguns.

Com um nó, as quatro últimas colunas dizem a mesma coisa três vezes. **Elas começam a diferir na lição
5**, em que uma partição tem três cópias em três nós e perder uma é algo a acompanhar.

## Por que três, e não uma

Uma partição é lida em ordem por um leitor de cada vez dentro de um grupo, e escrita pelo seu líder
num nó. Isso tem duas consequências, e elas puxam para lados opostos:

- **A ordem só vale dentro de uma partição.** Duas vendas em duas partições não têm ordem nenhuma
  entre si, digam o que disserem os offsets. A lição 2 defendeu que ordem por chave basta; a próxima
  seção mostra como o Kafka manda cada chave para uma partição, e é isso que faz bastar.
- **O paralelismo para no número de partições.** Três partições podem ser lidas por três cópias de
  um programa ao mesmo tempo, cada uma pegando uma; uma quarta cópia não tem o que ler. A lição 4 roda
  exatamente isso. Num cluster de vários nós, as três partições também podem morar em três máquinas
  diferentes, que é o que a lição 5 faz.

Então o número de partições é uma decisão com custo dos dois lados, e a última seção desta lição é
sobre tomá-la.
