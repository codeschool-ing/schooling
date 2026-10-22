---
title: Subcomandos, cada um com flags próprias
version: 1
---

`go build -o bin/ ./...` e `go test -race` são um programa só, `go`, cuja primeira palavra escolhe
um subcomando, e cada subcomando tem flags próprias. **As funções de nível de pacote das duas
primeiras seções desta lição trabalham todas num `FlagSet` escondido, `flag.CommandLine`; um
subcomando é um `FlagSet` que você mesmo cria** com `flag.NewFlagSet` e lê a partir das palavras
depois do nome dele.

Uma ferramenta pequena com dois subcomandos, salva como `tool/main.go`:

```go
// Command tool has two subcommands, each with flags of its own.
package main

import (
	"flag"
	"fmt"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: tool add|list [flags]")
		os.Exit(2)
	}
	switch os.Args[1] {
	case "add":
		fs := flag.NewFlagSet("add", flag.ExitOnError)
		tag := fs.String("tag", "", "tag for the note")
		fs.Parse(os.Args[2:])
		fmt.Printf("add %q tagged %q\n", fs.Args(), *tag)
	case "list":
		fs := flag.NewFlagSet("list", flag.ExitOnError)
		limit := fs.Int("limit", 10, "how many notes to show")
		fs.Parse(os.Args[2:])
		fmt.Println("list, at most", *limit)
	default:
		fmt.Fprintf(os.Stderr, "tool: unknown command %q\n", os.Args[1])
		os.Exit(2)
	}
}
```

`os.Args[0]` é o nome do programa e `os.Args[1]` o subcomando, então cada caso lê `os.Args[2:]`,
tudo o que vem depois. Os dois `FlagSet`s não sabem nada um do outro: `-tag` pertence a `add` e
`-limit` a `list`.

```
ana@vm:~/flags$ bin/tool add -tag work buy milk
add ["buy" "milk"] tagged "work"
ana@vm:~/flags$ bin/tool list -limit 3
list, at most 3
ana@vm:~/flags$ bin/tool list -tag x; echo $?
flag provided but not defined: -tag
Usage of list:
  -limit int
    	how many notes to show (default 10)
2
```

**Uma flag dada ao subcomando errado é recusada por esse subcomando**, com o próprio texto de uso,
que só cita as próprias flags. `flag.ExitOnError` é o que faz a recusa encerrar o programa com o
status 2, como fazem as funções de nível de pacote. As outras duas escolhas são
`flag.ContinueOnError`, em que o `Parse` devolve o erro e o programa decide, e `flag.PanicOnError`.
Um programa que lê flags mais de uma vez, ou um teste que confere o erro, quer `ContinueOnError`.

Os casos que os `FlagSet`s nunca veem, um subcomando desconhecido e nenhum, são do próprio
programa, e ele segue a mesma convenção:

```
ana@vm:~/flags$ bin/tool remove; echo $?
tool: unknown command "remove"
2
ana@vm:~/flags$ bin/tool; echo $?
usage: tool add|list [flags]
2
```

**Status 2 e uma linha na saída de erro** é o que um script de shell espera de uma ferramenta
chamada errado, seja qual for a linguagem em que foi escrita. Escrever essa linha na saída de erro
em vez da saída padrão a mantém fora de um pipe que era para a saída de verdade da ferramenta.

Passando de dois ou três subcomandos, com ajuda para cada um e flags compartilhadas, uma biblioteca
de terceiros começa a valer o download. Este curso fica na biblioteca padrão, e o que está acima é
aquilo sobre o que essas bibliotecas são construídas.
