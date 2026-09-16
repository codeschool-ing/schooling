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

```
┌────────────────────────────────────────────────────────────────────────┐
│  1 # the server configuration                                          │
│  2 listen 8080                                                         │
│  3 workers 4                                                           │
│  4 timeout 30                                                          │
│  5 log_level info                                                      │
│  6 log_file /var/log/app.log                                           │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│:set number                                           1,1           All │
└────────────────────────────────────────────────────────────────────────┘
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
