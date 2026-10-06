---
title: "`make`, slices vazias e slices nil"
version: 1
---

A seção 03 contou quanto custa crescer: doze arrays alocados e preenchidos para 2.000 números.
Quando você sabe o tamanho de antemão, pode pagar por um array só, e o `make` é como você diz isso.
A documentação dele para slices tem quatro frases:

```
ana@vm:~/slices-make-doc$ go doc builtin.make | head -15
package builtin // import "builtin"

func make(t Type, size ...IntegerType) Type
    The make built-in function allocates and initializes an object of type
    slice, map, or chan (only). Like new, the first argument is a type,
    not a value. Unlike new, make's return type is the same as the type of its
    argument, not a pointer to it. The specification of the result depends on
    the type:

      - Slice: The size specifies the length. The capacity of the slice is equal
        to its length. A second integer argument may be provided to specify a
        different capacity; it must be no smaller than the length. For example,
        make([]int, 0, 10) allocates an underlying array of size 10 and returns
        a slice of length 0 and capacity 10 that is backed by this underlying
        array.
```

Então `make([]int, 0, 2000)` é uma slice vazia sobre um array com espaço para 2.000. O mesmo laço
da seção 03, uma vez sem `make` e outra com ele, contando os arrays e as cópias:

```go
package main

import "fmt"

func main() {
	var grown []int
	arrays, copied := 0, 0
	for i := 0; i < 2000; i++ {
		if len(grown) == cap(grown) {
			arrays++
			copied += len(grown)
		}
		grown = append(grown, i)
	}
	fmt.Println("append alone:", arrays, "new arrays,", copied, "elements copied")

	sized := make([]int, 0, 2000)
	arrays, copied = 0, 0
	for i := 0; i < 2000; i++ {
		if len(sized) == cap(sized) {
			arrays++
			copied += len(sized)
		}
		sized = append(sized, i)
	}
	fmt.Println("make first:  ", arrays, "new arrays,", copied, "elements copied")
}
```

```
ana@vm:~/slices-make$ go run .
append alone: 12 new arrays, 4940 elements copied
make first:   0 new arrays, 0 elements copied
```

`len(grown) == cap(grown)` é o momento logo antes de o `append` precisar de um array novo, e nesse
momento ele copia todos os elementos que a slice guarda. Sem `make`, 2.000 appends moveram 4.940
elementos, duas vezes e meia os dados, por doze arrays. Com ele, o `append` nunca saiu do primeiro.
**Quando o tamanho final é conhecido, ou um limite superior razoável, passe-o ao `make` como
capacidade.** Quando não é, acrescentar a uma slice que começa vazia é o normal, e a seção 03
mostrou por que isso sai barato o bastante.

## Comprimento ou capacidade: a armadilha do argumento único

O erro mais comum com `make` é passar o tamanho como único argumento e depois usar `append`:

```go
package main

import (
	"fmt"
	"strings"
)

func main() {
	names := []string{"ana", "bia", "caio"}
	upper := make([]string, len(names))
	for i := 0; i < len(names); i++ {
		upper = append(upper, strings.ToUpper(names[i]))
	}
	fmt.Println(len(upper), upper)
	fmt.Printf("%q\n", upper)
}
```

```
ana@vm:~/slices-zeros$ go run .
6 [   ANA BIA CAIO]
["" "" "" "ANA" "BIA" "CAIO"]
```

Seis nomes onde deveria haver três. **`make([]string, 3)` já é uma slice de três strings, cada uma
a string vazia; não é espaço para três.** O `append` acrescenta depois do comprimento, então os
nomes de verdade caem nas posições 3, 4 e 5. O `Println` mostra as três strings vazias como lacunas
fáceis de não ver, e o `%q` põe aspas em cada uma para você poder contar. Há duas versões corretas,
e elas não se misturam: `make([]string, 0, len(names))` com `append`, ou `make([]string,
len(names))` com `upper[i] = …` escrevendo em cada posição.

A ordem dos dois números é comprimento, depois capacidade. Com constantes, o compilador confere:

```go
package main

import "fmt"

func main() {
	fmt.Println(make([]int, 10, 3))
}
```

```
ana@vm:~/slices-swap$ go run .
# example.com/swap
./main.go:6:26: invalid argument: length and capacity swapped
```

## Uma slice nil e uma vazia

Uma slice sem elementos vem em dois tipos, e quase todo o Go não consegue distingui-los:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"encoding/json\"\n\t\"fmt\"\n)\n\nfunc main() {\n\tvar none []string\n\tempty := []string{}\n",
      "note": "**`var` dá a uma slice o seu valor zero, que é `nil`: nenhum array**, comprimento 0, capacidade 0. O literal `[]string{}` dá uma slice de comprimento 0 que não é `nil`."
    },
    {
      "code": "\tfmt.Println(none, empty)\n\tfmt.Println(len(none), len(empty))\n",
      "note": "As duas imprimem `[]` e as duas têm comprimento 0. Nem o `fmt` nem o `len` veem diferença."
    },
    {
      "code": "\tfmt.Println(none == nil, empty == nil)\n",
      "note": "O `== nil` vê. É a única comparação que uma slice aceita; a lição 13 mostra o compilador recusando `==` entre duas slices."
    },
    {
      "code": "\n\ta, _ := json.Marshal(none)\n\tb, _ := json.Marshal(empty)\n\tfmt.Println(string(a), string(b))\n",
      "note": "**O `encoding/json` escreve uma slice nil como `null` e uma vazia como `[]`.** Quem lê esperando uma lista recebe `null` da primeira. O `_` descarta o erro que o `Marshal` também devolve, o que a lição 20 explica, e a lição 15 é sobre JSON."
    },
    {
      "code": "\n\tnone = append(none, \"ana\")\n\tfmt.Println(none, len(none))\n}\n",
      "note": "`append` numa slice nil funciona, e aloca o primeiro array sozinho. Você nunca precisa de `make` só para ter onde acrescentar."
    }
  ],
  "output": "[] []\n0 0\ntrue false\nnull []\n[ana] 1"
}
```

A regra prática sai dessa saída. Declare com `var s []T` quando quer dizer "nada ainda", porque a
slice nil se comporta como vazia em tudo o que importa dentro do programa. **Teste se está vazia
com `len(s) == 0`, nunca com `s == nil`**, porque a segunda forma é falsa para `[]string{}` e
verdadeira só para uma das duas. E onde a slice sai do programa como JSON, decida qual de `null` e
`[]` quem lê espera, e comece de `[]string{}` ou de `make` se for a segunda.
