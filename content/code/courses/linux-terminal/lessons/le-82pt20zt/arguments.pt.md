---
title: Argumentos, e por que o `"$@"` tem aspas em volta
version: 1
---

Um script que só funciona num arquivo é um bilhete para você mesmo. Argumentos são o que o
transformam numa ferramenta.

```
ana@vm:~/work/scripts$ cat args.sh
#!/bin/bash
echo "name:  $0"
echo "count: $#"
echo "first: $1   second: $2   tenth: ${10}"
echo "all:   $@"
ana@vm:~/work/scripts$ ./args.sh one two
name:  ./args.sh
count: 2
first: one   second: two   tenth: 
all:   one two
```

| | |
|---|---|
| `$0` | como o script foi invocado — um caminho, não só um nome |
| `$1` … `$9` | os argumentos |
| `${10}` | o décimo. **As chaves são obrigatórias do dez em diante** |
| `$#` | quantos são |
| `$@` | todos eles |
| `$*` | todos eles, juntos numa string só |

O `${10}` não é elegância. `$10` é `$1` seguido de um `0`, porque o shell lê o nome mais longo que
consegue e `1` é um nome completo. Com dez argumentos:

```
ana@vm:~/work/scripts$ ./args.sh a b c d e f g h i j
name:  ./args.sh
count: 10
first: a   second: b   tenth: j
```

E o `$2` não imprimiu nada na primeira execução, porque não havia segundo argumento — a mesma
expansão vazia e silenciosa de qualquer outra variável não definida.

## `"$@"` versus `$@` versus `"$*"`

Esta é a única coisa não óbvia desta seção, e ela importa em todo script que repassa os próprios
argumentos para outra coisa.

```
ana@vm:~/work/scripts$ cat loopargs.sh
#!/bin/bash
echo "-- unquoted \$@"
for a in $@; do echo "  [$a]"; done
echo "-- quoted \"\$@\""
for a in "$@"; do echo "  [$a]"; done
echo "-- quoted \"\$*\""
for a in "$*"; do echo "  [$a]"; done
ana@vm:~/work/scripts$ ./loopargs.sh 'two words' second
-- unquoted $@
  [two]
  [words]
  [second]
-- quoted "$@"
  [two words]
  [second]
-- quoted "$*"
  [two words second]
```

Entraram dois argumentos. Três jeitos de pedi-los de volta, e só um devolve dois.

| | |
|---|---|
| `$@` | expande e então divide. Dois argumentos viraram três palavras |
| `"$@"` | **uma palavra entre aspas por argumento.** Dois argumentos, os dois inteiros |
| `"$*"` | uma palavra, tudo junto com espaço. Um argumento |

**O `"$@"` é um caso especial na gramática**, não uma expansão normal: as aspas não o transformam
numa string, elas o transformam em *n* strings. Não há outra construção no bash que se comporte
assim, e ela existe justamente porque repassar argumentos é o que scripts fazem.

```sh
mycommand "$@"          # hand on exactly what you were given
mycommand $@            # hand on something else, if any argument had a space
mycommand "$*"          # hand on one argument that looks like all of them
```

O `"$*"` é genuinamente útil para uma coisa: montar uma mensagem. O `log "$*"` dentro de uma função
junta todas as palavras numa linha, que é o que você queria.

## O `shift`

```
ana@vm:~/work/scripts$ cat shifter.sh
#!/bin/bash
while [ "$#" -gt 0 ]; do
  echo "handling [$1], $# left"
  shift
done
echo "done, \$# is $#"
ana@vm:~/work/scripts$ ./shifter.sh alpha beta gamma
handling [alpha], 3 left
handling [beta], 2 left
handling [gamma], 1 left
done, $# is 0
```

**O `shift` joga o `$1` fora e move todo o resto para baixo**: o `$2` vira `$1`, o `$#` cai um. É
assim que você percorre a lista de argumentos, e o laço acima é o esqueleto de todo parser de
opções que você vai escrever — a seção 146 preenche o miolo dele.

O `shift 2` desloca dois, que é como uma opção que recebe um valor consome os dois.

## Conferir que te deram alguma coisa

Duas linhas no topo de qualquer script que recebe argumentos:

```sh
[ "$#" -ge 1 ] || { echo "usage: $0 LOGFILE" >&2; exit 2; }
[ -r "$1" ]    || { echo "$0: cannot read $1" >&2; exit 1; }
```

```
ana@vm:~/work/scripts$ ./needsarg.sh; echo "exit $?"
usage: ./needsarg.sh LOGFILE
exit 2
ana@vm:~/work/scripts$ ./needsarg.sh /etc/shadow; echo "exit $?"
./needsarg.sh: cannot read /etc/shadow
exit 1
ana@vm:~/work/scripts$ ./needsarg.sh ~/work/logs/app.log; echo "exit $?"
would report on /home/ana/work/logs/app.log
exit 0
ana@vm:~/work/scripts$ ./needsarg.sh > /tmp/out.txt; echo "exit $?"; cat /tmp/out.txt
usage: ./needsarg.sh LOGFILE
exit 2
```

**O `>&2` não é opcional**, e a última execução é o motivo. Toda a saída padrão foi para o
`/tmp/out.txt`, e a mensagem de uso continuou na tela — porque ela foi para a saída de erro (seção
120), em que o redirecionamento não tocou. Sem o `>&2` ela estaria em silêncio dentro de um arquivo
que o usuário não quis e não vai ler.

E `exit 2` em vez de `exit 1` para erro de uso é uma convenção leve que vale manter: ela permite a
quem chamou distinguir "você me invocou errado" de "eu rodei e falhei".

## O `$0` não é um nome

```sh
./args.sh        →  $0 is ./args.sh
/home/ana/args.sh →  $0 is /home/ana/args.sh
```

Use `${0##*/}` (seção 152) quando quiser só o nome do arquivo para uma mensagem. E não use o `$0`
para achar o diretório do próprio script — ele não é confiável em casos suficientes para que o
idioma seja uma linha à parte, digna de copiar em vez de deduzir:

```
ana@vm:~/work/scripts$ cat whereami.sh
#!/bin/bash
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
echo "the script lives in $here"
ana@vm:~/work/scripts$ ./whereami.sh
the script lives in /home/ana/work/scripts
ana@vm:~/work/scripts$ cd /tmp && ~/work/scripts/whereami.sh
the script lives in /home/ana/work/scripts
```

Chamado de dois jeitos diferentes, a partir de dois diretórios diferentes, uma resposta. É isso que
aquela linha compra, e é por isso que um script que precisa de um arquivo ao lado de si usa
`"$here/data.csv"` e não `./data.csv`.
