---
title: De array para slice
version: 1
---

A lição 11 fatiou arrays para criar visões de uma parte deles. Fatiar sem número nenhum, `a[:]`, dá
uma visão do array inteiro, e é o sentido de conversão que você mais vai usar. É fácil ler `a[:]`
como "o array, transformado em slice", como se algo fosse transformado. Nada é. **`a[:]` é uma
slice cujo ponteiro é o primeiro elemento do array, com o comprimento do array como comprimento e
como capacidade; os elementos ficam onde estavam.**

```go
package main

import "fmt"

func main() {
	a := [4]int{1, 2, 3, 4}
	s := a[:]
	s[0] = 100
	fmt.Println(a, s, len(s), cap(s))
}
```

```
ana@vm:~/slicearray$ go run .
[100 2 3 4] [100 2 3 4] 4 4
```

Escrever por `s` mudou `a`, porque só existe um conjunto de quatro `int`s. Comprimento 4 e
capacidade 4: a slice alcança exatamente até onde o array vai, e o primeiro `append` nela vai ter de
copiar, como a lição 12 mostrou para qualquer slice sem espaço sobrando.

## Por que você precisa disso: funções recebem slices

Quase toda a biblioteca padrão recebe slices, porque uma slice serve para qualquer comprimento e um
tipo array fixa um só. Algumas funções devolvem arrays, pelos motivos de que trata a seção 04. O
`sha256.Sum256` é o primeiro que você vai encontrar:

```
ana@vm:~/slicearray-hash$ go doc crypto/sha256.Sum256
package sha256 // import "crypto/sha256"

func Sum256(data []byte) [Size]byte
    Sum256 returns the SHA256 checksum of the data.

```

`Size` é uma constante, 32, então o resultado é um `[32]byte`. Entregar esse array ao
`hex.EncodeToString`, que recebe um `[]byte`, é a primeira coisa que se tenta, e pular a variável
também:

```go
package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
)

func main() {
	sum := sha256.Sum256([]byte("hello"))
	fmt.Println(hex.EncodeToString(sum))
	fmt.Println(hex.EncodeToString(sha256.Sum256([]byte("hello"))[:]))
}
```

```
ana@vm:~/slicearray-hash$ go run .
# example.com/hash
./main.go:11:33: cannot use sum (variable of type [32]byte) as []byte value in argument to hex.EncodeToString
./main.go:12:33: cannot slice unaddressable value sha256.Sum256([]byte("hello")) (value of type [32]byte)
```

Duas recusas, e elas são diferentes.

A primeira é a regra da lição 10 aplicada a arrays: **Go nunca converte por você, e um `[32]byte`
não é um `[]byte`**, por mais parecidos que sejam. Um são 32 bytes; o outro é um ponteiro, um
comprimento e uma capacidade. Você precisa escrever a expressão de fatia.

A segunda é sobre para onde a slice apontaria. Uma slice é um ponteiro para dentro de um array,
então o array precisa estar em algum lugar que um ponteiro alcance: numa variável, num campo, num
elemento de outro array. O array que uma função devolve é um valor que ninguém guardou ainda, e o
compilador chama esse valor de **não endereçável** (*unaddressable*). Fatiá-lo é recusado, em vez
de o compilador guardá-lo por você em silêncio. A correção é a variável que a primeira linha já
tinha:

```go
package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
)

func main() {
	sum := sha256.Sum256([]byte("hello"))
	fmt.Println(hex.EncodeToString(sum[:]))
}
```

```
ana@vm:~/slicearray-hash$ go run .
2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
```

Sessenta e quatro dígitos hexadecimais, dois para cada um dos 32 bytes. `sum[:]` empresta ao
`EncodeToString` uma visão do array em `sum`, e nada foi copiado para isso.
