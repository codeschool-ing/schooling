---
title: Quando um canal é a ferramenta pior
version: 1
---

A lição 1 citou o provérbio *compartilhe memória se comunicando*, e é fácil lê-lo como uma proibição
de mutexes. Não é. **Canais servem para passar a posse de dados e para coordenar goroutines; um mutex
serve para proteger um pedaço de estado que várias goroutines alteram no lugar.** Usar um canal para
o segundo trabalho funciona, e custa clareza e tempo.

## Um contador, três jeitos

O programa abaixo conta até 400.000 a partir de quatro goroutines três vezes: com um mutex, com
`sync/atomic`, e entregando o número a uma goroutine que é dona dele e recebe os incrementos por um
canal. Cada jeito é uma função, cronometrada pelo `main`. Salvo como `three.go`:

```go
// Command three counts to 400,000 from four goroutines, three ways, and times each.
package main

import (
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

const goroutines, each = 4, 100_000

func withMutex() int {
	var mu sync.Mutex
	total := 0
	var wg sync.WaitGroup
	for range goroutines {
		wg.Go(func() {
			for range each {
				mu.Lock()
				total++
				mu.Unlock()
			}
		})
	}
	wg.Wait()
	return total
}

func withAtomic() int {
	var total atomic.Int64
	var wg sync.WaitGroup
	for range goroutines {
		wg.Go(func() {
			for range each {
				total.Add(1)
			}
		})
	}
	wg.Wait()
	return int(total.Load())
}

// withChannel gives the number to one goroutine, which owns it, and sends it the increments.
func withChannel() int {
	incs := make(chan int)
	done := make(chan int)
	go func() {
		total := 0
		for n := range incs {
			total += n
		}
		done <- total
	}()
	var wg sync.WaitGroup
	for range goroutines {
		wg.Go(func() {
			for range each {
				incs <- 1
			}
		})
	}
	wg.Wait()
	close(incs)
	return <-done
}

func main() {
	for _, way := range []struct {
		name string
		f    func() int
	}{{"mutex", withMutex}, {"atomic", withAtomic}, {"channel", withChannel}} {
		start := time.Now()
		total := way.f()
		fmt.Printf("%-8s total %d in %v\n", way.name, total, time.Since(start).Round(time.Millisecond))
	}
}
```

Compilado com `go build -o three three.go` e rodado duas vezes:

```
ana@vm:~/locks$ ./three
mutex    total 400000 in 26ms
atomic   total 400000 in 2ms
channel  total 400000 in 80ms
ana@vm:~/locks$ ./three
mutex    total 400000 in 31ms
atomic   total 400000 in 8ms
channel  total 400000 in 95ms
```

Os três chegaram ao total certo. O contador atômico foi o mais rápido nas duas execuções, com 2 e 8
milissegundos, contra 26 e 31 do mutex; a diferença muda de uma execução para outra, a ordem não. O
canal levou cerca de três vezes o tempo do mutex, 80 e 95 milissegundos. Uma operação num canal é
uma entrega entre duas goroutines, com uma trava dentro do canal e uma goroutine acordada do outro
lado. Um mutex custa poucas instruções atômicas quando está livre, e só põe uma goroutine para dormir
quando ela tem de esperar. Para um contador, a versão com canal também é a mais longa de ler: uma
goroutine, dois canais, um fechamento e um recebimento final, para fazer o que `total++` diz.

## `sync/atomic`, para um número só

`atomic.Int64` e os seus parentes, `Int32`, `Uint64`, `Bool` e `Pointer`, tornam indivisível uma
operação sobre um valor: `Add`, `Load`, `Store`, `Swap`, `CompareAndSwap`. **Eles são a ferramenta
certa quando todo o estado compartilhado é um número ou um ponteiro**, um contador de requisições,
uma flag que diz "desligando". O `semaphore.go` da lição 7 contou falhas com um deles.

Eles deixam de ser a ferramenta certa no segundo valor. Duas variáveis atômicas atualizadas uma
depois da outra podem ser vistas meio atualizadas por outra goroutine, entre as duas; manter as duas
coerentes é o trabalho de um mutex. Como um mutex, um tipo atômico não pode ser copiado depois do
primeiro uso, e o `go vet` confere isso também.

## Uma regra para escolher

O conselho do próprio projeto Go se resume a qual pergunta o código está respondendo:

| o código está… | use |
|---|---|
| entregando um valor a outra goroutine, que passa a ser dona dele | um canal |
| distribuindo trabalho, ou juntando resultados, lições 7, 13 e 14 | um canal |
| dizendo "isto aconteceu", "pare", "terminei" | um canal, muitas vezes fechado em vez de usado para enviar |
| protegendo um cache, um map, uma struct que goroutines leem e alteram no lugar | um mutex |
| um contador ou uma flag, e mais nada | `sync/atomic` |

**Quando um desenho com canais precisa de uma goroutine cujo único trabalho é guardar uma variável,
isso costuma ser um mutex disfarçado**, e o `withChannel` acima é o exemplo. A lição 9 completa o
`sync`: esperar goroutines, fazer algo uma vez só e um map feito para uso concorrente.
