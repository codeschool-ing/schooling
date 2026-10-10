---
title: Informação, não permissão
version: 1
---

**Cem Kaner, um dos fundadores da escola de teste orientada ao contexto, definiu o teste de software como
uma investigação empírica e técnica conduzida para dar às partes interessadas informação sobre a
qualidade do produto ou serviço sob teste.** Cada palavra se paga, e a última importante é *informação*.
Não aprovação, não sentença: informação, para outra pessoa decidir com ela.

## Do que uma decisão de entrega precisa de verdade

Na quinta antes do primeiro domingo com sessão de manhã, a Lia tinha achado o defeito das 9:30 da aula 4,
e a correção do Rafael não estava pronta. Sob um portão, a pergunta seria se a Lia aprovava a entrega. Pela
definição de Kaner, a pergunta era o que a Joana precisava saber para decidir. A Lia deu a ela quatro
coisas:

1. **O que se sabe.** *Um horário de sessão escrito como `9:30` é cobrado como noite. Toda sessão que
   começa antes das 10:00 é afetada. Há uma: domingo às 9:30, uns sessenta lugares.*
2. **Quanto custa se for para produção.** *Cada adulto paga R$ 8,00 a mais, cada criança R$ 4,00. Os
   clientes vão perceber no balcão, porque a Célia vende a mesma sessão por menos.*
3. **O que não se sabe.** *Testei preços. Não testei o mapa de assentos para uma sessão antes das 10:00,
   porque a primeira vez que uma existiu foi ontem.*
4. **O que poderia reduzir o risco.** *Escrever o horário como `09:30` na lista de sessões contorna o
   problema hoje. Ou só a bilheteria física poderia vender a sessão da manhã nesta semana.*

Nenhuma delas é "sim" ou "não". A Joana escolheu entregar na sexta com a sessão escrita como `09:30`, e a
correção na semana seguinte. **A decisão era dela, e foi melhor porque a informação estava completa**,
incluindo a parte sobre o que não tinha sido testado.

## A parte que as pessoas deixam de fora

O terceiro item é o que quem testa mais deixa de fora, e é o mais valioso. Um relato do que foi achado
responde a uma pergunta que ninguém fez: "está tudo bem?". Ninguém consegue responder isso. Um relato do
que **não** foi conferido diz a quem decide onde estão as incógnitas, e essa pessoa pode saber algo que
quem testa não sabe: que o mapa de assentos não compartilha código nenhum com a regra de preço, ou que
compartilha tudo.

Michael Bolton, escrevendo sobre relatos de teste, diz que um bom relato conta três histórias ao mesmo
tempo: **o produto** (o que você achou), **o teste** (como você olhou, e quão bem), e **a qualidade do
teste** (o que o tornou mais difícil, e o que você não alcançou). A terceira é a que permite a quem lê
julgar quanto confiar na primeira.

## Defender sem vetar

Dar informação em vez de permissão não quer dizer ser neutro. Quem testa e acredita que um defeito deveria
segurar uma entrega diz isso, com clareza, com a evidência. O que muda é a forma da frase:

| como portão | como informação |
|---|---|
| "Não estou aprovando esta entrega." | "Eu não entregaria isto, e o motivo é este: todo cliente da manhã de domingo paga a mais, e a Célia vai ficar sabendo primeiro." |
| "O QA reprovou este build." | "Dois defeitos achados; um afeta dinheiro, outro um rótulo. Aqui está o do dinheiro em dois comandos." |
| "Isto não está pronto." | "Isto é o que testei e o que não testei. A parte não testada é o mapa de assentos antes das 10:00." |

A coluna da direita convence mais, não menos. Dá a quem decide algo para pesar, e uma recomendação com
evidência é mais difícil de descartar que uma recusa, que só convida a pergunta de quem manda em quem.

## Quando a resposta é entregar mesmo assim

Às vezes quem é dono do produto ouve tudo e decide entregar um defeito que quem testa teria segurado. Isso
não é uma falha de quem testa. É o sistema funcionando: a decisão foi tomada por quem responde por ela, com
os riscos à vista. O que quem testa deve ao time nesse caso é **anotar o que se sabia e o que foi
decidido**, para que, se o risco se concretizar, a conversa depois seja sobre a decisão e não sobre quem
sabia o quê. A aula 18 trata de ter essa conversa sem culpa.
