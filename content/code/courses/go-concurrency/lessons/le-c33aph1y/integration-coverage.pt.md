---
title: Cobertura de um programa inteiro
version: 1
---

O `go test -cover` mede o que os testes de unidade alcançam. Parte do código só é alcançada rodando
o programa: a função `main`, a leitura das flags, o jeito como ele informa um arquivo que falta e o
status de saída que usa. **O `go build -cover` compila um binário que registra a própria cobertura
enquanto roda**, então o programa pode ser exercitado como um usuário o usaria e medido depois.

## Um comando para o pacote

O `wordcount` foi uma biblioteca por seis lições. Um comando pequeno no mesmo módulo o transforma
numa ferramenta, num diretório próprio como todo comando Go, salvo como `cmd/topwords/main.go`:

```go
// Command topwords prints the most frequent words of the files it is given.
package main

import (
	"context"
	"flag"
	"fmt"
	"os"

	"example.com/wordcount"
)

func main() {
	n := flag.Int("n", 3, "how many words to print")
	flag.Parse()
	if flag.NArg() == 0 {
		fmt.Fprintln(os.Stderr, "usage: topwords [-n N] FILE...")
		os.Exit(2)
	}
	src := wordcount.FSSource{FS: os.DirFS(".")}
	for _, name := range flag.Args() {
		top, err := wordcount.TopOf(context.Background(), src, name, *n)
		if err != nil {
			fmt.Fprintln(os.Stderr, "topwords:", err)
			os.Exit(1)
		}
		fmt.Println(name)
		for _, e := range top {
			fmt.Printf("  %-8s %d\n", e.Word, e.Count)
		}
	}
}
```

Ele lê arquivos pelo `FSSource` sobre `os.DirFS(".")`, o sistema de arquivos real com raiz no
diretório atual, então os nomes são dados relativos a ele, sem um `./` na frente. O `flag` é o da
lição 21.

## Compilando para contar, e rodando

O `GOCOVERDIR` dá o nome do diretório onde um binário instrumentado escreve os contadores quando
termina. Duas execuções, uma comum e uma com um arquivo que não existe:

```
ana@vm:~/wordcount$ go build -cover -o topwords ./cmd/topwords
ana@vm:~/wordcount$ printf 'to be or not to be\nthat is the question\n' > hamlet.txt
ana@vm:~/wordcount$ mkdir -p covdata
ana@vm:~/wordcount$ GOCOVERDIR=covdata ./topwords -n 2 hamlet.txt; echo "exit $?"
hamlet.txt
  be       2
  to       2
exit 0
ana@vm:~/wordcount$ GOCOVERDIR=covdata ./topwords missing.txt; echo "exit $?"
topwords: open missing.txt: open missing.txt: no such file or directory
exit 1
ana@vm:~/wordcount$ ls covdata
covcounters.c83cd828c40e25e8101d3015c630c648.2417.1792191798276497761
covcounters.c83cd828c40e25e8101d3015c630c648.2428.1792191798288892120
covmeta.c83cd828c40e25e8101d3015c630c648
```

O programa se comportou exatamente como um build comum, status de saída inclusive, e a mensagem da
segunda execução diz `open missing.txt` duas vezes: uma do embrulho do `TopOf` e outra do próprio
erro do pacote `os`, um defeitinho que só uma execução do programa real mostra. Ele também deixou
arquivos para trás: um arquivo `covmeta` descrevendo o binário e um arquivo `covcounters` por
execução. O `go tool covdata` os lê, juntando as execuções:

```
ana@vm:~/wordcount$ go tool covdata percent -i=covdata
	example.com/wordcount		coverage: 45.9% of statements
	example.com/wordcount/cmd/topwords		coverage: 85.7% of statements
ana@vm:~/wordcount$ go tool covdata textfmt -i=covdata -o prog.out
ana@vm:~/wordcount$ go tool cover -func=prog.out | grep -E 'main|TopOf|Handler|total'
example.com/wordcount/cmd/topwords/main.go:13:	main		85.7%
example.com/wordcount/handler.go:13:		Handler		0.0%
example.com/wordcount/source.go:16:		TopOf		87.5%
total:						(statements)	53.3%
```

**As duas execuções juntas alcançaram parte da biblioteca e quase todo o `main`.** O caminho de uso,
sem arquivo nomeado, é a parte do `main` que nenhuma execução percorreu. O `Handler` está em zero,
porque nada neste programa serve HTTP. O `textfmt` converte os contadores para o mesmo formato de
perfil que o `go test -coverprofile` escreve, então o `go tool cover` os lê do mesmo jeito, `-html`
inclusive.

## Quando recorrer a isso

A cobertura de unidade é de onde vem a maior parte do mapa, e ela é barata. A cobertura do programa
vale a pena onde os testes de unidade não chegam: uma ferramenta de linha de comando guiada por um
roteiro de invocações reais, ou um servidor exercitado por um conjunto de ponta a ponta, com
`GOCOVERDIR` definido e o binário compilado com `-cover`. **Ela responde que partes do programa as
execuções realistas nunca tocam**, e essas são as partes que um usuário alcança primeiro.

Tudo nestas seis lições veio de um toolchain sem nada instalado ao lado: o `go test` com as suas
flags, o `testing` e os seus helpers, o `httptest`, o `iotest`, o `fstest`, os benchmarks e as duas
ferramentas de cobertura. O resto deste curso, as lições 1 a 24, é a concorrência da linguagem e a
sua biblioteca padrão, e esta metade é como mostrar que código construído com elas faz o que diz.
