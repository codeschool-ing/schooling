---
title: Ler linhas, e as quatro coisas que dão errado
version: 1
---

O laço que lê um arquivo linha a linha tem uma linha e quatro armadilhas dentro. Aqui está ele com
as quatro já evitadas:

```
ana@vm:~/work/scripts$ cat readloop.sh
#!/bin/bash
n=0
while IFS= read -r line; do
  n=$((n+1))
  echo "$n: $line"
done < "$1"
echo "read $n lines"
ana@vm:~/work/scripts$ ./readloop.sh ~/work/logs/app.log | head -4
1: app started
2: app ready
3: app handled a request
4: app started
```

O `read` tira uma linha da entrada padrão, põe numa variável, e sai com código diferente de zero no
fim do arquivo — que é o que para o `while`. O redirecionamento está no `done`, alimentando o laço
inteiro.

**`while IFS= read -r line` é um idioma só, para digitar como uma coisa só.** Aqui está o que cada
pedaço compra.

## O `-r`, para barras invertidas

```
ana@vm:/tmp/q2$ cat -A tricky.txt
C:\path\to\file$
   padded   $
ana@vm:/tmp/q2$ while read line; do echo "[$line]"; done < tricky.txt
[C:pathtofile]
[padded]
ana@vm:/tmp/q2$ while IFS= read -r line; do echo "[$line]"; done < tricky.txt
[C:\path\to\file]
[   padded   ]
```

**Sem o `-r`, o `read` trata a `\` como caractere de escape e a come.** Um caminho do Windows
perdeu os três separadores. E qualquer outra coisa que contivesse uma barra invertida também.

Não existe caso em que você queira esse comportamento ao ler dados. `-r` sempre.

## O `IFS=`, para espaço em branco

Olhe a segunda linha da mesma saída. `   padded   ` voltou como `padded`.

**O `read` divide no `$IFS` e remove espaço em branco do começo e do fim** antes de atribuir.
Definir `IFS=` vazio durante aquele `read` desliga isso, e a linha chega como está no arquivo.

O `IFS=` vai *na frente do `read`*, que é a forma um-comando-uma-variável da seção 03 — ela se
aplica àquele `read` e a mais nada, então o resto do script continua com o `IFS` normal.

## O `IFS=,`, quando você quer a divisão

O mesmo mecanismo, usado de propósito, é como se lê um arquivo delimitado:

```
ana@vm:~/work/scripts$ cat fields.sh
#!/bin/bash
while IFS=, read -r region rep quarter units revenue; do
  echo "$region/$rep sold $units for $revenue"
done < <(tail -n +2 "$1" | head -3)
ana@vm:~/work/scripts$ ./fields.sh ~/work/data/sales.csv
north/ana sold 171 for 8721
north/bruno sold 49 for 4116
south/carla sold 292 for 37084
```

**O `read` com vários nomes de variável divide a linha entre eles**, e o último fica com tudo que
sobrou — então `while read -r first rest` é "a primeira palavra e depois a linha".

Esta é uma alternativa genuína ao `cut` e ao `awk` quando você precisa dos campos num laço de shell
em vez de num filtro. Também é bem mais lenta — um `read` por linha, no shell — então para um
arquivo grande a resposta é o `awk` da aula 8 seção 14.

Dois limites que vale conhecer antes de construir um parser de CSV com isso: **ele não entende
campos entre aspas**, então uma vírgula dentro de `"Smith, Ana"` o quebra, e ele não entende
escapes. Para CSV de verdade, use um parser de verdade.

## O subshell, que é a invisível

```
ana@vm:~/work/scripts$ cat subshell.sh
#!/bin/bash
total=0
printf '%s\n' 10 20 30 | while read -r n; do
  total=$((total + n))
done
echo "after the pipe, total is $total"
total=0
while read -r n; do
  total=$((total + n))
done < <(printf '%s\n' 10 20 30)
echo "after the redirect, total is $total"
ana@vm:~/work/scripts$ ./subshell.sh
after the pipe, total is 0
after the redirect, total is 60
```

A mesma aritmética, os mesmos três números, e o primeiro diz zero.

**Todo estágio de um pipeline roda num subshell**, então o laço à direita do `|` somou
corretamente — num processo filho, que então saiu e levou o `total` junto. O `./script.sh` versus
`source` da seção 02 é o mesmo mecanismo.

O conserto é `< <(comando)`, que se chama **substituição de processo**. Ela faz a saída de um
comando parecer um arquivo, então o laço lê de um redirecionamento e continua no shell atual.

| | |
|---|---|
| `cmd \| while read …` | o laço está num subshell. As variáveis não sobrevivem |
| `while read … done < arquivo` | sem subshell |
| `while read … done < <(cmd)` | sem subshell. **Esta é a de usar** |

O espaço em `< <(` importa — o `<(` é a substituição de processo e o primeiro `<` é o
redirecionamento.

## A última linha que some

```
ana@vm:/tmp/q2$ printf 'one\ntwo' > nonl.txt; cat -A nonl.txt
one$
twoana@vm:/tmp/q2$ while IFS= read -r l; do echo "[$l]"; done < nonl.txt
[one]
ana@vm:/tmp/q2$ while IFS= read -r l || [ -n "$l" ]; do echo "[$l]"; done < nonl.txt
[one]
[two]
```

O `nonl.txt` não tem quebra de linha na última linha — dá para ver no prompt colado no `two`. **O
laço leu uma linha e parou**, porque o `read` chegou ao fim do arquivo antes de uma quebra de
linha, devolveu diferente de zero, e o `while` acreditou nele.

O `read` mesmo assim atribuiu `two` à variável. Ele só informou falha ao mesmo tempo.

**O `|| [ -n "$l" ]` é o conserto**: continue se o `read` que falhou mesmo assim produziu alguma
coisa. Acrescente sempre que a entrada puder não vir de um programa bem-comportado — um arquivo que
alguém editou no Windows, a saída de uma ferramenta que esqueceu a quebra de linha final.

## Ler do terminal

O `-p` imprime um prompt, e imprime na **saída de erro**, o que você pode observar:

```
ana@vm:/tmp/q2$ read -rp 'Continue? [y/N] ' answer 2>/tmp/q2/e.txt
y
ana@vm:/tmp/q2$ echo "answer=[$answer]"; echo '--- stderr file:'; cat -A /tmp/q2/e.txt
answer=[y]
--- stderr file:
Continue? [y/N] ana@vm:/tmp/q2$ [[ $answer == [Yy]* ]] && echo 'treated as yes' || echo 'treated as no'
treated as yes
```

O prompt não estava na tela — ele foi para o arquivo, porque o `2>` o pegou. Redirecione a saída
*padrão* em vez disso e o prompt continua visível, que é o comportamento que você quer: um script
cuja saída está sendo capturada ainda faz a pergunta no terminal.

O `[[ $answer == [Yy]* ]]` é a correspondência de glob da seção 08, e aceita `y`, `Y`, `yes` e
`Yes` tratando uma resposta vazia — alguém só apertando enter — como não. **Padrão não** em
qualquer coisa destrutiva.

Mais uma coisa a saber: um `read` dentro de um laço que já está lendo um arquivo vai comer a próxima
linha do arquivo em vez de esperar o usuário — use `read -u 3` com um descritor explícito, ou
reestruture.

E o `-t 10` desiste depois de dez segundos, que é o que transforma um script que trava para sempre
no `cron` num que falha.
