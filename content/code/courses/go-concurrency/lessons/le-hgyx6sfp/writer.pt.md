---
title: O Writer, e para onde a saída de um programa pode ir
version: 1
---

`io.Writer` é a imagem no espelho: um método, `Write(p []byte) (n int, err error)`, que recebe os
bytes de `p` e diz quantos aceitou. **O contrato dele é mais rígido que o do Read num ponto: um
Writer que aceita menos que `len(p)` bytes tem de devolver um erro dizendo por quê.** Quem chama
pode, portanto, conferir só o `err` e saber se tudo foi.

A consequência útil é que uma função que escreve a saída num `io.Writer`, em vez de direto na tela,
não decidiu nada sobre para onde a saída vai. Este programa escreve um relatório pequeno três vezes,
salvo como `writer.go`:

```go
// Command writer sends one report to three different destinations.
package main

import (
	"bytes"
	"crypto/sha256"
	"fmt"
	"io"
	"os"
)

func report(w io.Writer) {
	fmt.Fprintf(w, "served %d requests\n", 42)
	fmt.Fprintf(w, "slowest took %s\n", "180ms")
}

func main() {
	report(os.Stdout)

	var buf bytes.Buffer
	report(&buf)
	fmt.Printf("the buffer holds %d bytes\n", buf.Len())

	h := sha256.New()
	report(h)
	fmt.Printf("sha256 %x\n", h.Sum(nil))
}
```

```
ana@vm:~/rw$ go run writer.go
served 42 requests
slowest took 180ms
the buffer holds 38 bytes
sha256 ff1ea3dc3e39037131f06e56f9619e42783fd71fda2916692a9334fffc4aaec5
ana@vm:~/rw$ printf "served 42 requests\nslowest took 180ms\n" | sha256sum
ff1ea3dc3e39037131f06e56f9619e42783fd71fda2916692a9334fffc4aaec5  -
```

**Três destinos, uma função, nenhuma mudança nela.** `os.Stdout` é o terminal. Um `bytes.Buffer`
guarda os 38 bytes na memória, que é o que um teste faz na lição 25 para conferir o que uma função
imprimiu. E `sha256.New()` devolve um hash que também é um Writer: o que entra nunca é guardado,
só digerido. O `sha256sum` do próprio shell, com as mesmas duas linhas, concorda até o último
dígito, um jeito barato de ter certeza de que o relatório escreveu exatamente o que parecia.

`fmt.Fprintf` é a função que tornou isso possível. `fmt.Printf` é o `Fprintf` com `os.Stdout` já
preenchido, e toda função `Print` tem uma gêmea com `F` que recebe um Writer primeiro.

## Escrevendo um

Um Writer seu é tão curto quanto um Reader. A forma comum embrulha outro Writer e faz alguma coisa
no caminho; este conta, salvo como `counting.go`:

```go
// Command counting wraps a Writer in one that counts what passes through.
package main

import (
	"fmt"
	"io"
	"os"
)

type counter struct {
	w io.Writer
	n int64
}

func (c *counter) Write(p []byte) (int, error) {
	n, err := c.w.Write(p)
	c.n += int64(n)
	return n, err
}

func main() {
	c := &counter{w: os.Stdout}
	fmt.Fprintln(c, "one line")
	fmt.Fprintln(c, "and another")
	fmt.Println("bytes written:", c.n)
}
```

```
ana@vm:~/rw$ go run counting.go
one line
and another
bytes written: 21
```

Nove bytes e doze, com as quebras de linha, dão 21. **O invólucro repassa o `n` e o `err` do Writer
de dentro sem mudança**, então quem escreve através dele vê exatamente o que veria sem ele, e ele só
acrescenta aquilo para que foi escrito. Esse padrão, um tipo que guarda um `io.Writer` e também é
um, é como o `bufio.Writer` da lição 18 e os handlers de log da lição 22 são construídos.

Um aviso vem da primeira metade. O `counter` não é seguro para duas goroutines ao mesmo tempo:
`c.n += int64(n)` é a atualização perdida da lição 1 esperando para acontecer. O próprio `os.Stdout`
pode ser escrito de várias goroutines, mas um invólucro com estado próprio precisa da trava que a
lição 16 pôs no `Cache`.
