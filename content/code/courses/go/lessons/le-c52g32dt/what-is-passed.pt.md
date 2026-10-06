---
title: O que uma função recebe
version: 1
---

Uma função em Go recebe uma cópia de cada argumento; a lição 22 faz disso a regra para todo tipo. O
que muda de tipo para tipo é o que é copiado. A seção 02 mostrou que, para um array, são todos os
elementos, então `zero(a)` mudou uma cópia e `a` ficou com o seu 1. Para uma slice, a cópia são as
três palavras da seção 03, e os tamanhos confirmam:

```go
package main

import (
	"fmt"
	"unsafe"
)

func main() {
	var big [1000]int
	s := big[:]
	fmt.Println(unsafe.Sizeof(big), unsafe.Sizeof(s))
	fmt.Println(len(s), cap(s))
}
```

```
ana@vm:~/arrays-size$ go run .
8000 24
1000 1000
```

`unsafe.Sizeof` informa quantos bytes um valor ocupa ele mesmo, e aqui serve só para medir. Um
array de mil `int` tem 8000 bytes, oito por elemento. Uma slice sobre ele inteiro tem 24: três
palavras de oito bytes, um ponteiro, um comprimento e uma capacidade, seja o que for que o array
guarde por trás. `big[:]` é a slice do array inteiro, do índice 0 até o fim.

**Passar uma slice copia 24 bytes e divide o array; passar um array copia o array.** As duas
metades dessa frase têm consequência, e o programa abaixo mostra cada uma.

## Elementos sim, comprimento não

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc setFirst(s []int) {\n\ts[0] = 100\n}\n",
      "note": "**Mudar um elemento pelo parâmetro muda o elemento de quem chamou.** `s` é uma cópia da slice de quem chamou, e o ponteiro dela leva ao mesmo array."
    },
    {
      "code": "\nfunc addFour(s []int) {\n\ts = append(s, 4)\n\tfmt.Println(\"inside: \", s, len(s))\n}\n",
      "note": "`append` devolve uma slice com um elemento a mais, e esta função a guarda em `s`, **a sua própria cópia**. Lá dentro, `s` tem quatro elementos."
    },
    {
      "code": "\nfunc main() {\n\tnums := []int{1, 2, 3}\n\n\tsetFirst(nums)\n\tfmt.Println(\"after setFirst:\", nums)\n",
      "note": "Depois de `setFirst`, a slice de quem chamou começa com `100`."
    },
    {
      "code": "\n\taddFour(nums)\n\tfmt.Println(\"after addFour: \", nums, len(nums))\n}\n",
      "note": "**Depois de `addFour`, a slice de quem chamou continua com três elementos.** O 4 foi para uma slice que só existia dentro de `addFour`."
    }
  ],
  "output": "after setFirst: [100 2 3]\ninside:  [100 2 3 4] 4\nafter addFour:  [100 2 3] 3"
}
```

As duas funções parecem iguais e se comportam de jeitos opostos. `setFirst` escreveu pelo ponteiro
da sua cópia, e esse ponteiro leva ao mesmo array que `nums` usa, então quem chamou vê o `100`.
`addFour` mudou o seu próprio `s`: atribuiu um comprimento novo, e talvez um ponteiro novo, a uma
variável que só existe dentro de `addFour`. A slice de quem chamou nunca foi tocada, e **continua
dizendo comprimento 3, seja o que for que o `append` tenha feito por baixo.**

Essa última oração é vaga de propósito. Se o `append` escreveu o 4 no mesmo array ou num novo
depende da capacidade, e a lição 12 mostra os dois casos e o que cada um faz com quem chamou. Para
esta lição tanto faz: em nenhum dos casos o comprimento de quem chamou muda.

## Devolva a slice

A correção é a que a biblioteca padrão usa em todo lugar: uma função que pode aumentar uma slice
devolve a nova, e quem chama a guarda.

```go
package main

import "fmt"

func withFour(s []int) []int {
	return append(s, 4)
}

func main() {
	nums := []int{1, 2, 3}
	nums = withFour(nums)
	fmt.Println(nums, len(nums))
}
```

```
ana@vm:~/arrays-return$ go run .
[1 2 3 4] 4
```

O próprio `append` tem exatamente esse formato. Recebe uma slice e devolve uma, e **o resultado é
a única slice com garantia de ter o que foi acrescentado**. O compilador chega a recusar uma chamada
que o joga fora:

```go
package main

import "fmt"

func main() {
	nums := []int{1, 2, 3}
	append(nums, 4)
	fmt.Println(nums)
}
```

```
ana@vm:~/arrays-forgot$ go run .
# example.com/arrays-forgot
./main.go:7:2: append(nums, 4) (value of type []int) is not used
```

É por isso que `s = append(s, x)` se escreve com o mesmo nome dos dois lados. É também por isso que
o `addFour` lá de cima compilou: ele atribuiu o resultado, sim, a uma cópia que mais ninguém via.

Então, a resposta à pergunta da lição:

| você passa | a função recebe | ela pode mudar os seus elementos | ela pode mudar o seu comprimento |
|---|---|---|---|
| um array `[3]int` | uma cópia de todos os elementos | não | não, ele é fixo |
| uma slice `[]int` | uma cópia das três palavras | sim, pelo array dividido | não, devolva a slice |
