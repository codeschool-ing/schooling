---
title: Depuração, e a ferramenta que lê o seu script por você
version: 1
---

Quatro coisas, na ordem em que você deve pegá-las.

## O `bash -n`, antes de rodar

```
ana@vm:~/work/scripts$ cat typo.sh
#!/bin/bash
for i in 1 2 3; do
  echo "$i"
done
if [ 1 -eq 1 ]; then
  echo yes
ana@vm:~/work/scripts$ bash -n typo.sh; echo "exit $?"
typo.sh: line 7: syntax error: unexpected end of file
exit 2
```

**O `-n` analisa o arquivo e não o roda.** O `fi` faltando é achado em um décimo de segundo, sem
executar as três linhas antes dele.

Repare para onde ele aponta: **a linha 7 é o fim do arquivo**, não a linha 5 onde está o `if`. Um
shell não tem como saber qual bloco não terminado você quis dizer, então o erro sempre cai lá
embaixo. Quando o `bash -n` diz "unexpected end of file", a resposta é um `fi`, `done`, `esac` ou
`}` faltando e você procura a partir do topo.

O `-n` pega sintaxe e mais nada. Um script que analisa limpo ainda pode fazer algo terrível.

## O `shellcheck`, que é o importante

```
ana@vm:~/work/scripts$ cat buggy.sh
#!/bin/bash
files=$1
count=`ls $files | wc -l`
if [ $count > 5 ]; then
  echo "many files"
fi
for f in $(ls $files); do
  rm $f
done
ana@vm:~/work/scripts$ shellcheck buggy.sh

In buggy.sh line 3:
count=`ls $files | wc -l`
      ^-----------------^ SC2006 (style): Use $(...) notation instead of legacy backticks `...`.
       ^-------^ SC2012 (info): Use find instead of ls to better handle non-alphanumeric filenames.
          ^----^ SC2086 (info): Double quote to prevent globbing and word splitting.

Did you mean: 
count=$(ls "$files" | wc -l)


In buggy.sh line 4:
if [ $count > 5 ]; then
     ^----^ SC2086 (info): Double quote to prevent globbing and word splitting.
            ^-- SC2071 (error): > is for string comparisons. Use -gt instead.

Did you mean: 
if [ "$count" > 5 ]; then


In buggy.sh line 7:
for f in $(ls $files); do
         ^----------^ SC2045 (error): Iterating over ls output is fragile. Use globs.
              ^----^ SC2086 (info): Double quote to prevent globbing and word splitting.

Did you mean: 
for f in $(ls "$files"); do


In buggy.sh line 8:
  rm $f
     ^-- SC2086 (info): Double quote to prevent globbing and word splitting.

Did you mean: 
  rm "$f"
```

Nove linhas de script. Ele analisa limpo, o `bash -n` está satisfeito com ele, e há um bug em cada
linha — quatro aspas faltando, crases, iteração sobre `ls`, e uma comparação que não é uma
comparação.

Cada um desses é algo desta aula. A seção 141 é o `SC2086`, a seção 147 é o `SC2045`, a seção 151 é
o `SC2006`, e o `SC2071` é a seção 145.

Instale — `apt install shellcheck`, `dnf install ShellCheck` — e rode antes de todo script que você
rodar pela primeira vez. **Ele não é um verificador de estilo com opiniões; ele acha bugs.**

### O que o `SC2071` é de fato

```
ana@vm:/tmp/q2$ cd /tmp/q2 && rm -rf ./* && count=3
ana@vm:/tmp/q2$ if [ $count > 5 ]; then echo 'many'; else echo 'few'; fi
many
ana@vm:/tmp/q2$ ls -l
total 0
-rw-r--r-- 1 ana ana 0 Sep 15 10:06 5
ana@vm:/tmp/q2$ if [ $count -gt 5 ]; then echo 'many'; else echo 'few'; fi
few
```

