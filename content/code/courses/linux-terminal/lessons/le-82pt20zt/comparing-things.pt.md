---
title: Comparar coisas, e por que o `[[` existe
version: 1
---

Números e strings não se comparam do mesmo jeito, e o shell te obriga a dizer qual você quis.

```
ana@vm:/tmp/q$ x=10; y=9
ana@vm:/tmp/q$ [ "$x" -gt "$y" ] && echo 'numeric: 10 > 9'
numeric: 10 > 9
ana@vm:/tmp/q$ [ "$x" \> "$y" ] && echo 'string: 10 > 9' || echo 'string: 10 is not > 9'
string: 10 is not > 9
```

**Dez é maior que nove, e `"10"` vem antes de `"9"` na ordenação.** As duas respostas estão certas;
só uma delas é a pergunta que você fez.

| números | strings | |
|---|---|---|
| `-eq` | `=` | igual |
| `-ne` | `!=` | diferente |
| `-lt` `-le` | `\<` | menor |
| `-gt` `-ge` | `\>` | maior |

**As letras são para números, os símbolos são para strings**, que é exatamente o contrário de toda
outra linguagem e é o motivo de dizer isso em voz alta uma vez.

E a `\` no `\<` é porque o `<` dentro de `[ ]` é um redirecionamento — a seção 154 tem esse bug
pego em flagrante.

## Vazio

```
ana@vm:/tmp/q$ [ -z "$empty" ] && echo 'empty is empty'
empty is empty
ana@vm:/tmp/q$ [ -n "$x" ] && echo 'x is not empty'
x is not empty
```

O `-z` é comprimento zero, o `-n` é comprimento diferente de zero. As aspas no `-n` não são
opcionais:

```
ana@vm:/tmp/q2$ empty=; [ -n $empty ] && echo 'says non-empty' || echo 'says empty'
says non-empty
ana@vm:/tmp/q2$ empty=; [ -n "$empty" ] && echo 'says non-empty' || echo 'says empty'
says empty
```

**Sem aspas, `[ -n $empty ]` virou `[ -n ]`** — o `[` com um único argumento, que é verdadeiro
sempre que esse argumento é uma string não vazia, e `-n` é uma string não vazia. O teste respondeu
uma pergunta sobre a palavra `-n`.

## As aspas não são conselho aqui

```
ana@vm:/tmp/q$ empty=
ana@vm:/tmp/q$ [ $empty = yes ]; echo "status $?"
bash: [: =: unary operator expected
status 2
ana@vm:/tmp/q$ [ "$empty" = yes ]; echo "status $?"
status 1
ana@vm:/tmp/q$ [[ $empty = yes ]]; echo "status $?"
status 1
```

Três jeitos de fazer a mesma pergunta. O primeiro é erro de sintaxe, porque o `[` recebeu `= yes ]`
e não existe esse teste. O segundo funciona. **O terceiro funciona sem as aspas**, e é para isso
que o `[[ ]]` serve.

Repare também no código: **o `[` devolve 2 para "você me perguntou algo malformado"**, distinto do
1 para "falso". Um script testando `if [ … ]` não consegue diferenciar os dois, que é mais um
motivo para não chegar nesse estado.

## O `[[ ]]`, que é bash e não é um comando

O `[[` é sintaxe do shell — não um programa — então o shell analisa o que está dentro dele em vez
de expandir tudo em argumentos primeiro. Três coisas decorrem disso.

**Sem divisão em palavras e sem globbing**, como acima.

**O `<` e o `>` querem dizer comparação**, sem escape.

**E o `==` faz correspondência de glob:**

```
ana@vm:/tmp/q2$ name=report.log
ana@vm:/tmp/q2$ [[ $name == *.log ]] && echo match || echo 'no match'
match
```

Aquilo é um padrão, não uma string. `[[ $host == web* ]]`, `[[ $f == *.tar.gz ]]` — a mesma sintaxe
do `case` da próxima seção, e a mesma sintaxe do globbing da seção 45.

Ponha aspas no lado direito e ele vira literal de novo:

```
ana@vm:/tmp/q2$ name=report.log; [[ $name == "*.log" ]] && echo match || echo 'no match'
no match
```

Aquilo comparou com os cinco caracteres `*.log`. O que é ocasionalmente o que você quer, e é sempre
o que você obtém sem querer quando põe aspas por hábito.

### O que o `[` faz com a mesma linha

Vale observar de perto, porque ele falha de três jeitos diferentes conforme o que há no diretório:

```
ana@vm:/tmp/q2$ cd /tmp/q2 && rm -f *.log && ls
ana@vm:/tmp/q2$ name=report.log
ana@vm:/tmp/q2$ [ "$name" == *.log ] && echo match || echo 'no match'
no match
ana@vm:/tmp/q2$ touch other.log && ls
other.log
ana@vm:/tmp/q2$ [ "$name" == *.log ] && echo match || echo 'no match'
no match
ana@vm:/tmp/q2$ touch third.log && ls
other.log  third.log
ana@vm:/tmp/q2$ [ "$name" == *.log ] && echo match || echo 'no match'
bash: [: too many arguments
no match
ana@vm:/tmp/q2$ [[ $name == *.log ]] && echo match || echo 'no match'
match
```

Uma linha de script, três resultados, decididos por arquivos que ela nunca mencionou:

| arquivos presentes | o que o `[` de fato recebeu | resultado |
|---|---|---|
| nenhum | `report.log == *.log` — o glob não casou com nada, então ficou literal | falso |
| um | `report.log == other.log` | falso, **pelo motivo errado** |
| dois | `report.log == other.log third.log` | argumentos demais |

**O shell expandiu o padrão antes de o `[` sequer rodar**, porque o `[` é um comando e é isso que
acontece com os argumentos de um comando. A linha do meio é a de se assustar: nenhum erro, uma
resposta, e a resposta depende do diretório de trabalho.

### Expressões regulares

```
ana@vm:/tmp/q$ [[ $name =~ ^report\.[a-z]+$ ]] && echo 'matches the regex'
matches the regex
ana@vm:/tmp/q$ echo "BASH_REMATCH: ${BASH_REMATCH[0]}"
BASH_REMATCH: report.log
```

O `=~` recebe uma expressão regular estendida — a sintaxe da seção 125 — e preenche o
`BASH_REMATCH` com o que casou e com os grupos de captura.

**Não ponha aspas no padrão.** A mesma armadilha do `==`, e é mais silenciosa, porque uma regex
entre aspas nunca dá erro — ela só nunca casa:

```
ana@vm:/tmp/q2$ n=42; [[ $n =~ "^[0-9]+$" ]] && echo match || echo 'no match'
no match
ana@vm:/tmp/q2$ n=42; [[ $n =~ ^[0-9]+$ ]] && echo match || echo 'no match'
match
ana@vm:/tmp/q2$ re='^[0-9]+$'; [[ $n =~ $re ]] && echo match || echo 'no match'
match
```

A terceira linha é o idioma para um padrão longo: ponha numa variável, entre aspas simples, e então
use a variável **sem aspas**.

A única coisa para a qual o `=~` é genuinamente a ferramenta certa é validar um argumento:

```sh
[[ $threshold =~ ^[0-9]+$ ]] || die "-t wants a number, got '$threshold'"
```

## Testes de arquivo

```
ana@vm:/tmp/q2$ ls -l
total 8
lrwxrwxrwx 1 ana ana    7 Sep 15 10:02 broken -> nowhere
drwxr-xr-x 2 ana ana 4096 Sep 15 10:02 d
-rw-r--r-- 1 ana ana    0 Sep 15 10:02 empty
-rw-r--r-- 1 ana ana    5 Sep 15 10:02 f
lrwxrwxrwx 1 ana ana    1 Sep 15 10:02 good -> f
ana@vm:/tmp/q2$ for t in -e -f -d -s -x -L; do [ $t f ] && echo "$t yes" || echo "$t no"; done
-e yes
-f yes
-d no
-s yes
-x no
-L no
```

| | |
|---|---|
| `-e` | existe |
| `-f` | existe e é um arquivo **comum** |
| `-d` | é um diretório |
| `-s` | existe e **não está vazio** |
| `-r` `-w` `-x` | você pode ler / escrever / executar |
| `-L` | é um link simbólico |
| `a -nt b` | `a` é mais novo que `b` |

Dois deles têm uma sutileza que vale ter visto:

```
ana@vm:/tmp/q2$ [ -e broken ] && echo 'broken: exists' || echo 'broken: -e says no'
broken: -e says no
ana@vm:/tmp/q2$ [ -L broken ] && echo 'broken: -L says yes'
broken: -L says yes
ana@vm:/tmp/q2$ [ -s empty ] && echo 'empty has size' || echo 'empty: -s says no'
empty: -s says no
```

**O `-e` segue links simbólicos**, então um link quebrado não existe no que diz respeito a ele —
mesmo que o `ls` o mostre e o `rm` consiga apagá-lo. O `-L` é o que pergunta sobre o link em si.

E **o `-f` não é "tem um arquivo ali"** — é "tem um arquivo comum ali", o que exclui diretórios,
dispositivos e o tipo de coisa que é o `/dev/stdin`. Quando você quer dizer "consigo ler isto", o
`-r` diz com mais precisão que o `-f`.

## Qual colchete usar

**Use o `[[ ]]`.** Ele é mais seguro em todos os aspectos que importam: sem divisão, sem globbing
acidental, `&&` e `||` dentro dele, correspondência de padrões, expressões regulares.

Use o `[ ]` quando o script tiver `#!/bin/sh` no topo, porque o `[[` é bash e o dash não o tem —
seção 139. Esse é o único motivo.

E use qual usar, ponha aspas nas suas variáveis assim mesmo. O hábito vale mais que a exceção.
