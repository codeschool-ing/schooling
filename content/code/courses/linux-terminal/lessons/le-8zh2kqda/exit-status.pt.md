---
title: Códigos de saída, e o que o `$?` está mesmo te dizendo
version: 1
---

A seção 03 disse que um processo termina entregando um número ao pai. Este é aquele número, e é a
única coisa que um programa pode dizer sobre como foi que outro programa consegue usar.

**Zero é sucesso. Todo o resto é falha.** Isso é ao contrário da maioria das coisas e é o jeito certo
aqui, porque há um jeito de dar certo e muitos de dar errado — então as falhas ficam com os números.

O `$?` é o código do último comando:

```
ana@vm:~/work$ true; echo $?
0
ana@vm:~/work$ false; echo $?
1
```

O `true` e o `false` são programas de verdade que não fazem nada além de sair com 0 e 1. Eles existem
para que scripts tenham algo com que dizer "sim" e "não".

## Os números que você vai encontrar

```
ana@vm:~/work$ ls /nosuchplace; echo $?
ls: cannot access '/nosuchplace': No such file or directory
2
ana@vm:~/work$ grep nosuchpattern README.md; echo $?
1
ana@vm:~/work$ nosuchcommand; echo $?
bash: nosuchcommand: command not found
127
ana@vm:~/work$ /etc/hostname; echo $?
bash: /etc/hostname: Permission denied
126
ana@vm:~/work$ bash -c "exit 42"; echo $?
42
```

| | |
|---|---|
| `0` | sucesso |
| `1` | a falha genérica, e o **"não achei nada" do `grep`** |
| `2` | por convenção, os argumentos estavam errados — o `ls` o usa para um caminho que não existe |
| `126` | achou, **não conseguiu rodar** — a permissão da aula 4 |
| `127` | **comando não encontrado** |
| `128+n` | morto pelo sinal `n` |
| qualquer | o que o programa escolheu. `exit 42` quer dizer 42 |

**O `126` e o `127` são os dois que valem decorar**, porque são os dois que você recebe do script em
vez de da coisa que o script estava tentando fazer. `127` num log é um erro de digitação ou um pacote
faltando; `126` é um arquivo sem o bit de execução, que é do que a seção 09 da aula 4 tratava.

**E o `1` do `grep` não é um erro.** Quer dizer que o padrão não estava lá, o que muitas vezes é a
resposta que você queria. O `pgrep` da seção 05 usa a mesma convenção pelo mesmo motivo.

## Sinais, dentro do código

```
ana@vm:~/work$ sh -c "kill -TERM \$\$"; echo $?
Terminated
143
ana@vm:~/work$ sleep 60
^C

ana@vm:~/work$ 
ana@vm:~/work$ echo $?
130
```

**128 mais o número do sinal.** O `TERM` é 15, então 143. O `INT` é 2, então 130 — que é o que você
recebe toda vez que aperta `Ctrl+C`, e é por isso que o 130 aparece tanto em logs. O `SIGPIPE` da
seção 08 era 141 pela mesma conta.

Então um código acima de 128 vale ser lido como uma subtração: **`137` é `128 + 9`, que é `SIGKILL`,
que muitíssimas vezes é o matador de falta de memória** e não uma pessoa. Esse fato sozinho explicou
mais reinícios misteriosos de contêiner do que qualquer outro número desta aula.

## Onde dá errado: pipelines

```
ana@vm:~/work$ false | true; echo $?
0
```

**O `false` falhou e o código é `0`.** O `$?` depois de um pipeline é o código do **último** comando,
e o último deu certo. Cada etapa antes dele pode falhar em silêncio.

É por isso que `curl badurl | tar xz` já estragou tardes: o `curl` falha, não imprime nada útil, e o
`tar` reporta o que achar da entrada vazia.

Dois jeitos de sair disso, e o bash tem os dois:

```
ana@vm:~/work$ false | true; echo "${PIPESTATUS[@]}"
1 0
ana@vm:~/work$ set -o pipefail
ana@vm:~/work$ false | true; echo $?
1
```

O `PIPESTATUS` é um array com **um código por etapa**, e é o único jeito de descobrir qual etapa
falhou. A seção 08 o usou para pegar o `yes` sendo morto pelo `SIGPIPE`.

**O `set -o pipefail` muda a regra**: o código do pipeline vira o último diferente de zero. Num
script que faz qualquer coisa com pipes, esta linha pertence ao topo, e o dia em que você precisa
dela é o dia em que você descobre que ela não estava lá.

## Usando: o `&&` e o `||`

```
ana@vm:~/work$ mkdir -p build && echo made it
made it
ana@vm:~/work$ ls /nosuchplace || echo "fell back"
ls: cannot access '/nosuchplace': No such file or directory
fell back
ana@vm:~/work$ test -f README.md && echo present
present
```

O `&&` roda a coisa seguinte **só se a anterior deu certo**; o `||` só se ela falhou. Eles são o `$?`
usado sem ser escrito, e são como a maior parte da lógica de shell é de fato escrita.

O `test` — também escrito `[ ]` — existe puramente para produzir um código: `test -f arquivo` é 0 se
o arquivo existe e 1 se não, e não imprime nada em nenhum dos casos. **É esse o projeto inteiro.** A
aula 9 é onde isso vira `if`.

## Em scripts

| | |
|---|---|
| `exit 0` | dizer que funcionou |
| `exit 1` | dizer que não |
| `set -e` | parar o script no primeiro comando que falhar |
| `set -o pipefail` | contar falhas dentro de pipelines |
| `set -u` | falhar numa variável não definida, que é outro bug e a mesma disciplina |

O `set -euo pipefail` é a linha no topo de um script bash bem-comportado, e agora cada pedaço dela
tem um motivo em vez de ser copiado. A aula 9 o desmonta direito, inclusive os lugares em que o
`set -e` não faz o que parece que faz.

**E dê códigos de verdade aos seus próprios scripts.** Um script que sempre sai com 0 não pode ser
usado por nada — nem pelo `&&`, nem pelo e-mail de falha de um job de cron, nem pelo
`Restart=on-failure` da aula 5, que lê exatamente este número para decidir se um serviço morreu ou
terminou. O número é a interface inteira entre o seu programa e tudo que o roda.
