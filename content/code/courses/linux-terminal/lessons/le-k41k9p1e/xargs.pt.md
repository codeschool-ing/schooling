---
title: O `xargs`, para comandos que aceitam argumentos em vez de entrada
version: 1
---

Toda ferramenta até aqui lê a entrada padrão. Muitas não leem — `rm`, `cp`, `chmod`, `git`, a saída
do `grep -l` passada para qualquer coisa — e o `xargs` é o adaptador.

**Ele lê linhas e as transforma em argumentos.**

```
ana@vm:~/work$ ls logs/*.log | xargs wc -l
  1200 logs/access.log
    30 logs/app.log
     0 logs/empty.log
     1 logs/error.log
  1231 total
```

Sem o `xargs`, o `wc -l` teria lido a *lista de nomes* como entrada dele e contado quatro linhas. Com
ele, os nomes viraram argumentos.

## Ele empacota o máximo que consegue

```
ana@vm:~/work$ printf "a\nb\nc\n" | xargs echo
a b c
ana@vm:~/work$ printf "a\nb\nc\n" | xargs -n1 echo saw
saw a
saw b
saw c
```

**Por padrão o `xargs` roda o comando o menor número de vezes possível**, enchendo a linha de comando
até o limite do sistema. É isso que o torna rápido: um `rm` com dez mil argumentos em vez de dez mil
`rm`.

O `-n1` força um de cada vez, que é o que você quer quando o comando só aceita um argumento, ou
quando você precisa ver qual deles falhou.

## O `-I`, para pôr o argumento em outro lugar que não o fim

```
ana@vm:~/work$ printf "x\ny\n" | xargs -I{} echo "[{}]"
[x]
[y]
```

O `-I{}` nomeia um marcador e põe o argumento onde quer que ele apareça — que é como se escreve
`xargs -I{} mv {} {}.bak`, ou qualquer coisa em que o argumento não é o último.

**O `-I` implica `-n1`**, então é um processo por linha. Em dez mil itens isso é lento, e é a troca
por conseguir posicionar o argumento.

## A falha, e o conserto

```
ana@vm:~/work$ mkdir -p spaces && cd spaces && printf "one\n" > "a file.txt" && printf "two\n" > plain.txt && ls
'a file.txt'   plain.txt
ana@vm:~/work/spaces$ find . -type f | xargs wc -l
wc: ./a: No such file or directory
wc: file.txt: No such file or directory
1 ./plain.txt
1 total
ana@vm:~/work/spaces$ find . -type f -print0 | xargs -0 wc -l
1 ./a file.txt
1 ./plain.txt
2 total
```

**O `xargs` divide em espaço em branco por padrão**, então `a file.txt` virou dois argumentos e o
`wc` procurou dois arquivos que não existem.

O conserto é um par de opções que precisam ser usadas juntas:

| | |
|---|---|
| `find -print0` | separa os resultados com um **byte nulo** em vez de uma quebra de linha |
| `xargs -0` | espera bytes nulos |

Um byte nulo não pode aparecer num nome de arquivo, que é por que este é o único separador sempre
seguro. **O `find … -print0 | xargs -0 …` é a forma a digitar por padrão**, não a de lembrar quando
um nome tem espaço — porque o nome com espaço vai ser de outra pessoa, num dia em que você não estava
esperando.

E repare em como a falha se comportou: ela **funcionou pela metade**. O `plain.txt` foi contado, o
total disse 1, e um script conferindo só o código de saída do pipeline teria visto a falha — mas um
script lendo o total teria recebido um número errado plausível.

## O `find -exec`, que é a alternativa

```
find . -name '*.log' -exec gzip {} \;      # one process per file
find . -name '*.log' -exec gzip {} +       # as many per process as fit
```

O `-exec … \;` é o `xargs -I{}`; o `-exec … +` é o `xargs` puro. **Nenhum dos dois precisa de
`-print0`**, porque o `find` entrega os nomes ao comando diretamente em vez de por um fluxo.

Então: **`-exec … +` quando o `find` já está no pipeline**, e `xargs -0` quando a lista vem de outro
lugar.

## Duas opções que te salvam

```
xargs -p          # prompt before each run
xargs -t          # print each command before running it
```

**O `-t` é o de usar na primeira vez que você escreve qualquer coisa com `xargs` e `rm` dentro.** Ele
imprime o que está prestes a fazer; combinado com um `echo` na frente do comando real, é uma
simulação:

```
find . -name '*.tmp' -print0 | xargs -0 echo rm      # shows what would go
find . -name '*.tmp' -print0 | xargs -0 rm           # does it
```

## O `-r`, para o caso vazio

O `xargs` sem entrada nenhuma ainda roda o comando uma vez, sem argumentos:

```
ana@vm:~/work$ printf "" | xargs echo "ran with:"
ran with:
ana@vm:~/work$ printf "" | xargs -r echo "ran with:"; echo "(nothing above means -r skipped it)"
(nothing above means -r skipped it)
ana@vm:~/work$ printf "" | xargs ls | head -3
Makefile
README.md
build
```

**A terceira é a forma perigosa.** Nada foi encontrado, o `xargs` rodou o `ls` sem argumentos, e o
`ls` listou o diretório atual — então um pipeline que não achou nada produziu uma listagem completa
que parece um resultado. Troque o `ls` por `rm` e a consequência é óbvia.

**O `-r` — `--no-run-if-empty` — pula o comando inteiramente quando não há entrada.** Só no `xargs` do
GNU; no BSD é o padrão. Ponha em qualquer coisa scriptada.

## A coisa toda em quatro linhas

```
ls *.log | xargs wc -l                           # simple, no odd filenames
find . -name '*.log' -print0 | xargs -0 wc -l    # safe, always
find . -name '*.log' -exec gzip {} +             # find already has the names
printf '%s\n' a b | xargs -I{} mv {} {}.bak      # the argument is not last
```

**A segunda linha é a de virar hábito**, porque ela é correta em todo caso e custa oito caracteres.
