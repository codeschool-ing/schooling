---
title: Pôr a dívida técnica na mesa
version: 1
---

**A dívida técnica entra numa negociação de prazo de uma de duas formas: abertamente, como um item
com preço que o outro lado consegue ver e aceitar, ou em silêncio, como um atalho que ninguém menciona
e todo mundo paga depois.** Só a primeira é uma negociação. A segunda é a alavanca da qualidade
mexida no escuro.

A aula 14 de `process-management` trata de registrar a dívida e pagá-la como prática de projeto. Aqui
a pergunta é mais estreita: o que dizer sobre ela quando alguém quer uma data.

## Dívida como juros, na unidade deles

Ward Cunningham, que criou a metáfora em 1992, quis dizer algo preciso: pôr no ar um código que você
sabe que não está bem certo é como pegar dinheiro emprestado, e cada mudança feita em cima dele paga
juros até a dívida ser quitada. Numa negociação, a metáfora só funciona se os juros forem ditos numa
unidade que o outro lado usa.

O time de Henrique tinha um número para isso. **No último ano, onze mudanças no checkout e na
logística tinham precisado, cada uma, de dias a mais para contornar a máquina de estados do pedido,
cerca de 25 dias-engenheiro no total.** Esses são os juros. As três semanas de desembaraço são o
principal. Dito assim, Renata não ouviu "a engenharia quer um refactor"; ouviu "isso custa cerca de
um mês por ano, e consertar de uma vez custa três semanas de que esta funcionalidade precisa de
qualquer jeito".

## Dois tipos de dívida na mesma conversa

- **Dívida sendo paga dentro da funcionalidade.** O trabalho na máquina de estados. Entra no plano
  como uma linha própria, com número próprio, para que ninguém pergunte depois por que a
  funcionalidade levou três semanas a mais do que "a funcionalidade".
- **Dívida contraída para cumprir a data.** Se o time decidir, junto com Renata, que a edição de
  pedidos vai ser feita de forma rudimentar em dezembro (cancelar e pedir de novo), isso é um atalho
  deliberado. Ele recebe um nome, é registrado com os juros esperados e ganha data.

O *quadrante da dívida técnica* de Martin Fowler separa a dívida contraída de propósito da contraída
por acidente, e a contraída com prudência da contraída com imprudência. **O objetivo da conversa é
que toda dívida contraída fique no canto deliberado e prudente**: escolhida, com preço e planejada,
por pessoas que sabiam o que estavam fazendo.

## O que não dizer

| em vez de | diga |
|---|---|
| "Precisamos de tempo para refatorar" | "Esta parte custa cerca de 25 dias-engenheiro por ano em contornos; consertar leva três semanas, uma vez" |
| "O código está uma bagunça" | "Toda mudança aqui demora mais do que a mesma mudança em outro lugar; aqui estão as últimas onze" |
| "A gente arruma isso depois" | "Estamos pegando este atalho; ele vai custar cerca de X até consertarmos em janeiro" |

Cada frase da esquerda é verdadeira e perde, pelo motivo que a aula 4 deu: um adjetivo não pode ser
pesado contra uma funcionalidade.
