---
title: As regras a que esta plataforma obedece
version: 1
---

A página que você está lendo obedece às regras desta aula, conferidas por máquinas, a cada mudança.

## A interface

A interface desta escola é conferida com o **axe**, um motor de acessibilidade de código aberto, na
**WCAG 2.2 AA**, em toda tela, nos **dois temas, claro e escuro**. A conferência roda na integração
contínua do repositório, então uma mudança que derrube o contraste de um rótulo abaixo de 4,5:1 falha
antes de chegar a um aluno.

A primeira execução achou um caso que esta aula reconheceria. Um cartão de curso bloqueado tinha sido
apagado com transparência para dizer "você não pode ter isto", e o apagamento levou o próprio texto
dele a **4,09:1 no tema escuro e 3,32:1 no claro**. A correção foi a que esta aula ensina: dizer
"bloqueado" em palavras e desenhar uma borda tracejada, e nunca depender de um esmaecimento.

## As figuras

O axe mede a página, e **ele não enxerga dentro de um desenho**: texto desenhado dentro de uma figura
SVG é invisível para ele. Então as figuras têm conferências próprias:

- todo rótulo de texto dentro de toda figura é medido contra o que está atrás dele, **nos dois temas,
  em AA**;
- toda cor que uma figura cita tem de existir na paleta, porque uma que falte deixa a forma invisível
  sem erro nenhum;
- toda figura traz uma **descrição em texto** para leitores de tela, como as que a seção anterior
  descreveu, e a tradução dela traz a sua.

## O que nenhuma máquina confere

Se uma descrição diz a coisa certa, se um destaque aponta para o que importa, se um gráfico ainda
funciona quando as cores falham: isso são julgamentos, e é por eles que esta aula existe. **As máquinas
pegam as falhas mensuráveis para que as pessoas gastem a atenção no resto.** Esse é o arranjo a buscar
no seu próprio trabalho: automatize a conferência de contraste, e guarde o julgamento.

## Fazendo o mesmo no seu trabalho

- **Rode um verificador de contraste** na sua paleta uma vez, e guarde os resultados com ela.
- **Simule o daltonismo** em todo painel antes de compartilhá-lo.
- **Escreva a alternativa em texto** junto com o título, enquanto o achado está fresco.
- **Peça a alguém** que usa leitor de tela ou tem deficiência na visão de cores para testar o seu
  relatório mais importante. Nenhuma lista de conferência substitui isso.
