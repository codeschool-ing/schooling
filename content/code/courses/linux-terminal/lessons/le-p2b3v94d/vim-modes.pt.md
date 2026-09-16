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

```
ana@vm:~/work/edit$ vim server.conf
┌────────────────────────────────────────────────────────────────────────┐
│# the server configuration                                              │
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
│"server.conf" 6L, 101B                                1,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

**A linha de baixo é a interface inteira do vim.** À esquerda: o que acabou de
acontecer — aqui, o arquivo que ele abriu, seis linhas, 101 bytes. À direita: o
cursor, linha 1 coluna 1, e `All`, querendo dizer que o arquivo inteiro cabe na
tela.

As linhas com `~` não fazem parte do arquivo. Elas marcam onde o arquivo termina
e a tela continua.

Aperte `i`:

```
┌────────────────────────────────────────────────────────────────────────┐
│# the server configuration                                              │
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
│-- INSERT --                                          1,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

**`-- INSERT --`.** É a única diferença na tela, e é o que olhar quando você não
tem certeza se as suas teclas estão indo para o arquivo.

`Esc`, e ele some. Um modo sem anúncio é o modo normal.

E o visual:

```
┌────────────────────────────────────────────────────────────────────────┐
│# the server configuration                                              │
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
│-- VISUAL LINE --                           3         3,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

`V` e então `jj` — `-- VISUAL LINE --`, e o `3` no meio é quantas linhas estão
selecionadas. (Num terminal de verdade aquelas três linhas ficam destacadas; uma
página como esta não mostra cor, então a contagem é a parte a ler.)

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
