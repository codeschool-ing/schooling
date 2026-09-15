---
title: O nano, que é o nano inteiro
version: 1
---

Esta seção não é uma introdução ao nano. Ela é o nano.

```
ana@vm:~/work/edit$ nano notes.txt
┌────────────────────────────────────────────────────────────────────────┐
│  GNU nano 7.2                    notes.txt                             │
│the first line                                                          │
│the second line                                                         │
│the third line                                                          │
│                                                                        │
│                                                                        │
│                                                                        │
│                                                                        │
│                                                                        │
│                            [ Read 3 lines ]                            │
│^G Help       ^O Write Out  ^W Where Is   ^K Cut        ^T Execute      │
│^X Exit       ^R Read File  ^\ Replace    ^U Paste      ^J Justify      │
└────────────────────────────────────────────────────────────────────────┘
```

**Digite, e ele digita.** As setas movem. O backspace apaga. Não há modos. Se
você usou qualquer caixa de texto em qualquer programa desde 1990, você já sabe
usar o nano.

E as duas linhas de baixo são o manual. O `^` quer dizer Control, então `^X` é
Control-X.

## Os dez que importam

| | |
|---|---|
| `^O` | **write out** — salvar. Ele pergunta o nome do arquivo; aperte Enter |
| `^X` | **sair**. Se houver mudanças não salvas ele pergunta |
| `^W` | **where is** — buscar |
| `^\` | **substituir** |
| `^K` | **recortar** a linha atual |
| `^U` | **colar** de volta |
| `^C` | mostra a linha e a coluna atuais |
| `^_` | ir para um número de linha |
| `^G` | ajuda, que é a mesma lista com explicações |
| `M-U` | desfazer. O `M-` quer dizer Alt, ou Escape e a tecla |

O `^O` para salvar é o que as pessoas erram, porque todo outro programa usa
`^S`. Nesta versão o `^S` salva:

```
│                           [ Wrote 3 lines ]                            │
```

Mas o `^S` também é a tecla de *parar a saída* do terminal, da seção 8, e num
arranjo em que o nano não a tomou para si, apertá-la congela a sua tela até você
apertar `^Q`. **O `^O` funciona em todo lugar**, e é o que vale ter nos dedos.

O `M-U` é desfazer mesmo, e diz o que desfez:

```
│                           [ Undid addition ]                           │
```

## Buscar

```
┌────────────────────────────────────────────────────────────────────────┐
│  GNU nano 7.2                    notes.txt                             │
│the first line                                                          │
│the second line                                                         │
│the third line                                                          │
│                                                                        │
│                                                                        │
│                                                                        │
│                                                                        │
│                                                                        │
│Search: second                                                          │
│^G Help       M-C Case Sens M-B Backwards ^P Older      ^T Go To Line   │
│^C Cancel     M-R Reg.exp.  ^R Replace    ^N Newer                      │
└────────────────────────────────────────────────────────────────────────┘
```

**As duas linhas de baixo mudaram.** É assim que o nano funciona o tempo todo: a
barra de atalhos sempre mostra o que está disponível *agora*, então o prompt de
busca oferece sensibilidade a maiúsculas, busca para trás, expressões regulares e
o histórico.

O `^C` cancela, aqui e em todo lugar. Aperte quando estiver perdido.

## Sair

```
┌────────────────────────────────────────────────────────────────────────┐
│  GNU nano 7.2                    notes.txt *                           │
│a new word the first line                                               │
│the second line                                                         │
│the third line                                                          │
│                                                                        │
│                                                                        │
│                                                                        │
│                                                                        │
│                                                                        │
│Save modified buffer?                                                   │
│ Y Yes                                                                  │
│ N No           ^C Cancel                                               │
└────────────────────────────────────────────────────────────────────────┘
```

**`^X`, e então `Y` ou `N`.** Essa é a resposta à pergunta com que o vídeo desta
aula abre, e é por isso que o nano existe.

Repare no `*` depois do nome do arquivo na barra de título — é o nano dizendo que
o buffer tem mudanças não salvas, e ele aparece no instante em que você digita
qualquer coisa.

## Duas opções que valem

```
ana@vm:~/work/edit$ nano -l +2 notes.txt
┌────────────────────────────────────────────────────────────────────────┐
│  GNU nano 7.2                    notes.txt                             │
│ 1 the first line                                                       │
│ 2 the second line                                                      │
│ 3 the third line                                                       │
│ 4                                                                      │
│                                                                        │
│                                                                        │
│                                                                        │
│                                                                        │
│                            [ Read 3 lines ]                            │
│^G Help       ^O Write Out  ^W Where Is   ^K Cut        ^T Execute      │
│^X Exit       ^R Read File  ^\ Replace    ^U Paste      ^J Justify      │
└────────────────────────────────────────────────────────────────────────┘
```

O `-l` numera as linhas, o `+2` abre na linha 2, e o `-w` desliga a quebra.

**O `-w` é o importante.** Por padrão o nano quebra linhas longas *no arquivo* —
ele insere quebras de linha de verdade — e num arquivo de configuração com um
valor longo isso é uma mudança que você não fez de propósito. Versões modernas
vêm com isso desligado, e as antigas não vinham.

O `~/.nanorc` deixa isso permanente:

```sh
set nowrap
set linenumbers
set tabstospaces
```

## O que o nano não faz

Ele não tem macros, não tem janelas divididas, não tem ecossistema de plugins e
não tem consciência de linguagem além de colorir a sintaxe. Editar um arquivo de
mil linhas nele é desagradável, e editar uma base de código nele não é algo que
alguém faça.

**Nada disso é para o que você o abriu.** Para "mudar uma linha num arquivo de
configuração por ssh" ele é completo, levou dez minutos para aprender, e os
atalhos estão na tela.

As próximas sete seções são o vim, para as máquinas em que o nano não está
instalado — e porque há um argumento real a favor dele que esta seção não fez.
