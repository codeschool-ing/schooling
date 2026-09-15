---
title: O `if`, e o fato de que o `[` é um programa
version: 1
---

```
ana@vm:~/work/scripts$ cat grade.sh
#!/bin/bash
n=$1
if [ "$n" -ge 90 ]; then
  echo "excellent"
elif [ "$n" -ge 60 ]; then
  echo "pass"
else
  echo "fail"
fi
ana@vm:~/work/scripts$ ./grade.sh 95; ./grade.sh 70; ./grade.sh 12
excellent
pass
fail
```

A forma é `if … then … elif … else … fi`, o `then` precisa de um `;` ou de uma quebra de linha
antes dele, e o bloco termina com `fi`. Até aí é decorar.

O que não é decorar é o que vai entre o `if` e o `then`.

## O `if` não recebe uma condição. Ele recebe um comando.

**Não existe expressão booleana no shell.** O `if` roda um comando e olha o código de saída: zero
quer dizer then, qualquer outra coisa quer dizer else. A regra da seção 99, usada como controle de
fluxo.

```
ana@vm:~/work/scripts$ test -f /etc/hostname; echo $?
0
```

Então isto é legal, e quer dizer exatamente o que diz:

```
ana@vm:~/work$ if grep -q 'GET /health' logs/access.log; then echo 'it is in the log'; fi
it is in the log
```

**Nenhum colchete em lugar nenhum**, porque o `grep` já informa sucesso e falha. As pessoas
escrevem `if [ $(grep -c ERROR arquivo) -gt 0 ]` por hábito; o `grep -q` é mais curto, mais rápido
e para de ler na primeira ocorrência. O mesmo vale para `ping -c1 -W1 host`,
`systemctl is-active nginx`, `id -u alguem` — qualquer coisa cujo trabalho é responder uma pergunta
já a responde no `$?`.

## O `[` é um comando

```
ana@vm:~/work/scripts$ type [ ; ls -l /usr/bin/[
[ is a shell builtin
-rwxr-xr-x 1 root root 55744 Jun 22  2025 '/usr/bin/['
```

Existe um **arquivo em disco chamado `[`**. Ele não é pontuação, é um programa — o mesmo programa
que o `test`, que é por que o `[` exige um `]` de fechamento como último argumento, e por que ele
se escreve com espaços em volta.

```
ana@vm:~/work/scripts$ [ 1 -lt 2 ]; echo $?
0
ana@vm:~/work/scripts$ [ 1 -lt 0 ]; echo $?
1
```

`[ 1 -lt 2 ]` é o `[` rodado com quatro argumentos, o último dos quais é `]`. Esse fato sozinho
explica toda mensagem estranha que ele vai te dar algum dia:

```
ana@vm:~/work$ [1 -lt 2]
bash: [1: command not found
ana@vm:~/work$ x=; [ $x = y ]
bash: [: =: unary operator expected
ana@vm:~/work$ touch /tmp/q2/'a b'; [ /tmp/q2/a b ]
bash: [: /tmp/q2/a: unary operator expected
```

A primeira diz *command not found* porque `[1` é uma palavra e não existe esse comando. As outras
duas dizem *unary operator expected* porque o `[` conta os argumentos: com dois, ele espera um
teste como `-f`, e recebeu um `=` num caso e um nome de arquivo perdido no outro.

**Ele é um comando, então os argumentos dele são divididos e passados por globbing como os de
qualquer comando.** É essa a origem inteira do problema da seção 145.

## O `&&` e o `||`

```
ana@vm:~/work/scripts$ [ -d /etc ] && echo 'etc is a directory'
etc is a directory
ana@vm:~/work/scripts$ [ -d /nope ] || echo 'not a directory'
not a directory
```

| | |
|---|---|
| `a && b` | rode `b` só se `a` deu certo |
| `a \|\| b` | rode `b` só se `a` falhou |

São operadores de curto-circuito sobre o código de saída, e `mkdir -p x && cd x` é o uso do dia a
dia: faça a segunda coisa só se a primeira funcionou.

**`a && b || c` não é um if-então-senão**, e a diferença morde:

```
ana@vm:~/work$ true && echo b-ran || echo c-ran
b-ran
ana@vm:~/work$ true && false || echo 'c ran even though a succeeded'
c ran even though a succeeded
```

A primeira linha é o que todo mundo espera. Na segunda, `a` deu certo, `b` rodou e falhou, e `c`
rodou assim mesmo — porque o `||` está olhando para o código de tudo à esquerda dele, não para qual
ramo foi tomado. Serve bem para `[ -d x ] && echo yes || echo no`, em que o `echo` não pode falhar.
Para qualquer coisa em que o meio pode falhar, escreva o `if`.

## O `!`, e os pequenos

```sh
if ! command; then …            # negate
if [ -f a ] && [ -f b ]; then … # two tests, joined with the shell's own &&
if [ -f a -a -f b ]; then …     # test's own -a. Works, deprecated, avoid
```

**Dois `[ ]` separados unidos por `&&` é a grafia a usar.** O `-a` e o `-o` dentro de um `[` só são
obsolescentes no POSIX e ambíguos quando um valor se parece com um operador.

E três comandos que existem só para controle de fluxo:

| | |
|---|---|
| `true` | não faz nada, dá certo |
| `false` | não faz nada, falha |
| `:` | não faz nada, dá certo. O jeito mais curto de escrever "aqui não vai nada" |

`while true; do …; done` é um laço infinito, `|| true` é a válvula de escape da seção 143, e o `:` é
o que preenche um ramo que você ainda não escreveu — um `then` vazio é erro de sintaxe.

## Formatação

```sh
if [ "$n" -ge 90 ]; then          # the common one
if [ "$n" -ge 90 ]
then                              # also fine, and used in older scripts
```

O `;` antes do `then` está ali porque o `then` precisa começar um comando novo. Uma quebra de linha
faz o mesmo trabalho. As duas formas estão em todo lugar; nenhuma é mais correta.
