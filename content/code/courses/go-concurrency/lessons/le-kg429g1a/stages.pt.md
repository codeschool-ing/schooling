---
title: Estágios ligados por canais
version: 1
---

**Um pipeline é uma corrente de estágios, cada um uma goroutine que recebe valores do estágio
anterior e envia resultados ao estágio seguinte**, ligados por canais. As lições 13 e 14
espalharam um fluxo por muitas goroutines e juntaram muitos num só. Um pipeline é a terceira forma:
um fluxo que passa por vários passos em ordem, cada passo trabalhando ao mesmo tempo num item
diferente.

Todo estágio em Go tem a mesma forma de assinatura: recebe o canal de onde lê e devolve o canal em
que escreve, depois de iniciar a goroutine que liga os dois. É essa forma que permite encadear
estágios chamando um com o resultado do outro. O programa abaixo tem um primeiro estágio, `gen`, que
transforma uma lista num canal, e um estágio do meio, `sq`, que eleva ao quadrado. Ele é salvo em
`~/pipeline/squares` como `squares.go`:

```go
// Command squares chains three stages, each a goroutine joined to the next by a channel.
package main

import "fmt"

// gen is the first stage: it turns a list into a channel.
func gen(nums ...int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for _, n := range nums {
			out <- n
		}
	}()
	return out
}

// sq is a middle stage: it receives numbers and sends their squares.
func sq(in <-chan int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for n := range in {
			out <- n * n
		}
	}()
	return out
}

func main() {
	for v := range sq(gen(1, 2, 3, 4)) {
		fmt.Println(v)
	}
	for v := range sq(sq(gen(1, 2, 3))) {
		fmt.Println("twice:", v)
	}
}
```

```
ana@vm:~/pipeline$ go run ./squares
1
4
9
16
twice: 1
twice: 16
twice: 81
```

`sq(gen(1, 2, 3, 4))` se lê de dentro para fora: `gen` produz de 1 a 4, `sq` eleva ao quadrado, e o
`main`, o último estágio, percorre o resultado. **Como a entrada e a saída de um estágio são do
mesmo tipo, um estágio pode ser usado duas vezes**: `sq(sq(gen(1, 2, 3)))` elevou cada número à
quarta potência, 1, 16 e 81, sem código novo. Cada chamada iniciou mais uma goroutine e mais um
canal.

## Todo estágio trabalha ao mesmo tempo

Encadear funções não é novidade. O que as goroutines acrescentam é que **todos os estágios rodam ao
mesmo tempo**, cada um num item diferente: enquanto o segundo estágio cuida do item 1, o primeiro
já produz o item 2. O programa abaixo tem dois estágios que levam 20 milissegundos por item, cinco
itens, e horários em cada passo. Ele é salvo em `~/pipeline/overlap` como `overlap.go`:

```go
// Command overlap times five items through two slow stages.
package main

import (
	"fmt"
	"time"
)

var start = time.Now()

func stamp() time.Duration { return time.Since(start).Round(10 * time.Millisecond) }

// read takes 20ms to produce each item.
func read(n int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for i := 1; i <= n; i++ {
			time.Sleep(20 * time.Millisecond)
			fmt.Printf("%5v  read   item %d\n", stamp(), i)
			out <- i
		}
	}()
	return out
}

// store takes 20ms to handle each item.
func store(in <-chan int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for i := range in {
			time.Sleep(20 * time.Millisecond)
			fmt.Printf("%5v  stored item %d\n", stamp(), i)
			out <- i
		}
	}()
	return out
}

func main() {
	done := 0
	for range store(read(5)) {
		done++
	}
	fmt.Printf("%d items, 200ms of work, finished at %v\n", done, stamp())
}
```

```
ana@vm:~/pipeline$ go run ./overlap
 20ms  read   item 1
 40ms  stored item 1
 40ms  read   item 2
 60ms  stored item 2
 60ms  read   item 3
 80ms  stored item 3
 80ms  read   item 4
100ms  stored item 4
100ms  read   item 5
120ms  stored item 5
5 items, 200ms of work, finished at 120ms
```

Dez passos de 20 milissegundos são 200 milissegundos de trabalho, e terminaram aos 120. Dos 40
milissegundos em diante, cada linha vem em par: um item guardado e o seguinte lido no mesmo
instante, os dois estágios ocupados juntos. **O tempo de um pipeline é dado pelo estágio mais lento,
repetido uma vez por item, mais o tempo de enchê-lo**: aqui, 20 milissegundos por item para cinco
itens, mais os 20 que a primeira leitura levou antes de `store` ter o que fazer.

Isso também diz onde gastar esforço. Acelerar um estágio que não é o mais lento não muda nada que o
relógio veja; a seção 03 alarga o lento em vez disso.
