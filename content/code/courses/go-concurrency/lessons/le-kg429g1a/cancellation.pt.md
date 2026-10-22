---
title: Parando um pipeline antes do fim
version: 1
---

A cascata da seção 03 vai do primeiro estágio ao último, e supõe que o último estágio lê tudo.
Muitas vezes ele não lê: uma busca para no primeiro resultado, uma página mostra os dez primeiros,
uma requisição é abandonada. **Quando o consumidor para antes, todo estágio acima dele fica preso
num envio que ninguém vai receber**, e nada na cascata os alcança, porque o fechamento só anda
corrente abaixo.

O programa abaixo pega dois resultados de um pipeline que produziria mil, e depois confere quantas
goroutines estão vivas um décimo de segundo mais tarde. Ele é salvo em `~/pipeline/stuck` como
`stuck.go`:

```go
// Command stuck reads two results from a pipeline of a thousand, and walks away.
package main

import (
	"fmt"
	"runtime"
	"time"
)

func gen(n int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for i := 1; i <= n; i++ {
			out <- i
		}
	}()
	return out
}

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
	results := sq(gen(1000))
	fmt.Println(<-results, <-results)
	time.Sleep(100 * time.Millisecond)
	fmt.Println("goroutines still alive:", runtime.NumGoroutine())
}
```

```
ana@vm:~/pipeline$ go run ./stuck
1 4
goroutines still alive: 3
```

Três: o `main` e os dois estágios. `sq` está preso enviando 9, e `gen` está preso enviando 4 para
`sq`. Nenhum dos dois vai rodar de novo, e nenhum será coletado, porque uma goroutine travada ainda
é uma goroutine. **Este é o vazamento da lição 6**, montado aqui a partir de um pipeline
perfeitamente correto. Num programa que sai no fim do `main` isso não custa nada. Num servidor que
monta um pipeline por requisição custa duas goroutines e a memória delas por requisição, para
sempre.

## Um contexto em cada estágio

O conserto é o que a lição 11 deu para todo laço que pode esperar: todo envio que pode travar também
espera `ctx.Done()`. Cada estágio recebe o contexto primeiro, e o consumidor cancela quando tem o
que queria. O programa abaixo também conta os estágios com um `WaitGroup`, para que o `main` possa
esperá-los terminar em vez de adivinhar com uma pausa. Ele é salvo em `~/pipeline/stoppable` como
`stoppable.go`:

```go
// Command stoppable is the same pipeline, with a context every stage watches.
package main

import (
	"context"
	"fmt"
	"runtime"
	"sync"
)

var stages sync.WaitGroup

func gen(ctx context.Context, n int) <-chan int {
	out := make(chan int)
	stages.Go(func() {
		defer close(out)
		for i := 1; i <= n; i++ {
			select {
			case out <- i:
			case <-ctx.Done():
				return
			}
		}
	})
	return out
}

func sq(ctx context.Context, in <-chan int) <-chan int {
	out := make(chan int)
	stages.Go(func() {
		defer close(out)
		for n := range in {
			select {
			case out <- n * n:
			case <-ctx.Done():
				return
			}
		}
	})
	return out
}

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	results := sq(ctx, gen(ctx, 1000))
	fmt.Println(<-results, <-results)
	cancel()
	stages.Wait()
	fmt.Println("goroutines still alive:", runtime.NumGoroutine())
}
```

```
ana@vm:~/pipeline$ go run -race ./stoppable
1 4
goroutines still alive: 1
```

Uma goroutine viva: o `main`. Quando o `main` chamou `cancel`, `sq` esperava para enviar 9, e o
`select` dele pegou o case `ctx.Done()` e retornou; o `close(out)` adiado rodou. `gen` esperava para
enviar 4, pegou o mesmo case, retornou e também fechou a saída. O `stages.Wait()` retornou quando os
dois terminaram, e o detector de corridas, compilado junto, não achou nada a relatar.

**O cancelamento sobe, contra os dados, e o fechamento desce, com eles.** Um pipeline que só fecha
vaza quando o leitor vai embora; um que só cancela deixa o leitor esperando um fechamento. Os
estágios do `stoppable.go` fazem as duas coisas, e esse é o padrão completo: receber com `range`,
enviar dentro de um `select` com `ctx.Done()`, e `defer close(out)`.

Todo padrão até aqui dependeu de as regras da lição 1 valerem: nunca duas goroutines mexendo na
mesma memória sem sincronização. A lição 16 é a ferramenta que as confere.
