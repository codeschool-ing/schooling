---
title: Um diretório, um pacote
version: 1
---

Todo programa deste curso até aqui foi um diretório com um `package main` dentro. Programas maiores
são divididos, e o hábito que se traz de outras linguagens é dividir por arquivo: uma classe por
arquivo, um módulo por arquivo, um `import` que nomeia um arquivo. **Em Go a unidade é o
diretório.** Todo arquivo `.go` de um diretório pertence ao mesmo pacote, todo nome declarado num
deles é visível nos outros, e os nomes dos arquivos não significam nada para o compilador.

Aqui está um módulo pequeno, `example.com/wordy`, com dois programas que dividem uma biblioteca:

```
ana@vm:~/pkgs$ find . -type f | sort
./cmd/wordcount/main.go
./cmd/wordtop/main.go
./go.mod
./internal/fold/fold.go
./notes.txt
./text/count.go
./text/top.go
ana@vm:~/pkgs$ go run ./cmd/wordcount notes.txt
13 different words
ana@vm:~/pkgs$ go run ./cmd/wordtop notes.txt
go     3
is     3
simple 2
```

Quatro diretórios têm código Go, então são quatro pacotes: `cmd/wordcount` e `cmd/wordtop` são cada
um um `package main`, `text` conta palavras, e `internal/fold` põe uma palavra na forma que `text`
compara. O `go run` recebeu um diretório, não um arquivo, que é o que a lição 4 queria dizer com
`go run .`.

## O caminho de importação é o caminho do módulo mais o diretório

O `go list` nomeia os pacotes de um módulo, e com um template diz mais sobre cada um:

```
ana@vm:~/pkgs$ go list ./...
example.com/wordy/cmd/wordcount
example.com/wordy/cmd/wordtop
example.com/wordy/internal/fold
example.com/wordy/text
ana@vm:~/pkgs$ go list -f "{{.ImportPath}}  {{.Name}}  {{.Dir}}" ./text
example.com/wordy/text  text  /home/ana/pkgs/text
```

`./...` quer dizer este diretório e todos abaixo dele. Cada **caminho de importação é o caminho do
módulo, do `go.mod`, seguido do diretório**, que é a promessa que a lição 38 fez: renomeie o módulo
e todos estes mudam. O segundo comando mostra as três coisas que um pacote tem, e elas não são a
mesma coisa. O caminho de importação é o que uma linha `import` escreve. O nome é o que a cláusula
`package` diz, e é o que o código escreve antes de um ponto: `text.Count`. O diretório é onde os
arquivos estão.

O nome costuma ser o último elemento do caminho, e nada obriga que seja:

```
ana@vm:~/pkgs$ go list -f "{{.ImportPath}}  {{.Name}}" math/rand/v2 encoding/json
math/rand/v2  rand
encoding/json  json
```

`math/rand/v2` é a segunda versão major de `math/rand`, com o sufixo `/v2` que a lição 38 encontrou
na versão do Docker, e os arquivos dele continuam dizendo `package rand`. Um arquivo que o importa
escreve `rand.N`.

## Dois arquivos, um pacote

`text` são dois arquivos. `count.go` declara o tipo `Counts` e a função `Count`:

```go
// Package text counts the words in a piece of prose.
package text

import (
	"strings"

	"example.com/wordy/internal/fold"
)

// Counts maps each word to the number of times it appears.
type Counts map[string]int

// Count splits s into words and counts each one, ignoring case.
func Count(s string) Counts {
	c := Counts{}
	for _, w := range strings.Fields(s) {
		if w = fold.Word(w); w != "" {
			c[w]++
		}
	}
	return c
}
```

E `top.go` usa `Counts` sem importar nada para isso, porque está no mesmo pacote:

```go
package text

import (
	"cmp"
	"slices"
)

// Entry is one word and how often it appeared.
type Entry struct {
	Word  string
	Count int
}

// Top returns the n most frequent words, most frequent first.
func (c Counts) Top(n int) []Entry {
	list := c.entries()
	slices.SortFunc(list, byCount)
	return list[:min(n, len(list))]
}

func (c Counts) entries() []Entry {
	list := make([]Entry, 0, len(c))
	for w, n := range c {
		list = append(list, Entry{w, n})
	}
	return list
}

func byCount(a, b Entry) int {
	if d := cmp.Compare(b.Count, a.Count); d != 0 {
		return d
	}
	return cmp.Compare(a.Word, b.Word)
}
```

