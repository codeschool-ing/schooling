---
title: Três equipes, três respostas
version: 1
---

**As mesmas sete perguntas, feitas por três equipes diferentes, apontam para três lados diferentes.**
As equipes abaixo são inventadas, e cada uma foi desenhada para que um ou dois critérios dominem.
Repare em quais respostas decidem, porque essa é a habilidade desta aula; a ferramenta no fim de
cada história importa menos que o caminho até ela.

## A equipe Android de um banco

Dois desenvolvedores que escrevem Kotlin para Android há anos recebem um app de banco. Ele precisa
entrar com a digital do usuário, guardar um token no armazenamento seguro do celular e passar pela
revisão de segurança do banco. O Android vem primeiro, porque é o que a maioria dos clientes do banco
usa; o iOS está planejado para o ano seguinte.

- Linguagens: Kotlin, e mais nada. Swift e TypeScript seriam os dois novos.
- Recursos do aparelho: biometria e armazenamento seguro, onde um erro é um defeito de segurança e
  não um bug.
- Plataformas: uma agora, a segunda depois.

**A resposta é Android nativo, com o Kotlin Multiplatform à vista.** Para uma plataforma, o nativo
não custa nada a mais, e põe os recursos críticos de segurança na linguagem da própria equipe, sem
ponte no meio. Quando o iOS chegar, as regras já escritas em Kotlin podem ir para um módulo
compartilhado, e as telas iOS são escritas em SwiftUI. A decisão é começar nativo e manter a lógica
livre do Android, para que ela possa ser compartilhada depois.

## Uma startup com um app web

Quatro desenvolvedores web têm um app web parecido com o planner, que as pessoas já usam, escrito em
React e TypeScript. Os investidores querem o app nas duas lojas em três meses. São listas,
formulários, algumas notificações e armazenamento no aparelho; nada anima sob o dedo.

- Linguagens: TypeScript e React, todo dia.
- Tempo até a loja: três meses, para duas plataformas ao mesmo tempo.
- Desempenho: modesto. Listas de algumas centenas de linhas.

**A resposta é React Native, com um embrulho como plano B.** O React Native mantém a linguagem e o
jeito React de construir telas, dá a cada celular os próprios controles nativos e compartilha a
lógica que eles já têm. Um embrulho seria mais rápido ainda, porque mantém também as telas; se os
três meses fossem seis semanas, ele ganharia. A equipe deveria anotar que a escolha entre os dois
dependeu do prazo, porque, quando o prazo passar, os motivos para um embrulho vão junto.

## Um estúdio fazendo um app de desenho

Um estúdio pequeno está fazendo um app de esboço: pincéis próprios, camadas, uma tela que segue o
dedo sem atraso visível. Os designers querem a mesma tela, pixel a pixel, nos dois celulares. A
equipe sabe um pouco de Dart e um pouco de Swift.

- Desempenho: dominante. Cada traço é desenhado enquanto o dedo se move.
- Plataformas: as duas, e o mesmo desenho em cada uma.
- Recursos do aparelho: toque e uma caneta, e pouco mais.

**A resposta é Flutter, a não ser que a caneta diga outra coisa.** O Flutter pinta cada pixel
sozinho, então um desenho fica igual nos dois celulares, e o código dele é compilado para código
nativo em vez de rodar num interpretador. Mas, se o ponto forte do app passar a ser um recurso de
caneta que só uma plataforma oferece, a balança pende para o nativo naquela plataforma, porque esse
recurso mora do outro lado da fronteira.

## O que as três têm em comum

**Nenhuma delas escolheu perguntando qual ferramenta é a melhor.** O banco escolheu pela linguagem e
pelos recursos de segurança, a startup pelo prazo e pelo código que já tinha, o estúdio pelo que
desenha. Cada resposta estaria errada para as outras duas equipes. E cada uma veio com uma condição
em que mudaria, que é a frase mais útil de anotar em qualquer uma dessas decisões.
