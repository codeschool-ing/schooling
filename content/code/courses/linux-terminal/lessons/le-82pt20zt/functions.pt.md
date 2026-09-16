---
title: Funções, que são scripts pequenos que dividem suas variáveis
version: 1
---

```
ana@vm:~/work/scripts$ cat funcs.sh
#!/bin/bash
log() {
  echo "[$(date +%H:%M:%S)] $*" >&2
}

greet() {
  local who="${1:-world}"
  echo "hello, $who"
}

is_even() {
  [ $(( $1 % 2 )) -eq 0 ]
}

sum() {
  local total=0 n
  for n in "$@"; do total=$((total + n)); done
  echo "$total"
}

log "starting"
greet
greet ana
if is_even 4; then echo "4 is even"; fi
if is_even 7; then echo "7 is even"; else echo "7 is odd"; fi
t=$(sum 1 2 3 4 5)
echo "the sum is $t"
log "done"
ana@vm:~/work/scripts$ ./funcs.sh
[10:04:43] starting
hello, world
hello, ana
4 is even
7 is odd
the sum is 15
[10:04:43] done
ana@vm:~/work/scripts$ ./funcs.sh 2>/dev/null
hello, world
hello, ana
4 is even
7 is odd
the sum is 15
```

A segunda execução jogou fora a saída de erro e as duas linhas de `log` sumiram com ela, enquanto o
relatório ficou. Isso é o `>&2` dentro do `log` fazendo o trabalho dele, e o motivo está no fim
desta seção.

`nome() { … }`, e então `nome` para chamar. **Uma função precisa ser definida antes da linha que a
chama**, porque o shell lê o arquivo de cima para baixo — que é por que as definições ficam no topo
e o trabalho de fato do script fica embaixo.

## Uma função é um script pequeno

Esse é o modelo mental, e ele é quase exato.

| | |
|---|---|
| `$1 $2 $#` | os argumentos **da função**, não os do script |
| `"$@"` | os argumentos da função, mesma regra de aspas da seção 05 |
| `return N` | o código de saída da função. `$?` depois |
| `exit N` | **sai do script inteiro.** Não da função |
| `$0` | ainda é o script. Funções não têm nome próprio no `$0` |

A diferença para um script é que uma função divide o shell — as variáveis, o diretório de trabalho,
os redirecionamentos. É esse o sentido dela, e é também a armadilha.

## O `local`

```
ana@vm:~/work/scripts$ cat funcbugs.sh
#!/bin/bash
i=outer
nolocal() { i=clobbered; }
withlocal() { local i=safe; }
echo "before: i=$i"
nolocal;    echo "after nolocal:    i=$i"
i=outer
withlocal;  echo "after withlocal:  i=$i"

big() { return 300; }
big; echo "return 300 arrived as $?"

neg() { return -1; }
neg; echo "return -1 arrived as $?"

double() { echo $(( $1 * 2 )); }
r=$(double 21); echo "double 21 is $r"

talky() { echo "about to compute" ; echo $(( $1 * 2 )); }
r=$(talky 21); echo "talky 21 is [$r]"
ana@vm:~/work/scripts$ ./funcbugs.sh
before: i=outer
after nolocal:    i=clobbered
after withlocal:  i=outer
return 300 arrived as 44
return -1 arrived as 255
double 21 is 42
talky 21 is [about to compute
42]
```

Aquele arquivo tem quatro lições dentro. Comece pelas três primeiras linhas de saída.

O `nolocal() { i=clobbered; }` esticou o braço e mudou a variável de quem chamou; o
`withlocal() { local i=safe; }` não.

**Tudo dentro de uma função é global a menos que você diga `local`.** Um contador de laço chamado
`i` dentro de uma função vai destruir em silêncio o `i` de quem chamou, e esse é o tipo de bug que
só aparece quando o script cresce a ponto de dois laços se aninharem através de uma chamada de
função.

A regra é mecânica: **toda variável a que uma função atribui ganha um `local`**, na primeira linha
que a menciona, a menos que mudar a cópia de quem chamou seja o propósito inteiro.

