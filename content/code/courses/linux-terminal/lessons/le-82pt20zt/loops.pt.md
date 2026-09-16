---
title: Laços, e nunca iterar sobre o `ls`
version: 1
---

O `for` percorre uma lista de palavras. É só isso que ele faz, e todo o resto decorre de onde a
lista vem.

```
ana@vm:/tmp/q2$ for i in 1 2 3; do echo "i=$i"; done
i=1
i=2
i=3
```

`for NOME in PALAVRAS; do … done`. O `;` antes do `do` é a mesma regra do `then` na seção 07 — uma
quebra de linha também serve.

## A lista costuma ser um glob

```
ana@vm:/tmp/q2$ for f in *.log; do echo "[$f]"; done
[a.log]
[b.log]
[two words.log]
ana@vm:/tmp/q2$ for f in $(ls *.log); do echo "[$f]"; done
[a.log]
[b.log]
[two]
[words.log]
```

Entraram três arquivos. O glob deu três; o `$(ls)` deu quatro.

**Nunca itere sobre a saída do `ls`.** O `ls` imprime nomes separados por quebras de linha, o shell
divide aquilo no espaço em branco, e um nome com espaço vira dois. O `shellcheck` tem um número de
regra para isso — SC2045 — porque é assim tão comum.

O glob não tem esse problema, porque o próprio shell produziu a lista e sabe onde cada nome
termina. **`for f in *.log` é a grafia certa, sempre.**

### As duas surpresas do glob

```
ana@vm:/tmp/q2$ for f in *.nothing; do echo "[$f]"; done
[*.nothing]
```

**Um glob que não casa com nada fica literal.** O laço rodou uma vez, com o padrão como valor. Se o
corpo fosse `rm "$f"` você recebe um erro; se fosse `mkdir -p "$f"` você recebe um diretório
chamado `*.nothing`.

```
ana@vm:/tmp/q2$ shopt -s nullglob; for f in *.nothing; do echo "[$f]"; done; echo 'loop over'
loop over
```

**O `shopt -s nullglob` faz um glob sem correspondência expandir para nada**, então o laço roda
zero vezes, que é o que você quis dizer. Ligue-o uma vez no topo de um script que usa globs.

A alternativa, se você prefere não mudar o comportamento do shell globalmente, é conferir dentro do
laço:

```sh
for f in *.log; do
  [ -e "$f" ] || continue
  …
done
```

## Intervalos

```
ana@vm:/tmp/q2$ for i in {1..5}; do printf '%s ' "$i"; done; echo
1 2 3 4 5 
ana@vm:/tmp/q2$ for i in {0..20..5}; do printf '%s ' "$i"; done; echo
0 5 10 15 20 
ana@vm:/tmp/q2$ for ((i=0; i<4; i++)); do printf '%s ' "$i"; done; echo
0 1 2 3 
```

O `{1..5}` é expansão de chaves — ela acontece antes de tudo, e **não** é um glob, então funciona
com qualquer coisa: `{a..e}`, `{web,db}0{1..3}`, `file{,.bak}`.

**A expansão de chaves não consegue usar uma variável**, porque as chaves são processadas antes dos
parâmetros:

```
ana@vm:/tmp/q2$ n=4; for i in {1..$n}; do printf '%s ' "$i"; done; echo
{1..4} 
ana@vm:/tmp/q2$ n=4; for ((i=1; i<=n; i++)); do printf '%s ' "$i"; done; echo
1 2 3 4 
ana@vm:/tmp/q2$ echo {web,db}0{1..2}
web01 web02 db01 db02
```

O primeiro laço rodou **uma vez**, sobre os oito caracteres literais `{1..4}` — o `$n` foi
substituído, mas tarde demais para ajudar. Esse é o único motivo comum para pegar o `for (( ))`
estilo C.

A terceira linha é a expansão de chaves fazendo o que ela faz bem, e vale saber fora de laços
também: `mkdir -p /srv/{app,db}/{logs,data}` cria quatro diretórios num comando.

## O `while` e o `until`

```
ana@vm:/tmp/q2$ n=0; while [ $n -lt 3 ]; do echo "n=$n"; n=$((n+1)); done
n=0
n=1
n=2
ana@vm:/tmp/q2$ n=0; until [ $n -ge 3 ]; do echo "n=$n"; n=$((n+1)); done
n=0
n=1
n=2
```

O `while` roda enquanto um comando dá certo; o `until` roda até que um dê. São o mesmo laço com a
condição invertida, e o `until` merece o lugar dele em exatamente um idioma:

```sh
until curl -sf http://localhost:8080/health >/dev/null; do
  echo "waiting for the service…"
  sleep 2
done
```

"Continue tentando até funcionar" se lê melhor que "continue tentando enquanto não funciona".

**O `while` recebe um comando, como o `if`** — então `while read …` (a próxima seção) é a mesma
construção, não uma forma especial.

## O `break` e o `continue`

```
ana@vm:/tmp/q2$ for i in 1 2 3 4 5 6; do [ $((i%2)) -eq 0 ] && continue; echo "odd $i"; done
odd 1
odd 3
odd 5
ana@vm:/tmp/q2$ for i in 1 2 3 4 5; do [ $i -eq 3 ] && break; echo "i=$i"; done
i=1
i=2
```

O `continue` pula para a próxima iteração, o `break` sai do laço. Os dois aceitam um número para
laços aninhados:

```
ana@vm:/tmp/q2$ for i in 1 2; do for j in a b; do echo "$i$j"; done; done
1a
1b
2a
2b
ana@vm:/tmp/q2$ for i in 1 2; do for j in a b; do [ $j = b ] && break 2; echo "$i$j"; done; done
1a
```

**O `break 2` sai de dois níveis**, o que encerrou também o laço externo — uma linha de saída em
vez de quatro. Um `break` simples ali teria encerrado só o interno e o externo teria recomeçado.

## Laços e pipes

Um laço é um comando, então pode ser redirecionado e encanado como um:

```
ana@vm:/tmp/q2$ for f in *.log; do echo "$f: $(wc -l < "$f") lines"; done > summary.txt
ana@vm:/tmp/q2$ cat summary.txt
a.log: 2 lines
b.log: 1 lines
```

**Um `>` no `done`, não um dentro do laço.** A versão com `>> summary.txt` no corpo abre e fecha o
arquivo a cada iteração; esta abre uma vez. Em três arquivos não faz diferença. Em trinta mil faz.

## Quando não escrever laço nenhum

Esta é a parte que separa um script de shell de um programa escrito em shell.

```sh
for f in *.log; do gzip "$f"; done      # a loop
gzip *.log                              # the same thing, one process
```

**A maioria dos comandos já recebe muitos argumentos.** Um laço que chama `mv`, `rm`, `chmod` ou
`gzip` uma vez por arquivo geralmente é um laço que não precisava existir — e o `xargs` da aula 8
seção 16 cobre o caso em que a lista é longa demais ou vem de outro lugar.

Escreva o laço quando cada iteração precisar *fazer* algo diferente: montar um nome, conferir uma
condição, manter um total. Não quando é o mesmo comando com outro argumento.