Três não é maior que cinco, e o script disse `many`.

**O `>` era um redirecionamento.** O `[ $count > 5 ]` rodou `[ 3 ]` com a saída redirecionada para
um arquivo chamado `5` — que o `ls` achou parado no diretório. `[ 3 ]` é "a string `3` é não
vazia", que é verdade, então o ramo do `then` rodou.

Resposta errada, nenhum erro, e um arquivo perdido. Esta é a classe de bug para a qual o
`shellcheck` existe: o script é válido, ele roda, e ele está errado.

## O `bash -x`, quando ele roda e faz a coisa errada

```
ana@vm:~/work/scripts$ bash -x traced.sh
+ total=0
+ for n in 3 4
+ total=3
+ for n in 3 4
+ total=7
+ echo 'total is 7'
total is 7
```

**O `-x` imprime todo comando depois da expansão, prefixado com `+`.** Depois da expansão é o ponto
inteiro: você vê `total=3`, não `total=$((total + n))`, então você vê os valores que o seu script de
fato tinha em vez dos que você supôs.

Ele vai para a saída de erro, então `bash -x script.sh 2>trace.log` guarda o rastro e a saída
separados.

Ligue para parte de um script com `set -x` e desligue com `set +x`, que é como se rastreia a única
função que está se comportando mal num script que imprime quatro mil linhas.

### O `PS4`, que o torna duas vezes mais útil

```
ana@vm:~/work/scripts$ PS4='+ ${BASH_SOURCE##*/}:${LINENO}: '
ana@vm:~/work/scripts$ bash -x traced.sh 2>&1 | head -8
+ total=0
+ for n in 3 4
+ total=3
+ for n in 3 4
+ total=7
+ echo 'total is 7'
total is 7
ana@vm:~/work/scripts$ export PS4; bash -x traced.sh 2>&1 | head -8
+ traced.sh:2: total=0
+ traced.sh:3: for n in 3 4
+ traced.sh:4: total=3
+ traced.sh:3: for n in 3 4
+ traced.sh:4: total=7
+ traced.sh:6: echo 'total is 7'
total is 7
```

O `PS4` é o prefixo que o `-x` usa, e o padrão é um `+` sozinho. Definir como arquivo e número de
linha transforma uma parede de comandos em algo que você consegue casar com o código-fonte — e
olhe a segunda e a terceira linhas da segunda execução: `3, 4, 3, 4` é o laço, visivelmente dando a
volta.

A primeira tentativa não fez nada, e essa é a parte que vale notar. **O `PS4` tem que ser
exportado**, porque o rastro é impresso pelo `bash` que você está iniciando, não pelo shell em que
você digitou.

Ponha no arquivo de inicialização do seu próprio shell e todo `-x` que você rodar na vida fica
melhor.

## Imprimir coisas

A técnica mais antiga, e a que você vai usar mais:

```sh
echo "DEBUG: f=[$f] count=[$count]" >&2
declare -p f count >&2
```

**Os colchetes são a técnica**, não enfeite — eles te mostram o espaço no fim, a string vazia, a
quebra de linha que o `echo` sozinho esconderia. O `declare -p` (seção 140) faz isso direito, com
tipos e aspas.

E o `>&2`, para a sua depuração não acabar no arquivo que o script está escrevendo.

## Em que ordem

| | |
|---|---|
| ele não roda | `bash -n` |
| antes de rodar algo novo | `shellcheck` |
| ele roda e faz a coisa errada | `bash -x`, com o `PS4` exportado |
| você sabe mais ou menos onde | `echo "…[$var]…" >&2` |

E um hábito que vale mais que os quatro: **rode a versão destrutiva por último.** Ponha um `echo` na
frente do `rm`, olhe as vinte linhas que ele imprime, e então tire o `echo`. A seção 134 fez o mesmo
argumento sobre o `xargs`, e é o mesmo argumento aqui.
