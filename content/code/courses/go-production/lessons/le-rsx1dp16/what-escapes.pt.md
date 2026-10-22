---
title: O que faz um valor escapar
version: 1
---

A seção 02 encontrou o primeiro motivo no `At`: **um endereço devolvido a quem chama**. Todos os outros
motivos são a mesma regra com outra cara, e nenhum deles se escreve `&` no código. Uma interface
guarda um ponteiro para o conteúdo, uma closure guarda ponteiros para as variáveis que usa, um map
guarda as chaves, e um method value guarda o receptor. Quando quem guarda sobrevive à chamada, aquilo
para o que ele aponta sobrevive também.

Cada caso abaixo é um arquivo pequeno num segundo pacote, `why`, e cada um é consultado sozinho,
filtrando o relatório do compilador com `grep` pelo nome do arquivo. O pacote inteiro é compilado
toda vez, então as linhas de um arquivo não dependem de quais outros arquivos estão lá.

## Um valor numa interface

`why/iface.go`:

```go
package why

import "fmt"

// Show prints n.
func Show(n int) {
	fmt.Println(n)
}

// Box returns n inside an interface.
func Box(n int) any {
	return n
}
```

```
ana@vm:~/escape$ go build -gcflags=-m ./why 2>&1 | grep iface.go
why/iface.go:6:6: can inline Show
why/iface.go:11:6: can inline Box
why/iface.go:7:13: inlining call to fmt.Println
why/iface.go:7:13: ... argument does not escape
why/iface.go:7:14: n escapes to heap
why/iface.go:12:9: n escapes to heap
```

**`n escapes to heap` num simples `int`, duas vezes.** Um valor de interface são duas palavras, um tipo
e um ponteiro para os dados, então um `int` posto em `any` precisa de algum lugar para onde apontar.
No `Box` a interface é devolvida, então esse lugar precisa sobreviver à chamada. No `Show` nada é
devolvido, e o motivo está um nível abaixo:

```
ana@vm:~/escape$ go build -gcflags=-m=2 ./why 2>&1 | grep -A9 "iface.go:7:14: n escapes to heap in"
why/iface.go:7:14: n escapes to heap in Show:
why/iface.go:7:14:   flow: {storage for ... argument} ← &{storage for n}:
why/iface.go:7:14:     from n (spill) at why/iface.go:7:14
why/iface.go:7:14:     from ... argument (slice-literal-element) at why/iface.go:7:13
why/iface.go:7:14:   flow: fmt.a ← &{storage for ... argument}:
why/iface.go:7:14:     from ... argument (spill) at why/iface.go:7:13
why/iface.go:7:14:     from fmt.a := ... argument (assign-pair) at why/iface.go:7:13
why/iface.go:7:14:   flow: {heap} ← *fmt.a:
why/iface.go:7:14:     from fmt.Fprintln(os.Stdout, fmt.a...) (call parameter) at why/iface.go:7:13
why/iface.go:7:13: ... argument does not escape
```

Lendo de cima: `n` é guardado na fatia que contém os argumentos do `Println`, a fatia vira `fmt.a`, e
`fmt.Fprintln(os.Stdout, fmt.a...)` é uma chamada cujo parâmetro vaza para o heap. **O `Println` foi
inlined, o `Fprintln` não**, e o resumo que o compilador escreveu quando compilou o pacote `fmt` diz
que os argumentos do `Fprintln` vazam. O relatório para aí: um resumo de outro pacote é usado como
está, e os motivos dele estão no relatório daquele pacote. A última linha é a outra metade da
história: `... argument does not escape`. A própria fatia de argumentos fica na pilha; só os valores
postos nela se mudam. Todo `fmt.Println(x)` de um valor que não é ponteiro num laço quente é este
caso, e a seção 05 mostra que o runtime às vezes se livra da alocação que o compilador previu.

## Uma closure

`why/closure.go`:

```go
package why

// Counter returns a function that counts its own calls.
func Counter() func() int {
	n := 0
	return func() int {
		n++
		return n
	}
}

// Each calls f on every element of xs.
func Each(xs []int, f func(int)) {
	for _, x := range xs {
		f(x)
	}
}

// Total adds up xs with a closure that never leaves the call.
func Total(xs []int) int {
	t := 0
	Each(xs, func(x int) { t += x })
	return t
}
```

```
ana@vm:~/escape$ go build -gcflags=-m ./why 2>&1 | grep closure.go
why/closure.go:4:6: can inline Counter
why/closure.go:6:9: can inline Counter.func1
why/closure.go:13:6: can inline Each
why/closure.go:20:6: can inline Total
why/closure.go:22:11: can inline Total.func1
why/closure.go:22:6: inlining call to Each
why/closure.go:22:6: inlining call to Total.func1
why/closure.go:5:2: moved to heap: n
why/closure.go:6:9: func literal escapes to heap
why/closure.go:13:11: xs does not escape
why/closure.go:13:21: f does not escape
why/closure.go:20:12: xs does not escape
```

