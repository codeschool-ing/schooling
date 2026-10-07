---
title: Um valor atípico é uma posição, não um veredito
version: 1
---

**Um valor atípico é um valor longe dos outros. Um erro é um valor que não corresponde ao mundo.** Os
dois se sobrepõem, e a sobreposição é menor do que parece. A aula 9 do `statistics` traçou a linha
em geral; esta aula a aplica aos totais dos pedidos da Quitanda Verde, onde as quatro possibilidades
aparecem:

| | longe dos outros | perto dos outros |
|---|---|---|
| **errado** | um total digitado com um zero a mais | um erro que por acaso caiu na faixa normal |
| **certo** | o pedido de Natal de uma clínica | quase todo pedido |

A célula de baixo à esquerda é o motivo de não se apagar um valor atípico só de vê-lo: os maiores
pedidos do ano estão entre as linhas mais importantes do arquivo. A célula de cima à direita é o
motivo de uma regra de distância não bastar: um erro que cai entre valores comuns é invisível para
qualquer regra que só mede quão longe um valor está do resto.

Então o trabalho desta aula tem duas metades. **Marcar** é estatística: decidir o que conta como
longe, e listar o que está longe. **Decidir** é todo o resto: para cada valor marcado, descobrir o
que aconteceu — pelas outras colunas da linha, por outro arquivo, por quem sabe — e então escolher
entre corrigir, manter, deixar de lado para algumas perguntas, ou marcar.

Três perguntas resolvem a maioria dos casos, e elas vêm de fora do número:

- **ele é coerente com o resto do próprio registro?** Um total que discorda dos itens do pedido está
  errado, seja qual for o tamanho;
- **há uma explicação no contexto?** Um cliente que é uma clínica, uma data em meados de dezembro, um
  produto que só se vende em quantidade;
- **é um valor, ou um de um padrão?** Vinte e três reembolsos são comuns um a um e impossíveis
  juntos.

As seções seguintes pegam um tipo cada, e a última transforma as decisões em números.
