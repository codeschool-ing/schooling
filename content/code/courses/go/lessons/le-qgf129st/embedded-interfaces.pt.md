---
title: Interfaces feitas de interfaces
version: 1
---

A lição 16 embutiu uma struct em outra e avisou que aquilo não era herança. Interfaces também
podem ser embutidas, e o mesmo aviso vale com ainda mais força: **uma interface listada dentro de
outra acrescenta os seus métodos à lista, e é só isso que ela faz.** Não há pai, nem filho, nem
nada que um tipo concreto precise declarar. O pacote `io` é montado assim:

```
ana@vm:~/assert$ go doc io.ReadWriter
package io // import "io"

type ReadWriter interface {
	Reader
	Writer
}
    ReadWriter is the interface that groups the basic Read and Write methods.

ana@vm:~/assert$ go doc io.ReadWriteCloser
package io // import "io"

type ReadWriteCloser interface {
	Reader
	Writer
	Closer
}
    ReadWriteCloser is the interface that groups the basic Read, Write and Close
    methods.
```

`io.ReadWriter` não nomeia nenhum método próprio. As suas duas linhas dizem "todos os métodos de
`Reader` e todos os métodos de `Writer`", que são `Read` e `Write`. `io.ReadWriteCloser` acrescenta
`Closer`, cujo único método é `Close() error`. Escrever os três métodos à mão declararia exatamente
a mesma interface. Embutir é mais curto, e mantém a definição de `Read` num lugar só.

## Uma interface maior cabe em menos tipos

A regra da lição 27 continua decidindo quem a satisfaz: um tipo satisfaz uma interface quando tem
todos os métodos que ela lista. Uma lista mais longa é mais difícil de cumprir, então cada interface
embutida deixa menos tipos dentro:

```go
package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
)

func main() {
	var buf bytes.Buffer
	var rw io.ReadWriter = &buf
	fmt.Fprint(rw, "into the buffer")

	var r io.Reader = rw
	data, err := io.ReadAll(r)
	fmt.Printf("%q %v\n", data, err)

	var rwc io.ReadWriteCloser = os.Stdout
	fmt.Printf("%T %T %T\n", rw, r, rwc)
}
```

```
ana@vm:~/assert$ go run .
"into the buffer" <nil>
*bytes.Buffer *bytes.Buffer *os.File
```

Um `*bytes.Buffer` pode ser lido e escrito, então cabe em `io.ReadWriter`. O `fmt.Fprint` escreveu
nele através de `rw`, e o `io.ReadAll`, que lê um reader até ele acabar, leu os mesmos bytes de
volta através de `r`. `os.Stdout` é um `*os.File`, que também tem `Close`, então cabe nas três
interfaces. E `var r io.Reader = rw` compilou sem cerimônia: **um valor que satisfaz a interface
maior satisfaz todas as interfaces dentro dela**, porque tem os métodos delas. O `%T` mostra que
nada foi convertido no caminho. `rw`, `r` e o buffer são um único `*bytes.Buffer` visto através de
duas listas de métodos diferentes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Três regiões de tipos, uma dentro da outra. A região de fora é todo tipo que satisfaz io.Reader, que pede Read; *strings.Reader fica ali e em nenhuma mais funda. Dentro dela está io.ReadWriter, que pede Read e Write; *bytes.Buffer fica ali. A mais interna é io.ReadWriteCloser, que pede Read, Write e Close; *os.File fica ali, e por isso também satisfaz as duas regiões em volta. Cada interface embutida acrescenta métodos, e cabem menos tipos.\"><rect x=\"20\" y=\"20\" width=\"470\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">io.Reader</text><text x=\"370\" y=\"36\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pede</text><text x=\"378\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Read</text><rect x=\"50\" y=\"70\" width=\"410\" height=\"170\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"62\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">io.ReadWriter</text><text x=\"340\" y=\"86\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pede</text><text x=\"348\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Read Write</text><rect x=\"80\" y=\"120\" width=\"350\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"92\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">io.ReadWriteCloser</text><text x=\"310\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pede</text><text x=\"318\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Read Write Close</text><text x=\"255\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">*strings.Reader</text><text x=\"255\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">*bytes.Buffer</text><text x=\"255\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">*os.File</text><text x=\"515\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cada método a mais</text><text x=\"515\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">deixa menos tipos dentro</text><text x=\"515\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um valor numa região interna</text><text x=\"515\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">satisfaz todas as regiões</text><text x=\"515\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">em volta dela</text></svg>", "caption": "Os conjuntos de tipos que satisfazem io.Reader, io.ReadWriter e io.ReadWriteCloser. Embutir aumenta a lista de métodos e encolhe o conjunto."}
```

O compilador confere cada passo contra essas listas, e quando um passo não cabe, ele nomeia o
método que falta:

```go
package main

