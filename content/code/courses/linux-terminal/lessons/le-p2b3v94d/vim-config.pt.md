---
title: Um `.vimrc` que vale, e um que não
version: 1
---

O vim sem configuração nenhuma é usável. O vim com dez linhas de configuração é
agradável. O vim com a configuração de quatrocentas linhas de outra pessoa é um
programa diferente que você não conhece.

## As dez linhas

```vim
" ~/.vimrc — the minimum
set number              " line numbers
set ignorecase          " searching is case-insensitive
set smartcase           " unless the pattern has a capital in it
set incsearch           " jump to matches as you type
set hlsearch            " highlight every match
set expandtab           " the Tab key inserts spaces
set tabstop=4           " a Tab character displays as four columns
set shiftwidth=4        " > and < indent by four
set scrolloff=3         " keep three lines visible above and below the cursor
syntax on               " colour, if the terminal has it
```

A `"` começa um comentário, que é uma esquisitice do próprio vim e não um erro de
digitação.

Quatro delas valem uma frase cada.

**O `ignorecase` com o `smartcase`** é o par. Sozinho, o `ignorecase` quer dizer
que você nunca consegue buscar uma letra maiúscula de propósito; juntos eles
fazem o que você quer de verdade, que é não diferenciar até você digitar uma
maiúscula.

**O `scrolloff=3`** é o que ninguém menciona e todo mundo sente falta depois de
ter tido. O cursor para a três linhas da borda em vez de ficar na última linha,
então você sempre vê o que vem.

**O `expandtab` é uma decisão, não um padrão.** Ele faz a tecla Tab inserir
espaços. Num arquivo Python isso é o certo; num `Makefile` quebra o arquivo,
porque o make exige tabulações de verdade. `:set noexpandtab` para esses, ou
deixe uma regra de tipo de arquivo fazer isso.

**O `hlsearch` deixa o destaque ligado** depois que você achou o que queria, o
que é irritante. O `:noh` limpa até a próxima busca.

## Onde ele fica

| | |
|---|---|
| `~/.vimrc` | o seu |
| `~/.vim/` | os seus plugins, cores e regras de tipo de arquivo |
| `/etc/vim/vimrc` | o da máquina, aplicado a todo mundo |
| `~/.config/nvim/init.vim` | o do neovim, que fora isso é a mesma coisa |

**O `vim -u NONE arquivo`** inicia sem configuração nenhuma. É como você descobre
se uma coisa estranha é o vim ou é o seu `.vimrc`, e é a primeira coisa a tentar
quando um editor se comporta diferente em duas máquinas.

## O `:set` em tempo de execução

Todo `set` funciona como comando enquanto você edita:

```schooling-figure
{"caption": "`:set number`, capturado de um terminal de verdade. O comando fica na linha de baixo até outra coisa precisar dela.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"Uma tela do vim capturada depois de :set number: as seis linhas do server.conf cada uma com o seu número numa coluna à esquerda, e o comando ainda na linha de baixo.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"68.00\" y=\"14.00\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-yellow)\">  1 </tspan><tspan fill=\"#0a0e14\">#</tspan><tspan fill=\"var(--term-cyan)\"> the server configuration</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-yellow)\">  2 </tspan><tspan fill=\"var(--paper)\">listen 8080</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-yellow)\">  3 </tspan><tspan fill=\"var(--paper)\">workers 4</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-yellow)\">  4 </tspan><tspan fill=\"var(--paper)\">timeout 30</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-yellow)\">  5 </tspan><tspan fill=\"var(--paper)\">log_level info</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-yellow)\">  6 </tspan><tspan fill=\"var(--paper)\">log_file /var/log/app.log</tspan></text><text x=\"40\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">:set number                                                                       1,1           All</tspan></text></g></svg>"}
```

| | |
|---|---|
| `:set number` | liga |
| `:set nonumber` | desliga |
| `:set number!` | alterna |
| `:set number?` | como está agora |

**Dois de que você vai precisar com pressa:**

`:set paste` antes de colar no modo de inserção. Sem ele, o vim aplica indentação
automática a cada linha colada e o texto chega com formato de escada. `:set
nopaste` depois. (Terminais que suportam colagem entre colchetes tornam isso
desnecessário, e muitos não suportam.)

`:set list` mostra tabulações como `^I` e fins de linha como `$` — o `cat -A` da
aula 8 seção 05, dentro do editor, e o jeito de ver por que um `Makefile` não
está funcionando.

## Duas coisas que não são configuração

**O `vimtutor`** é um programa, vem instalado junto com o vim, e são trinta
minutos:

```
ana@vm:~$ which vimtutor || echo 'vimtutor: not installed'
/usr/bin/vimtutor
```

Ele abre uma cópia de um arquivo de aula que você edita enquanto lê. Se você vai
usar o vim de alguma forma, é a melhor meia hora disponível.

**O `:help`** é o manual e é genuinamente bom:

```vim
:help                 " the front page
:help dw              " what dw does
:help 'expandtab'     " an option — note the quotes
:help :set            " a command — note the colon
:help i_CTRL-w        " a key in insert mode
```

As aspas e os dois-pontos não são decoração: são como o vim sabe se você quer
dizer a opção, o comando ou a tecla.

## A questão dos plugins

O vim moderno (8 em diante) tem um sistema de pacotes embutido, e existem
gerenciadores de plugins por cima dele. Tudo isso é real e útil e pertence a
quem já decidiu que o vim é o seu editor.

**Para esta aula está fora de escopo**, e há um argumento prático para manter
assim: as máquinas onde você mais precisa do vim são aquelas onde a sua
configuração não está. Um vim que você só consegue pilotar com os seus plugins
não é um vim que você consegue usar numa imagem de resgate.

Aprenda o simples primeiro. É o mesmo programa em todo lugar.
