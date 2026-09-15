---
title: Arquivos temporários, e limpar quando você não planejava parar
version: 1
---

Um script que precisa de espaço de rascunho tem dois problemas: escolher um nome que mais ninguém
vá escolher, e apagá-lo de qualquer jeito que o script termine.

## O `mktemp`

```
ana@vm:~/work/scripts$ mktemp -d /tmp/work.XXXXXX
/tmp/work.YPo5kn
```

**O `mktemp` cria o arquivo ou o diretório e imprime o nome**, de forma atômica. O `XXXXXX` é
substituído por caracteres aleatórios; o `-d` faz um diretório em vez de um arquivo.

Não `/tmp/meuscript.tmp`, e nem `/tmp/meuscript.$$`. O `$$` é o id do processo, que é previsível e
reutilizado, e um nome fixo é pior: duas cópias do script rodando ao mesmo tempo sobrescrevem o
trabalho uma da outra, e qualquer pessoa na máquina pode criar o `/tmp/meuscript.tmp` como um link
simbólico apontando para algum lugar interessante antes de você.

O `mktemp` cria dono seu e ilegível para os outros, numa operação só:

```
ana@vm:~/work/scripts$ f=$(mktemp); d=$(mktemp -d); ls -ld "$f" "$d"; rm -rf "$f" "$d"
drwx------ 2 ana ana 4096 Sep 15 10:22 /tmp/tmp.7WT247IVW4
-rw------- 1 ana ana    0 Sep 15 10:22 /tmp/tmp.GCpTPnFgyN
```

`700` e `600` — o octal da seção 57. Sem modelo nenhum ele escolhe o nome e o diretório sozinho,
que é a grafia a usar quando você não se importa onde cai.

**Um diretório temporário costuma ser melhor que um arquivo temporário**, porque um script que
precisa de um arquivo de rascunho normalmente acaba precisando de três, e um `rm -rf` limpa todos.

## A limpeza que não acontece

```
ana@vm:~/work/scripts$ cat leaky.sh; ./leaky.sh; ls /tmp/leaky.* 2>&1
#!/bin/bash
tmp=$(mktemp /tmp/leaky.XXXXXX)
echo "working in $tmp"
echo data > "$tmp"
exit 1
working in /tmp/leaky.qpK48w
/tmp/leaky.qpK48w
```

O script saiu por um caminho de erro e deixou o arquivo para trás. Rode isso agendado e o `/tmp`
enche ao longo de meses — devagar o bastante para ninguém ligar o disco cheio ao script.

**Um `rm` no fim do arquivo não resolve**, porque o fim do arquivo é exatamente onde um script que
falha não chega.

## O `trap`

```
ana@vm:~/work/scripts$ cat tidy.sh; ./tidy.sh; ls /tmp/tidy.* 2>&1
#!/bin/bash
tmp=$(mktemp /tmp/tidy.XXXXXX)
trap 'rm -f "$tmp"' EXIT
echo "working in $tmp"
echo data > "$tmp"
exit 1
working in /tmp/tidy.58ZF4t
ls: cannot access '/tmp/tidy.*': No such file or directory
```

**O `trap 'comando' EXIT` roda aquele comando sempre que o shell sai** — normalmente, por um `exit`
em qualquer lugar do arquivo, ou porque o `set -e` o parou.

O lugar é a parte a acertar: **logo depois do `mktemp`, na linha seguinte.** Não no fim do script,
não depois da validação. Tudo entre criar a coisa e armar o trap é uma janela em que o script pode
morrer e deixá-la para trás.

```sh
work=$(mktemp -d /tmp/logreport.XXXXXX)
trap 'rm -rf "$work"' EXIT
```

Repare nas aspas simples: o comando é guardado e avaliado **quando o trap dispara**, então o `$work`
é expandido ali. Com aspas duplas ele seria expandido agora, o que por acaso funciona aqui e não
funciona quando a variável é definida depois.

## Sinais

```
ana@vm:~/work/scripts$ cat trapped.sh
#!/bin/bash
cleanup() { echo "cleanup ran, signal or not"; }
trap cleanup EXIT
trap 'echo "caught an interrupt"; exit 130' INT
echo "my pid is $$"
sleep 30
echo "not reached"
ana@vm:~/work/scripts$ ./trapped.sh
my pid is 9852
^Ccaught an interrupt
cleanup ran, signal or not
ana@vm:~/work/scripts$ echo "exit status $?"
exit status 130
```

Aquele `^C` é um Ctrl-C de verdade. O tratador de `INT` rodou, saiu com 130, e **o tratador de
`EXIT` rodou também** — porque um `exit` ainda é uma saída.

Este é o arranjo a copiar: ponha a limpeza no `EXIT` e deixe os tratadores de sinal fazerem o que
têm que fazer e então saírem. Uma limpeza, um lugar, alcançada de qualquer jeito que o script
termine.

| | |
|---|---|
| `EXIT` | qualquer saída. **O que você quer para limpeza** |
| `INT` | Ctrl-C |
| `TERM` | o `kill`, e o que um gerenciador de serviços manda ao parar |
| `HUP` | o terminal foi embora (seção 96) |
| `ERR` | o próprio do bash: qualquer comando que dispararia o `set -e` |

A regra da seção 93 continua valendo: **o `KILL` não pode ser capturado.** O `kill -9` não dá ao seu
script chance nenhuma de limpar, que é mais um motivo para preferir o `kill` simples.

E 130 como código de saída não é arbitrário: é 128 mais o sinal 2, a convenção da seção 99.

## `trap … ERR` para uma mensagem

```
ana@vm:~/work/scripts$ cat errtrap.sh
#!/bin/bash
set -e
trap 'echo "failed at line $LINENO" >&2' ERR
echo "step one"
cp /etc/nosuchfile /tmp/x 2>/dev/null
echo "never reached"
ana@vm:~/work/scripts$ ./errtrap.sh; echo "exit $?"
step one
failed at line 5
exit 1
```

A mensagem do próprio `cp` foi jogada fora pelo `2>/dev/null`, e o script teria parado em silêncio —
que é o que o `set -e` faz sozinho. Três palavras e um número de linha em vez disso.

Não é perfeito: o `$LINENO` dentro de uma função informa a linha dentro da função. Mas "failed at
line 5" é muito mais que nada, e custa uma linha no topo do arquivo.

## Mais dois hábitos

**Tudo por uma variável só.** `work=$(mktemp -d …)` uma vez, e então `"$work/status"`,
`"$work/slow"`. Um trap limpa tudo aquilo, e nada no script nomeia o `/tmp` de novo.

**O `TMPDIR` é respeitado pelo `mktemp` quando você não dá um modelo:**

```
ana@vm:~/work/scripts$ TMPDIR=/home/ana/work mktemp
/home/ana/work/tmp.oyq8gILcPd
```

Então `t=$(mktemp)` põe o arquivo onde o ambiente disser, o que importa em sistemas em que o `/tmp`
é pequeno, ou em que um gerenciador de serviços deu a cada unidade um privado. Um modelo com
`/tmp/…` fixo abre mão disso.
