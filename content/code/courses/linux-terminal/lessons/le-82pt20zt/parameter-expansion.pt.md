---
title: Expansão de parâmetro, ou como não chamar o `basename`
version: 1
---

O `${var}` tem uma segunda metade: um punhado de operadores que cortam, substituem e dão valor
padrão **sem rodar um programa**. Eles parecem crípticos, são uns doze, e quatro valem decorar.

## Cortar caminhos

```
ana@vm:~/work/scripts$ p=/var/log/nginx/access.log.1
ana@vm:~/work/scripts$ echo "${p##*/}"; echo "${p#*/}"
access.log.1
var/log/nginx/access.log.1
ana@vm:~/work/scripts$ echo "${p%/*}"; echo "${p%%.*}"
/var/log/nginx
/var/log/nginx/access
```

Dois caracteres, e o padrão é regular:

| | |
|---|---|
| `#` | remove pela **frente** |
| `%` | remove por **trás** |
| dobrado | remove a correspondência **mais longa** em vez da mais curta |

Então o `${p##*/}` é "remova a coisa mais longa terminada em barra" — que é o nome do arquivo, que é
o `basename`. E o `${p%/*}` é "remova a coisa mais curta começada em barra, a partir do fim" — que é
o diretório, que é o `dirname`.

```sh
${p##*/}     # basename, without a process
${p%/*}      # dirname,  without a process
```

O gancho para lembrar qual é qual: **o `#` fica à esquerda do `$` num teclado e o `%` fica à
direita.** É um mnemônico bobo e funciona.

O padrão é um glob, não uma expressão regular — a sintaxe da seção 45, a mesma do `case`.

### Extensões

```
ana@vm:~/work/scripts$ f=report.tar.gz; echo "${f%.tar.gz}"; echo "${f%.*}"
report
report.tar
```

O `${f%.*}` remove a correspondência mais curta, que é só a última extensão. O `${f%%.*}` removeria
a partir do primeiro ponto e daria `report`. Qual você quer depende de `.tar.gz` ser uma extensão ou
duas, e a resposta é que depende do arquivo — que é por que nomear o sufixo exato, como no primeiro
exemplo, é a versão que não tem como surpreender.

## Padrões e exigências

```
ana@vm:~/work/scripts$ unset v; echo "[${v:-default}] v is still [${v-unset}]"
[default] v is still [unset]
ana@vm:~/work/scripts$ unset v; echo "[${v:=assigned}] v is now [$v]"
[assigned] v is now [assigned]
ana@vm:~/work/scripts$ unset v; echo "${v:?the script needs v}"
bash: v: the script needs v
```

| | |
|---|---|
| `${v:-x}` | use `x` se `v` não estiver definida ou estiver vazia. **`v` não muda** |
| `${v:=x}` | use `x` e **atribua a `v`** |
| `${v:?msg}` | imprima `msg` no stderr e saia, se `v` não estiver definida ou estiver vazia |
| `${v:+x}` | use `x` só se `v` **estiver** definida. Senão, nada |

O `:-` é o do dia a dia — `rows="${2:-5}"`, `"${LOG_LEVEL:-info}"`.

**O `:?` é o que te salva do caminho vazio da seção 141.** Sob `set -u` uma variável não definida já
dá erro; o `:?` acrescenta a sua própria mensagem e também pega a variável que está definida mas
vazia, o que o `-u` não pega.

O `:+` é o mais raro e é genuinamente útil para montar uma opção opcional:

```
ana@vm:~/work/scripts$ unset T; echo "[${T:+-H \"auth $T\"}]"
[]
ana@vm:~/work/scripts$ T=abc; echo "[${T:+-H \"auth $T\"}]"
[-H "auth abc"]
```

Nada quando a variável não está definida, a opção inteira quando está — que é como
`curl ${TOKEN:+-H "Authorization: Bearer $TOKEN"} "$url"` manda o cabeçalho só quando há um token.

E lembre dos dois pontos da seção 140: sem eles, o teste é só "não definida", e uma string vazia
conta como valor.

```
ana@vm:~/work/scripts$ v=; echo "[${v:?needs a value}]"
bash: v: needs a value
ana@vm:~/work/scripts$ v=; echo "[${v?needs a value}]"
[]
```

Mesma variável, mesma mensagem, um caractere de diferença, e o segundo deixou uma string vazia
passar. **Escreva os dois pontos.**

## Substituir

```
ana@vm:~/work/scripts$ echo "${p/log/LOG}"; echo "${p//log/LOG}"
/var/LOG/nginx/access.log.1
/var/LOG/nginx/access.LOG.1
```

**Uma barra substitui a primeira ocorrência, duas barras substituem todas** — a mesma distinção da
opção `g` do `sed` na seção 131, e a mesma ordem de surpresa.

```
ana@vm:~/work/scripts$ echo "[${p//log/}]"; s=logfile; echo "[${s/#log/X}] [${s/%file/Y}]"
[/var//nginx/access..1]
[Xfile] [logY]
```

**Omita a substituição inteiramente e ele apaga** — repare na barra dupla e no ponto duplo onde o
texto foi removido. O `/#` ancora o padrão na frente e o `/%` atrás, que é como você substitui um
prefixo sem tocar nas mesmas letras em outro lugar da string.

Para qualquer coisa além disso, o `sed` é a ferramenta certa. Para exatamente isso, a expansão de
parâmetro é mais rápida, não tem problema de aspas e não bifurca.

## Comprimento, fatias, caixa

```
ana@vm:~/work/scripts$ echo "${#p}"
27
ana@vm:~/work/scripts$ echo "${p:5}"; echo "${p:5:3}"
log/nginx/access.log.1
log
ana@vm:~/work/scripts$ name=ana; echo "${name^^} ${name^}"
ANA Ana
ana@vm:~/work/scripts$ shout=ANA; echo "${shout,,}"
ana
```

| | |
|---|---|
| `${#v}` | comprimento em caracteres |
| `${v:n}` | do deslocamento `n` até o fim. **Deslocamentos começam em zero** |
| `${v:n:m}` | `m` caracteres a partir do deslocamento `n` |
| `${v^^}` `${v,,}` | maiúsculas, minúsculas. O `^` e o `,` fazem só o primeiro caractere |

O `${v^^}` e o `${v,,}` são do bash 4, e são o motivo de não passar uma variável pelo `tr` para algo
tão pequeno.

## Por que se dar ao trabalho

Cada um destes evita iniciar um processo:

```sh
name=$(basename "$path")     # forks
name=${path##*/}             # does not

lower=$(echo "$x" | tr A-Z a-z)   # forks twice
lower=${x,,}                      # does not
```

Numa linha não faz diferença mensurável. **Num laço sobre dez mil arquivos é a diferença entre um
segundo e meio minuto**, e é o motivo mais comum de um script de shell ser descrito como lento
quando a lentidão é inteiramente autoinfligida.

Há um segundo motivo, e é o melhor: o `${path##*/}` não tem como dar errado num nome de arquivo com
espaço, quebra de linha ou traço no começo, e o `$(basename $path)` tem.

## Os quatro para lembrar

```sh
${v:-default}     # a fallback
${v:?message}     # a requirement
${p##*/}          # the filename
${p%/*}           # the directory
```

O resto você vai consultar, e o fato de existirem é a parte que vale carregar.
