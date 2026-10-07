---
title: Estimativa por analogia
version: 1
---

A técnica mais simples também é uma das mais precisas: ache um trabalho parecido com este que já foi feito, veja quanto tempo levou e ajuste pelas diferenças.

## Um exemplo resolvido

O time Agenda precisa estimar o **agendamento online** da rede de clínicas. No ano passado ele construiu o **cadastro de clínicas** — as telas e a API que deixam uma clínica nova se registrar, configurar suas salas e convidar sua equipe. As duas funcionalidades têm formato parecido: algumas telas, uma API, uma integração com terceiros e um piloto numa clínica. O cadastro levou **18 dias úteis**.

O agendamento online é julgado um pouco maior: a integração de pagamento é mais complexa que a integração de e-mail do cadastro, e ele tem mais regras. O time o estima em cerca de 1,2 vez o cadastro, o que dá **21,6 dias úteis**.

A conta é trivial. O trabalho está nos dois julgamentos: que as funcionalidades são comparáveis, e quanto maior é a nova. Esses julgamentos ficam melhores nas mãos de quem trabalhou na funcionalidade antiga, e piores nas de quem só leu o ticket dela.

## Por que vence a imaginação

A analogia funciona porque os 18 dias da funcionalidade antiga já contêm tudo o que a falácia do planejamento deixa de fora: o dia de doença, o requisito mal entendido, a dependência atrasada. Ninguém precisou imaginá-los, porque aconteceram. Daniel Kahneman, escrevendo sobre a falácia do planejamento, chamou isso de adotar a **visão de fora**: olhar como projetos parecidos de fato correram, em vez da visão de dentro de como este vai correr se tudo sair como planejado. Bent Flyvbjerg desenvolveu isso depois para grandes projetos públicos como **previsão por classe de referência**.

## Do que ela precisa

A analogia precisa de **registros**: quanto tempo o trabalho passado de fato levou, não quanto se estimou que levaria. Um time que nunca anota as durações reais não tem analogias de onde tirar, o que é mais um argumento para os tempos de ciclo da aula 3, registrados pelo quadro sem custo extra. Ela também precisa de **comparação honesta**. O erro mais comum é escolher a analogia que dá a resposta que alguém quer — o projeto parecido menor, o que correu excepcionalmente bem —, e um time deveria nomear mais de um trabalho comparável e olhar a dispersão.
