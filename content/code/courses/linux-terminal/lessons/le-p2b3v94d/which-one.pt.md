---
title: Qual deles, e a resposta que não é uma personalidade
version: 1
---

## Os três, lado a lado

| | nano | vim | emacs |
|---|---|---|---|
| **tempo até ser útil** | dez minutos | algumas horas | um fim de semana |
| **instalado por padrão** | quase sempre | **sempre**, como `vi` | nunca |
| **modos** | não | sim, e é esse o ponto | não |
| **ajuda na tela** | sim, sempre | não | em parte |
| **como se sai** | `^X` | `:q!` | `C-x C-c` |
| **bom em** | um arquivo, uma mudança | texto, com velocidade | ser um ambiente |
| **o argumento contra** | ele para por aí | as horas | não é um editor |

## A resposta

**Aprenda o nano em dez minutos. Aprenda quatro comandos do vim. Escolha depois,
ou nunca.**

O nano faz o trabalho de que esta aula trata — mudar uma linha num arquivo numa
máquina que está em outro lugar — completamente e imediatamente. Não há vergonha
nisso e ninguém sério acha que há.

Os quatro comandos do vim não são opcionais, porque **o `vi` é o que está sempre
lá**: numa imagem de resgate, num contêiner construído a partir do `scratch` mais
um shell, numa máquina em que alguém removeu o nano para poupar quatro megabytes.
`Esc`, `:q!`, `:wq`, `u`.

Se você vai mais fundo no vim é uma escolha genuína, com um retorno real e um
custo real. O retorno está na seção 198 — a gramática, e editar na velocidade em
que você pensa. O custo são as horas, e elas também não são opcionais.

## Duas razões para escolher o vim que não são estéticas

**Ele está na máquina quebrada.** Todo o resto é um pacote que pode não estar
instalado. Esse não é um argumento pequeno quando a máquina que você está
consertando é a que não consegue instalar pacotes.

**As teclas dele estão em todo lugar.** O `less` as usa (seção 43). O `man` usa o
`less`. O `git log` usa o `less`. O `k9s`, a busca do `htop`, o `psql`, o
`mysql`, a maioria dos gerenciadores de arquivos, e o modo vim de toda IDE. `j`,
`k`, `/`, `n`, `q` e `G` são as teclas de ler texto no Unix, e não só as do vim.

## Duas razões para escolher o nano que não são preguiça

**Você vai estar certo oito vezes em dez.** O trabalho é uma linha num arquivo,
por `ssh`, num momento ruim. O nano faz isso, com as teclas na tela, sem chance
de um modo em que você não sabia que estava.

**Outra pessoa vai ter que ler o que você escreve.** Uma máquina compartilhada,
um runbook, um colega olhando a sua tela. O `nano /etc/nginx/nginx.conf` num
documento é seguido por qualquer pessoa; `vim`, então `/server_name`, então
`ciw`, não é.

## Uma razão para escolher o emacs

Você quer o ambiente, e decidiu gastar o tempo. Essa é uma resposta legítima e
não é assunto deste curso.

## O que não é uma razão

**Que um deles é para gente séria.** Todos editam texto. Alguém que administra
sistemas em produção há quinze anos usando o nano não vem fazendo errado, e
alguém cuja configuração do vim tem mil linhas não é necessariamente mais rápido
que essa pessoa.

O argumento é sobre o trabalho específico à sua frente, e a máquina específica em
que você está — que é sobre o que é a próxima seção, porque em muitíssimos dias o
editor não é algo que você escolha.
