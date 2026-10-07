---
title: O que o tipo fazia por você
version: 1
---

Pôr um valor num `any` não custa nada para escrever. O custo chega quando você quer o valor de
volta: **no momento em que um valor entra num `any`, o compilador deixa de saber o tipo dele**, e
toda verificação que ele fazia por você vira trabalho seu, feito enquanto o programa roda.

## Tirando o valor de volta

O `age` do documento da seção 02 está dentro de um `map[string]any`. Para somar um a ele, você
precisa dizer que tipo espera encontrar, com uma **asserção de tipo**: `x.(T)` afirma que a
interface `x` guarda um `T`, e entrega esse `T`. Se ela guarda outra coisa, o programa para:

```go
package main

import (
	"encoding/json"
	"fmt"
)

func main() {
	var doc map[string]any
	if err := json.Unmarshal([]byte(`{"name": "Ana", "age": 31}`), &doc); err != nil {
		fmt.Println(err)
		return
	}

	age := doc["age"].(float64)
	fmt.Println("next year:", age+1)

	years := doc["age"].(int)
	fmt.Println("next year:", years+1)
}
```

```
ana@vm:~/any-age$ go run .
next year: 32
panic: interface conversion: interface {} is float64, not int

goroutine 1 [running]:
main.main()
	/home/ana/any-age/main.go:18 +0x257
exit status 2
```

`doc["age"].(float64)` devolveu um `float64`, e `age+1` compilou porque `age` voltou a ter tipo.
`doc["age"].(int)` também compilou, já que o compilador não tem como saber o que um map de `any` vai
guardar quando o programa rodar. Na execução ele guardava um `float64`, e o programa entrou em
**panic** na linha 18 com uma mensagem que nomeia os dois tipos, `interface {} is float64, not int`.
Quem lê `31` no JSON e pensa num `int` escreve exatamente essa linha, e ela passa por toda
verificação antes de rodar.

Um panic encerra o programa com status de saída 2, que é o assunto da lição 36. A lição 29 mostra
as duas formas que perguntam em vez de insistir: a asserção que responde `false` quando o tipo está
errado, e o `type switch`.

## O que o compilador recusa

Sem uma asserção, um `any` não pode ser usado como o valor que guarda, nem quando claramente guarda
um número:

```go
package main

import "fmt"

func main() {
	var a, b any = 2, 3
	fmt.Println(a + b)

	var s any = "Ana"
	fmt.Println(len(s))

	var n int = a
	fmt.Println(n)
}
```

```
ana@vm:~/any-ops$ go build
# example.com/ops
./main.go:7:14: invalid operation: operator + not defined on a (variable of interface type any)
./main.go:10:18: invalid argument: s (variable of interface type any) for built-in len
./main.go:12:14: cannot use a (variable of interface type any) as int value in variable declaration: need type assertion
```

`+` é definido para números e strings, e um `any` pode ser um, outro ou nenhum dos dois, então o
compilador não o permite em nenhum caso. `len` funciona com strings, slices, maps e alguns outros
tipos de valor, e o mesmo raciocínio o recusa. A terceira mensagem já aponta a saída:
`need type assertion`. **Um `any` aceita o que todo valor Go aceita e nada mais**: ser atribuído,
passado, impresso pelo `fmt` e comparado com `==`, e esta última tem uma pegadinha própria logo
abaixo.

## O engano sai da compilação e vai para a execução

Aqui está uma função que soma números, escrita para receber `any` e assim aceitar qualquer coisa:

```go
package main

import "fmt"

func sum(xs []any) float64 {
	total := 0.0
	for _, x := range xs {
		total += x.(float64)
	}
	return total
}

func main() {
	fmt.Println(sum([]any{1.5, 2.5}))
	fmt.Println(sum([]any{1.5, 2}))
}
```

```
ana@vm:~/any-sum$ go vet && go run .
4
panic: interface conversion: interface {} is int, not float64

goroutine 1 [running]:
main.sum(...)
	/home/ana/any-sum/main.go:8
main.main()
	/home/ana/any-sum/main.go:15 +0x16b
exit status 2
```

O `go vet` passou e a primeira chamada funcionou. A segunda quebrou num `2`. Esse `2` é uma
constante sem tipo, e a lição 5 mostrou que uma constante sem tipo assume o seu **tipo padrão**
quando nada pede outro: um número inteiro vira `int`. Um `any` não pede nada, então foi um `int`
que entrou, e a asserção para `float64` falhou. O trace tem dois quadros, `sum`, onde ocorreu o
panic, e `main`, de onde `sum` foi chamada; a lição 37 lê traces como este linha a linha.

A mesma função com o tipo escrito:

```go
package main

import "fmt"

func sum(xs []float64) float64 {
	total := 0.0
	for _, x := range xs {
		total += x
	}
	return total
}

func main() {
	fmt.Println(sum([]float64{1.5, 2.5}))
	fmt.Println(sum([]float64{1.5, 2}))
	fmt.Println(sum([]float64{1.5, "2"}))
}
```

```
ana@vm:~/any-sum-typed$ go build
# example.com/sum
./main.go:16:33: cannot use "2" (untyped string constant) as float64 value in array or slice literal
```

A linha 15 agora está certa: o slice pede `float64`, então o `2` sem tipo vira `2.0` ao entrar. E
uma string na lista, que a versão com `any` teria aceitado para depois quebrar, é recusada antes de
o programa existir, com linha e coluna. **A versão tipada acha o engano na sua máquina; a versão
com `any` o acha onde quer que o programa esteja rodando quando aquela entrada chegar.**

## `==` compila e ainda assim pode dar panic

Dois valores de interface são iguais quando guardam o mesmo tipo dinâmico e valores iguais. As duas
metades contam:

```go
package main

import "fmt"

func main() {
	var a, b any = 1, 1
	fmt.Println(a == b)

	var c, d any = 1, 1.0
	fmt.Println(c == d)

	var e, f any = []int{1}, []int{1}
	fmt.Println(e == f)
}
```

```
ana@vm:~/any-compare$ go run .
true
false
panic: runtime error: comparing uncomparable type []int

goroutine 1 [running]:
main.main()
	/home/ana/any-compare/main.go:13 +0x115
exit status 2
```

`1` e `1.0` são o mesmo número e não o mesmo valor aqui: um entrou como `int` e o outro como
`float64`, então a comparação dá falso. A terceira comparação é o custo de novo. A lição 11 mostrou
o compilador recusando `==` entre dois slices. Dentro de um `any` ele não enxerga os slices, então
o programa compilou, e a recusa veio na execução, como panic.

## Quando recorrer a `any`

A biblioteca padrão recebe `any` onde uma função aceita de fato todo tipo e decide em tempo de
execução o que fazer com cada um: o `fmt` imprime qualquer coisa, o `json.Unmarshal` preenche
qualquer coisa. Duas outras ferramentas cobrem a maior parte dos casos que à primeira vista parecem
`any`:

| o que você quer | a ferramenta | onde |
|---|---|---|
| uma função que faz a mesma coisa para vários tipos, como `sum` sobre `int` ou `float64` | generics: `Sum[T]`, conferido em cada chamada | lição 30 |
| vários tipos que compartilham um comportamento, como tudo em que se pode escrever | uma interface com métodos, como `io.Writer` | lição 27 |
| um valor de um tipo que ninguém conhecia quando o programa foi escrito | `any`, e uma asserção ou um `type switch` para lê-lo | lição 29 |

**Comece pelo tipo concreto**, e abra mão dele só quando souber dizer o que ganha em troca.
