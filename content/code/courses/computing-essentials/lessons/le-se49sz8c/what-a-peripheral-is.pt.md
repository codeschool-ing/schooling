---
title: Um periférico é um tradutor, e isso já diz onde ficam as falhas
version: 1
---

As duas aulas anteriores foram sobre peças que computam. Nada nesta aqui computa coisa alguma. Um
periférico fica na fronteira entre uma máquina que só guarda números e um mundo que não é feito
deles, e o serviço inteiro dele é **transformar um no outro**.

| aparelho | o que ele traduz | em que sentido |
|---|---|---|
| teclado | um dedo numa tecla | mundo → números |
| mouse | um movimento na mesa | mundo → números |
| scanner | a luz refletida numa folha | mundo → números |
| monitor | números | números → mundo |
| impressora | números | números → mundo |
| tela sensível ao toque | os dois, no mesmo vidro | ambos |

Entrada, saída, ou os dois. Essa é a taxonomia inteira, e vale nomear porque ela antecipa o
formato de toda falha desta aula.

## O que um periférico pode e não pode ser

**Ele não pode ser lento do jeito que o armazenamento é lento.** Um disco rígido faz você esperar
porque um braço físico precisa se mover. Um monitor não tem o que esperar; ele redesenha num
ritmo fixo, tenha mudado alguma coisa ou não. Se uma tela parece arrastada, a tela quase nunca é
a coisa que está arrastada.

**Ele pode traduzir mal.** Um teclado que não escreve `ç` sem ginástica, uma impressora que
transforma uma fotografia numa grade de pontos visíveis, um scanner que inventa um detalhe que
nunca enxergou — cada um é uma tradução que perdeu alguma coisa, e nenhum deles aparece como
mensagem de erro.

**Ele pode ser caro de um jeito que a etiqueta de preço esconde.** Três dos cinco aparelhos daqui
têm custo de uso: tinta, toner, papel. Um deles é vendido abaixo do que custa fabricar, no
entendimento de que você vai pagar a diferença depois. Isso é a seção das impressoras, e é o
maior gasto evitável deste curso inteiro.

## A única regra que cobre todos eles

**Um periférico é escolhido contra uma pessoa, não contra o resto da máquina.** Um processador é
escolhido contra o trabalho; um monitor é escolhido contra os seus olhos e a sua mesa, um teclado
contra as suas mãos e a sua língua, um mouse contra a sua pegada.

É por isso que o conselho aqui não pode ser um número. Ninguém consegue te dizer qual é o teclado
certo, e quem diz está vendendo um. O que esta aula consegue fazer é te dizer **quais números da
caixa são reais e quais são propaganda**, para que na hora de escolher você escolha sobre fatos.
