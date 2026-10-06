---
title: Um trabalho, vários tipos e três jeitos de contornar
version: 1
---

Cedo ou tarde um programa precisa da mesma função para dois tipos. Somar uma slice é o menor caso
possível: um laço, uma variável, um `+`. Escrita para `int` e depois para `float64`, em
`~/generics`, ela fica assim:

```go
package main

import "fmt"

func SumInts(xs []int) int {
	var total int
	for _, x := range xs {
		total += x
	}
	return total
}

func SumFloats(xs []float64) float64 {
	var total float64
	for _, x := range xs {
		total += x
	}
	return total
}

func main() {
	fmt.Println(SumInts([]int{3, 4, 5}))
	fmt.Println(SumFloats([]float64{1.5, 2.25}))
}
```

```
ana@vm:~/generics$ go run .
12
3.75
ana@vm:~/generics$ diff <(sed -n 5,11p main.go) <(sed -n 13,19p main.go)
1,2c1,2
< func SumInts(xs []int) int {
< 	var total int
---
> func SumFloats(xs []float64) float64 {
> 	var total float64
```

O `diff` comparou as sete linhas de uma função com as sete linhas da outra. **Elas diferem em duas
linhas, e nessas duas linhas só os tipos mudam.** O laço, o `+=` e o `return` são o mesmo texto. Um
terceiro tipo numérico quer dizer uma terceira cópia, e um bug achado numa cópia é um bug que você
precisa lembrar de corrigir em todas.

O Go 1.0 saiu em 2012 sem nenhum jeito de escrever essa função uma vez só e ainda ter o compilador
conferindo cada chamada. Os parâmetros de tipo, o recurso que esta lição e a lição 31 ensinam,
chegaram no Go 1.18, em março de 2022; a lição 2 os colocou na linha do tempo. Na década entre as
duas datas, quem programava em Go contornou a falta de três jeitos, e o pacote `sort` da biblioteca
padrão ainda carrega os três. Vale conhecer cada um, porque você vai ler código escrito de cada
jeito, e porque o terceiro continua sendo a resposta certa para outra pergunta.

## Copiar para cada tipo

O primeiro jeito é o de cima: escrever de novo. O `sort` fez exatamente isso para os três tipos de
elemento que as pessoas mais ordenam:

```
ana@vm:~/generics$ go doc sort | grep -E "Ints|Float64s|Strings"
func Float64s(x []float64)
func Float64sAreSorted(x []float64) bool
func Ints(x []int)
func IntsAreSorted(x []int) bool
func SearchFloat64s(a []float64, x float64) int
func SearchInts(a []int, x int) int
func SearchStrings(a []string, x string) int
func Strings(x []string)
func StringsAreSorted(x []string) bool
```

**Nove funções, que na verdade são três funções escritas por extenso para três tipos.** Quem precisava
ordenar um `[]int64` ou um `[]uint8` não achava nada nessa lista. A documentação da primeira mostra o
que aconteceu com as cópias quando a linguagem passou a permitir coisa melhor:

```
ana@vm:~/generics$ go doc sort.Ints
package sort // import "sort"

func Ints(x []int)
    Ints sorts a slice of ints in increasing order.

    Note: as of Go 1.22, this function simply calls slices.Sort.

```

`slices.Sort` é uma única função genérica, e a seção 03 a usa. As cópias continuam lá por causa da
promessa de compatibilidade da lição 2: código que chama `sort.Ints` tem de continuar compilando.

## Receber `any` e olhar dentro

O segundo jeito é aceitar `any`, que a lição 28 mostrou guardar um valor de qualquer tipo, e
descobrir em tempo de execução o que chegou. Um type switch, o assunto da lição 29, faz essa
descoberta:

```go
package main

import "fmt"

func SumAny(xs []any) float64 {
	var total float64
	for _, x := range xs {
		switch v := x.(type) {
		case int:
			total += float64(v)
		case float64:
			total += v
		default:
			panic(fmt.Sprintf("SumAny: cannot add %T", v))
		}
	}
	return total
}

func main() {
	fmt.Println(SumAny([]any{3, 4, 5}))
	fmt.Println(SumAny([]any{1.5, 2.25}))

	var stock int64 = 7
	fmt.Println(SumAny([]any{3, stock}))
}
```

```
ana@vm:~/generics-any$ go vet && go run . 2>&1 | head -3
12
3.75
panic: SumAny: cannot add int64
```

