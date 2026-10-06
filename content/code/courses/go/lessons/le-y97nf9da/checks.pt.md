---
title: Quando um tipo não se encaixa
version: 1
---

Implícito não quer dizer sem verificação. Em todo lugar onde um valor é usado como interface —
passado a um parâmetro, atribuído a uma variável, posto num slice dessa interface — o compilador
compara o conjunto de métodos do valor com os métodos da interface. Se faltar algum, ele recusa o
programa. **A verificação acontece em tempo de compilação, no ponto de uso, e a mensagem nomeia o
método.** Vale a pena reconhecer de vista três jeitos de falhar nela.

## Um método ausente, ou do tipo errado

`Square` tem o seu método com outro nome. `Grid` tem `Area`, devolvendo o tipo errado:

```go
package main

import "fmt"

type Shape interface {
	Area() float64
}

type Square struct {
	Side float64
}

func (s Square) Size() float64 {
	return s.Side * s.Side
}

type Grid struct {
	Rows, Cols int
}

func (g Grid) Area() int {
	return g.Rows * g.Cols
}

func main() {
	sq := Square{Side: 2}
	g := Grid{Rows: 3, Cols: 4}
	shapes := []Shape{sq, g}
	fmt.Println(len(shapes))
}
```

```
ana@vm:~/ifaces-missing$ go build
# example.com/missing
./main.go:28:20: cannot use sq (variable of struct type Square) as Shape value in array or slice literal: Square does not implement Shape (missing method Area)
./main.go:28:24: cannot use g (variable of struct type Grid) as Shape value in array or slice literal: Grid does not implement Shape (wrong type for method Area)
		have Area() int
		want Area() float64
```

Os dois erros apontam para a linha 28, o literal do slice, e não para os tipos: os tipos estão
certos sozinhos, e só o uso pede algo deles. **Leia cada mensagem pelo fim.** `missing method Area`
quer dizer nenhum método com esse nome. `wrong type for method Area` quer dizer que o nome está lá
e a assinatura não, e as duas linhas recuadas as põem lado a lado: `have` é o que o tipo declara,
`want` é o que a interface pede. Um `int` não é um `float64` aqui, como em nenhum outro lugar de
Go (lição 10).

## Um método no ponteiro

A terceira falha é a da lição 26, vista do lado da interface. O `Write` de `strings.Builder` tem
receptor ponteiro, então um valor `strings.Builder` não o tem no seu conjunto de métodos:

```go
package main

import (
	"fmt"
	"strings"
)

func main() {
	var sb strings.Builder
	fmt.Fprintf(sb, "hello")
	fmt.Println(sb.String())
}
```

```
ana@vm:~/ifaces-value$ go build
# example.com/value
./main.go:10:14: cannot use sb (variable of struct type strings.Builder) as io.Writer value in argument to fmt.Fprintf: strings.Builder does not implement io.Writer (method Write has pointer receiver)
```

`fmt.Fprintf(&sb, "hello")` é a correção, do jeito que a seção 02 escreveu. **Quando a mensagem
termina em `(method Write has pointer receiver)`, ou nas mesmas palavras sobre qualquer método,
passe o endereço.**

## Fazendo o compilador verificar cedo

Os três erros apareceram porque algo usou o tipo como interface. Quando nada usa ainda, nada é
verificado. Um `Rect` que deveria ser um `Shape`, cujo método alguém renomeou para `Size`, compila
e roda sem dizer nada:

```go
package main

type Shape interface {
	Area() float64
}

type Rect struct {
	W, H float64
}

func (r Rect) Size() float64 {
	return r.W * r.H
}
```

```go
package main

import "fmt"

func main() {
	r := Rect{W: 3, H: 4}
	fmt.Println(r.Size())
}
```

```
ana@vm:~/ifaces-assert$ go build && ./assert
12
```

Num projeto de verdade, o código que usa `Rect` como `Shape` muitas vezes está em outro pacote,
então o erro apareceria lá, para outra pessoa, depois de a mudança de nome entrar. Uma linha no
pacote do próprio tipo o traz de volta:

```
ana@vm:~/ifaces-assert$ cat check.go
package main

var _ Shape = Rect{}
ana@vm:~/ifaces-assert$ go build
# example.com/assert
./check.go:3:15: cannot use Rect{} (value of struct type Rect) as Shape value in variable declaration: Rect does not implement Shape (missing method Area)
```

`var _ Shape = Rect{}` declara uma variável do tipo `Shape`, dá a ela um `Rect` e a chama de `_`, o
identificador vazio que a lição 20 usou para jogar um resultado fora. Nenhum código pode lê-la. O
único efeito dela é a atribuição, e uma atribuição a uma interface é exatamente o que faz o
compilador comparar conjuntos de métodos. **É uma verificação que custa uma linha, e quem a faz é
o compilador, então uma mudança de nome quebra o build do próprio pacote do tipo.**

Para um tipo cujos métodos têm receptor ponteiro, o valor à direita é um ponteiro, e o ponteiro
mais barato de escrever é um nil convertido para o tipo. A biblioteca padrão faz isso:

```
ana@vm:~/ifaces-assert$ grep -n "^var _ " /usr/local/go/src/net/http/transport.go /usr/local/go/src/encoding/json/stream.go
/usr/local/go/src/net/http/transport.go:2153:var _ io.ReaderFrom = (*persistConnWriter)(nil)
/usr/local/go/src/encoding/json/stream.go:292:var _ Marshaler = (*RawMessage)(nil)
/usr/local/go/src/encoding/json/stream.go:293:var _ Unmarshaler = (*RawMessage)(nil)
```

`(*RawMessage)(nil)` é a conversão da lição 10 aplicada a `nil`: um `*RawMessage` que não aponta
para nada, e isso basta, porque só o tipo dele está sendo verificado. Escreva uma dessas linhas
quando um tipo existe para satisfazer uma interface que é usada em outro lugar. Quando a interface
é usada logo ao lado do tipo, como na seção 02, o próprio uso já é a verificação.
