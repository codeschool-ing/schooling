---
title: Inteiros têm tamanho, e o tamanho é um limite
version: 1
---

Em Python um inteiro cresce o quanto precisar: dois elevado a setenta é um número comum ali. **Em Go
todo tipo inteiro tem um número fixo de bits, e uma conta que passa do último não para nem
reclama. Ela dá a volta.** Quase toda esta seção é sobre onde ficam esses limites e o que acontece
neles.

## Dez tipos, e o que usar

Go tem quatro tamanhos de inteiro com sinal, `int8`, `int16`, `int32` e `int64`, os mesmos quatro
sem sinal, de `uint8` a `uint64`, e dois cujo tamanho depende da máquina, `int` e `uint`. O pacote
`math` dá nome aos limites de cada um deles, e o `go doc` os imprime com os valores:

```
ana@vm:~/numbers$ go doc math.MaxInt
package math // import "math"

const (
	MaxInt    = 1<<(intSize-1) - 1  // MaxInt32 or MaxInt64 depending on intSize.
	MinInt    = -1 << (intSize - 1) // MinInt32 or MinInt64 depending on intSize.
	MaxInt8   = 1<<7 - 1            // 127
	MinInt8   = -1 << 7             // -128
	MaxInt16  = 1<<15 - 1           // 32767
	MinInt16  = -1 << 15            // -32768
	MaxInt32  = 1<<31 - 1           // 2147483647
	MinInt32  = -1 << 31            // -2147483648
	MaxInt64  = 1<<63 - 1           // 9223372036854775807
	MinInt64  = -1 << 63            // -9223372036854775808
	MaxUint   = 1<<intSize - 1      // MaxUint32 or MaxUint64 depending on intSize.
	MaxUint8  = 1<<8 - 1            // 255
	MaxUint16 = 1<<16 - 1           // 65535
	MaxUint32 = 1<<32 - 1           // 4294967295
	MaxUint64 = 1<<64 - 1           // 18446744073709551615
)
    Integer limit values.
```

Um tipo com sinal de n bits vai de −2ⁿ⁻¹ a 2ⁿ⁻¹ − 1, e é por isso que `int8` para em 127 e não em
128: um dos seus 256 valores é gasto com o zero. Um tipo sem sinal abre mão dos negativos e vai
duas vezes mais longe, então `uint8` vai de 0 a 255.

`MaxInt` diz "depending on intSize", e o programa abaixo pergunta quanto isso vale na máquina do
laboratório, e de novo com o programa compilado para x86 de 32 bits:

```go
// Command intsize prints how wide int is on the machine it was built for.
package main

import (
	"fmt"
	"math"
	"strconv"
)

func main() {
	fmt.Println("int is", strconv.IntSize, "bits")
	fmt.Println("largest int:", math.MaxInt)
	fmt.Printf("%T %T %T\n", 42, 4.2, 2i)
}
```

```
ana@vm:~/numbers$ go run .
int is 64 bits
largest int: 9223372036854775807
int float64 complex128
ana@vm:~/numbers$ GOARCH=386 go run .
int is 32 bits
largest int: 2147483647
int float64 complex128
```

**`int` tem 64 bits no amd64 do laboratório, e 32 bits quando o mesmo código é compilado para x86
de 32 bits.** O mesmo código-fonte deu dois valores máximos diferentes, e esse é o motivo para
escolher um tipo com tamanho sempre que o tamanho faz parte do significado: um formato de arquivo,
um protocolo de rede, uma coluna de banco de dados. Para todo o resto, contar, indexar e medir
tamanhos, use `int`. O `len` devolve um `int`, e os índices de todo slice e de toda string também
são `int`, então um programa que usa `int` nos seus contadores nunca precisa converter entre eles.
A última linha mostra os tipos que Go dá a um literal numérico quando nada mais diz: um número
inteiro é `int`, um número com ponto é `float64` e um com `i` é `complex128`.

Tipos sem sinal são para bits e bytes: hashes, flags, dados brutos. Não são um jeito de dizer "esta
contagem nunca pode ser negativa", e o próximo programa mostra por quê.

