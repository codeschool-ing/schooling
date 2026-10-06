---
title: Perguntando a uma interface o que ela guarda
version: 1
---

A lição 28 escreveu `x.(T)` e pagou um palpite errado com um panic. Essa forma é a certa quando um
tipo errado seria um bug. Quando um tipo errado é uma possibilidade que o programa deve tratar,
existe uma segunda forma, e é a que você vai escrever com mais frequência. **`v, ok := x.(T)` não
entra em panic: responde com o valor e um booleano dizendo se `x` guardava um `T`.** É o comma-ok
da lição 14, que perguntava a um map se ele tinha uma chave, agora perguntando a uma interface que
tipo ela guarda:

```go
package main

import (
	"encoding/json"
	"fmt"
)

func main() {
	var doc map[string]any
	if err := json.Unmarshal([]byte(`{"name": "Ana", "age": 31}`), &doc); err != nil {
		fmt.Println(err)
		return
	}

	for _, k := range []string{"age", "name", "email"} {
		n, ok := doc[k].(float64)
		fmt.Printf("%-6s %v %v\n", k, n, ok)
	}

	email := doc["email"].(string)
	fmt.Println(email)
}
```

```
ana@vm:~/assert-ok$ go run .
age    31 true
name   0 false
email  0 false
panic: interface conversion: interface {} is nil, not string

goroutine 1 [running]:
main.main()
	/home/ana/assert-ok/main.go:20 +0x327
exit status 2
```

`age` guardava um `float64`, então `n` vale 31 e `ok` é verdadeiro. `name` guardava uma string, e a
asserção respondeu falso com `n` no valor zero de `float64`. `email` nem está no map, então
`doc["email"]` deu o valor zero de `any`, uma interface que não guarda nada, e pedir a ela um
`float64` também respondeu falso. Nada parou até a última linha, onde a forma de um resultado pediu
à mesma interface vazia uma `string`, e o panic disse o que encontrou:
`interface {} is nil, not string`.

Então a escolha da forma diz algo sobre o programa. `x.(T)` diz "se isto não for um `T`, o código
em volta está errado, então pare". `v, ok := x.(T)` diz "pode não ser um `T`, e eis o que acontece
nesse caso". Ler valores de um documento que outra pessoa escreveu é o segundo caso quase sempre.

## Asserção para uma interface: o que mais você sabe fazer?

`T` não precisa ser um tipo concreto. Quando é uma interface, a asserção pergunta se o valor lá
dentro tem os métodos que essa interface lista. Isso a transforma numa pergunta sobre
**capacidade**: este valor foi entregue como `io.Writer`, então ele sabe fazer algo mais?

Uma função que escreve um relatório em qualquer `io.Writer` mostra por que a pergunta importa. Aqui
ela recebe um `*bufio.Writer`, que guarda o que recebe no seu buffer até alguém chamar `Flush`:

```go
package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
)

func report(w io.Writer, lines ...string) error {
	for _, l := range lines {
		if _, err := fmt.Fprintln(w, l); err != nil {
			return err
		}
	}
	return nil
}

func main() {
	if err := report(os.Stdout, "straight to the terminal"); err != nil {
		fmt.Println(err)
	}
	if err := report(bufio.NewWriter(os.Stdout), "through a bufio.Writer"); err != nil {
		fmt.Println(err)
	}
}
```

```
ana@vm:~/assert-lost$ go run .
straight to the terminal
```

A segunda linha sumiu. `report` a escreveu no buffer, não devolveu erro, e o programa terminou com
a linha ainda parada ali. `report` não pode pedir um `FlushWriter` como o `greet` da seção 02,
porque aí `os.Stdout` não poderia ser passado a ela. Então ela continua pedindo um `io.Writer`, e
confere o método a mais enquanto roda:

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

func report(w io.Writer, lines ...string) error {
	for _, l := range lines {
		if _, err := fmt.Fprintln(w, l); err != nil {
			return err
		}
	}
	if f, ok := w.(FlushWriter); ok {
		return f.Flush()
	}
	return nil
}

