---
title: Agindo, e as horas que ninguém usa
version: 1
---

Três tipos de mudança saem desta lição, e eles são feitos numa ordem certa, o mais barato e seguro
primeiro.

1. **Apagar o que está ocioso**, depois da semana de marcar e perguntar. Economiza dinheiro e não arrisca
   nada a que alguém não tenha tido uma semana para objetar.
2. **Desligar o que não é necessário à noite.** Um ambiente de desenvolvimento ou de staging usado no
   horário de trabalho não precisa rodar às três da manhã.
3. **Redimensionar o que está rodando**, com teste, porque este pode deixar algo mais lento.

## Horas, não tamanhos

O segundo item costuma ser o maior. Uma semana tem 168 horas; uma equipe trabalha talvez 12 horas em 5
dias, 60 delas. **Um ambiente que roda só nessas horas é cobrado por 36% da semana**, e pará-lo fora delas
remove 64% do custo de computação sem mudar instância nenhuma.

Para o staging da loja, quatro `m7g.large` a 0,1301 USD por hora:

| | horas por semana | USD por mês |
|---|---|---|
| sempre ligado | 168 | 4 × 0,1301 × 730 = 379,89 |
| só no horário de trabalho | 60 | 379,89 × 60 / 168 = 135,68 |
| **economizado** | | **244,21** |

O mecanismo é comum: um agendamento no EventBridge Scheduler que para as instâncias à noite e as liga de
manhã, ou um auto scaling group cujas ações agendadas põem a capacidade desejada em zero e de volta. Os
discos mantêm o preço, como a instância parada do `idle.py`, então um ambiente parado sai mais barato, não
grátis.

## Em que ordem olhar

A seção sobre compromissos terminou com *ajuste o tamanho primeiro*, e o motivo é este: **os compromissos
da lição 22 são dimensionados pelo piso do que roda**, e cada disco ocioso, instância grande demais e
staging rodando à noite sobe esse piso. Limpe primeiro, redimensione depois, agende o que pode dormir, e
só então se comprometa com o piso que sobrou, que é menor e mais verdadeiro.
