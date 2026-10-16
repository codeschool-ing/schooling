---
title: Perguntando ao toolchain com `go doc` e `go list`
version: 1
---

Duas perguntas aparecem o dia inteiro: o que esta função promete, e do que este pacote é feito.
**O comando go responde as duas a partir do código no seu disco**, sem navegador e sem rede: o
`go doc` imprime os comentários de documentação de qualquer pacote que ele encontre, os seus
inclusive, e o `go list` imprime qualquer fato que o comando go sabe sobre um pacote, no formato que
você pedir.

## O `go doc` no seu próprio código

Os comentários que a lição 1 escreveu acima de cada declaração do `tally` são a documentação. O
`go doc` recebe um pacote, um símbolo, ou um pacote e um símbolo, e acha o pacote pelo caminho de
importação completo, por um caminho relativo ou por qualquer parte final do caminho que seja única:

```
ana@vm:~/daily$ go doc
Command hits summarises a web server's access log.
ana@vm:~/daily$ go doc ./internal/tally
package tally // import "example.com/hits/internal/tally"

Package tally reads the lines of an access log and counts them.

type Entry struct{ ... }
    func Parse(line string) (Entry, error)
type PathCount struct{ ... }
    func Top(s Summary, n int) []PathCount
type Summary struct{ ... }
    func Count(r io.Reader) (Summary, error)
ana@vm:~/daily$ go doc tally.Top
package tally // import "example.com/hits/internal/tally"

func Top(s Summary, n int) []PathCount
    Top returns the n paths with the most requests, the most first. Paths with
    the same count come in alphabetical order.

ana@vm:~/daily$ go doc tally.summary
package tally // import "example.com/hits/internal/tally"

type Summary struct {
	Lines    int
	ByStatus map[int]int
	ByPath   map[string]int
	Total    time.Duration
}
    Summary is what Count found.

func Count(r io.Reader) (Summary, error)
```

Sem argumento, ele documenta o pacote do diretório atual, e para um pacote `main` isso é o
comentário do pacote e mais nada: `Command hits summarises a web server's access log.` **Para uma
biblioteca, ele imprime o comentário do pacote e uma linha por declaração exportada**, agrupadas do
jeito que um leitor as procura. O `Parse` fica sob o `Entry` e o `Count` sob o `Summary` porque cada
um devolve aquele tipo, então a função que cria um valor aparece junto dele. Um símbolo em
minúsculas casa com as duas caixas, e é por isso que `tally.summary` achou o `Summary`, os seus
campos e o seu construtor.

Essa saída só é tão boa quanto os comentários, e as convenções de que ela depende são as que o
`tally` segue. **Um comentário de documentação é uma frase completa que começa com o nome que
documenta**: `Top returns the n paths with the most requests`, `Summary is what Count found.` O
comentário do pacote começa com `Package tally`, e é a frase que o `go doc` põe no topo. Um nome
exportado sem comentário continua aparecendo, e o `go doc` sobre ele imprime a declaração sem nada
embaixo, que é o sinal para escrever um.

Três flags mudam o quanto volta:

```
ana@vm:~/daily$ go doc -short tally
type Entry struct{ ... }
    func Parse(line string) (Entry, error)
type PathCount struct{ ... }
    func Top(s Summary, n int) []PathCount
type Summary struct{ ... }
    func Count(r io.Reader) (Summary, error)
ana@vm:~/daily$ go doc -src tally.Top
package tally // import "example.com/hits/internal/tally"

// Top returns the n paths with the most requests, the most first. Paths
// with the same count come in alphabetical order.
func Top(s Summary, n int) []PathCount {
	rows := make([]PathCount, 0, len(s.ByPath))
	for p, h := range s.ByPath {
		rows = append(rows, PathCount{p, h})
	}
	slices.SortFunc(rows, func(a, b PathCount) int {
		return cmp.Or(cmp.Compare(b.Hits, a.Hits), cmp.Compare(a.Path, b.Path))
	})
	return rows[:min(n, len(rows))]
}
ana@vm:~/daily$ go doc -ex tally.Top
package tally // import "example.com/hits/internal/tally"

func Top(s Summary, n int) []PathCount
    Top returns the n paths with the most requests, the most first. Paths with
    the same count come in alphabetical order.

    func ExampleTop()
ana@vm:~/daily$ go doc -all tally | wc -l
41
```

O `-short` fica só com as declarações de uma linha. **O `-src` imprime o código da declaração, com
corpo e tudo**, o que muitas vezes é o jeito mais rápido de responder "o que ela faz num empate" sem
abrir um editor. O `-ex` acrescenta os exemplos ligados a um símbolo, e o `ExampleTop` da seção 04
aparece sob o `Top` por causa do nome: `Example` seguido do símbolo é como um exemplo se liga a ele.
O `-all` imprime de uma vez a documentação de todas as declarações exportadas do pacote, 41 linhas
para o `tally`, o formato para mandar ao `less` ou ao `grep`.

## O `go doc` em todo o resto

O mesmo comando lê a biblioteca padrão, e um método se escreve `tipo.Método`. O `tally.Count` lê
linhas com um `bufio.Scanner`, e isso faz valer a pena olhar:

```
ana@vm:~/daily$ go doc bufio.Scanner.Buffer
package bufio // import "bufio"

func (s *Scanner) Buffer(buf []byte, max int)
    Buffer controls memory allocation by the Scanner. It sets the initial buffer
    to use when scanning and the maximum size of buffer that may be allocated
    during scanning. The contents of the buffer are ignored.

    The maximum token size must be less than the larger of max and cap(buf).
    If max <= cap(buf), Scanner.Scan will use this buffer only and do no
    allocation.

    By default, Scanner.Scan uses an internal buffer and sets the maximum token
    size to MaxScanTokenSize.

    Buffer panics if it is called after scanning has started.

ana@vm:~/daily$ go doc bufio.MaxScanTokenSize
package bufio // import "bufio"

const (
	// MaxScanTokenSize is the maximum size used to buffer a token
	// unless the user provides an explicit buffer with [Scanner.Buffer].
	// The actual maximum token size may be smaller as the buffer
	// may need to include, for instance, a newline.
	MaxScanTokenSize = 64 * 1024
)
ana@vm:~/daily$ head -c 70000 /dev/zero | tr "\0" a | ./bin/hits count; echo $?
hits: bufio.Scanner: token too long
1
```

**A documentação previu uma falha que nenhum teste do `hits` tinha achado.** Um `Scanner` recusa
uma linha maior que o seu tamanho máximo de token, 64 KiB a menos que o `Buffer` o aumente, e o
`Count` nunca chama o `Buffer`. Uma linha de 70.000 bytes feita com `head` e `tr` para o `hits` com
`bufio.Scanner: token too long` e status de saída 1. Nenhuma linha de log de acesso real tem esse
tamanho, então o `hits` pode conviver com isso, mas agora é uma decisão, e não uma surpresa.

## O `go list`: os fatos que o comando go usa

O `go list` com um padrão imprime caminhos de importação, um por linha. Com `-f`, ele roda um
template Go sobre uma estrutura que descreve cada pacote; o `go help list` imprime essa estrutura
campo a campo, e cada campo é uma pergunta que você pode fazer:

```
ana@vm:~/daily$ go list ./...
example.com/hits
example.com/hits/internal/tally
example.com/hits/tools/genlog
ana@vm:~/daily$ go list -f "{{.Name}}  {{.ImportPath}}  {{.GoFiles}} {{.TestGoFiles}} {{.XTestGoFiles}}" ./...
main  example.com/hits  [main.go] [main_test.go] []
tally  example.com/hits/internal/tally  [tally.go] [] [tally_test.go]
main  example.com/hits/tools/genlog  [main.go] [] []
ana@vm:~/daily$ go list -json=Dir,GoFiles,Imports ./internal/tally
{
	"Dir": "/home/ana/daily/internal/tally",
	"GoFiles": [
		"tally.go"
	],
	"Imports": [
		"bufio",
		"cmp",
		"fmt",
		"io",
		"slices",
		"strconv",
		"strings",
		"time"
	]
}
```

O `.Name` é a cláusula package e o `.ImportPath` é o caminho pelo qual os outros pacotes o importam,
e é por isso que dois pacotes aqui se chamam `main`. **Os arquivos de teste ficam separados em duas
listas**: o `main_test.go` está em `TestGoFiles` porque diz `package main`, e o `tally_test.go` está
em `XTestGoFiles` porque diz `package tally_test`. O `-json` imprime a estrutura inteira, e com uma
lista de nomes de campo imprime só esses, que é o formato que um script lê. O `.Dir` é onde o pacote
fica no disco, a resposta para "qual cópia deste pacote está sendo compilada" quando há um cache de
módulos ou um `replace` no meio.

O `-deps` amplia a lista, dos pacotes nomeados para tudo o que eles importam, direta ou
indiretamente:

```
ana@vm:~/daily$ go list -deps . | wc -l
80
ana@vm:~/daily$ go list -deps -f "{{if not .Standard}}{{.ImportPath}}{{end}}" .
example.com/hits/internal/tally
example.com/hits
```

**80 pacotes entram no `hits`, e 78 deles são da biblioteca padrão.** É um a mais que os 79 que o
`go build -a -v` compilou na seção 02; o extra é o `unsafe`, que o próprio compilador fornece e
nunca compila. Um template que não imprime nada para um pacote não deixa linha, então o `if` reduz
a lista aos dois pacotes deste módulo. A ordem é a do build: um pacote sempre vem depois de tudo o
que ele importa.

O `-m` troca pacotes por módulos:

```
ana@vm:~/daily$ go list -m all
example.com/hits
ana@vm:~/daily$ go list -m -f "{{.Path}} {{.GoVersion}} {{.Dir}}"
example.com/hits 1.27.1 /home/ana/daily
```

O `go list -m all` é o grafo de módulos que o build usa, e para o `hits` é uma linha, porque o
`hits` não exige nada. Instalar o `stringer` na seção 03 não mudou isso, que é o mesmo fato do
`go.mod` ter ficado intocado. Num módulo com dependências, ele imprime um módulo e uma versão por
linha, os módulos que uma ferramenta como o `govulncheck` da lição 9 precisa conhecer.
