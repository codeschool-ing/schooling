---
title: Números complexos, embutidos
version: 1
---

Go tem números complexos na própria linguagem, como Python, e não numa biblioteca. A maioria dos
programas nunca os usa. Processamento de sinais, engenharia elétrica e um pouco de geometria usam,
e para esses casos eles poupam uma página de código. São dois tipos: `complex128`, feito de dois
`float64`, e `complex64`, feito de dois `float32`.

```go
package main

import (
	"fmt"
	"math"
	"math/cmplx"
)

func main() {
	z := complex(3, 4)
	fmt.Println(z, real(z), imag(z))
	fmt.Println(cmplx.Abs(z))

	w := 2i
	fmt.Println(w * w)

	fmt.Println(math.Sqrt(-1), cmplx.Sqrt(-1))
	fmt.Printf("%T\n", z)
}
```

```
ana@vm:~/numbers-complex$ go run .
(3+4i) 3 4
5
(-4+0i)
NaN (0+1i)
complex128
```

`complex(3, 4)` monta o número 3 + 4i, e as funções embutidas `real` e `imag` o desmontam de novo.
Um literal numérico terminado em `i` é imaginário, então `2i` já é um número complexo sozinho, e
`2i * 2i` é −4, como deve ser. **A aritmética funciona com números complexos usando os operadores
de sempre**; o que vai além da aritmética, como o valor absoluto, que é 5 para 3 + 4i, fica no
pacote `math/cmplx`.

A raiz quadrada mostra por que os dois pacotes são separados. O `math.Sqrt(-1)` trabalha com os
números reais, onde −1 não tem raiz quadrada, então devolve `NaN`, como a seção 02 mostrou. O
`cmplx.Sqrt(-1)` trabalha com os números complexos, onde a resposta é `i`, impressa como `(0+1i)`.
**O pacote que você chama decide entre quais números a resposta pode estar.**
