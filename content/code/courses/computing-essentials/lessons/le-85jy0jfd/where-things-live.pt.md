---
title: Onde as coisas de fato moram, e a pasta que não é um lugar
version: 1
---

Todo sistema põe o mesmo punhado de coisas no mesmo punhado de lugares, e saber qual é qual
transforma "em algum lugar do computador" num endereço.

| | Windows | macOS | Linux |
|---|---|---|---|
| **as suas coisas** | `C:\Users\ana` | `/Users/ana` | `/home/ana` |
| **programas instalados** | `C:\Program Files` | `/Applications` | `/usr/bin` e outros |
| **o sistema** | `C:\Windows` | `/System` | `/etc`, `/var`, `/usr` |
| **ajustes, por usuário** | `AppData` | `~/Library` | `~/.config` |
| **lixo temporário** | `C:\Users\ana\AppData\Local\Temp` | `/tmp` | `/tmp` |

**A pasta pessoal é a única que é sua**, e é a única que precisa ser copiada num backup. Todo o
resto ou é reinstalável ou é o sistema operacional, e os dois voltam de um instalador.

## A Área de Trabalho é uma pasta

Isso surpreende as pessoas e vale um parágrafo. **A área de trabalho não é uma superfície
especial. É uma pasta** — `C:\Users\ana\Desktop` — e o fundo da sua tela é uma janela mostrando o
conteúdo dela.

O que significa: arquivos na área de trabalho estão na pasta pessoal e são copiados como
quaisquer outros; uma área de trabalho com quatrocentos itens é uma pasta com quatrocentos itens
e ela carrega devagar; e arrumar a área de trabalho é mover arquivos entre pastas, nada mais.

## Downloads, e a pasta que todo mundo usa como arquivo morto

`Downloads` é onde um navegador põe as coisas, e é a pasta em que os documentos importantes da
maioria das pessoas de fato moram. É também a pasta com mais chance de ser esvaziada por uma
ferramenta de limpeza, e aquela em que um arquivo chamado `documento(3).pdf` é impossível de
identificar.

**Trate como caixa de entrada e não como gaveta.** Tudo nela ou é processado para algum lugar com
nome ou é apagado. Esse hábito é o maior ganho de organização disponível, e custa uns dois
minutos por semana.

## Arquivos ocultos, e por que eles são ocultos

Um arquivo cujo nome começa com ponto — `.config`, `.ssh` — é oculto no macOS e no Linux. No
Windows ocultar é uma marca no arquivo e não uma convenção de nome.

Eles são ocultos porque são ajustes que programas administram, não porque sejam segredo. Dá para
mostrá-los — `Ctrl+H` no Linux, `Cmd+Shift+.` no macOS, uma caixa de seleção no Windows — e vale
saber que existem, porque **um backup que pula arquivos ocultos pula os ajustes de todo
programa.**

## AppData, Library e a única coisa a tirar delas

Quando um programa lembra alguma coisa — as suas preferências, os seus logins, um documento pela
metade — ele não guarda ao lado do programa. Guarda na sua pasta pessoal, num daqueles diretórios
de ajustes.

**Então a regra útil é: reinstalar um programa não o reseta.** É por isso que um programa que
está se comportando mal continua se comportando mal depois de uma reinstalação, e por que apagar
a pasta de ajustes é o passo que de fato ajuda. É também por isso que copiar a sua pasta pessoal
copia muito mais que os seus documentos.
