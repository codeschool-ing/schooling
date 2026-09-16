---
title: O `tr`, que trabalha com caracteres e não com palavras
version: 1
---

O `tr` traduz um conjunto de caracteres em outro. Ele não faz ideia do que é uma palavra, não faz
ideia do que é uma linha, e não tem linguagem de padrões — e é essa estreiteza que o torna a
ferramenta certa para quatro trabalhos específicos.

**Ele só lê a entrada padrão.** Não há argumento de nome de arquivo; `tr a-z A-Z < arquivo` ou um
pipe.

## Caixa

```
ana@vm:~/work$ echo "Hello World" | tr a-z A-Z
HELLO WORLD
```

O `tr '[:lower:]' '[:upper:]'` é a grafia sensível ao locale e é melhor em texto que não é inglês.

## Um caractere por outro

```
ana@vm:~/work$ echo "a,b,c" | tr , "\n"
a
b
c
ana@vm:~/work$ printf "a\tb\tc\n" | tr "\t" ","
a,b,c
```

**Transformar um delimitador em quebras de linha é a coisa mais útil que o `tr` faz**, porque
converte "uma linha com coisas nela" em "coisas, uma por linha" — que é a forma que toda outra
ferramenta desta aula quer.

Os dois conjuntos são pareados posição a posição: o `tr abc xyz` transforma todo `a` em `x`, `b` em
`y`, `c` em `z`. Se o segundo conjunto for menor, o último caractere dele é repetido.

## O `-d` apaga

```
ana@vm:~/work$ cut -d" " -f1 logs/access.log | tr -d "." | head -2
10016
100111
```

Todo ponto embora. Aquele exemplo é propositalmente bobo — os endereços agora não querem dizer nada —
e ele mostra o ponto: **o `tr -d` remove caracteres, sem fazer ideia se isso fazia sentido.**

Os usos reais são remover coisas que não deveriam estar lá:

```
tr -d '\r' < windows.txt > unix.txt     # strip carriage returns
tr -d '[:blank:]'                       # strip spaces and tabs
tr -dc '[:print:]\n'                    # keep only printable characters
```

**O `tr -d '\r'` é o que você vai precisar de verdade:**

```
ana@vm:~/work$ printf "line one\r\nline two\r\n" > /tmp/w.txt; cat -A /tmp/w.txt
line one^M$
line two^M$
ana@vm:~/work$ tr -d '\r' < /tmp/w.txt | cat -A
line one$
line two$
```

Um arquivo editado no Windows tem `\r\n` no fim de cada linha. O `cat -A` da seção 05 mostra isso
como `^M$`, e um script de shell com esses finais falha com um erro que nomeia um comando que você vê
que está escrito corretamente — porque o comando que ele de fato tentou rodar tinha um retorno de
carro invisível no fim do nome.

O `-c` complementa o conjunto, então o `-dc` é "apague tudo exceto". Aquela última linha é o
higienizador para um arquivo com caracteres de controle soltos.

## O `-s` comprime sequências

```
ana@vm:~/work$ head -2 logs/access.log | tr -s " " | cut -d" " -f1,6,7
10.0.1.6 "GET /static/app.js
10.0.1.11 "GET /
```

**Este é o conserto para o delimitador de um caractere da seção 08.** O `tr -s " "` transforma
qualquer sequência de espaços num único espaço, o que faz o `cut -d" "` funcionar em texto alinhado
com preenchimento em vez de separado por um caractere.

O `tr -s '\n'` agrupa linhas em branco — várias linhas vazias viram uma — o que arruma a saída antes
de você lê-la.

## Os quatro usos que valem lembrar

| | |
|---|---|
| `tr a-z A-Z` | caixa |
| `tr , '\n'` | dividir num caractere, um por linha |
| `tr -d '\r'` | tirar retornos de carro de um arquivo do Windows |
| `tr -s ' '` | comprimir sequências, para o `cut` funcionar |

## O que o `tr` não consegue fazer

**Ele não consegue substituir uma palavra:**

```
ana@vm:~/work$ echo "cat attack" | tr cat dog
dog oggodk
ana@vm:~/work$ echo "cat attack" | sed "s/cat/dog/g"
dog attack
```

O `tr cat dog` transforma todo `c` em `d`, todo `a` em `o` e todo `t` em `g`. O `cat` de fato vira
`dog` — que é por que isso parece funcionar até você dar uma segunda palavra. Substituir uma palavra
é o `sed` da seção 13.

**Ele não tem padrões.** Sem `.`, sem `*`, sem âncoras. Conjuntos de caracteres e nada mais.

**E ele não consegue inserir.** Os dois conjuntos têm o mesmo tamanho por construção, então um
caractere vira um caractere. Apagar é a única mudança de comprimento que ele consegue fazer.

Que é a linha divisória: **`tr` para caracteres, `sed` para padrões, `awk` para campos.** Pegar o
`sed` quando o `tr -d '\r'` bastaria é um desperdício comum e inofensivo; pegar o `tr` quando você
queria o `sed` produz `oggodk`.