O método `Top` é declarado num arquivo diferente do tipo dele, o que a regra da lição 25 permite: um
método tem de ser declarado no pacote do tipo, e o pacote é o diretório inteiro. **Já os imports
pertencem ao arquivo.** `top.go` importa `cmp` e `slices` para si, e o import de `strings` em
`count.go` não faz nada por ele. O comentário do pacote, o que fica acima da cláusula `package` em
`count.go`, é escrito uma vez só; o `go doc` o lê de qualquer arquivo que o tenha.

Como o diretório é o pacote, um segundo nome de pacote nele é recusado antes de qualquer
compilação. Numa cópia do módulo, `text/words.go` diz `package words`:

```
ana@vm:~/pkgs-twonames$ go build ./...
cmd/wordcount/main.go:8:2: found packages text (count.go) and words (words.go) in /home/ana/pkgs-twonames/text
```

A única exceção é para arquivos de teste, que o `go help test` descreve e o curso `go-concurrency`
usa.

## cmd, internal e o grafo entre eles

O arranjo é uma convenção, e o próprio código-fonte do Go a segue. **Cada programa ganha um
diretório em `cmd/`, com o nome do binário que gera**, então um comando só compila todos, aqui para
um diretório `bin` do próprio módulo, ajustando `GOBIN` só nesta execução:

```
ana@vm:~/pkgs$ GOBIN=~/pkgs/bin go install ./cmd/... && ls bin
wordcount
wordtop
ana@vm:~/pkgs$ ls -d /usr/local/go/src/cmd/go /usr/local/go/src/cmd/gofmt /usr/local/go/src/cmd/vet
/usr/local/go/src/cmd/go
/usr/local/go/src/cmd/gofmt
/usr/local/go/src/cmd/vet
```

O comando go que você digita desde a lição 3 foi compilado de `cmd/go`, o mesmo formato. Os pacotes
que os programas dividem ficam ao lado de `cmd`, aqui `text`. E `internal/` guarda pacotes que não
são da conta de mais ninguém, e a seção 04 mostra o comando go fazendo valer isso.

O `go list` sabe imprimir o que cada pacote importa, e essas linhas são toda a estrutura do módulo:

```
ana@vm:~/pkgs$ go list -f "{{.ImportPath}}: {{join .Imports \" \"}}" ./...
example.com/wordy/cmd/wordcount: example.com/wordy/text fmt os
example.com/wordy/cmd/wordtop: example.com/wordy/text fmt os
example.com/wordy/internal/fold: strings unicode
example.com/wordy/text: cmp example.com/wordy/internal/fold slices strings
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"O grafo de imports do módulo example.com/wordy, como o go list o imprimiu. Dois pacotes main, cmd/wordcount e cmd/wordtop, importam text, e fmt e os da biblioteca padrão. text importa internal/fold, e cmp, slices e strings. internal/fold importa strings e unicode e nada do módulo. Toda seta aponta para baixo, então não há ciclo, e internal/fold só pode ser importado de dentro de example.com/wordy.\"><defs><marker id=\"ig-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16\" y=\"14\" width=\"468\" height=\"292\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"30\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">example.com/wordy</text><text x=\"160\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o módulo</text><rect x=\"50.0\" y=\"72\" width=\"170\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cmd/wordcount</text><text x=\"135\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">+ fmt os</text><rect x=\"280.0\" y=\"72\" width=\"170\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"365\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cmd/wordtop</text><text x=\"365\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">+ fmt os</text><rect x=\"150.0\" y=\"162\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">text</text><text x=\"250\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">+ cmp slices strings</text><rect x=\"150.0\" y=\"247\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"250\" y=\"261\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">internal/fold</text><text x=\"250\" y=\"275\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">+ strings unicode</text><path d=\"M135 108 L215 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ig-phosphor)\"></path><path d=\"M365 108 L285 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ig-phosphor)\"></path><path d=\"M250 198 L250 245\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ig-phosphor)\"></path><path d=\"M484 90 L500 90\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"508\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">programas: package main</text><path d=\"M484 180 L500 180\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"508\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a biblioteca que os programas dividem</text><path d=\"M484 265 L500 265\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"508\" y=\"265\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">só para código dentro do módulo</text><text x=\"508\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma seta é um import</text><text x=\"508\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">+ ...</text><text x=\"540\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">da biblioteca padrão</text><text x=\"508\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">toda seta aponta para baixo:</text><text x=\"508\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nenhum ciclo</text></svg>", "caption": "Os quatro pacotes do módulo e o que cada um importa. Um caminho de importação é o caminho do módulo mais um diretório; as setas são as linhas que o go list imprimiu."}
```

Desenhado, é um grafo em que toda seta aponta para o mesmo lado: programas em cima, `fold` embaixo,
importando só a biblioteca padrão. Esse sentido não é capricho. A seção 04 mostra que o comando go
recusa uma seta apontando de volta para cima.
