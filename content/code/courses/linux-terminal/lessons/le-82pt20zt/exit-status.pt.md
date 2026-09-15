---
title: Modo estrito, e os quatro lugares em que ele não ajuda
version: 1
---

A seção 99 estabeleceu o que é um código de saída: zero para sucesso, qualquer outra coisa para
falha, no `$?`. Um script também tem um, e é o que você deu ao `exit`:

```
ana@vm:~/work/scripts$ cat status.sh; ./status.sh; echo "exit status was $?"
#!/bin/bash
echo "starting"
exit 3
starting
exit status was 3
```

**Um script sem `exit` termina com o código do último comando**, que quase sempre é um `echo`, que
quase sempre dá certo. É assim que um script que falhou informa sucesso.

## Por padrão, nada para

```
ana@vm:~/work/scripts$ cat noset.sh withset.sh
#!/bin/bash
cp /etc/nosuchfile /tmp/dest.txt
echo "still running, and about to do damage"
#!/bin/bash
set -e
cp /etc/nosuchfile /tmp/dest.txt
echo "still running, and about to do damage"
ana@vm:~/work/scripts$ ./noset.sh; echo "noset.sh finished with $?"
cp: cannot stat '/etc/nosuchfile': No such file or directory
still running, and about to do damage
noset.sh finished with 0
```

Dois arquivos, impressos um atrás do outro, diferindo por uma linha.

O `cp` falhou, disse isso, e **a linha seguinte rodou assim mesmo**. O script então saiu com zero,
de modo que qualquer coisa conferindo o código foi informada de que estava tudo bem.

Esse é o padrão porque o shell é primeiro um interpretador de comandos: num prompt, um comando que
falha não deve te deslogar. Num arquivo é exatamente o errado.

```
ana@vm:~/work/scripts$ ./withset.sh; echo "withset.sh finished with $?"
cp: cannot stat '/etc/nosuchfile': No such file or directory
withset.sh finished with 1
```

O `cp` falhou, o script parou ali, e o código que ele devolveu foi o do `cp`. Uma linha de
diferença entre os dois arquivos, e um deles mente sobre o que aconteceu.

## As três configurações

```sh
#!/usr/bin/env bash
set -euo pipefail
```

| | |
|---|---|
| `-e` | `errexit` — pare no primeiro comando que falhar |
| `-u` | `nounset` — expandir uma variável não definida é erro, não string vazia |
| `-o pipefail` | um pipeline falha se **qualquer** estágio falhou, não só o último |

### O `-u`, que é o que salva um diretório

```
ana@vm:~/work/scripts$ cat nounset.sh
#!/bin/bash
TARGET=/tmp/scratch-dir
echo "would remove $TARGE/old"
echo "reached the end"
ana@vm:~/work/scripts$ ./nounset.sh
would remove /old
reached the end
```

`TARGET` numa linha, `$TARGE` na outra — um caractere faltando. Sem o `-u`, o `$TARGE` é vazio e o
caminho é `/old`. Leia aquela linha como um `rm -rf` e você tem o problema inteiro: **ele não
falhou, ele operou na coisa errada**.

```
ana@vm:~/work/scripts$ cat unset.sh
#!/bin/bash
set -u
TARGET=/tmp/scratch-dir
echo "would remove $TARGET/old"
echo "would remove $TARGE/old"
echo "reached the end"
ana@vm:~/work/scripts$ ./unset.sh; echo "script exit: $?"
would remove /tmp/scratch-dir/old
./unset.sh: line 5: TARGE: unbound variable
script exit: 1
```

Mesmo erro de digitação, com `set -u`. A linha correta rodou; o erro foi nomeado, com o número da
linha, e o script parou.

### O `pipefail`, que é o que ninguém nunca ouviu falar

```
ana@vm:~/work/scripts$ cat pipe.sh; ./pipe.sh; echo "script exit: $?"
#!/bin/bash
set -e
grep nothing /etc/hostname | wc -l
echo "reached the end anyway, status of the pipeline was $?"
0
reached the end anyway, status of the pipeline was 0
script exit: 0
```

