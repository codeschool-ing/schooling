---
title: O que o `go run` e o `go build` deixam para trás
version: 1
---

O `go run` parece um interpretador: você aponta um diretório, o programa roda e nenhum binário fica
no disco. **É um compilador com a saída escondida.** O `go run` e o `go build` passam pelos mesmos
passos, leem o mesmo código e guardam o trabalho no mesmo cache. O que muda é onde o executável
pronto vai parar e quem o inicia. Saber disso é o que permite prever quanto tempo um comando vai
levar, e por que um script nunca deve depender do status de saída do `go run`.

Tudo nesta lição roda sobre o `hits` da lição 1, copiado para um diretório próprio, `~/daily`: os
quatro arquivos que a lição 1 imprime, um `go.mod` criado com `go mod init example.com/hits` e as
20.000 linhas que `go run ./tools/genlog -n 20000 > access.log` escreve.

```
ana@vm:~/daily$ find . -type f | sort
./access.log
./go.mod
./internal/tally/tally.go
./main.go
./main_test.go
./tools/genlog/main.go
```

## Uma execução é um build e depois um exec

O comando go guarda tudo o que compila no **cache de build**, um diretório que ele indica em
`GOCACHE`. Para vê-lo trabalhar do zero, Ana aponta o `GOCACHE` para um diretório vazio durante
alguns comandos. É uma variável de ambiente comum, então o cache de verdade fica intocado:

```
ana@vm:~/daily$ go env GOCACHE
/home/ana/.cache/go-build
ana@vm:~/daily$ GOCACHE=/tmp/cold go build -o hits . && echo built
built
ana@vm:~/daily$ GOCACHE=/tmp/cold go run -x . top -n 1 access.log 2>&1 | grep -E "link -o|exe/hits|-d/hits" | cut -c1-96
GOROOT='/usr/local/go' /usr/local/go/pkg/tool/linux_amd64/link -o $WORK/b001/exe/hits -importcfg
go tool buildid -w $WORK/b001/exe/hits # internal
cp $WORK/b001/exe/hits /tmp/cold/ab/ab03424fdf182dd09ed40909f09aeec5e7408029cba36d37c18d058213c0
$WORK/b001/exe/hits top -n 1 access.log
ana@vm:~/daily$ GOCACHE=/tmp/cold go run -x . top -n 1 access.log 2>&1 | grep -E "link -o|exe/hits|-d/hits" | cut -c1-96
/tmp/cold/ab/ab03424fdf182dd09ed40909f09aeec5e7408029cba36d37c18d058213c08567-d/hits top -n 1 ac
```

O `-x` imprime cada comando que o comando go executa, umas cem linhas aqui, então o `grep` fica com
as quatro que importam e o `cut` as corta na largura da página. **O primeiro `go run` ligou um
executável num diretório temporário, `$WORK`, copiou-o para o cache e o executou.** Os pacotes de
que ele precisava já estavam compilados, pelo `go build` logo antes. Ainda assim foi preciso ligar,
porque o `go run` compila sem a informação que um depurador usa (o `go help run` diz isso), e o
executável dele é um arquivo diferente do que o `go build` escreveu. O segundo `go run` achou esse
executável no cache sob o mesmo hash, o que começa com `ab03424f`, e o iniciou direto: nada foi
compilado nem ligado.

A outra metade da diferença é quem inicia o programa. O `go run` é o processo pai, e ele não repassa
o status de saída do filho:

```
ana@vm:~/daily$ go run .; echo $?
usage: hits <command> [flags] [file]

commands:
  count   requests per status code
  top     the paths with the most requests

With no file, or with -, hits reads standard input.
exit status 2
1
```

O `hits` devolveu 2, por uma linha de comando sem subcomando, como a seção 04 da lição 1 o
projetou. O `go run` imprimiu `exit status 2` como mensagem e saiu com **1**, o mesmo que faz para
qualquer falha própria. O `go help run` diz isso numa linha: o status de saída do `go run` não é o
status de saída do binário compilado. **Um script, um `Makefile` ou um passo de CI que testa um
código de saída constrói o binário e o roda**, porque pelo `go run` um erro de uso e uma execução que
falhou ficam iguais.

## O cache de build, medido

