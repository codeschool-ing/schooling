---
title: Juntando com select
version: 1
---

Quando as entradas são poucas e conhecidas na hora de escrever o código, um `select` pode juntá-las
numa goroutine só, sem copiadoras e sem `WaitGroup`. A lição 5 apresentou o `select` para esperar
vários canais ao mesmo tempo. Usado como junção, ele tem uma armadilha que o `range` escondia: **um
canal fechado está sempre pronto para receber**, e entrega o valor zero do seu tipo, para sempre.

O programa abaixo esquece disso. Ele junta dois canais de três números cada e conta o que recebe
durante 100 milissegundos. É salvo em `~/fanin/spin` como `spin.go`:

```go
// Command spin merges two channels with select and forgets that a closed channel is always ready.
package main

import (
	"fmt"
	"time"
)

func numbers(n int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for i := 1; i <= n; i++ {
			out <- i
		}
	}()
	return out
}

func main() {
	a, b := numbers(3), numbers(3)
	stop := time.After(100 * time.Millisecond)
	values, zeros := 0, 0
	for {
		select {
		case v := <-a:
			if v == 0 {
				zeros++
			} else {
				values++
			}
		case v := <-b:
			if v == 0 {
				zeros++
			} else {
				values++
			}
		case <-stop:
			fmt.Println("in 100ms:", values, "real values and", zeros, "zero values")
			return
		}
	}
}
```

```
ana@vm:~/fanin$ go run ./spin
in 100ms: 6 real values and 972922 zero values
```

Seis números foram enviados e seis chegaram. Depois os dois canais fecharam, e o laço passou o
resto dos 100 milissegundos recebendo 972.922 zeros: cada `case` estava pronto em toda volta,
porque receber de um canal fechado nunca espera. Um programa escrito assim, sem o timer, nunca
terminaria, e manteria um processador ocupado fazendo isso. Pior: se os canais levassem valores em
que zero é uma leitura válida, os zeros seriam indistinguíveis dos dados.

## Desligando um case

Duas coisas consertam isso. **A forma comma-ok separa um canal fechado de um valor**, como a lição
3 mostrou: `v, ok := <-a` põe `ok` em `false` quando `a` está fechado e vazio. **E um canal nil
nunca está pronto**, como a lição 5 mostrou, então pôr a variável em `nil` desliga o `case` dela
pelo resto do laço. O laço roda enquanto algum dos canais ainda está vivo. É salvo em
`~/fanin/pair` como `pair.go`:

```go
// Command pair merges two channels with select, switching off each one as it closes.
package main

import "fmt"

func numbers(from, n int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for i := from; i < from+n; i++ {
			out <- i
		}
	}()
	return out
}

func main() {
	a, b := numbers(1, 3), numbers(100, 2)
	for a != nil || b != nil {
		select {
		case v, ok := <-a:
			if !ok {
				fmt.Println("a closed")
				a = nil
				continue
			}
			fmt.Println("a:", v)
		case v, ok := <-b:
			if !ok {
				fmt.Println("b closed")
				b = nil
				continue
			}
			fmt.Println("b:", v)
		}
	}
	fmt.Println("both closed")
}
```

```
ana@vm:~/fanin$ go run ./pair
b: 100
a: 1
b: 101
b closed
a: 2
a: 3
a closed
both closed
```

Valores dos dois canais, intercalados conforme chegaram. `b` fechou primeiro, depois de dois
valores; o `case` dele foi desligado por `b = nil`, e o laço continuou recebendo só de `a` até `a`
fechar também. Então a condição `a != nil || b != nil` ficou falsa e o laço terminou, sem nada
girando à toa.

Pôr uma variável de canal em `nil` muda só aquela variável, a referência do próprio laço ao canal.
O canal em si e qualquer outra goroutine que o use ficam intactos.

**Qual usar é uma questão de quantas entradas há.** Um `select` precisa de um `case` por canal,
escrito no código, então serve para dois ou três canais fixos na hora de escrever, e mantém tudo
numa goroutine. Uma lista de canais cujo tamanho só se conhece quando o programa roda precisa do
`merge` da seção 02, uma goroutine por entrada.
