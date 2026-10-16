---
title: Nunca há tempo para testar tudo
version: 1
---

**Testar tudo é impossível: as cinco frases da Joana já permitem mais combinações de idade, dia, horário e tamanho de
pedido do que alguém rodaria, e um sistema real tem milhares de frases. Então todo plano de teste é uma escolha do que
deixar de fora.** Priorizar é fazer essa escolha de propósito, com motivos que outra pessoa consegue ler, em vez de
pelo que foi testado primeiro antes de o tempo acabar.

No Cine Aurora, a entrega de sexta traz seis áreas de mudança, e a Lia tem dois dias, dezesseis horas, para testá-las:

| área | o que mudou |
|---|---|
| **regra de preço** | a linha da idade e a quarta, a correção da aula 17 |
| **pedidos** | o programa de pedidos agora recusa um pedido sem gravá-lo |
| **cupons** | PIPOCA e ESTREIA, aulas 15 e 16 |
| **mapa de assentos** | o site agora mostra quais assentos estão ocupados |
| **reembolsos** | um botão de reembolso na bilheteria |
| **relatório noturno** | uma coluna de desconto, a ação da aula 18 |

Dezesseis horas não cobrem tudo isso a fundo. Dividi-las por igual, menos de três horas para cada, trata o relatório
noturno como a regra de preço, e ninguém acha que importam igual. A pergunta é como dizer *quanto* cada uma importa, de
um jeito com que o time possa concordar ou discutir.

## Quatro perguntas

Quatro perguntas fazem a maior parte do trabalho, e cada uma tem uma seção própria nesta aula:

1. **Qual a chance de estar quebrado?** Código novo, código complexo, código mudado às pressas, código que ninguém
   entende.
2. **Quão ruim seria se estivesse?** Dinheiro, confiança, lei, segurança, quantas pessoas são prejudicadas.
3. **Com que frequência é usado?** Um defeito em algo que todo cliente toca faz mais estrago que um num canto.
4. **Onde já houve defeitos?** Defeitos se agrupam; a parte que falhou no mês passado é uma boa aposta para este.

As duas primeiras são a definição clássica de **risco**: probabilidade vezes impacto. As outras duas a refinam. A
frequência de uso afina o impacto; o histórico de defeitos afina a probabilidade.

## Priorizar é uma decisão do time

A Lia não decide sozinha o que importa mais. A probabilidade muitas vezes é melhor julgada pelo Rafael e pelo Tomás,
que sabem que código foi difícil de escrever. O impacto é a Joana quem julga, porque sabe quanto um preço errado custa
ao negócio. O uso vem dos dados, e o histórico dos registros de defeito. A parte da Lia é fazer as quatro perguntas,
juntar as respostas num lugar só, e transformá-las numa ordem que todos conseguem ver.

Além de uma ordem de teste, o resultado é uma declaração do **que vai ser testado de leve ou não vai ser
testado**, dita em voz alta antes de sexta, que é o assunto da aula 21: uma decisão de entrega tomada com as lacunas
visíveis é uma decisão; uma tomada sem elas é uma surpresa esperando para acontecer.
