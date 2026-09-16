---
title: `$( )` e `$(( ))`, que se parecem e não têm relação
version: 1
---

Duas construções, um caractere de diferença, fazendo coisas completamente distintas.

| | |
|---|---|
| `$(comando)` | roda um comando, vira a **saída** dele |
| `$(( expressão ))` | avalia aritmética, vira o **número** |

## `$( )` — substituição de comando

```
ana@vm:~/work/scripts$ now=$(date +%F); echo "today is $now"
today is 2026-09-15
ana@vm:~/work/scripts$ n=$(wc -l < ~/work/logs/access.log); echo "[$n]"
[1200]
```

O comando roda num subshell, a saída padrão dele é capturada, e esse texto substitui o `$( )`
inteiro. A saída de erro **não** é capturada — ela vai para o terminal normalmente, o que
geralmente é o que você quer e é ocasionalmente por que uma mensagem de erro aparece no meio da sua
saída.

Repare no `wc -l < arquivo` em vez de `wc -l arquivo`:

```
ana@vm:~/work/scripts$ n=$(wc -l ~/work/logs/access.log); echo "[$n]"
[1200 /home/ana/work/logs/access.log]
```

Dado um nome de arquivo, o `wc` imprime o nome também, e aquilo não é um número. **Alimentar o
arquivo pela entrada padrão é como se obtém uma contagem pelada do `wc`**, e o mesmo truque vale
para qualquer ferramenta que rotula a saída quando conhece o nome do arquivo.

### Quebras de linha do fim são removidas

```
ana@vm:~/work/scripts$ printf 'a\n\n\n' > /tmp/q2/tn.txt; v=$(cat /tmp/q2/tn.txt); echo "[$v]"
[a]
```

Entraram três quebras de linha, não saiu nenhuma. **O `$( )` remove todas as quebras de linha do
fim**, que é por que `n=$(wc -l < arquivo)` te dá `1200` e não `1200` seguido de uma quebra.

Isso quase sempre ajuda e vale saber quando não ajuda — ler um arquivo para uma variável e escrevê-
lo de volta perde a quebra de linha final, e um arquivo sem ela causa o problema da seção 11.

### Crases

```
ana@vm:~/work/scripts$ old=`date +%F`; echo "backticks give $old"
backticks give 2026-09-15
```

`` `comando` `` é a grafia mais antiga e ainda funciona em todo lugar. Use o `$( )` assim mesmo:

```
ana@vm:~/work/scripts$ echo "nested: $(basename $(dirname /usr/local/bin/node))"
nested: bin
```

**Aninhar é o motivo.** A versão com crases precisa escapar a crase dentro de si mesma e fica
ilegível em dois níveis. O `$( )` aninha por ser parentizado de verdade.

O `shellcheck` aponta crases (SC2006) e sugere a substituição, que é uma das poucas regras de
estilo que vale aceitar sem discutir.

### É uma expansão, então ponha aspas

`"$(cmd)"`, pelos motivos da seção 04. Sem aspas, a saída é dividida no espaço em branco e passa
por globbing.

## `$(( ))` — aritmética

```
ana@vm:~/work/scripts$ echo $(( 7 / 2 )) $(( 7 % 2 )) $(( 2 ** 10 ))
3 1 1024
ana@vm:~/work/scripts$ i=5; echo $(( i * 3 ))
15
```

**Aritmética inteira apenas.** `7 / 2` é 3, não 3,5, e não há arredondamento — ele trunca.

Dentro do `$(( ))` uma variável não precisa do `$`: `i * 3` funciona porque a coisa inteira é um
contexto aritmético. As duas grafias servem e `$i * 3` é mais claro para quem lê e não decorou
isso.

Os operadores são os do C: `+ - * / %`, `**` para potência, `++ --`, `+= -=`, `== != < > <= >=`,
`&& || !`, e o ternário `a ? b : c`.

Comparações produzem 1 e 0:

```
ana@vm:~/work/scripts$ echo $(( 10 > 3 )) $(( 10 < 3 ))
1 0
```

O que é o contrário dos códigos de saída, em que 0 é sucesso — então o `$(( ))` serve para
calcular números, e o `[ ]` ou o `(( ))` serve para decidir.

O `(( ))` sem o `$` é a forma de instrução. Ele avalia e define o **código de saída**, com zero
querendo dizer que a expressão foi diferente de zero — então ele se lê naturalmente num `if`:

```
ana@vm:~/work/scripts$ echo $(( 5 > 3 )); (( 5 > 3 )); echo "exit $?"
1
exit 0
ana@vm:~/work/scripts$ echo $(( 3 > 5 )); (( 3 > 5 )); echo "exit $?"
0
exit 1
```

A mesma expressão, duas formas, números opostos. O `$(( ))` dá o valor; o `(( ))` traduz aquilo em
sucesso e falha.

E essa tradução é uma armadilha, que é melhor encontrar aqui do que em produção:

```
ana@vm:~/work/scripts$ cat counttrap.sh
#!/bin/bash
set -e
count=0
(( count++ ))
echo "count is now $count"
echo "never reached"
ana@vm:~/work/scripts$ ./counttrap.sh; echo "exit $?"
exit 1
```

**O script não imprimiu absolutamente nada.** O `count++` é pós-incremento: ele avalia para o valor
*antes* de incrementar, que era 0, que o `(( ))` informa como falha, que o `set -e` trata como
erro. O contador foi incrementado e o script morreu na mesma linha.

```
ana@vm:~/work/scripts$ count=0; (( count++ )); echo "status $?"
status 1
ana@vm:~/work/scripts$ count=0; (( ++count )); echo "status $?"
status 0
ana@vm:~/work/scripts$ count=0; count=$((count+1)); echo "status $? count $count"
status 0 count 1
```

Três jeitos de somar um. **Use o terceiro** — `count=$((count+1))` é uma atribuição, e uma
atribuição sempre dá certo. O `(( count++ )) || true` também funciona e diz menos sobre o porquê.

### O zero à esquerda

```
ana@vm:~/work/scripts$ echo $(( 08 + 1 ))
bash: 08: value too great for base (error token is "08")
ana@vm:~/work/scripts$ echo $(( 10#08 + 1 ))
9
```

**Um número com zero à esquerda é octal**, e não existe dígito 8 em octal.

Isso não é curiosidade, porque os números com mais chance de chegar com zero à esquerda são datas:

```
ana@vm:~/work/scripts$ d=08; echo $(( d + 1 ))
bash: 08: value too great for base (error token is "08")
```

O `date +%m` dá `08` em agosto e `09` em setembro, o `date +%d` dá `01` no dia primeiro, e cada um
desses é um script que funciona dez meses por ano. **O `10#` força base dez** e é o conserto; tirar
o zero com `${x#0}` é o outro, e ele quebra em `00`.

### Frações

```
ana@vm:~/work/scripts$ echo 'scale=3; 7/2' | bc
3.500
```

O `$(( ))` não consegue fazer isso de jeito nenhum. O `bc` consegue, o `awk` consegue, e a aula 8
seção 11 tratou dos dois. **Se o seu script precisa de uma porcentagem ou de uma média, quem está
fazendo a aritmética é um deles**, não o bash.

## O `let` e o `expr`

Você vai ver estes em scripts antigos:

```sh
let "n = n + 1"          # bash, older, no advantage over (( n++ ))
n=$(expr $n + 1)         # a separate process, per addition
```

O `expr` é um programa. Num laço ele bifurca uma vez por iteração, onde o `$(( ))` é de graça.
Nenhum dos dois é errado; nenhum dos dois vale escrever hoje.
