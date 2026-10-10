---
title: Transformando uma característica em algo que se verifica
version: 1
---

**Um requisito que ninguém consegue verificar é um defeito no requisito, e é o defeito mais barato que
quem testa vai achar na vida.** O primeiro rascunho da Joana com os objetivos da bilheteria tinha três
linhas que pareciam boas e não podiam ser testadas de jeito nenhum:

> A loja precisa ser rápida. Precisa ser fácil de usar. Não pode perder vendas.

Cada uma cita uma característica da seção anterior: eficiência de desempenho, capacidade de interação,
confiabilidade. Nenhuma diz o que contaria como falhar. Pergunte a um desenvolvedor se a loja é rápida e
a resposta honesta é "comparada com o quê?". Peça a quem testa que teste se ela é rápida e a resposta
honesta é "não consigo te dizer quando terminei".

## Quatro perguntas que a tornam verificável

Um requisito de qualidade fica verificável quando responde a quatro perguntas:

1. **Quem**, ou o quê, está fazendo algo? Um cliente, a bilheteria física, o relatório da noite.
2. **Fazendo o quê?** Uma tarefa, com nome: abrir o mapa de assentos, comprar dois ingressos, imprimir
   um recibo.
3. **Em que condições?** Num celular, numa conexão lenta, com trezentas pessoas comprando ao mesmo tempo,
   na primeira noite de uma estreia.
4. **Quanto basta?** Um número, uma proporção ou um acontecimento observável, com o limite dito.

Aplique as quatro às três linhas da Joana e elas saem assim:

| vago | verificável |
|---|---|
| a loja precisa ser rápida | num celular com conexão 4G, o mapa de assentos abre em até 2 segundos em 95 de cada 100 pedidos, com 300 clientes comprando ao mesmo tempo |
| precisa ser fácil de usar | cinco clientes fiéis que nunca usaram a loja nova compram dois ingressos cada um, sem ajuda, em menos de três minutos |
| não pode perder vendas | se o pagamento com cartão falhar, os assentos ficam reservados por dez minutos e o cliente pode pagar de novo sem escolhê-los outra vez |

Os números da direita são decisões, não fatos. Dois segundos podiam ser três; cinco clientes podiam ser
oito. **O que mudou é que agora alguém precisa escolhê-los**, e quem deve escolher é a Joana, porque ela
sabe o que o cinema pode pagar e o que os clientes aguentam. O trabalho de quem testa era tornar a
escolha visível, não fazê-la.

## Por que isso é garantia de qualidade

Fazer as quatro perguntas é prevenção no estado mais puro. Nada foi construído, nada rodou, e uma classe
inteira de discussão foi evitada: a do fim de projeto em que o desenvolvedor diz que a loja é rápida o
bastante, a dona do produto diz que não é, e ninguém consegue provar nada porque ninguém escreveu o que
bastante queria dizer.

Elas também expõem requisitos que escondem um desacordo. Quando a Lia perguntou o que *não pode perder
vendas* queria dizer, a Joana disse "o pagamento nunca falha", o Rafael disse "o provedor de pagamento
falha mais ou menos uma vez em duzentas tentativas e não temos como mudar isso", e a versão verificável
à direita é o acordo que a pergunta forçou. Sem a pergunta, o Rafael teria construído uma coisa, a Joana
teria esperado outra, e a primeira pessoa a descobrir a diferença seria um cliente com dois assentos que
não conseguia mais pagar.

## A característica que ninguém perguntou

Passe as quatro perguntas pelas nove características e algumas voltam sem resposta nenhuma, porque
ninguém tinha pensado nelas. No Cine Aurora foi a **proteção**: uma sala tem 180 assentos, a bilheteria
física e o site vendem para a mesma sala, e nenhum documento dizia o que impede os dois, juntos, de vender
um 181º ingresso. Esse número quem fixa é o alvará do corpo de bombeiros, então não é um detalhe
comercial. Isso também é um requisito, e a ausência dele é o tipo de lacuna que uma lista existe para
revelar.

Você não precisa resolver uma lacuna dessas por conta própria. Anotá-la como uma pergunta para a dona do produto,
com o cenário que te preocupa, é a entrega.
