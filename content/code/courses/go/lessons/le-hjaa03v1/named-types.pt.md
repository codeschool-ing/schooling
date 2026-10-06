---
title: Tipos seus, e por que eles não se misturam
version: 1
---

Quem começa e lê `type Celsius float64` costuma entender um apelido: Celsius *é* um `float64`, com
um nome mais legível. **É um tipo novo, com um `float64` por baixo**, e a regra da seção 01 vale
para ele por inteiro. Dois tipos de temperatura mostram isso:

```go
package main

import "fmt"

type Celsius float64
type Fahrenheit float64

func main() {
	var boil Celsius = 100
	var body Fahrenheit = 98.6
	var reading float64 = 21.5

	fmt.Println(boil + body)
	var room Celsius = reading
	fmt.Println(room)
}
```

```
ana@vm:~/convert-temp$ go run .
# example.com/convert-temp
./main.go:13:14: invalid operation: boil + body (mismatched types Celsius and Fahrenheit)
./main.go:14:21: cannot use reading (variable of type float64) as Celsius value in variable declaration
```

Somar um Celsius com um Fahrenheit é um erro de unidade, e o compilador o pegou só com duas linhas
de declaração. A segunda recusa é a mesma regra vista do outro lado: um `float64` comum também não
é um `Celsius`, mesmo sendo guardado exatamente igual. As constantes sem tipo `100` e `98.6` foram
aceitas, pelo motivo que a seção 01 deu.

**Um tipo que você define é uma promessa sobre o que o número significa, e o compilador cobra essa
promessa em cada linha do programa.** Custa pouco escrever e pega uma classe inteira de bugs antes
de o programa rodar.

## Converter muda o tipo, nunca o número

Os dois tipos têm o mesmo tipo subjacente, `float64`, então a conversão entre eles é permitida. O
que ela faz é fácil de entender errado:

```go
package main

import "fmt"

type Celsius float64
type Fahrenheit float64

func CToF(c Celsius) Fahrenheit {
	return Fahrenheit(c*9/5 + 32)
}

func main() {
	var boil Celsius = 100
	fmt.Println(Fahrenheit(boil))
	fmt.Println(CToF(boil))

	var reading float64 = 21.5
	room := Celsius(reading)
	fmt.Printf("%v %T\n", room, room)
}
```

```
ana@vm:~/convert-temp2$ go run .
100
212
21.5 main.Celsius
```

`Fahrenheit(boil)` imprimiu `100`. A conversão trocou o rótulo do valor e não fez conta nenhuma, e
agora afirma que a água ferve a 100 °F. Nada na linguagem sabe como Celsius se relaciona com
Fahrenheit; `CToF` é onde esse conhecimento mora, e é o único lugar onde uma conversão entre os
dois faz sentido. Dentro dela, `9`, `5` e `32` são constantes sem tipo, então `c*9/5 + 32` é uma
conta em `Celsius`, convertida uma vez só no fim.

`%T` imprime o tipo de um valor, e diz `main.Celsius`: o pacote que definiu o tipo, depois o nome.
A lição 25 dá a um tipo assim métodos próprios, que é o outro motivo para defini-lo.

## A biblioteca padrão faz o mesmo

`time.Duration` é o tipo definido que você mais vai encontrar, e ele derruba todo mundo uma vez:

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	n := 2
	fmt.Println(n * time.Second)
}
```

```
ana@vm:~/convert-dur$ go run .
# example.com/convert-dur
./main.go:10:14: invalid operation: n * time.Second (mismatched types int and time.Duration)
ana@vm:~/convert-dur$ go doc time.Duration | head -6
package time // import "time"

type Duration int64
    A Duration represents the elapsed time between two instants as an int64
    nanosecond count. The representation limits the largest representable
    duration to approximately 290 years.
```

Um `Duration` é um `int64` que conta nanossegundos, definido como tipo próprio para que uma
contagem de segundos e uma de nanossegundos não se confundam. A conversão vai em `n`, e o lugar
onde ela fica importa:

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	n := 2
	fmt.Println(time.Duration(n) * time.Second)
	fmt.Println(time.Duration(n))
}
```

```
ana@vm:~/convert-dur2$ go run .
2s
2ns
```

`time.Duration(n)` sozinho são 2 nanossegundos, porque é isso que o número dentro de um `Duration`
conta. Multiplicar por `time.Second` faz dele dois segundos. **A conversão diz de que tipo é um
número; só a aritmética diz em que unidade ele está.**

## Um alias é outro nome para o mesmo tipo

Ponha um `=` na declaração e você ganha outra coisa: um **alias**, um segundo nome para um tipo que
já existe, e não um tipo novo.

```go
package main

import "fmt"

type Celsius float64
type Reading = float64

func main() {
	var x float64 = 21.5
	var r Reading = x
	c := Celsius(x)
	fmt.Printf("%T %T\n", r, c)
	fmt.Println(r + x)
}
```

```
ana@vm:~/convert-alias$ go run .
float64 main.Celsius
43
ana@vm:~/convert-alias$ go doc builtin.byte
package builtin // import "builtin"

type byte = uint8
    byte is an alias for uint8 and is equivalent to uint8 in all ways. It is
    used, by convention, to distinguish byte values from 8-bit unsigned integer
    values.
```

`Reading` recebeu um `float64` sem conversão e somou com outro, e o `%T` nem o menciona: o tipo de
`r` é `float64`, e `Reading` é só como o código o escreve. Você já usou dois aliases. `byte` é
`uint8` e `rune` é `int32`, e é por isso que a lição 8 pôde dizer que um byte é um `uint8` ao pé da
letra.

| declaração | o que ela cria | mistura com `float64`? |
|---|---|---|
| `type Celsius float64` | um tipo novo, uma **definição** | não, precisa de conversão |
| `type Reading = float64` | um segundo nome, um **alias** | sim, é o mesmo tipo |

A definição é a que lhe dá alguma coisa. Um alias dá outro nome a um tipo e mantém legal toda linha
que o mistura com o original, então não pega nada.