`local total=0 n` numa linha declara duas, que é a grafia usual para "e a minha variável de laço
também".

Uma verruga, e vale ver em vez de ouvir falar:

```
ana@vm:~/work/scripts$ cat localstatus.sh
#!/bin/bash
set -e
try_one() { local out=$(grep nothing /etc/hostname); echo "local assignment: still here"; }
try_two() { local out; out=$(grep nothing /etc/hostname); echo "never reached"; }
try_one
try_two
echo "never reached either"
ana@vm:~/work/scripts$ ./localstatus.sh; echo "exit $?"
local assignment: still here
exit 1
```

O mesmo `grep` que falha nas duas funções. Na `try_one` ele foi invisível, porque o comando cujo
código o `set -e` olhou foi o `local`, e o `local` deu certo. Na `try_two` a declaração e a
atribuição são instruções separadas, e a falha parou o script.

**`local x; x=$(cmd)` em duas instruções, sempre que o código de saída importar.**

## Devolver um valor

**O `return` devolve um código, não um valor.** É um inteiro de 0 a 255, e quer dizer sucesso ou
falha, não dado. Voltando ao `funcbugs.sh`, linhas quatro e cinco da saída dele:

O `return 300` chegou como **44**, que é 300 módulo 256. O `return -1` chegou como **255**. O número
é truncado sem uma palavra de reclamação, o que torna o `return` inútil para qualquer coisa que não
seja sucesso e falha.

Então uma função que calcula algo *imprime* o resultado, e quem chama pega com `$( )`:
`double() { echo $(( $1 * 2 )); }`, chamada como `r=$(double 21)`, deu 42. **A saída padrão é como
uma função devolve dados**, exatamente como um programa.

O que leva direto à armadilha, as duas últimas linhas daquela saída. O `talky` imprimiu uma
mensagem de progresso e depois a resposta, e quem chamou recebeu as duas — `[about to compute` e
`42]` são uma string só.

**Uma função que devolve dados na saída padrão não pode também conversar na saída padrão.**
Mensagens de progresso, avisos, qualquer coisa que um humano lê — mande para a saída de erro com
`>&2`, que é o que o `log()` do começo desta seção faz.

Isso não é uma gambiarra. É para isso que a saída de erro existe (aula 8 seção 02), e é por isso que
a saída normal de um script bem-comportado pode ser encanada para outra coisa sem ser contaminada.

## Duas coisas que fazem funções valerem a pena

**Uma função `die`, em todo script que você escrever:**

```sh
die() { echo "${0##*/}: $*" >&2; exit 1; }

[ -r "$1" ] || die "cannot read $1"
```

Todo caminho de erro vira uma linha, toda mensagem é formatada do mesmo jeito, e todas elas vão
para a saída de erro e saem diferente de zero — porque existe um lugar que decide, não catorze.

**Uma função `usage`**, imprimindo um heredoc:

```sh
usage() {
  cat <<'USAGE'
usage: logreport.sh [-t MS] [-n COUNT] LOGFILE
  -t MS     call a request slow above this many milliseconds (default 1000)
  -n COUNT  how many rows per table (default 5)
USAGE
}
```

O `<<'USAGE'` com o marcador entre aspas quer dizer **nenhuma expansão acontece dentro** — o texto
chega exatamente como escrito, que é o que você quer para algo contendo `$` e `*`. Sem aspas, o
`<<USAGE` expande variáveis, o que é ocasionalmente útil e normalmente uma surpresa.

## O que funções não conseguem fazer

Elas não podem ser chamadas antes de definidas, não podem devolver nada além de um número, e **não
podem ser exportadas para um script filho** de nenhum jeito em que você deva confiar — o `export -f`
existe, é só do bash, e foi o mecanismo por trás de um furo de segurança famoso em 2014.

Se dois scripts precisam da mesma função, ponha num terceiro arquivo e use `source` (seção 02).
Essa é a versão de biblioteca que o shell tem, e é toda ela.
