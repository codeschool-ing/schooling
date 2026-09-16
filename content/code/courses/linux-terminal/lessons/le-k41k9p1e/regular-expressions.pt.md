---
title: Expressões regulares, a metade útil
version: 1
---

Uma expressão regular é um padrão que descreve um conjunto de strings. Há muita coisa nisso e você
precisa de umas doze peças, que é o que esta seção é.

Tudo aqui usa `grep -E`. A seção 06 explicou por quê: a sintaxe básica precisa de contrabarra na
frente da metade dela, sem benefício.

## Casando um caractere

```
ana@vm:~/work$ printf "cat\ncot\ncut\ncoat\n" | grep -E "c.t"
cat
cot
cut
ana@vm:~/work$ printf "cat\ncot\ncut\ncoat\n" | grep -E "c[ao]t"
cat
cot
ana@vm:~/work$ printf "cat\ncot\ncut\ncoat\n" | grep -E "c[^o]t"
cat
cut
```

| | |
|---|---|
| `.` | qualquer um caractere. **Não** "um ponto final" |
| `[abc]` | qualquer um destes |
| `[^abc]` | qualquer um **exceto** estes |
| `[a-z]`, `[0-9]` | faixas |

O `coat` não casou com nenhum dos três, porque os três descrevem exatamente três caracteres e `coat`
tem quatro.

**O `[^o]` quer dizer "um caractere que não é `o`", não "nenhum caractere".** Uma linha sem nada
entre o `c` e o `t` não casa com ele.

## Quantos

```
ana@vm:~/work$ printf "color\ncolour\n" | grep -E "colou?r"
color
colour
ana@vm:~/work$ printf "a\naa\naaa\n" | grep -E "^a{2,}$"
aa
aaa
```

| | |
|---|---|
| `?` | zero ou um |
| `*` | zero ou mais |
| `+` | um ou mais |
| `{2}` | exatamente dois |
| `{2,}` | dois ou mais |
| `{2,5}` | entre dois e cinco |

**Eles se aplicam à coisa imediatamente antes deles**, então `ab*` é "um `a` e depois qualquer
quantidade de `b`", e `(ab)*` é "qualquer quantidade de `ab`".

## Onde

```
ana@vm:~/work$ printf "2026-09-15\nnot a date\n15/09/2026\n" | grep -E "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"
2026-09-15
```

| | |
|---|---|
| `^` | o começo da linha |
| `$` | o fim da linha |
| `\b` | um limite de palavra — o `grep -w` é a versão legível |

**O `^` e o `$` juntos são como se diz "exatamente isto e mais nada".** Sem eles, aquele padrão
também casaria com uma linha que tem uma data no meio, o que normalmente não é o que você quis
dizer.

E repare que o `^` quer dizer duas coisas diferentes: **no começo de um padrão ele é uma âncora;
dentro de `[ ]` ele é negação.** O `[^^]` é um caractere que não é um acento circunflexo, e é legal.

## Alternativas e grupos

```
ana@vm:~/work$ printf "cat\ndog\nbird\n" | grep -E "cat|dog"
cat
dog
ana@vm:~/work$ grep -cE "^(10|198)\." logs/access.log
997
```

O `|` é "ou". Os `( )` agrupam, tanto para o `|` quanto para repetição.

No `grep` básico aqueles precisam ser escritos `\|` e `\( \)`, que é o imposto que o `-E` remove.

## O que pega todo mundo

```
ana@vm:~/work$ printf "10.50\n10050\n10x50\n" | grep -E "10.50"
10.50
10050
10x50
ana@vm:~/work$ printf "10.50\n10050\n10x50\n" | grep -E "10\.50"
10.50
ana@vm:~/work$ printf "10.50\n10050\n10x50\n" | grep -F "10.50"
10.50
```

**O primeiro padrão casou com as três linhas**, porque o `.` é qualquer caractere e tanto `10050`
quanto `10x50` têm um ali.

Dois consertos, e eles são para situações diferentes. **O `\.` escapa o ponto** quando o resto do
padrão ainda é um padrão. **O `-F` desliga a linguagem de padrões inteira** quando ele não é — que é
a resposta certa para um endereço IP, um número de versão, um caminho de arquivo, e qualquer coisa
que um usuário digitou.

Os caracteres que precisam de escape numa expressão estendida são `. ^ $ * + ? ( ) [ ] { } | \`.
Pegar o `-F` é mais fácil do que lembrar dessa lista.

## Classes de caracteres com nome

O `[[:digit:]]` e o `[0-9]` fazem a mesma coisa, e as com nome valem conhecer porque são sensíveis ao
locale e legíveis:

| | |
|---|---|
| `[[:digit:]]` | `0-9` |
| `[[:alpha:]]` | letras |
| `[[:alnum:]]` | letras e dígitos |
| `[[:space:]]` | espaço, tabulação, quebra de linha |
| `[[:upper:]]`, `[[:lower:]]` | caixa |

Os colchetes duplos parecem erro e não são: o par de fora é a classe de caracteres, o de dentro é o
nome. O `[[:digit:].]` é "um dígito ou um ponto final".

## Guloso, e por que isso te surpreende

```
ana@vm:~/work$ grep -oE "\"[A-Z]+ [^ ]+" logs/access.log | head -3
"GET /static/app.js
"GET /
"POST /index.html
```

Aquilo funciona porque o `[^ ]+` para num espaço. A versão que não funciona é `".*"` numa linha com
duas strings entre aspas: **o `*` e o `+` pegam o máximo que conseguem**, então o `.*` entre duas
aspas casa da primeira aspas até a *última*, engolindo tudo no meio.

O conserto numa expressão básica é dizer o que você quer de fato — `[^"]*` em vez de `.*` — porque o
grep não tem quantificador preguiçoso. **"Qualquer coisa exceto o delimitador" é quase sempre o que
você queria mesmo.**

## O que guardar

Umas doze peças, e a disciplina é: **teste o padrão em três linhas antes de rodar num milhão.** Um
`printf` e um pipe, como em toda transcrição desta página, leva dez segundos e pega o `.*` guloso e o
ponto sem escape antes que eles importem.

O `grep -o` é a outra metade dessa disciplina: ele imprime **o que casou** em vez da linha que
continha aquilo, então dá para ver se o padrão pegou o que você esperava.
