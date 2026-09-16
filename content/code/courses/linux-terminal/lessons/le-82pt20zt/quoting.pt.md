---
title: Aspas, que é onde os bugs moram
version: 1
---

Mais bugs de shell vêm de aspas do que de todo o resto desta aula somado. O motivo é que **uma
expansão sem aspas não é um valor — é uma lista de palavras, e quem decide quantas é o shell.**

Há três tipos de aspas e eles diferem em exatamente uma coisa: o que ainda deixam o shell fazer.

```
ana@vm:~/work/scripts$ who='ana'
ana@vm:~/work/scripts$ echo "double: $who"
double: ana
ana@vm:~/work/scripts$ echo 'single: $who'
single: $who
ana@vm:~/work/scripts$ echo "escaped: \$who"
escaped: $who
```

| | |
|---|---|
| `"duplas"` | expandem `$var`, `` `cmd` ``, `$(cmd)` e `\`. Bloqueiam divisão e globbing |
| `'simples'` | não expandem absolutamente nada. A única coisa que não cabe dentro é uma aspa simples |
| `\x` | um caractere, tomado literalmente |

**As aspas simples são as fortes.** Qualquer coisa entre elas chega exatamente como escrita, que é
por que toda expressão regular, todo programa de `awk` e todo comando de `sed` da aula passada
estava entre aspas simples: o `$1` dentro de aspas duplas teria sido o primeiro argumento do shell,
não o primeiro campo do awk.

## O que as aspas duplas de fato impedem

Não a expansão — essa elas deixam passar. Elas impedem as *duas coisas que acontecem depois* dela.

```
ana@vm:/tmp/q$ touch 'my file.txt' plain.txt a.log b.log
ana@vm:/tmp/q$ f='my file.txt'
ana@vm:/tmp/q$ ls -l $f
ls: cannot access 'my': No such file or directory
ls: cannot access 'file.txt': No such file or directory
ana@vm:/tmp/q$ ls -l "$f"
-rw-r--r-- 1 ana ana 0 Sep 15 10:00 'my file.txt'
```

**A variável guardava um nome de arquivo e o `ls` recebeu dois argumentos.** O shell expandiu o
`$f` para `my file.txt` e então dividiu no espaço em branco, porque é o que ele faz com o
*resultado* de uma expansão sem aspas. Isso se chama divisão em palavras.

A segunda coisa é o globbing:

```
ana@vm:/tmp/q$ pattern='*.log'
ana@vm:/tmp/q$ echo $pattern
a.log b.log
ana@vm:/tmp/q$ echo "$pattern"
*.log
```

Mesma variável, mesmos dois caracteres dentro, dois resultados diferentes — porque, sem aspas, o
`*` que *saiu* da variável foi então comparado com o diretório.

Ou seja: **`"$var"` quer dizer "este um valor"; `$var` quer dizer "corte isto em palavras e depois
expanda os curingas que houver nelas".** Você quer a primeira praticamente sempre.

## O espaço em branco vai junto

```
ana@vm:/tmp/q$ sentence='one   two'
ana@vm:/tmp/q$ echo $sentence
one two
ana@vm:/tmp/q$ echo "$sentence"
one   two
```

A divisão em palavras não só separa — ela colapsa. Três espaços viraram um, porque o shell dividiu
em duas palavras e o `echo` as juntou com um espaço só. Se o seu script está reformatando os
próprios dados, é por isso.

## A variável vazia, que é a perigosa

```
ana@vm:/tmp/q$ empty=
ana@vm:/tmp/q$ echo "rm -rf /var/cache/$empty/*"
rm -rf /var/cache//*
```

Aquilo é um `echo`, então nada aconteceu. Tire o `echo` e leia de novo.

**Uma variável não definida ou vazia expande para nada, e o caminho em volta dela se fecha.** Um
script feito para limpar o diretório de cache de uma aplicação limpa o de todas. Não há erro, não
há aviso, e o comando está sintaticamente perfeito.

As aspas não te salvam aqui — `"$empty"` continua vazio. Três coisas salvam, e você deve usar as
três:

| | |
|---|---|
| `set -u` | seção 06. Uma variável não definida vira erro em vez de string vazia |
| `${var:?mensagem}` | seção 15. Recuse-se a expandir, com a sua própria mensagem |
| `[ -n "$var" ] \|\| exit 1` | confira você mesmo, cedo |

## Substituição de comando também é uma expansão

```
ana@vm:/tmp/q$ count=$(ls | wc -l); echo "there are $count entries"
there are 4 entries
```

O `$(...)` roda um comando e vira a saída dele — e essa saída está então sujeita à mesma divisão e
ao mesmo globbing que qualquer outra coisa. **`$(comando)` sem aspas é o mesmo bug que `$var` sem
aspas**, e é mais provável, porque a saída de um comando tem mais chance de conter espaços.

## A regra

**Ponha aspas duplas em toda expansão, toda vez.** `"$var"`, `"$@"`, `"$(cmd)"`, `"${arr[@]}"`.

Não "quando o valor puder ter um espaço" — sempre, porque você não sabe o que vai estar naquela
variável numa máquina que você não viu, num dia em que um nome de arquivo tem um espaço porque
alguém o exportou de uma planilha.

Há dois lugares em que dá para deixar de fora:

```
[[ $count -gt 5 ]]      # inside [[ ]] no splitting or globbing happens, so quotes are optional
cmd $FLAGS              # when you deliberately want one variable to become several arguments
```

O `[[ ]]` é a seção 08, e as aspas continuam não sendo *erradas* lá — elas só não mudam nada. A
segunda linha é uma técnica real e é também como as pessoas se machucam; quando você precisar dela,
um array (seção 12) faz o mesmo trabalho e preserva as palavras que você quis dizer.

Repare que o `[ ]` — um colchete — **não** está nessa lista. Ele é um comando comum, os argumentos
dele são divididos como os de qualquer outro, e a seção 08 mostra o que isso custa.

O `shellcheck` (seção 17) aponta toda aspa faltando num arquivo em menos de um segundo, o que é um
revisor melhor que este parágrafo.
