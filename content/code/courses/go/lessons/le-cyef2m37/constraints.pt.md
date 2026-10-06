---
title: Restrições são interfaces, lidas como conjuntos de tipos
version: 1
---

A parte depois do nome de um parâmetro de tipo parece sintaxe especial, uma lista de tipos separados
por barras. **É uma interface**, a mesma construção da lição 27, e toda restrição é uma. O que ela
descreve é um conjunto de tipos: os tipos que `T` pode ser. O compilador então deixa o corpo fazer o
que todo tipo do conjunto sabe fazer, e nada mais.

`any`, a interface sem métodos da lição 28, é o conjunto mais largo que existe, então é o que menos
permite. Um valor do tipo `T any` pode ser guardado, passado, devolvido e posto numa slice, e muito
pouco além disso. Até `==` é recusado, porque alguns tipos não podem ser comparados. Um `Index` que
procura numa slice, em `~/generic2-index`:

```go
package main

import "fmt"

func Index[T any](xs []T, v T) int {
	for i, x := range xs {
		if x == v {
			return i
		}
	}
	return -1
}

func main() {
	fmt.Println(Index([]string{"ana", "bia", "caio"}, "bia"))
}
```

```
ana@vm:~/generic2-index$ go run .
# example.com/generic2-index
./main.go:7:6: invalid operation: x == v (incomparable types in type set)
```

`incomparable types in type set` quer dizer que em algum lugar do conjunto que `any` descreve há um
tipo em que `==` não funciona, uma slice ou um map, por exemplo, e o corpo tem de valer para todos
eles. O erro está na linha 7, dentro de `Index`, e não na chamada: **um corpo genérico é conferido
uma vez, contra a restrição inteira, antes que alguém o chame.** Com `any` trocado por `comparable`,
o mesmo programa roda:

```
ana@vm:~/generic2-index$ go run .
1
```

`comparable` é pré-declarado, como `any`, e o `go doc` lista o que ele contém:

```
ana@vm:~/generic2-index$ go doc builtin.comparable
package builtin // import "builtin"

type comparable interface{ comparable }
    comparable is an interface that is implemented by all comparable types
    (booleans, numbers, strings, pointers, channels, arrays of comparable types,
    structs whose fields are all comparable types). The comparable interface may
    only be used as a type parameter constraint, not as the type of a variable.

```

É o mesmo conjunto de tipos que um map aceita como chave, o que a lição 14 mostrou o compilador
exigindo. Por isso `maps.Keys` declara o tipo da chave como `K comparable`.

## Uma união, e o `~` de que ela quase sempre precisa

`int | float64` é uma **união**: o conjunto que contém exatamente esses dois tipos. A lição 30 a usou
no `Sum`, e ela tem uma lacuna que um programa com tipos próprios encontra na hora. O `Celsius` da
lição 10 é um `float64` por baixo, então somar uma semana de leituras parece que deveria funcionar.
Em `~/generic2-celsius`:

```go
package main

import "fmt"

type Celsius float64

func Sum[T int | float64](xs []T) T {
	var total T
	for _, x := range xs {
		total += x
	}
	return total
}

func main() {
	week := []Celsius{20.5, 22, 19.5}
	fmt.Println(Sum(week))
}
```

```
ana@vm:~/generic2-celsius$ go run .
# example.com/generic2-celsius
./main.go:17:17: Celsius does not satisfy int | float64 (possibly missing ~ for float64 in int | float64)
```

A lição 10 disse que `Celsius` é um tipo novo com `float64` como **tipo subjacente**, não outro nome
para `float64`, e a união contém o próprio `float64` e mais nada. O compilador percebeu o que
provavelmente se queria e disse: `possibly missing ~ for float64`. **`~float64` é o conjunto de todo
tipo cujo tipo subjacente é `float64`**, o próprio `float64` incluído. Com o til nos dois membros, e a
restrição ganhando um nome para poder ser reutilizada, em `~/generic2-number`:

```go
package main

import (
	"fmt"
	"slices"
)

type Number interface {
	~int | ~float64
}

func Sum[T Number](xs []T) T {
	var total T
	for _, x := range xs {
		total += x
	}
	return total
}

type Celsius float64

func main() {
	week := []Celsius{20.5, 22, 19.5}
	total := Sum(week)
	fmt.Printf("%v %T\n", total, total)
	fmt.Println(Sum([]int{3, 4, 5}))

	slices.Sort(week)
	fmt.Println(week, slices.Max(week))
}
```

```
ana@vm:~/generic2-number$ go run .
62 main.Celsius
12
[19.5 20.5 22] 22
```

O total da semana voltou como `main.Celsius`, então a unidade que a lição 10 lhe deu sobreviveu à
passagem por uma função genérica. A última linha mostra `slices.Sort` e `slices.Max` da biblioteca
padrão aceitando a mesma slice, e o fim desta seção diz por que podem. Uma restrição declarada como
`Number` é uma declaração de interface comum cujo corpo é uma união em vez de uma lista de métodos.

