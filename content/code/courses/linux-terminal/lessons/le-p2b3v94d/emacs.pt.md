---
title: Emacs, honestamente e brevemente
version: 1
---

O emacs é o terceiro editor, e o enquadramento honesto é: é improvável que você o
encontre por acidente. Ele não vem instalado por padrão em nenhuma distribuição
mainstream, nenhuma ferramenta o abre a não ser que você tenha pedido, e nada
neste curso o exige.

Ele está nesta aula porque é genuinamente uma terceira ideia, e porque se você
herdar uma máquina em que alguém definiu `EDITOR=emacs` você não deve ficar
perdido.

```
ana@vm:~/work/edit$ emacs -nw server.conf
┌────────────────────────────────────────────────────────────────────────────┐
│File Edit Options Buffers Tools Conf Help                                   │
│# the server configuration                                                  │
│listen 8080                                                                 │
│workers 4                                                                   │
│timeout 30                                                                  │
│log_level info                                                              │
│log_file /var/log/app.log                                                   │
│                                                                            │
│                                                                            │
│                                                                            │
│                                                                            │
│                                                                            │
│-UU-:---  F1  server.conf    All   L1     (Conf[Space]) --------------------│
│For information about GNU Emacs and the GNU system, type C-h C-a.           │
└────────────────────────────────────────────────────────────────────────────┘
```

**O `-nw` quer dizer no window** — rode neste terminal em vez de abrir um
gráfico. Sem ele, numa máquina com tela, o emacs abre uma janela separada; numa
máquina por `ssh` ele diz que não consegue e recorre a este modo.

Três partes naquela tela. A **barra de menu** no alto, que é real e usável com
`F10`. A **mode line** perto do fim: `server.conf`, `All` (o arquivo inteiro está
visível), `L1` (linha 1) e `(Conf[Space])` — o modo principal que o emacs
escolheu pelo nome do arquivo. E a **echo area** bem no fim, que é onde os
prompts e as mensagens aparecem.

O `-UU-` e o `**` à esquerda da mode line são o estado do buffer: `**` quer dizer
mudanças não salvas, que a tela abaixo mostra.

## Sem modos, e uma ideia diferente no lugar

O emacs digita quando você digita, como o nano. Os comandos são **cadeias de
teclas** construídas a partir de dois modificadores:

| | |
|---|---|
| `C-x` | Control e x |
| `M-x` | Meta e x — Alt, ou `Esc` e então `x` |

O `M-` é `Esc` seguido da tecla num terminal que não manda o Alt direito, que é a
maioria deles por `ssh`.

## O mínimo

| | |
|---|---|
| `C-x C-s` | **salvar** |
| `C-x C-c` | **sair** |
| `C-x C-f` | abrir um arquivo |
| `C-g` | **cancelar** o que você começou. O `Esc` do emacs |
| `C-s` | buscar adiante, incrementalmente |
| `C-r` | buscar para trás |
| `C-_` ou `C-/` | desfazer |
| `C-k` | mata até o fim da linha |
| `C-y` | yank — colar |
| `C-a` `C-e` | começo, fim da linha |

**O `C-g` é o de ter.** O emacs é cheio de comandos de várias teclas, e o `C-g`
abandona aquele que você começou pela metade.

O `C-s` vale reparar por outra razão: ele é buscar aqui, e é o *parar a saída* do
terminal em outros lugares (aula 1 seção 08). O emacs toma a tecla para si, o que
funciona — e é por que um usuário de emacs e um de nano discordam sobre o que o
`C-s` faz.

## Sair

```
┌────────────────────────────────────────────────────────────────────────────┐
│File Edit Options Buffers Tools Conf Help                                   │
│hello# the server configuration                                             │
│listen 8080                                                                 │
│workers 4                                                                   │
│timeout 30                                                                  │
│log_level info                                                              │
│log_file /var/log/app.log                                                   │
│                                                                            │
│                                                                            │
│                                                                            │
│                                                                            │
│-UU-:**-  F1  server.conf    All   L1     (Conf[Space]) --------------------│
│Save file /home/ana/work/edit/server.conf? (y, n, !, ., q, C-r, C-f, d or C\│
│-h)                                                                         │
└────────────────────────────────────────────────────────────────────────────┘
```

`hello` foi digitado e então `C-x C-c`. **O emacs pergunta sobre cada buffer não
salvo pelo nome**, com nove respostas possíveis — `y`, `n`, `!` para todos, `d`
para ver um diff antes — e ele não sai até que cada um tenha sido resolvido.

A `\` no fim da linha do prompt é o emacs dizendo que a linha é mais longa que a
tela e continua.

## Para que ele serve de verdade

Tudo acima faz o emacs parecer um nano mais pesado. Ele não é; ele é um ambiente
Lisp com um editor dentro, e a razão pela qual as pessoas o usam são as coisas
que rodam dentro dele:

| | |
|---|---|
| `M-x shell`, `M-x eshell` | um shell, num buffer |
| `M-x dired` | um gerenciador de arquivos, num buffer |
| Magit | uma interface de git por que as pessoas trocam de editor |
| Org mode | notas, tópicos, agendamento e documentos literários |
| `M-x tramp` | edita arquivos numa máquina remota **como se fossem locais** |

Esse último é o assunto da seção 14, e é a única coisa desta lista em que o
emacs é diretamente melhor que as alternativas.

## Onde isso te deixa

**Se alguém te entregar um emacs, você precisa de três teclas**: `C-g` para
cancelar, `C-x C-s` para salvar, `C-x C-c` para sair. É para isso que esta seção
inteira serve.

**Se você quiser aprendê-lo direito**, o `C-h t` abre o tutorial embutido, que é
o `vimtutor` do emacs e é igualmente bom. É uma decisão de verdade, porém: o
emacs é um ambiente, e as pessoas que são felizes nele não aprenderam um editor,
elas se mudaram para lá.
