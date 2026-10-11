---
title: O que a maioria das empresas chama de estratégia
version: 1
---

Peça a estratégia técnica a uma organização de engenharia e quase sempre você recebe uma lista. Ela
tem de cinco a dez linhas, cada uma é uma meta, e ninguém discordaria de nenhuma delas. **Essa
concordância é o problema.** Um documento com o qual ninguém consegue discordar não escolheu nada,
e escolher é o único trabalho que uma estratégia faz.

Este curso acompanha uma empresa do começo ao fim. A **Coreto** é inventada: uma empresa de São
Paulo que vende uma plataforma de ingressos para teatros, casas de show e festivais, e ganha uma
taxa sobre cada ingresso. Tem 52 engenheiros em sete times, e quase tudo o que eles operam está no
`coreto-core`, uma aplicação Rails de nove anos. Em janeiro, a CTO, Helena Prates, pediu a Davi
Moreira, engenheiro staff, que escrevesse a primeira estratégia técnica da empresa. Davi reuniu o
que cada líder de time queria e voltou com isto:

> **Estratégia técnica da Coreto, primeira versão**
>
> 1. Ser a plataforma de ingressos mais confiável do Brasil.
> 2. Chegar a 99,99% de disponibilidade no checkout.
> 3. Migrar do monólito para microsserviços.
> 4. Cortar a fatura de nuvem em 20%.
> 5. Adotar um framework de front-end moderno.
> 6. Pagar a dívida técnica.

Cada linha se defende sozinha. Leia de novo e tente responder três perguntas a partir dela: **o que
está errado na Coreto, qual destes itens importa mais, e o que a empresa vai parar de fazer para
consegui-lo.** A versão não responde nenhuma, e esse é o teste em torno do qual esta aula foi
construída.

## Quatro jeitos de uma estratégia sair ruim

Richard Rumelt, em *Good Strategy Bad Strategy* (2011), deu nome às marcas do que chamou de estratégia ruim. Elas não são a ausência de
estratégia; são documentos que parecem uma. As quatro estão na primeira versão do Davi.

**Enchimento** é linguagem que soa como ideia e não carrega nenhuma. "Ser a plataforma de ingressos
mais confiável do Brasil" é um superlativo sem mecanismo. Leria igual em qualquer empresa do
mercado, e é por isso que você sabe que não diz nada sobre esta.

**Não encarar o desafio** é a marca mais comum e a mais cara. Uma estratégia é a resposta a uma
dificuldade, e se a dificuldade não tem nome, ninguém consegue julgar se a resposta serve. A versão
nunca diz o que está dando errado. A linha 6 acena para isso — "pagar a dívida técnica" — e para
antes de dizer qual dívida, ou por que agora.

**Confundir metas com estratégia** é o que a lista inteira faz. "Chegar a 99,99% de
disponibilidade" é um alvo; diz aonde chegar e nada sobre como. Um time que recebe isso faz o que
times fazem com um alvo sem abordagem: cada um escolhe o trabalho que já queria fazer e cola nele a
etiqueta da meta.

**Objetivos estratégicos ruins** são metas demais, desconectadas, ou impossíveis de executar com os
recursos que existem. Seis metas para 52 engenheiros, várias puxando umas contra as outras —
microsserviços e a troca de framework custam anos de engenharia cada uma, e o corte na nuvem também
— é uma lista em que algo vai cair. A versão não diz o quê, então os times vão decidir um a um, e a
empresa não vai perceber que decidiu.

## Por que a lista é tão comum

**Uma lista é barata politicamente.** Davi perguntou a seis líderes o que queriam e cada um achou
seu desejo no resultado. Ninguém perdeu uma discussão, porque discussão nenhuma aconteceu. Uma
estratégia de verdade produz perdedores no papel: o projeto de alguém espera um ano, e a pessoa lê
isso no documento antes de ouvir numa reunião.

Uma lista também sobrevive a qualquer resultado. No fim do ano, alguma coisa nela vai ter
melhorado, e a lista pode reivindicar o crédito. Uma estratégia que nomeou um desafio e uma
abordagem pode se provar errada, o que é desconfortável e é também o único jeito de uma empresa
descobrir se a estratégia dela funciona.

A próxima seção dá estrutura à alternativa: três partes que uma lista não tem.