## Dando a volta

```go
package main

import "fmt"

func main() {
	var small int8 = 127
	small++
	fmt.Println(small)

	var count uint = 0
	count--
	fmt.Println(count)
}
```

```
ana@vm:~/numbers-wrap$ go run .
-128
18446744073709551615
```

`127 + 1` num `int8` é −128, e `0 − 1` num `uint` é 18446744073709551615, o maior `uint` que
existe. **Overflow de inteiro em tempo de execução é silencioso: sem erro, sem panic, só um valor
que deu a volta no círculo.** Um contador `uint` decrementado uma vez a mais não vira −1. Ele vira
o maior número que o tipo guarda, e toda linha que confiava que ele era pequeno agora está errada.

O compilador confere o que pode. Uma constante não tem tempo de execução, então uma constante que
não cabe é recusada antes de o programa existir, a mesma checagem que a lição 5 mostrou para um
`1 << 100` sem tipo:

```go
package main

import "fmt"

const limit int8 = 127

func main() {
	var small int8 = 128
	next := limit + 1
	fmt.Println(small, next)
}
```

```
ana@vm:~/numbers-const$ go build
# example.com/const
./main.go:8:19: cannot use 128 (untyped int constant) as int8 value in variable declaration (overflows)
./main.go:9:10: limit + 1 (constant 128 of type int8) overflows int8
```

`limit + 1` foi recusado porque `limit` é uma constante com tipo, então a soma também é uma
constante do tipo `int8`, e 128 não é uma. Transforme `limit` em variável e a mesma linha compila,
e dá a volta.

## Divisão e resto

A divisão inteira tem duas regras que as pessoas erram, e um programa mostra as duas:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n"
    },
    {
      "code": "\tfmt.Println(7 / 2)\n",
      "note": "**Dividir dois inteiros dá um inteiro**, e a parte depois da vírgula é descartada: 3, não 3,5."
    },
    {
      "code": "\tfmt.Println(-7 / 2)\n",
      "note": "**Descartar quer dizer truncar em direção ao zero, não arredondar para baixo.** −3,5 vira −3. Uma linguagem que arredonda para baixo imprimiria −4 aqui, e Python imprime."
    },
    {
      "code": "\tfmt.Println(7 % 3)\n",
      "note": "`%` é o resto dessa divisão: 7 é 2 × 3 mais 1."
    },
    {
      "code": "\tfmt.Println(-7 % 3)\n",
      "note": "O resto fica com o sinal do número que está sendo dividido, então é −1. Os dois operadores combinam entre si: `(a / b) * b + a % b` é `a` para qualquer `b` que não seja zero."
    },
    {
      "code": "\tfmt.Println(7.0 / 2)\n}\n",
      "note": "`7.0` é uma constante de ponto flutuante, então esta divisão é entre floats e mantém a fração."
    }
  ],
  "output": "3\n-3\n1\n-1\n3.5\n"
}
```

Dividir por zero é onde os inteiros e o compilador se separam de novo. Com constantes, é recusado:

```go
package main

import "fmt"

func main() {
	fmt.Println(10 / 0)
}
```

```
ana@vm:~/numbers-zero$ go build
# example.com/zero
./main.go:6:19: invalid operation: division by zero
```

Com uma variável o compilador não tem como saber, então o programa compila e para quando a divisão
roda:

```go
package main

import "fmt"

func main() {
	d := 0
	fmt.Println(10 / d)
	fmt.Println("never printed")
}
```

```
ana@vm:~/numbers-zero$ go build && ./zero; echo $?
panic: runtime error: integer divide by zero

goroutine 1 [running]:
main.main()
	/home/ana/numbers-zero/main.go:7 +0x9
2
```

Isso é um **panic**: o programa para, imprime o que deu errado e onde (`main.go:7`, a divisão) e
sai com status 2. O `never printed` não foi impresso. A lição 36 trata de panics e a lição 37 lê o
resto dessa saída linha a linha. Divisão de ponto flutuante por zero não dá panic, como mostra a
seção 02, e esse é um dos poucos lugares em que os dois tipos de número se comportam de modo
completamente diferente.
