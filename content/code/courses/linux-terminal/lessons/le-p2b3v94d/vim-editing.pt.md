---
title: Operadores e movimentos, que são uma gramática
version: 1
---

Esta é a seção que explica por que quem usa vim não para de usar.

**Uma edição é um operador mais um movimento.** O `d` é delete, o `w` é uma
palavra, então `dw` apaga uma palavra. Você não aprende comandos; você aprende
uma dúzia de operadores e uma dúzia de movimentos, e todo par é um comando que
funciona.

```
┌────────────────────────────────────────────────────────────────────────┐
│# the server configuration                                              │
│listen 8080                                                             │
│workers 4                                                               │
│timeout                                                                 │
│log_level info                                                          │
│log_file /var/log/app.log                                               │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│/timeout                                              4,8           All │
└────────────────────────────────────────────────────────────────────────┘
```

Aquilo é `/timeout`, `w`, `dw` — achar a linha, andar até a próxima palavra,
apagar uma palavra. O `30` sumiu e o cursor está na coluna 8.

## Os operadores

| | |
|---|---|
| `d` | **delete** — apagar |
| `c` | **change** — apagar, e entrar no modo de inserção |
| `y` | **yank** — copiar |
| `>` `<` | indentar, desindentar |
| `gu` `gU` | minúsculas, maiúsculas |
| `=` | reindentar, se o vim conhecer a linguagem |

## A gramática

```
[contagem] operador [contagem] movimento
```

| | |
|---|---|
| `dw` | apaga uma palavra |
| `d3w` | apaga três palavras |
| `3dw` | a mesma coisa — a contagem vai dos dois lados |
| `d$` | apaga até o fim da linha |
| `d0` | apaga até o começo |
| `dG` | apaga até o fim do arquivo |
| `dgg` | apaga até o topo |
| `df,` | apaga até a próxima vírgula, incluindo ela |
| `ct=` | muda tudo até o próximo `=` |

**Nenhum desses precisou ser memorizado individualmente.** São duas coisas
conhecidas postas juntas, e essa é a afirmação inteira.

Dobrar o operador faz ele agir na linha toda: `dd` apaga uma linha, `yy` copia
uma, `cc` muda uma, `>>` indenta uma.

```
┌────────────────────────────────────────────────────────────────────────┐
│# the server configuration                                              │
│log_level info                                                          │
│log_file /var/log/app.log                                               │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│3 fewer lines                                         2,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

`2G` e então `3dd` — ir para a linha 2, apagar três linhas. **`3 fewer lines`** é
o vim dizendo exatamente o que fez, na linha onde ele diz tudo.

## Objetos de texto, que são a outra metade

Um movimento vai *daqui até ali*. Um objeto de texto é *essa coisa inteira, onde
quer que o cursor esteja dentro dela*:

| | |
|---|---|
| `iw` `aw` | **inner word**, **a word** (incluindo o espaço depois dela) |
| `i"` `a"` | dentro das aspas, e incluindo elas |
| `i(` `a(` | dentro dos parênteses, e incluindo eles |
| `ip` `ap` | um parágrafo |
| `it` `at` | uma tag de XML ou HTML |

`ci"` — **change inside quotes** — troca o conteúdo de uma string com o cursor em
qualquer lugar dentro dela. O `da(` apaga uma expressão entre parênteses e os
parênteses. O `dap` apaga um parágrafo.

**O `ciw` e o `ci"` são os dois que mudam como você edita.** Nada precisa ser
selecionado antes, e o cursor não precisa estar em nenhuma das pontas.

## Comandos pequenos que valem ter

| | |
|---|---|
| `x` | apaga o caractere sob o cursor |
| `r` e um caractere | **replace** — troca um caractere |
| `~` | inverte a caixa de um caractere |
| `J` | **join** — junta esta linha com a próxima |
| `.` | **repete a última mudança** |
| `u` | desfaz |
| `Ctrl-r` | refaz |

**O `.` é a tecla mais valiosa do vim.** Faça uma mudança, vá para o próximo
lugar onde ela é preciso, aperte `.`. `ciwnovo<Esc>`, então `n`, então `.` é uma
busca e substituição dirigida em que você aprova cada uma — e muitas vezes é
melhor que o comando de substituição da próxima seção, porque você vê cada
mudança acontecer.

## Copiar e colar

```
┌────────────────────────────────────────────────────────────────────────┐
│# the server configuration                                              │
│listen 8080                                                             │
│listen 8080                                                             │
│workers 4                                                               │
│timeout 30                                                              │
│log_level info                                                          │
│log_file /var/log/app.log                                               │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│                                                      3,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

`2G`, `yy`, `p` — ir para a linha 2, copiar, colar abaixo. A linha 2 agora está
lá duas vezes.

| | |
|---|---|
| `p` | cola **depois** do cursor, ou abaixo da linha |
| `P` | cola antes, ou acima |
| `yy` `3yy` | copia uma linha, três linhas |

**Apagar também copia.** O `dd` põe a linha no mesmo lugar que o `yy` põe, então
`dd` e depois `p` desce uma linha, e `ddP` a devolve. Não existe uma área de
transferência separada para recortar e para copiar.

## Desfazer é uma árvore, não uma pilha

O `u` desfaz, o `Ctrl-r` refaz, e o vim diz o que fez:

```
┌────────────────────────────────────────────────────────────────────────┐
│listen 8080                                                             │
│workers 4                                                               │
│timeout 30                                                              │
│log_level info                                                          │
│log_file /var/log/app.log                                               │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│1 more line; before #2  1 second ago                  1,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

Dois `dd` e então `u`. **`1 more line; before #2  1 second ago`** — uma linha
voltou, você está agora antes da mudança número 2, que foi um segundo atrás.

O `:undolist` mostra as mudanças numeradas, o `:earlier 5m` volta cinco minutos,
e o `g-` e o `g+` andam pela árvore em vez de pela linha. Isso é mais do que você
precisa hoje e é a razão de a mensagem ser escrita desse jeito.

## Um desfazer por inserção

O `u` desfaz uma **sessão de inserção** inteira, não um caractere. Digite um
parágrafo sem apertar `Esc` e um `u` remove tudo.

**Então aperte `Esc` em pontos naturais de parada.** Não custa nada e deixa o
desfazer granular, que é a diferença entre perder uma palavra e perder um
parágrafo.