import (
	"bytes"
	"fmt"
	"io"
	"strings"
)

func main() {
	var buf bytes.Buffer
	var rwc io.ReadWriteCloser = &buf
	var sr io.ReadWriter = strings.NewReader("read only")

	var r io.Reader = &buf
	var rw io.ReadWriter = r
	fmt.Println(rwc, sr, rw)
}
```

```
ana@vm:~/assert-missing$ go build
# example.com/missing
./main.go:12:31: cannot use &buf (value of type *bytes.Buffer) as io.ReadWriteCloser value in variable declaration: *bytes.Buffer does not implement io.ReadWriteCloser (missing method Close)
./main.go:13:25: cannot use strings.NewReader("read only") (value of type *strings.Reader) as io.ReadWriter value in variable declaration: *strings.Reader does not implement io.ReadWriter (missing method Write)
./main.go:16:25: cannot use r (variable of interface type io.Reader) as io.ReadWriter value in variable declaration: io.Reader does not implement io.ReadWriter (missing method Write)
```

Um buffer não tem nada para fechar. Um `*strings.Reader` lê uma string e não aceita escrita. A
terceira mensagem é a interessante. `r` guarda o mesmíssimo `*bytes.Buffer` que a linha 12 usou, que
aceita escrita, e o compilador recusa mesmo assim, porque julga `r` pelo seu tipo, `io.Reader`, e
um `io.Reader` promete `Read` e mais nada. **Ir de uma interface menor para uma maior não pode ser
conferido quando o programa é compilado**, e a seção 03 é o jeito de fazer isso enquanto o
programa roda.

## Embutindo nas suas próprias interfaces

Uma interface sua pode embutir uma da biblioteca padrão e acrescentar um método próprio. O
`bufio.Writer` junta o que você escreve num buffer e o repassa em pedaços grandes, e só repassa o
último pedaço quando você chama o seu método `Flush`. Uma função que precisa descarregar o que
escreveu pode pedir exatamente isso:

```go
package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
)

type FlushWriter interface {
	io.Writer
	Flush() error
}

func greet(w FlushWriter, name string) error {
	fmt.Fprintf(w, "Hello, %s\n", name)
	return w.Flush()
}

func main() {
	out := bufio.NewWriter(os.Stdout)
	if err := greet(out, "Ana"); err != nil {
		fmt.Println(err)
	}
}
```

```
ana@vm:~/assert-flush$ go run .
Hello, Ana
```

`FlushWriter` é `io.Writer` mais `Flush() error`. Um `*bufio.Writer` tem os dois e cabe, e é por
isso que `greet` pôde chamar `w.Flush()`. `os.Stdout` escreve direto no terminal e não tem nada para
descarregar, então não cabe:

```go
package main

import (
	"fmt"
	"io"
	"os"
)

type FlushWriter interface {
	io.Writer
	Flush() error
}

func greet(w FlushWriter, name string) error {
	fmt.Fprintf(w, "Hello, %s\n", name)
	return w.Flush()
}

func main() {
	if err := greet(os.Stdout, "Bia"); err != nil {
		fmt.Println(err)
	}
}
```

```
ana@vm:~/assert-flush-stdout$ go build
# example.com/flush
./main.go:20:18: cannot use os.Stdout (variable of type *os.File) as FlushWriter value in argument to greet: *os.File does not implement FlushWriter (missing method Flush)
```

Duas interfaces embutidas podem trazer o mesmo método. `io.ReadCloser` e `io.WriteCloser` incluem
`Close() error`, e uma interface montada com as duas tem um `Close`, não dois:

```go
package main

import (
	"fmt"
	"io"
	"os"
)

type ReadWriteCloser interface {
	io.ReadCloser
	io.WriteCloser
}

func main() {
	var f ReadWriteCloser = os.Stdout
	fmt.Printf("%T\n", f)
}
```

```
ana@vm:~/assert-union$ go run .
*os.File
```

O conjunto de métodos é um conjunto: um método com o mesmo nome e a mesma assinatura conta uma vez.
É isso que deixa interfaces pequenas combináveis. A lição 27 contou doze interfaces de um método em
`io` e nenhuma de mais de três, e **toda interface maior ali é montada embutindo interfaces
menores**, do jeito que esta seção montou `FlushWriter`.