Uma função agora atende as duas slices, e a terceira chamada está errada: um `int64` não é nenhum
dos dois casos. O `go vet` não imprimiu nada e o compilador gerou o programa, porque
`[]any{3, stock}` é um `[]any` perfeitamente válido. **O erro foi encontrado executando o programa,
na linha que por acaso o chamou com o tipo errado.** Num teste, isso é uma falha que você lê. Num
serviço, é um panic na requisição de alguém; a lição 36 trata do que um panic faz com um programa.

Esse é o custo principal, e há mais dois menores. Quem tem um `[]int` não consegue passá-lo, pelo
motivo que a lição 21 deu a respeito de `fmt.Println`: um `[]int` não é um `[]any`, e Go não converte
um no outro. Quem chama tem de copiar cada elemento para uma slice nova antes, que é o que
`~/generics-anyslice` faz:

```go
func main() {
	ages := []int{41, 7, 23}
	fmt.Println(SumAny(ages))

	boxed := make([]any, len(ages))
	for i, a := range ages {
		boxed[i] = a
	}
	total := SumAny(boxed)
	fmt.Printf("%v %T\n", total, total)
}
```

```
ana@vm:~/generics-anyslice$ go run .
# example.com/generics-anyslice
./main.go:22:21: cannot use ages (variable of type []int) as []any value in argument to SumAny
ana@vm:~/generics-anyslice$ go run .
71 float64
```

A segunda execução é o mesmo arquivo sem a linha recusada. A soma está certa e o tipo dela não: três
`int` entraram e saiu um `float64`, porque `SumAny` precisa declarar um único tipo de resultado para
qualquer entrada. Quem queria um `int` converte de volta.

O `sort` também tem esse jeito. `sort.Slice` recebe a slice como `any`:

```
ana@vm:~/generics-sort$ go doc sort.Slice | head -4
package sort // import "sort"

func Slice(x any, less func(i, j int) bool)
    Slice sorts the slice x given the provided less function. It panics if x is
```

A documentação diz que ela entra em panic se `x` não for uma slice, e isso quer dizer em tempo de
execução. Um programa que lhe entrega o número 42 passa pelo `go vet`, compila e para:

```go
package main

import "sort"

func main() {
	sort.Slice(42, func(i, j int) bool { return false })
}
```

```
ana@vm:~/generics-sort$ go vet && go run .
panic: reflect: call of Swapper on int Value

goroutine 1 [running]:
internal/reflectlite.Swapper({0x51d4c0?, 0x487f30?})
	/usr/local/go/src/internal/reflectlite/swapper.go:20 +0x5d6
sort.Slice({0x51d4c0?, 0x487f30?}, 0x526a68)
	/usr/local/go/src/sort/slice.go:26 +0x85
main.main()
	/home/ana/generics-sort/main.go:6 +0x28
exit status 2
```

Ninguém passa 42 de propósito. Passam um ponteiro para uma slice, ou uma struct que guarda uma, e o
compilador não tem como avisar, porque `any` aceita as duas coisas.

## Dizer o que o tipo sabe fazer, com uma interface

O terceiro jeito pede métodos ao tipo de quem chama. `sort.Sort(data Interface)` ordena qualquer
coisa cujo tipo tenha três: `Len`, `Less` e `Swap`. É conferido em tempo de compilação e funciona
para tipos de que o `sort` nunca ouviu falar, que é para isso que interfaces servem (lição 27). O
preço é escrever esses três métodos para cada tipo de slice que você quer ordenar. O
`type IntSlice []int` na própria lista do pacote existe para carregá-los no caso de `[]int`.

Uma interface é a ferramenta certa quando o que varia é **comportamento**: qualquer coisa que saiba
fazer `Write`, qualquer coisa que saiba se descrever com `String`. Ela não ajuda o `Sum`. **Uma
interface lista métodos, e `+` é um operador, não um método**, então nenhuma interface comum consegue
dizer "um tipo que se pode somar".

| | escrita | um tipo errado é pego | o que quem chama paga |
|---|---|---|---|
| uma cópia por tipo | uma vez por tipo | pelo compilador | nada, se existir uma cópia para o tipo dele |
| `any` e um type switch | uma vez | em tempo de execução, por um panic | uma cópia para `[]any`, e um resultado de um tipo fixo |
| uma interface | uma vez, mais métodos por tipo | pelo compilador | três métodos no tipo dele |

Cada linha abre mão de alguma coisa. A seção 03 é a quarta linha, que não abre mão de nenhuma das
três.