Aqui está o mesmo `go build` duas vezes, cronometrado com o `time` do shell, no cache vazio:

```
ana@vm:~/daily$ time GOCACHE=/tmp/cold go build -o hits .

real	0m5.832s
user	0m10.743s
sys	0m4.385s
ana@vm:~/daily$ time GOCACHE=/tmp/cold go build -o hits .

real	0m0.078s
user	0m0.063s
sys	0m0.100s
ana@vm:~/daily$ du -sh /tmp/cold
43M	/tmp/cold
```

O primeiro build levou **5,8 segundos** e o segundo **0,078**, umas setenta e cinco vezes menos. Os
segundos da sua máquina vão diferir destes, e de uma execução para outra; o que se mantém é a
proporção. Quase todo o primeiro build foi a biblioteca padrão: o `hits` são dois pacotes pequenos e
depende de 79 pacotes no total, cada um compilado uma vez e guardado, 43 MB deles. O seu `GOCACHE`
de sempre já guarda a maior parte da biblioteca padrão de todos os builds que você rodou desde a
lição 3 do `go`, e é por isso que ali um build parece instantâneo até na primeira vez.

A chave do cache é **o que entra numa compilação**: o conteúdo dos arquivos de código, a versão do
compilador, as flags e a forma compilada de cada pacote importado. Datas de modificação não fazem
parte dela:

```
ana@vm:~/daily$ touch main.go internal/tally/tally.go; GOCACHE=/tmp/cold go build -v -o hits .
ana@vm:~/daily$ sed -i 's/want 5 fields/want five fields/' internal/tally/tally.go && GOCACHE=/tmp/cold go build -v -o hits .
example.com/hits/internal/tally
example.com/hits
ana@vm:~/daily$ sed -i 's/want five fields/want 5 fields/' internal/tally/tally.go
ana@vm:~/daily$ GOCACHE=/tmp/cold go build -a -v -o hits . 2>&1 | wc -l
79
```

O `-v` nomeia cada pacote à medida que ele é compilado, e depois do `touch` não nomeou nenhum,
porque os bytes não tinham mudado. Essa é a diferença em relação ao `make`, que compara datas de
modificação e teria recompilado os dois. O `sed` mudou uma mensagem no `tally.go`, e o `-v` nomeou
dois pacotes: o `tally` e o pacote `main` que o importa. Nada da biblioteca padrão foi compilado de
novo, e o segundo `sed` devolve a mensagem original. **O `-a` ignora o cache e recompila tudo**,
aqui 79 pacotes; é a flag para quando você desconfia do cache, e quase nunca a solução. O
`go clean -cache` esvazia o cache de vez. Ele não foi rodado neste laboratório, porque o que custa
são aqueles 5,8 segundos de novo, para cada pacote de cada projeto da máquina.

## O que vai parar onde

O `go build` só escreve um executável quando compila **exatamente um pacote `main`**. Dado um
pacote que não é `main`, ou vários pacotes, ele os compila, guarda os resultados no cache e joga o
produto final fora, de modo que o comando serve para conferir que tudo compila:

```
ana@vm:~/daily$ go build ./... && ls
access.log
go.mod
internal
main.go
main_test.go
tools
ana@vm:~/daily$ go build ./internal/tally && go build && ls
access.log
go.mod
hits
internal
main.go
main_test.go
tools
ana@vm:~/daily$ go build -o bin/ ./... && stat -c "%s bytes  %n" bin/*
2586446 bytes  bin/genlog
4031935 bytes  bin/hits
```

`./...` é o padrão para este diretório e todos os que estão abaixo dele: três pacotes aqui, dois
deles `main`, e nada foi escrito. O `go build ./internal/tally` também não escreveu nada. Um
`go build` sem argumentos compilou o pacote do diretório atual e deu ao arquivo o nome do último
elemento do caminho de importação, `example.com/hits`, por isso ele se chama `hits`. **O `-o` com
um diretório, escrito com a barra no fim, muda a regra**: cada pacote `main` da lista ganha ali um
executável, com o nome dado do mesmo jeito, e é assim que um comando só constrói os dois programas
em `bin/`. A seção 03 dá o passo seguinte, em que o executável vai para um diretório do seu `PATH`.