A closure do `Counter` incrementa `n` depois que o `Counter` retornou, então `n` não pode morar no
quadro do `Counter`: **`moved to heap: n`**, e o valor de função que se refere a ele, devolvido também,
é um `func literal` que escapa. O `Total` também monta uma closure e não recebe veredito nenhum,
porque o `Each` e a closure foram ambos inlined nele e não sobrou closure. Desligar o inlining com
`-l` mostra o que o `Total` decide sozinho:

```
ana@vm:~/escape$ go build -gcflags='-m -l' ./why 2>&1 | grep closure.go:22
why/closure.go:22:11: func literal does not escape
```

A closure fica na pilha do `Total` mesmo sendo uma closure de verdade passada a uma chamada de
verdade, e o motivo é a linha `f does not escape` acima dela, escrita para o `Each`. **O resumo que
uma função chamada faz dos seus parâmetros é o que deixa quem chama ficar com os seus valores**: o
`Each` chama `f` e não guarda nada, então a closure do `Total`, e o `t` que ela altera, podem estar no
quadro do `Total`.

## Uma chave de map

`why/words.go`:

```go
package why

// Add counts the word in b.
func Add(m map[string]int, b []byte) {
	m[string(b)]++
}

// Get reads the count for the word in b.
func Get(m map[string]int, b []byte) int {
	return m[string(b)]
}
```

```
ana@vm:~/escape$ go build -gcflags=-m ./why 2>&1 | grep words.go
why/words.go:4:6: can inline Add
why/words.go:9:6: can inline Get
why/words.go:4:10: m does not escape
why/words.go:4:28: b does not escape
why/words.go:5:11: string(b) escapes to heap
why/words.go:9:10: m does not escape
why/words.go:9:28: b does not escape
why/words.go:10:18: string(b) does not escape
```

A mesma conversão, `string(b)`, recebe vereditos opostos. **Um map guarda as chaves que recebe**, e o
map mora no heap, então a string que o `Add` monta precisa estar lá também. O `Get` só procura a chave,
e nada guarda a string quando a consulta termina. A seção 06 encontra exatamente esta linha dentro do
`hits`.

## Anexar a uma fatia recebida

`why/push.go`:

```go
package why

// Push appends v to s and returns the result.
func Push(s []int, v int) []int {
	return append(s, v)
}
```

```
ana@vm:~/escape$ go build -gcflags=-m ./why 2>&1 | grep push.go
why/push.go:4:6: can inline Push
why/push.go:4:11: leaking param: s to result ~r0 level=0
why/push.go:5:15: append escapes to heap
```

Duas linhas sobre uma instrução. **`leaking param: s to result`** diz que o array por trás de `s` pode
sair no resultado, que é o que o `append` faz quando há espaço; se esse array escapa ou não, cada
chamador decide. **`append escapes to heap`** trata do outro caso: quando não há espaço, o `append`
aloca um array novo, e como ele é devolvido, é alocado no heap.

## Um method value

`why/method.go`:

```go
package why

// Clock counts ticks.
type Clock struct{ ticks int }

// Tick moves the clock on by one.
func (c *Clock) Tick() { c.ticks++ }

// TickTwice uses a method value inside the function.
func TickTwice(c *Clock) {
	f := c.Tick
	f()
	f()
}

// Ticker hands a method value to the caller.
func Ticker(c *Clock) func() {
	return c.Tick
}
```

```
ana@vm:~/escape$ go build -gcflags=-m ./why 2>&1 | grep method.go
why/method.go:7:6: can inline (*Clock).Tick
why/method.go:17:6: can inline Ticker
why/method.go:7:7: c does not escape
why/method.go:10:16: c does not escape
why/method.go:11:8: c.Tick does not escape
why/method.go:17:13: leaking param: c
why/method.go:18:10: c.Tick escapes to heap
```

`c.Tick` sem a chamada é um method value: uma função com `c` amarrado dentro, que é uma closure com
outro nome. **Usado dentro do `TickTwice`, ele fica na pilha** (`c.Tick does not escape`), e por isso
`c` também não escapa. Devolvido pelo `Ticker`, ele escapa e leva o receptor junto: `leaking param: c`,
sem "to result", é a forma do resumo que significa o próprio heap. Quem escrever `Ticker(&clk)` vai
achar `moved to heap: clk` no próprio relatório.