As três restrições desta lição ficam uma dentro da outra, e vistas como conjuntos são assim:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Três conjuntos de tipos, um dentro do outro. O mais interno, int | float64, tem exatamente dois tipos, int e float64. Em volta dele, ~int | ~float64 tem esses dois e todo tipo cujo tipo subjacente é int ou float64, como Celsius. Em volta desse, cmp.Ordered tem todo tipo ordenável, inclusive os definidos, como string, int64 e time.Duration. Fora dos três ficam tipos como bool e []int.\"><rect x=\"20\" y=\"16\" width=\"680\" height=\"254\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">cmp.Ordered</text><text x=\"40\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">todo tipo ordenável, inclusive os definidos</text><rect x=\"44\" y=\"74\" width=\"450\" height=\"180\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"62\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">~int | ~float64</text><text x=\"62\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e todo tipo cujo tipo subjacente é int ou float64</text><rect x=\"66\" y=\"132\" width=\"210\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"84\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">int | float64</text><text x=\"84\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">exatamente estes dois tipos</text><rect x=\"94.2\" y=\"196\" width=\"35.6\" height=\"24\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"112\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">int</text><rect x=\"163.8\" y=\"196\" width=\"64.4\" height=\"24\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"196\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">float64</text><rect x=\"357.8\" y=\"178\" width=\"64.4\" height=\"24\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Celsius</text><rect x=\"571.4\" y=\"108\" width=\"57.2\" height=\"24\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">string</text><rect x=\"575.0\" y=\"158\" width=\"50.0\" height=\"24\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">int64</text><rect x=\"546.2\" y=\"208\" width=\"107.60000000000001\" height=\"24\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">time.Duration</text><text x=\"40\" y=\"302\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">em nenhuma das três</text><rect x=\"188.6\" y=\"290\" width=\"42.8\" height=\"24\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"210\" y=\"302\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">bool</text><rect x=\"255.0\" y=\"290\" width=\"50.0\" height=\"24\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"302\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[]int</text></svg>", "caption": "Três restrições como os conjuntos de tipos que elas admitem. Uma união simples admite exatamente os seus membros; um ~ admite todo tipo construído sobre eles, que é onde o Celsius cai; cmp.Ordered é ainda mais larga."}
```

**Uma interface que contém uma união é uma restrição e mais nada.** Usada como tipo de uma variável,
em `~/generic2-astype`, ela é recusada:

```go
package main

import "fmt"

type Number interface {
	~int | ~float64
}

func main() {
	var n Number = 3
	fmt.Println(n)
}
```

```
ana@vm:~/generic2-astype$ go run .
# example.com/generic2-astype
./main.go:10:8: cannot use type Number outside a type constraint: interface contains type constraints
```

Uma interface feita só de métodos, como o `fmt.Stringer` da lição 30, funciona dos dois jeitos: como
restrição em `ShowAll` e como tipo de parâmetro comum em `ShowEach`.

## `cmp.Ordered`, e as assinaturas da biblioteca padrão

Raramente você precisa escrever um `Number` para comparações, porque o pacote `cmp` tem a restrição
que a lição 30 viu em `slices.Sort`:

```
ana@vm:~/generic2-number$ go doc cmp.Ordered | head -7
package cmp // import "cmp"

type Ordered interface {
	~int | ~int8 | ~int16 | ~int32 | ~int64 |
		~uint | ~uint8 | ~uint16 | ~uint32 | ~uint64 | ~uintptr |
		~float32 | ~float64 |
		~string
```

Todo membro leva um `~`. É por isso que `slices.Sort` e `slices.Max` aceitaram a semana de leituras
em `Celsius` de `~/generic2-number` sem conversão, e devolveram `[19.5 20.5 22] 22`. **Uma restrição
de biblioteca é escrita com `~` de propósito, porque os tipos de quem chama costumam ser tipos
próprios.**

Falta uma peça das assinaturas que as lições 14, 21 e 24 encontraram e deixaram sem explicação, o
formato `S ~[]E`:

```
ana@vm:~/generic2-clone$ go doc slices.Clone | head -3
package slices // import "slices"

func Clone[S ~[]E, E any](s S) S
```

Leia da esquerda para a direita. `E any` é o tipo do elemento, qualquer um. `S ~[]E` é um tipo cujo
tipo subjacente é uma slice de `E`, o que inclui o próprio `[]E` e todo tipo definido sobre ele. O
parâmetro é um `S` e o resultado também. O motivo do segundo parâmetro de tipo aparece ao lado de uma
versão mais simples que recebe `[]E` direto, em `~/generic2-clone`:

```go
package main

import (
	"fmt"
	"slices"
)

type Names []string

func CloneFlat[E any](s []E) []E {
	return append([]E(nil), s...)
}

func main() {
	team := Names{"ana", "bia"}
	a := slices.Clone(team)
	b := CloneFlat(team)
	fmt.Printf("%T %T\n", a, b)
}
```

```
ana@vm:~/generic2-clone$ go run .
main.Names []string
```

As duas cópias guardam os mesmos dois nomes. `slices.Clone` devolveu um `Names`, então qualquer
método que `Names` tenha (lição 25) continua lá; `CloneFlat` devolveu um `[]string` simples, e o tipo
de quem chamou se perdeu no caminho. É só para isso que serve `S ~[]E`, e é por isso que quase toda
função de `slices` o declara.
