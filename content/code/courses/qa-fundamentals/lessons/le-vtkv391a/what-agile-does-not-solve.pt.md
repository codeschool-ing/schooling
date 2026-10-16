---
title: O que o ágil não resolve
version: 1
---

**Os métodos ágeis resolvem o problema do retorno tardio. Não resolvem tudo, e parte do que deixam para
trás cai em quem testa.** Conhecer as falhas comuns com antecedência é a melhor proteção para não as
confundir com o método funcionando como projetado.

## Dívida de teste

Todo ciclo produz algo novo para testar e deixa tudo o que é antigo para retestar. Quando um ciclo termina
com o teste incompleto, a lacuna não some; passa para o ciclo seguinte, em cima do trabalho próprio dele.
Depois de alguns ciclos, o time carrega uma fila de coisas construídas e nunca conferidas direito. Isso se
chama **dívida de teste**, por analogia com a dívida técnica, e ela cresce do mesmo jeito: todo ciclo que
aumenta a dívida torna o seguinte menos capaz de pagá-la.

O sintoma é fácil de ver e fácil de ignorar: histórias marcadas como *prontas* que quem testa não viu, ou viu
e tem perguntas em aberto. A cura é a definição de pronto da aula 12, cumprida com honestidade: uma história
que não foi testada não está pronta, por mais pronto que esteja o código.

## Velocidade sem rede de proteção

Ciclos curtos querem dizer mudanças frequentes, e mudanças frequentes querem dizer oportunidades frequentes de
quebrar o que funcionava. A pilha de regressão da aula 10 cresce a cada ciclo. Times que não automatizam suas
verificações de regressão batem num muro, em geral por volta do sexto mês, quando retestar à mão leva mais
que um ciclo. Nesse ponto ou param de retestar, e os defeitos começam a escapar, ou alongam os ciclos, e
deixam de ser ágeis em tudo menos no nome.

## Quem testa como pensamento tardio

Alguns times adotam as cerimônias do ágil, os ciclos curtos, a reunião diária, o quadro, e deixam quem testa
fora delas: convidado ao planejamento como observador, recebendo histórias quando estão prontas, chamado a
"dar o aceite" no fim. É o portão da aula 5 com móveis novos. O sinal é simples: se quem testa descobre o que
uma história quer dizer no dia em que ela é entregue, o time está rodando uma minicascata dentro do
vocabulário ágil.

## Requisitos que nunca assentam

Responder a mudanças é um valor, e um time pode praticá-lo até nada nunca estar estável o bastante para ser
testado. Uma regra que muda três vezes num ciclo tem três conjuntos de resultados esperados, e quem escreveu
testes contra o primeiro precisa reescrevê-los duas vezes. A defesa é a que a aula 6 usou: **transforme cada
resposta num exemplo escrito**. "Meia é o maior desconto de qualquer ingresso" é uma decisão; escrita como um
caso com preço esperado, pode ser mudada de propósito, e todo mundo vê que foi.

## A posição de quem testa

Nada disso é um argumento contra o ágil. Cada item é um lugar em que o método depende de o time fazer algo
que ele não impõe: terminar o teste dentro do ciclo, automatizar a pilha de regressão, incluir quem testa
desde a primeira conversa, escrever as decisões. As próximas três aulas olham para três métodos ágeis
específicos, Scrum, Kanban e XP, e para o que cada um faz, ou não faz, a respeito disso.
