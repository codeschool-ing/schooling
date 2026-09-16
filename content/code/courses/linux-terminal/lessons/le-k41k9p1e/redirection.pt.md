---
title: Redirecionamento, e por que a ordem do `2>&1` importa
version: 1
---

Seis operadores, e você vai usar quatro deles todo dia.

| | |
|---|---|
| `> arquivo` | saída padrão para um arquivo, **substituindo** |
| `>> arquivo` | saída padrão para um arquivo, **acrescentando** |
| `< arquivo` | o arquivo como entrada padrão |
| `2> arquivo` | saída de erro para um arquivo |
| `2>&1` | saída de erro **para onde a saída padrão estiver indo agora** |
| `&> arquivo` | as duas, no bash. Atalho para `> arquivo 2>&1` |

## O `>` esvazia o arquivo antes

```
ana@vm:~/work$ echo one > note.txt; echo two > note.txt; cat note.txt
two
ana@vm:~/work$ echo three >> note.txt; cat note.txt
two
three
```

**O `>` trunca antes de o comando rodar**, não depois de ele dar certo. Vale internalizar isso,
porque quer dizer que `sort arquivo > arquivo` destrói o arquivo:

```
ana@vm:~/work$ printf "c\na\nb\n" > /tmp/t.txt; cat /tmp/t.txt
c
a
b
ana@vm:~/work$ sort /tmp/t.txt > /tmp/t.txt; wc -c /tmp/t.txt; cat /tmp/t.txt
0 /tmp/t.txt
```

**Zero bytes.** O shell esvaziou o arquivo enquanto o `sort` ainda estava abrindo, o `sort` não leu
nada, e não escreveu nada. Sem erro, sem aviso, e os dados sumiram.

O conserto é escrever em outro lugar e mover, ou usar uma ferramenta que edita no lugar. O `sed -i`
da seção 13 existe exatamente para isso.

## Redirecionando erros

```
ana@vm:~/work$ ls logs nosuchdir > out.txt 2> err.txt; cat err.txt
ls: cannot access 'nosuchdir': No such file or directory
```

Dois arquivos, dois fluxos, nada na tela. E para jogar os erros fora de vez:

```
ana@vm:~/work$ ls nosuchdir 2>/dev/null; echo "exit: $?"
exit: 2
```

**O `/dev/null` aceita qualquer coisa e não guarda nada** — o ralo vazio da aula 3. Repare no que
sobreviveu: o código de saída. Calar as reclamações de um comando não cala a **resposta** dele, que é
por que o `2>/dev/null` é seguro num script que confere o `$?` e perigoso num que não confere.

## As duas para um lugar só

```
ana@vm:~/work$ ls logs nosuchdir > both.txt 2>&1; cat both.txt
ls: cannot access 'nosuchdir': No such file or directory
logs:
access.log
app.log
app.log.1
empty.log
error.log
```

O `2>&1` se lê como **"faça o descritor 2 virar uma cópia do descritor 1"**, que é a frase da aula 6
seção 13. Como o 1 já aponta para o `both.txt` na hora em que ele roda, o 2 vai parar lá também.

## E é por isso que a ordem importa

```
ana@vm:~/work$ ls nosuchdir 2>&1 > out.txt; cat out.txt
ls: cannot access 'nosuchdir': No such file or directory
```

**Os mesmos dois operadores, trocados, e o erro está na tela e o arquivo está vazio.**

Leia da esquerda para a direita, como o shell lê:

1. `2>&1` — faça o 2 virar cópia do 1. Agora o 1 é **o terminal**, então o 2 agora é o terminal. Que
   ele já era.
2. `> out.txt` — aponte o 1 para o arquivo. **Isso não leva o 2 junto**; o 2 continua sendo o
   terminal.

O `2>&1` copia para onde um descritor aponta *naquele momento*. Não é um vínculo, e nada o atualiza
depois.

**Então o `> arquivo 2>&1` é o que funciona, e o `2>&1 > arquivo` é um erro silencioso.** Ele não
produz erro nenhum, escreve um arquivo, e perde a coisa que você provavelmente estava tentando
guardar. Quando alguém diz que um arquivo de log misteriosamente não tem os erros, normalmente é
isso.

O `&> arquivo` evita a questão inteira e é só do bash. Num script com `#!/bin/sh`, use
`> arquivo 2>&1`.

## Redirecionando dentro de um pipeline

Um pipe carrega só a saída padrão. Os erros passam por fora dele, para o terminal:

```
some-command 2>/dev/null | grep thing      # drop errors, pipe results
some-command 2>&1 | grep thing             # search results AND errors
```

**A segunda é como se faz grep numa mensagem de erro**, e as pessoas pegam a primeira por hábito e
depois se perguntam por que o `grep` não acha nada. Se o que você procura foi impresso em vermelho,
ele estava na saída de erro, e um `|` puro nunca o viu.

## Mais dois, ocasionalmente

O **here-doc** entrega um bloco de texto como entrada padrão, que é como um script fornece entrada
sem um arquivo:

```
cat > /tmp/config.txt <<'EOF'
first line
second line
EOF
```

As aspas em volta do `'EOF'` importam: sem elas o shell expande `$variáveis` dentro do bloco, e com
elas não expande.

A **here-string** é a versão de uma linha, o `<<<`:

```
ana@vm:~/work$ grep -c o <<< "hello world"
1
```

Um, porque o `grep -c` conta **linhas que casam**, não ocorrências — a seção 06 volta a isso.

E o `tee` é o que não é redirecionamento e resolve o mesmo problema — escrever num arquivo **e**
passar o texto adiante:

```
some-command | tee out.txt | grep error
```

O `tee -a` acrescenta. É o jeito padrão de guardar uma cópia do que passou, e o jeito padrão de
escrever num arquivo do root a partir de um pipeline, já que o `sudo cmd > /root/arquivo` falha — **o
redirecionamento é feito pelo seu shell, não pelo `sudo`** — e o `cmd | sudo tee /root/arquivo`
funciona.