O `grep` não achou nada, então saiu com 1. O `wc -l` contou o nada que recebeu e saiu com 0. **O
código de um pipeline é o do último comando dele**, então o pipeline deu certo, o `set -e` não viu
falha nenhuma, e o script seguiu.

```
ana@vm:~/work/scripts$ ./pipefail.sh; echo "script exit: $?"
0
script exit: 1
```

Acrescentando `-o pipefail` ao mesmo arquivo: o `0` do `wc` ainda é impresso — ele de fato rodou —
e então o script para, porque um estágio do pipeline falhou.

Se você quer o detalhe em vez do veredito:

```
ana@vm:~/work/scripts$ grep nothing /etc/hostname | wc -l; echo "PIPESTATUS: ${PIPESTATUS[@]}"
0
PIPESTATUS: 1 0
```

**O `PIPESTATUS` é um array com um código por estágio**, da esquerda para a direita, e só vale
imediatamente depois do pipeline.

## Os quatro lugares em que o `set -e` não faz nada

Isso importa mais que a configuração em si, porque um script com `set -e` no topo *parece* seguro.

```
ana@vm:~/work/scripts$ cat seholes.sh
#!/bin/bash
set -e
if false; then echo "no"; fi
echo "1: a false condition did not stop the script"
false || echo "2: the left of || may fail"
false && echo "never"
echo "3: even a bare false-and-something did not stop it"
check() { false; echo "4: and inside a function used as a condition, it goes on"; }
if check; then :; fi
false
echo "5: this line is never reached"
ana@vm:~/work/scripts$ ./seholes.sh; echo "exit: $?"
1: a false condition did not stop the script
2: the left of || may fail
3: even a bare false-and-something did not stop it
4: and inside a function used as a condition, it goes on
exit: 1
```

Quatro comandos falharam e o script continuou depois de todos eles. O quinto o parou, e a linha 5
nunca imprimiu.

| | |
|---|---|
| numa condição de `if`/`while` | o sentido de uma condição é que ela pode ser falsa |
| à esquerda de `&&` ou `\|\|` | você já está tratando a falha você mesmo |
| o caso do `false &&` | quem decide é o *último* comando da lista, e ele não rodou |
| **em qualquer lugar dentro de uma função usada como condição** | o `-e` fica suspenso na chamada inteira |

O último é o traiçoeiro. O `check` falhou na primeira linha e seguiu, porque a função inteira
estava sendo usada como condição. **O `set -e` não entra numa chamada cujo resultado você está
testando**, o que quer dizer que uma função de validação pode estar passando em silêncio pelas
próprias falhas.

## Então o que se faz de fato

Ponha `set -euo pipefail` no topo de todo script que você escrever. Não é uma rede de segurança —
os buracos acima são reais — mas cada um deles é um lugar onde ele *não ajuda*, não um lugar onde
ele atrapalha.

E depois confira explicitamente o que importa, porque é isso que os buracos te dizem:

```
ana@vm:~/work/scripts$ cat handled.sh
#!/bin/bash
set -euo pipefail
if ! cp /etc/nosuchfile /tmp/dest.txt 2>/dev/null; then
  echo "could not copy the file, carrying on without it" >&2
fi
grep -q nothing /etc/hostname || true
echo "reached the end"
ana@vm:~/work/scripts$ ./handled.sh; echo "exit $?"
could not copy the file, carrying on without it
reached the end
exit 0
```

Duas falhas sob `set -e`, nenhuma das quais parou nada, e as duas deliberadas. O `if !` trata uma;
o `|| true` deixa a outra passar.

**O `|| true` é a grafia honesta de "eu sei que isto pode falhar e não me importo".** Quem lê e vê
aquilo sabe que foi uma decisão. Quem vê um comando solto sob `set -e` não consegue dizer se a
falha foi considerada.
