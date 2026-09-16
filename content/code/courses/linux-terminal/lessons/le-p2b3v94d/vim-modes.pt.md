---
title: Modos, que é a ideia única
version: 1
---

Tudo que é confuso no vim vem de uma decisão de projeto, e quando você a entende
o resto é vocabulário.

**Em todo outro editor, o teclado digita. No vim, o teclado digita só quando você
está no modo de inserção.** No resto do tempo as teclas de letra são comandos.

É por isso que digitar `hello` num vim recém-aberto move o cursor e apaga alguma
coisa: o `h` é esquerda, o `e` é fim-de-palavra, o `l` é direita, o segundo `l` é
direita de novo, e o `o` abre uma linha nova — o que finalmente te põe no modo de
inserção, que é por que a confusão normalmente termina com uma linha em branco
perdida.

## Os modos que você vai usar

| | como se chega | como se sai |
|---|---|---|
| **normal** | `Esc`, de qualquer lugar | você não sai — aqui é casa |
| **inserção** | `i` `a` `o` `O` `I` `A` | `Esc` |
| **visual** | `v` `V` `Ctrl-v` | `Esc` |
| **linha de comando** | `:` `/` `?` | `Enter`, ou `Esc` para abandonar |

**O modo normal é casa.** Quando você não sabe onde está, aperte `Esc`. Ele é
inofensivo no modo normal — apita ou pisca — e te leva lá de qualquer outro.

O vim abre no modo normal. É o único editor que faz isso, e é a origem da piada
inteira.

## Como saber em qual você está

```schooling-figure
{"caption": "`vim server.conf`, capturado de um terminal de verdade. A linha de baixo é toda a interface do vim.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"Uma tela do vim capturada como ele abre: as seis linhas do server.conf, tils abaixo delas, e server.conf 6L, 101B com a régua em 1,1.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-cyan)\"># the server configuration</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">listen 8080</tspan></text><text x=\"40 47 54 61 68 75 82 89 96\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">workers 4</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">timeout 30</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_level info</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_file /var/log/app.log</tspan></text><text x=\"40\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">&#34;server.conf&#34; 6L, 101B                                                            1,1           All</tspan></text></g></svg>"}
```

**A linha de baixo é a interface inteira do vim.** À esquerda: o que acabou de
acontecer — aqui, o arquivo que ele abriu, seis linhas, 101 bytes. À direita: o
cursor, linha 1 coluna 1, e `All`, querendo dizer que o arquivo inteiro cabe na
tela.

As linhas com `~` não fazem parte do arquivo. Elas marcam onde o arquivo termina
e a tela continua.

Aperte `i`:

```schooling-figure
{"caption": "`i`. Essa é a única diferença na tela.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"A mesma tela do vim capturada depois de apertar i: o -- INSERT -- substituiu o nome do arquivo na linha de baixo, e nada mais se mexeu.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-cyan)\"># the server configuration</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">listen 8080</tspan></text><text x=\"40 47 54 61 68 75 82 89 96\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">workers 4</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">timeout 30</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_level info</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_file /var/log/app.log</tspan></text><text x=\"40\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726\" y=\"227.00\" xml:space=\"preserve\"><tspan font-weight=\"600\" fill=\"var(--paper)\">-- INSERT --</tspan><tspan fill=\"var(--paper)\">                                                                      1,1           All</tspan></text></g></svg>"}
```

**`-- INSERT --`.** É a única diferença na tela, e é o que olhar quando você não
tem certeza se as suas teclas estão indo para o arquivo.

`Esc`, e ele some. Um modo sem anúncio é o modo normal.

E o visual:

```schooling-figure
{"caption": "`V` e então `jj`, capturado de um terminal de verdade. As três linhas destacadas são a seleção; o `3` é quantas.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"A mesma tela do vim capturada depois de V j j: as três primeiras linhas estão destacadas, e a linha de baixo mostra -- VISUAL LINE -- com 3 como a contagem de linhas selecionadas.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"40.00\" y=\"14.00\" width=\"189.00\" height=\"15.50\" fill=\"var(--term-blue-bg)\"/><rect x=\"40.00\" y=\"29.50\" width=\"84.00\" height=\"15.50\" fill=\"var(--term-blue-bg)\"/><rect x=\"47.00\" y=\"45.00\" width=\"63.00\" height=\"15.50\" fill=\"var(--term-blue-bg)\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"#0a0e14\"># the server configuration </tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"#0a0e14\">listen 8080 </tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">w</tspan><tspan fill=\"#0a0e14\">orkers 4 </tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">timeout 30</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_level info</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_file /var/log/app.log</tspan></text><text x=\"40\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726\" y=\"227.00\" xml:space=\"preserve\"><tspan font-weight=\"600\" fill=\"var(--paper)\">-- VISUAL LINE --</tspan><tspan fill=\"var(--paper)\">                                                       3         3,1           All</tspan></text></g></svg>"}
```

`V` e então `jj` — `-- VISUAL LINE --`, e o `3` no meio é quantas linhas estão
selecionadas. (O destaque está azul aqui porque esta tela pediu, com
`:hi Visual ctermbg=blue`. O padrão do próprio vim é um cinza que dá 4,2:1 com
texto branco e 3,7:1 com preto — abaixo de 4,5 de qualquer jeito, onde o azul
dá 6,1:1.)

## Os seis jeitos de entrar no modo de inserção

Eles diferem em *onde* te põem, e escolher o certo poupa um movimento:

| | |
|---|---|
| `i` | **insere** antes do cursor |
| `a` | **acrescenta** depois do cursor |
| `I` | insere no primeiro caractere não branco da linha |
| `A` | acrescenta no **fim** da linha |
| `o` | **abre** uma linha nova abaixo, e vai para lá |
| `O` | abre uma linha nova acima |

**O `A` e o `o` são os dois que você vai mais usar**, porque as duas coisas que
você normalmente quer são "acrescentar ao fim desta linha" e "acrescentar uma
linha nova".

## O `Esc` fica longe

Num teclado em que o `Esc` está onde o `Caps Lock` deveria estar, tudo bem. Num
laptop com touch bar, não.

**O `Ctrl-[` é o `Esc`.** Não um substituto — o mesmo byte, 27, que é por que o
terminal não os distingue (aula 1 seção 08). Todo usuário de vim que não remapeia
o teclado usa isso.

O `Ctrl-c` também sai do modo de inserção e não é exatamente igual: ele pula
parte do que o `Esc` faz na saída, o que importa para um punhado de plugins e
nunca para nada desta aula.