func main() {
	if err := report(os.Stdout, "straight to the terminal"); err != nil {
		fmt.Println(err)
	}
	if err := report(bufio.NewWriter(os.Stdout), "through a bufio.Writer"); err != nil {
		fmt.Println(err)
	}
}
```

```
ana@vm:~/assert-cap$ go run .
straight to the terminal
through a bufio.Writer
```

`w.(FlushWriter)` pergunta se o valor dentro de `w` também tem `Flush() error`. Para `os.Stdout` a
resposta é falsa e nada mais acontece. Para o `*bufio.Writer` ela é verdadeira, `f` é o mesmo writer
visto como `FlushWriter`, e `f.Flush()` manda a linha adiante. **A função continua aceitando todo
writer, e dá o passo a mais com os que sabem dá-lo.** Esse é o passo que a seção 02 disse que o
compilador não consegue conferir, de uma interface menor para uma maior, dado enquanto o programa
roda.

A biblioteca padrão faz isso em muitos lugares. O `io.Copy`, que copia tudo de um reader para um
writer, começa perguntando aos dois se conhecem um jeito mais rápido:

```
ana@vm:~/assert$ sed -n 407,416p /usr/local/go/src/io/io.go
func copyBuffer(dst Writer, src Reader, buf []byte) (written int64, err error) {
	// If the reader has a WriteTo method, use it to do the copy.
	// Avoids an allocation and a copy.
	if wt, ok := src.(WriterTo); ok {
		return wt.WriteTo(dst)
	}
	// Similarly, if the writer has a ReadFrom method, use it to do the copy.
	if rf, ok := dst.(ReaderFrom); ok {
		return rf.ReadFrom(src)
	}
ana@vm:~/assert$ sed -n 588,594p /usr/local/go/src/bufio/bufio.go
// size, it returns the underlying [Writer].
func NewWriterSize(w io.Writer, size int) *Writer {
	// Is it already a Writer?
	b, ok := w.(*Writer)
	if ok && len(b.buf) >= size {
		return b
	}
```

O `io.Copy` chama `copyBuffer`, e as duas primeiras instruções dela são asserções para interfaces.
Um `*bytes.Buffer` tem um método `WriteTo`, então copiar a partir de um entrega o trabalho inteiro
ao buffer, que já guarda todos os bytes e não precisa de um laço de leituras. O `NewWriterSize`,
que o `bufio.NewWriter` chama, faz a asserção para um tipo concreto: se o writer que recebeu já é
um `*bufio.Writer` com buffer grande o bastante, devolve esse writer em vez de enrolar um buffer em
volta de outro buffer.

## O que o compilador ainda recusa

Asserções só fazem sentido sobre interfaces, e o compilador confere o que consegue:

```go
package main

import (
	"bytes"
	"fmt"
	"io"
)

func main() {
	n := 3
	s := n.(string)

	var r io.Reader = &bytes.Buffer{}
	b := r.(bytes.Buffer)
	fmt.Println(s, b)
}
```

```
ana@vm:~/assert-bad$ go build
# example.com/bad
./main.go:11:7: invalid operation: n (variable of type int) is not an interface
./main.go:14:7: impossible type assertion: r.(bytes.Buffer)
	bytes.Buffer does not implement io.Reader (method Read has pointer receiver)
```

`n` é um `int`. O tipo dele é conhecido com exatidão, então não há o que perguntar, e o compilador
diz que `n` não é uma interface. O segundo erro é mais sutil. `bytes.Buffer`, sem o `*`, nunca pode
estar dentro de um `io.Reader`, porque o seu método `Read` tem receptor ponteiro, a regra de
conjunto de métodos da lição 26. **Uma asserção que só poderia falhar é recusada como impossível**,
antes de qualquer coisa rodar. `r.(*bytes.Buffer)` teria compilado, e dado certo.
