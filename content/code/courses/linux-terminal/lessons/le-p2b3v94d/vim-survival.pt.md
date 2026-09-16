---
title: Como sair, e as quatro telas que te seguram
version: 1
---

Esta é a seção para ler duas vezes. Tudo nela acontece quando você está com
pressa.

## Os quatro comandos

| | |
|---|---|
| `Esc` | chegar ao modo normal. **Primeiro, sempre** |
| `:q!` | sair, jogando fora as mudanças |
| `:wq` | salvar e sair |
| `u` | desfazer |

**`Esc` e então `:q!`** é a resposta para "estou preso no vim". Funciona do modo
de inserção, do modo visual, de um comando digitado pela metade. Joga fora as
suas mudanças, que é o que você quer quando não teve a intenção de fazer
nenhuma.

Se o `Esc` parece não funcionar, você provavelmente está no meio de um comando de
várias teclas — aperte duas vezes.

## Tela um: ele não te deixa sair

```schooling-figure
{"caption": "Um caractere apagado com `x`, e depois `:q`. O vim não sai enquanto a mudança não for resolvida, e ele é assim de rígido por um caractere.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"Uma tela do vim capturada se recusando a sair: cinco linhas do server.conf e E37: No write since last change (add ! to override) na linha de baixo.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"40.00\" y=\"14.00\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-white-bg)\"/><rect x=\"40.00\" y=\"215.50\" width=\"357.00\" height=\"15.50\" fill=\"var(--term-red-bg)\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"#0a0e14\"> </tspan><tspan fill=\"var(--paper)\">the server configuration</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">listen 8080</tspan></text><text x=\"40 47 54 61 68 75 82 89 96\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">workers 4</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">timeout 30</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_level info</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_file /var/log/app.log</tspan></text><text x=\"40\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"#1b1a14\">E37: No write since last change (add ! to override)</tspan><tspan fill=\"var(--paper)\">                               1,1           All</tspan></text></g></svg>"}
```

**O `E37` é o vim te protegendo**, não o vim sendo difícil. Você mudou alguma
coisa e pediu para sair sem salvar.

| | |
|---|---|
| `:wq` | você queria manter |
| `:q!` | você não queria |

Repare na primeira linha. Ela dizia `# the server configuration` e agora começa
com um espaço, porque foi ali que o `x` caiu. Um caractere é tudo o que o vim
está se recusando a perder aqui, e ele se recusa com a mesma firmeza com que
recusaria um dia de trabalho.

## Tela dois: `Press ENTER`

Qualquer mensagem longa demais, ou qualquer comando que produziu saída, termina
com `Press ENTER or type command to continue`. **Aperte Enter.** Não é um prompt
com consequências; o vim está esperando você ter lido a linha.

## Tela três: o arquivo de swap

```schooling-figure
{"caption": "Um vim foi aberto, uma linha foi adicionada, e o processo foi morto. É isto que o vim seguinte mostra.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"Uma tela do vim capturada relatando um arquivo de swap: E325: ATTENTION, o dono do arquivo de swap, a data, o ID do processo e o arquivo a que ele pertence, e -- More -- no pé.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"40.00\" y=\"14.00\" width=\"105.00\" height=\"15.50\" fill=\"var(--term-red-bg)\"/><rect x=\"110.00\" y=\"215.50\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-white-bg)\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"#1b1a14\">E325: ATTENTION</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">Found a swap file by the name &#34;.server.conf.swp&#34;</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">          owned by: ana   dated: Wed Sep 16 19:34:06 2026</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">         file name: ~ana/work/edit/server.conf</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">          modified: YES</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">         user name: ana   host name: vm</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">        process ID: 3361</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">While opening file &#34;server.conf&#34;</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">             dated: Wed Sep 16 19:34:04 2026</tspan></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">(1) Another program may be editing the same file.  If this is the case,</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">    be careful not to end up with two different instances of the same</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">    file when making changes.  Quit, or continue with caution.</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-green)\">-- More --</tspan><tspan fill=\"#0a0e14\"> </tspan></text></g></svg>"}
```

Aquilo é real: um vim foi aberto, uma linha foi acrescentada, e o processo foi
morto. Isto é o que o vim seguinte mostra.

**O vim mantém um arquivo de swap enquanto você edita**, para que se ele morrer o
seu trabalho não se perca. Encontrar um ao iniciar quer dizer uma de duas coisas,
e a tela diz qual:

| | |
|---|---|
| `process ID: 7985` **ainda rodando** | outra pessoa está com este arquivo aberto. Aperte `q` e vá perguntar |
| aquele processo não existe mais | o vim ou a máquina morreu. O seu trabalho não salvo está no arquivo de swap |

Aperte Enter depois do `-- More --` e as escolhas aparecem. As que importam:

| | |
|---|---|
| `r` | **recover** — carrega o que estava no arquivo de swap |
| `e` | edita assim mesmo, ignorando |
| `q` | sai. **A segura, se você não tem certeza** |
| `d` | apaga o arquivo de swap |

**A sequência certa quando o trabalho era seu e o editor morreu:** aperte `r`,
olhe o que voltou, salve em algum lugar, e então `:q` e apague o arquivo de swap
— o vim não vai fazer isso por você, e enquanto ele existir você vê esta tela
toda vez.

```sh
ls -la .server.conf.swp        # they are hidden, and named after the file
rm .server.conf.swp
```

## Tela quatro: o terminal, não o vim

Às vezes o vim está bem e o terminal não. Os dois casos da aula 1 seção 08:

| | |
|---|---|
| nada aparece quando você digita | você apertou `Ctrl-s`. Aperte `Ctrl-q` |
| o vim saiu mas o terminal está bagunçado | `reset`, ou `stty sane` |

**O `Ctrl-s` é o que se parece exatamente com um editor travado**, e é um recurso
de terminal da era do papel.

## Dois jeitos de perder trabalho que não são culpa do vim

**Editar um arquivo que outra coisa reescreve.** Um gerenciador de configuração,
um deploy, um serviço que reescreve o próprio arquivo. O vim avisa ao salvar —
`WARNING: The file has been changed since reading it!!!` — e é um prompt que você
tem que ler em vez de dispensar.

**Editar a cópia errada.** `sudo vim` num arquivo, e então descobrir que a sua
mudança não está lá, porque você abriu o `/etc/nginx/nginx.conf` e o que está
valendo é o `/etc/nginx/sites-enabled/default`. Não é problema do editor, e é o
jeito mais comum de uma edição "não pegar".

## O cartão

```
Esc            get to normal mode
:q!            leave, discard changes
:wq            save and leave
u              undo
Ctrl-r         redo
/text  n       search, next
dd  yy  p      delete a line, copy a line, paste
i  A  o        insert here, at end of line, on a new line
:set paste     before pasting anything
```

Nove linhas. Se o vim não é o seu editor, é tudo dele de que você precisa — e as
quatro do alto são as que importam numa máquina em que alguém está esperando.
