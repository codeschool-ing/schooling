---
title: Parâmetros de tipo, e a biblioteca construída com eles
version: 1
---

O primeiro palpite comum sobre uma função genérica é que ela é uma função que recebe `any` com outro
nome: aceita qualquer tipo e se vira por dentro. **É o contrário.** Uma função genérica é escrita uma
vez com um **parâmetro de tipo**, um nome que representa um tipo escolhido por quem chama, e o
compilador confere cada chamada contra os tipos que esse parâmetro admite. Nada é resolvido em tempo
de execução, porque não sobra nada para resolver. Aqui está o `Sum` da seção 02, escrito uma vez, em
`~/generics-sum`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc Sum[T int | float64](xs []T) T {\n",
      "note": "**Os colchetes depois do nome declaram um parâmetro de tipo.** `T` é o nome dele e `int | float64` é a lista de tipos que ele pode representar. Os parâmetros comuns usam `T` como qualquer tipo: entra uma slice de `T` e sai um `T`."
    },
    {
      "code": "\tvar total T\n",
      "note": "Uma variável do tipo `T`. Ela começa no valor zero do que `T` vier a ser, `0` ou `0.0`, como a lição 6 prometeu que toda variável começa."
    },
    {
      "code": "\tfor _, x := range xs {\n\t\ttotal += x\n\t}\n\treturn total\n}\n",
      "note": "**`+=` é permitido porque todo tipo da lista tem `+`.** O compilador conferiu este corpo uma vez, contra a lista inteira, e o corpo é o laço da seção 02, sem mudança."
    },
    {
      "code": "\nfunc main() {\n\tints := Sum([]int{3, 4, 5})\n\tfloats := Sum([]float64{1.5, 2.25})\n\tfmt.Printf(\"%v %T\\n\", ints, ints)\n\tfmt.Printf(\"%v %T\\n\", floats, floats)\n}\n",
      "note": "As chamadas não citam tipo nenhum. O compilador lê `T` no argumento, `int` a partir de um `[]int`, e o resultado volta nesse mesmo tipo, que o `%T` imprime."
    }
  ],
  "output": "12 int\n3.75 float64"
}
```

Compare a saída com a da seção 02. `SumAny` devolvia um `float64` fosse qual fosse a entrada; `Sum`
devolveu um `int` para os `int`, porque o resultado dele é declarado como `T`. **O tipo que quem
chama tinha é o tipo que recebe de volta**, sem conversão em nenhuma das pontas.

A chamada errada que `SumAny` transformava em panic agora é recusada antes de o programa existir. O
mesmo `Sum`, em `~/generics-sumbad`, chamado com uma slice de `int64` e uma de `string`:

```go
func main() {
	var stock int64 = 7
	fmt.Println(Sum([]int64{3, stock}))
	fmt.Println(Sum([]string{"a", "b"}))
}
```

```
ana@vm:~/generics-sumbad$ go run .; echo $?
# example.com/generics-sumbad
./main.go:15:17: int64 does not satisfy int | float64 (int64 missing in int | float64)
./main.go:16:17: string does not satisfy int | float64 (string missing in int | float64)
1
```

A mensagem diz o tipo oferecido, a lista contra a qual ele foi conferido e o que falta nessa lista.
Acrescentar `int64` à lista tornaria a primeira chamada válida. Acrescentar `string` tornaria a
segunda válida também, e `Sum` passaria a juntar texto, porque é isso que `+` faz com strings. Se
isso conta como soma é decisão de quem escreve, e a lista é onde a decisão fica registrada. A lista
depois do parâmetro de tipo se chama **restrição** (em inglês, *constraint*), e a lição 31 é sobre
escrevê-las, inclusive a que falta nesta lista, que é o motivo de `int | float64` recusar um tipo
como o `Celsius` da lição 10.

Então a quarta linha da tabela da seção 02 fica assim: escrita uma vez, tipo errado pego pelo
compilador, e quem chama não paga nada. É esse o argumento inteiro a favor dos parâmetros de tipo, e
ele é estreito. Eles servem para código cuja **lógica é a mesma para todo tipo e só o tipo muda**.

## A biblioteca padrão é escrita assim

O sinal mais claro de como generics são comuns em Go é a biblioteca padrão, onde pacotes inteiros
são feitos deles. `slices` guarda as operações que todo programa faz com slices, cada uma escrita
uma vez para todo tipo de elemento:

```
ana@vm:~/generics-std$ go doc slices.Sort
package slices // import "slices"

func Sort[S ~[]E, E cmp.Ordered](x S)
    Sort sorts a slice of any ordered type in ascending order. When sorting
    floating-point numbers, NaNs are ordered before other values.

```

Essa assinatura é a da função que `sort.Ints` chama hoje. Os colchetes declaram dois parâmetros de
tipo, `S` para a slice e `E` para os elementos dela, e `cmp.Ordered` é uma restrição que o pacote
`cmp` define para todo tipo em que `<` funciona. A lição 31 lê essa linha pedaço por pedaço. O que
importa aqui é a consequência: **um único `Sort` ordena `int`, `string` e qualquer outro tipo
ordenável**, onde o `sort` precisava de uma cópia para cada.

O mesmo vale para buscar, comparar e pegar o maior elemento, e o `maps` faz o mesmo trabalho para
maps. Em `~/generics-std`:

```go
package main

import (
	"fmt"
	"maps"
	"slices"
)

func main() {
	ages := []int{41, 7, 23}
	names := []string{"caio", "ana", "bia"}

	slices.Sort(ages)
	slices.Sort(names)
	fmt.Println(ages, names)

	fmt.Println(slices.Index(names, "bia"), slices.Contains(ages, 23))
	fmt.Println(slices.Max(ages), slices.Max(names))

	stock := map[string]int{"pear": 4, "fig": 0, "plum": 9}
	fmt.Println(slices.Sorted(maps.Keys(stock)))
}
```

```
ana@vm:~/generics-std$ go run .
[7 23 41] [ana bia caio]
1 true
41 caio
[fig pear plum]
```

Toda chamada acima é a uma função genérica, e nenhuma delas menciona um tipo. `slices.Index`
devolveu `1` para `"bia"` nos nomes já ordenados; `slices.Max` achou o maior `int` e a última
`string` em ordem alfabética; `slices.Sorted(maps.Keys(stock))` é a linha que a lição 14 usou para
imprimir as chaves de um map em ordem. **Você chama funções genéricas desde o `slices.Clone` da
lição 12, e nada nas chamadas dizia isso.** É esse o objetivo da inferência: quem chama escreve Go
comum, e os colchetes são assunto de quem escreve a biblioteca.

O pacote `slices` inteiro cabe numa tela de `go doc`:

```
ana@vm:~/generics-std$ go doc slices | wc -l
44
```

Quarenta e quatro linhas, e abaixo das quatro do topo cada uma é uma função escrita uma vez para todo
tipo de elemento. A lista do `sort` na seção 02 precisava de nove linhas para três operações em três
tipos.
