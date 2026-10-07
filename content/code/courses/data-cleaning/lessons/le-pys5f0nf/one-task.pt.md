---
title: Uma tarefa, escrita antes
version: 1
---

Comparar ferramentas em tarefas diferentes compara as tarefas. Então esta aula fixa uma, pequena o
bastante para ser lida inteira em cada ferramenta e com armadilhas suficientes para diferenciá-las:

> A partir do `orders.csv`, conte os pedidos entregues e some a receita por canal, no ano e em
> dezembro. Remova antes as linhas repetidas exatas. Um total negativo, um cupom maior que a cesta,
> conta como zero. Dezembro quer dizer dezembro em São Paulo.

Cada cláusula vem de uma aula anterior, e cada uma é um lugar em que uma ferramenta pode divergir
em silêncio:

- **Linhas repetidas exatas**: os 25 pedidos copiados da aula 5. Uma ferramenta que tira duplicatas
  por uma chave em vez da linha inteira, ou não tira, chega a contagens diferentes.
- **Entregues**: a regra da aula 13 de que pedido cancelado ou reembolsado não é venda.
- **Totais negativos como zero**: a decisão da aula 9 para os 137 pedidos com cupom.
- **Dezembro em São Paulo**: os dois relógios da aula 7. O site escreve os horários em UTC com um
  `Z`, o aplicativo no horário local. Um pedido feito no site às 22h30 de 30 de novembro, horário de
  São Paulo, fica escrito como 1º de dezembro, e uma ferramenta que ignora o `Z` o põe no mês errado.

Uma coisa fica de fora de propósito: os sete totais digitados errado da aula 9. Corrigi-los exige
os itens dos pedidos, e isso tornaria a tarefa sobre junções e não sobre ferramentas. **Dizer o que
uma tarefa deixa de fora faz parte de escrevê-la**, para que três respostas iguais não sejam
tomadas por três respostas certas.

A tarefa é escrita em palavras antes de qualquer código, e esse é o primeiro hábito que esta aula
recomenda, seja qual for a ferramenta: **uma especificação que uma pessoa consegue conferir, contra
a qual toda implementação é medida**.
