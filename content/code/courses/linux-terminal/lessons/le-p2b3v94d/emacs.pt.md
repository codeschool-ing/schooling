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

```schooling-figure
{"caption": "`emacs -nw server.conf`, capturado de um terminal de verdade.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"Uma tela do emacs capturada: a barra de menu no topo, as seis linhas do server.conf, a linha de modo dizendo server.conf All L1 (Conf[Space]), e a área de eco abaixo dela.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"40.00\" y=\"14.00\" width=\"700.00\" height=\"15.50\" fill=\"var(--term-white-bg)\"/><rect x=\"40.00\" y=\"29.50\" width=\"7.00\" height=\"15.50\" fill=\"#b22222\"/><rect x=\"40.00\" y=\"200.00\" width=\"98.00\" height=\"15.50\" fill=\"#bfbfbf\"/><rect x=\"138.00\" y=\"200.00\" width=\"84.00\" height=\"15.50\" fill=\"#bfbfbf\"/><rect x=\"222.00\" y=\"200.00\" width=\"518.00\" height=\"15.50\" fill=\"#bfbfbf\"/><rect x=\"439.00\" y=\"215.50\" width=\"49.00\" height=\"15.50\" fill=\"#f5f5f5\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726 733\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"#0a0e14\">File Edit Options Buffers Tools Conf Help                                                           </tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"#ccd6e5\">#</tspan><tspan fill=\"var(--term-red)\"> the server configuration</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">listen</tspan><tspan fill=\"var(--paper)\"> 8080</tspan></text><text x=\"40 47 54 61 68 75 82 89 96\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">workers</tspan><tspan fill=\"var(--paper)\"> 4</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">timeout</tspan><tspan fill=\"var(--paper)\"> 30</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">log_level</tspan><tspan fill=\"var(--paper)\"> info</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">log_file</tspan><tspan fill=\"var(--paper)\"> /var/log/app.log</tspan></text><text x=\"40\" y=\"134.00\" xml:space=\"preserve\"></text><text x=\"40\" y=\"149.50\" xml:space=\"preserve\"></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"></text><text x=\"40\" y=\"196.00\" xml:space=\"preserve\"></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726 733\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"#0a0e14\">-UU-:---  F1  </tspan><tspan font-weight=\"600\" fill=\"#0a0e14\">server.conf </tspan><tspan fill=\"#0a0e14\">   All   L1     (Conf[Space]) --------------------------------------------</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">For information about GNU Emacs and the GNU system, type </tspan><tspan fill=\"#00008b\">C-h C-a</tspan><tspan fill=\"var(--paper)\">.</tspan></text></g></svg>"}
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

```schooling-figure
{"caption": "`hello` digitado e depois `C-x C-c`. O emacs pergunta sobre cada buffer não salvo pelo nome.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"A mesma tela do emacs capturada na saída: hello digitado no começo da linha 1, a linha de modo agora dizendo -UU-:**-, e uma pergunta na área de eco perguntando se o arquivo deve ser salvo.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"40.00\" y=\"14.00\" width=\"700.00\" height=\"15.50\" fill=\"var(--term-white-bg)\"/><rect x=\"40.00\" y=\"200.00\" width=\"98.00\" height=\"15.50\" fill=\"#bfbfbf\"/><rect x=\"138.00\" y=\"200.00\" width=\"84.00\" height=\"15.50\" fill=\"#bfbfbf\"/><rect x=\"222.00\" y=\"200.00\" width=\"518.00\" height=\"15.50\" fill=\"#bfbfbf\"/><rect x=\"593.00\" y=\"215.50\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-white-bg)\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726 733\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"#0a0e14\">File Edit Options Buffers Tools Conf Help                                                           </tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">hello</tspan><tspan fill=\"var(--term-red)\"># the server configuration</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">listen</tspan><tspan fill=\"var(--paper)\"> 8080</tspan></text><text x=\"40 47 54 61 68 75 82 89 96\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">workers</tspan><tspan fill=\"var(--paper)\"> 4</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">timeout</tspan><tspan fill=\"var(--paper)\"> 30</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">log_level</tspan><tspan fill=\"var(--paper)\"> info</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">log_file</tspan><tspan fill=\"var(--paper)\"> /var/log/app.log</tspan></text><text x=\"40\" y=\"134.00\" xml:space=\"preserve\"></text><text x=\"40\" y=\"149.50\" xml:space=\"preserve\"></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"></text><text x=\"40\" y=\"196.00\" xml:space=\"preserve\"></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726 733\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"#0a0e14\">-UU-:**-  F1  </tspan><tspan font-weight=\"600\" fill=\"#0a0e14\">server.conf </tspan><tspan fill=\"#0a0e14\">   All   L1     (Conf[Space]) --------------------------------------------</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">Save file /home/ana/work/edit/server.conf? (y, n, !, ., q, C-r, C-f, d or C-h) </tspan><tspan fill=\"#0a0e14\"> </tspan></text></g></svg>"}
```

`hello` foi digitado e então `C-x C-c`. **O emacs pergunta sobre cada buffer não
salvo pelo nome**, com nove respostas possíveis — `y`, `n`, `!` para todos, `d`
para ver um diff antes — e ele não sai até que cada um tenha sido resolvido.

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
