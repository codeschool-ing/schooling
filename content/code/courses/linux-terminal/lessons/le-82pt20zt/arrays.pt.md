---
title: Arrays, para quando uma lista de palavras não basta
version: 1
---

Uma variável comum guarda uma string. Ponha uma lista de nomes de arquivo numa delas, separados por
espaços, e você recriou todos os problemas da seção 04. Um array guarda uma lista de valores e
preserva as fronteiras.

```
ana@vm:/tmp/q2$ hosts=(web01 web02 'db 01')
ana@vm:/tmp/q2$ echo "${hosts[0]} / ${hosts[2]}"
web01 / db 01
ana@vm:/tmp/q2$ echo "count: ${#hosts[@]}"
count: 3
```

| | |
|---|---|
| `arr=(a b c)` | criar. Espaços separam, aspas agrupam |
| `${arr[0]}` | um elemento. **Os índices começam em zero** |
| `${arr[@]}` | todos |
| `${#arr[@]}` | quantos |
| `${!arr[@]}` | os índices |
| `arr+=(d)` | acrescentar |

**Cada um deles precisa de chaves.** O `$arr[0]` é a variável `arr` seguida de `[0]`, que não é o
que você quer e não dá erro.

E o `$arr` sozinho é o `${arr[0]}` — o primeiro elemento, em silêncio:

```
ana@vm:/tmp/q2$ arr=(one two three); echo "[$arr]"; echo "[${arr[0]}]"
[one]
[one]
```

Um array que parece ter perdido tudo depois do primeiro item normalmente só perdeu o `[@]` dele.

## `"${arr[@]}"`, com as aspas

Exatamente a mesma regra do `"$@"` da seção 05, pelo mesmo motivo:

```
ana@vm:/tmp/q2$ for h in "${hosts[@]}"; do echo "[$h]"; done
[web01]
[web02]
[db 01]
ana@vm:/tmp/q2$ for h in ${hosts[@]}; do echo "[$h]"; done
[web01]
[web02]
[db]
[01]
```

**O `"${arr[@]}"` dá uma palavra por elemento.** Sem aspas, os elementos são divididos de novo e o
array de três elementos vira quatro palavras.

O `${arr[*]}` entre aspas duplas junta tudo numa string, como o `"$*"`. Serve para imprimir, não
para iterar.

## Fazer um crescer

```
ana@vm:/tmp/q2$ hosts+=(cache01); echo "${hosts[@]}"
web01 web02 db 01 cache01
ana@vm:/tmp/q2$ echo "indices: ${!hosts[@]}"
indices: 0 1 2 3
ana@vm:/tmp/q2$ unset 'hosts[1]'; echo "indices now: ${!hosts[@]}"
indices now: 0 2 3
```

**O `unset` deixa um buraco.** Índices 0, 2 e 3, com nada no 1 — arrays do bash são esparsos, então
o `${#arr[@]}` é o número de elementos que existem, não o maior índice mais um. Nunca itere sobre
um array com `for ((i=0; i<${#arr[@]}; i++))`; itere sobre `"${arr[@]}"`, ou sobre `"${!arr[@]}"` se
você precisa dos índices.

## Preencher a partir de um glob

```
ana@vm:/tmp/q2$ cd /tmp/q2 && files=(*.txt); echo "${#files[@]} files: ${files[*]}"
2 files: nonl.txt tricky.txt
```

**`files=(*.log)` é a forma segura de guardar uma lista de nomes de arquivo**, porque o shell
montou a lista e cada nome é um elemento, com quantos espaços tiver. Combinado com o
`shopt -s nullglob` da seção 10, o `${#files[@]}` é então uma contagem verdadeira, inclusive zero.

A partir da saída de um comando, a grafia é o `mapfile`:

```
ana@vm:/tmp/q2$ mapfile -t lines < ~/work/logs/app.log; echo "${#lines[@]} lines"
30 lines
ana@vm:/tmp/q2$ mapfile users < /etc/passwd; echo "[${users[0]}]"
[root:x:0:0:root:/root:/bin/bash
]
```

**O `-t` tira a quebra de linha final** de cada linha. Sem ele, todo elemento termina em uma —
repare onde o colchete de fechamento foi parar. O `mapfile` também se chama `readarray`; são o
mesmo builtin. Ele lê de um redirecionamento, então `mapfile -t x < <(cmd)` é como se preenche um a
partir de um comando.

Não use `arr=($(comando))` para isso. Ele divide no espaço em branco e passa os resultados por
globbing — o mesmo bug do `for f in $(ls)`, numa forma que parece mais deliberada.

## Passar um array para um comando

```sh
rsync_opts=(-a --delete --exclude '*.tmp')
rsync "${rsync_opts[@]}" src/ dst/
```

Esta é a resposta ao problema do `cmd $FLAGS` da seção 04. A versão com string quebra no momento
em que uma opção tem espaço — o `--exclude '*.tmp'` vira três argumentos — e a versão com array não
tem como, porque cada elemento continua sendo um argumento.

**Quando você se pegar montando uma linha de comando numa variável, monte num array.**

## Arrays associativos

```
ana@vm:/tmp/q2$ declare -A color; color[apple]=red; color[lime]=green
ana@vm:/tmp/q2$ echo "${color[apple]}"; for k in "${!color[@]}"; do echo "$k=${color[$k]}"; done
red
lime=green
apple=red
```

**`declare -A` primeiro, sempre.** Veja o que acontece sem ele:

```
ana@vm:/tmp/q2$ unset c; c[apple]=red; c[lime]=green; declare -p c
declare -a c=([0]="green")
ana@vm:/tmp/q2$ unset d; declare -A d; d[apple]=red; d[lime]=green; declare -p d
declare -A d=([lime]="green" [apple]="red" )
```

O `declare -a` — minúsculo — é um array *indexado*, e o bash avaliou `apple` e `lime` como
aritmética, onde um nome não definido é zero. As duas atribuições foram para o elemento 0 e a
segunda sobrescreveu a primeira. **Nenhum erro, nenhum aviso: um valor onde você esperava um
dicionário**, e o `declare -p` é como você descobre.

O `${!color[@]}` dá as chaves. **A ordem não é a de inserção** e não é ordenada; é o que a tabela
hash produzir. Se você precisa de ordem, passe as chaves pelo `sort`.

Arrays associativos são do bash 4 em diante. Isso é tudo que é atual, e não é o bash de sistema do
macOS, que ainda é 3.2 por razões de licenciamento — se um script precisa rodar lá, ele não os tem.

## Quando um array é a resposta errada

Arrays do bash são unidimensionais e guardam strings. Não há array de arrays, não há como passar um
array para uma função pelo nome sem truques com `declare -n`, e não há como guardar nada
estruturado.

**Um script que quer uma lista de registros, cada um com campos, cresceu além do bash.** Isso não é
uma crítica ao bash; é a fronteira que o vídeo de encerramento traça.
