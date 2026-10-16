---
title: Muitos leitores, um escritor
version: 1
---

Um mutex comum deixa entrar uma goroutine de cada vez, e para dados que quase só são lidos isso é
mais cautela do que o necessário. Duas goroutines que só leem não estragam nada uma para a outra.
**Um `sync.RWMutex` tem dois tipos de trava: qualquer número de leitores pode segurar `RLock` junto,
e `Lock` é segurado por um escritor sem mais ninguém**, leitores incluídos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Duas linhas do tempo das mesmas quatro leituras e uma escrita. Com um Mutex, as quatro leituras e a escrita seguram a trava sozinhas, uma depois da outra. Com um RWMutex, as quatro leituras seguram a trava de leitura juntas e se sobrepõem, depois a escrita segura a trava sozinha, e a sequência inteira termina bem antes.\"><defs><marker id=\"l08rw-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sync.Mutex</text><rect x=\"130\" y=\"46\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">leitura 1</text><rect x=\"230\" y=\"46\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">leitura 2</text><rect x=\"330\" y=\"46\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"378.0\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">leitura 3</text><rect x=\"430\" y=\"46\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"478.0\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">leitura 4</text><rect x=\"530\" y=\"46\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"578.0\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">escrita</text><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sync.RWMutex</text><rect x=\"130\" y=\"132\" width=\"96\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">leitura 1</text><rect x=\"130\" y=\"156\" width=\"96\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">leitura 2</text><rect x=\"130\" y=\"180\" width=\"96\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">leitura 3</text><rect x=\"130\" y=\"204\" width=\"96\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">leitura 4</text><rect x=\"230\" y=\"132\" width=\"96\" height=\"92\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">escrita</text><path d=\"M328 126 V230\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"328\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fim</text><path d=\"M628 40 V78\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M130 262 H660\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08rw-paper-dim)\"></path><text x=\"80\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "Quatro leitores e um escritor: um Mutex põe os cinco em fila, um RWMutex deixa os leitores se sobreporem e mantém o escritor sozinho."}
```

## Medido num map compartilhado

O programa abaixo faz oito goroutines lerem uma lista de preços 100.000 vezes cada uma. Ele recebe
duas palavras: que trava usar, e quanto trabalho cada leitura faz enquanto segura a trava, para
comparar as duas em seções críticas longas e curtas. Salvo como `cache.go`:

```go
// Command cache reads a shared map from eight goroutines, under a Mutex or an RWMutex.
//
//	./cache mutex 200   each read holds a Mutex while it does 200 steps of work
//	./cache rw 0        each read holds an RWMutex's read lock and does no extra work
package main

import (
	"fmt"
	"os"
	"strconv"
	"sync"
	"time"
)

// locker is what both kinds of lock offer for reading.
type locker interface {
	lock()
	unlock()
}

type plain struct{ sync.Mutex }

func (p *plain) lock()   { p.Lock() }
func (p *plain) unlock() { p.Unlock() }

type rw struct{ sync.RWMutex }

func (r *rw) lock()   { r.RLock() }
func (r *rw) unlock() { r.RUnlock() }

var prices = map[string]int{"apple": 120, "bread": 450, "milk": 600}

var work int

// lookup reads the map and does some work with the answer, all under the lock.
func lookup(l locker, item string) int {
	l.lock()
	defer l.unlock()
	p := prices[item]
	for range work {
		p = (p*31 + 7) % 1000
	}
	return p
}

func main() {
	var l locker = &plain{}
	if os.Args[1] == "rw" {
		l = &rw{}
	}
	work, _ = strconv.Atoi(os.Args[2])
	start := time.Now()
	var wg sync.WaitGroup
	for range 8 {
		wg.Go(func() {
			for range 100_000 {
				lookup(l, "bread")
			}
		})
	}
	wg.Wait()
	fmt.Printf("%-5s work %3d: 800000 reads in %v\n", os.Args[1], work, time.Since(start).Round(time.Millisecond))
}
```

A interface `locker` deixa um mesmo `lookup` usar qualquer das travas: `plain` trava um `Mutex`
inteiro, `rw` toma só a trava de leitura de um `RWMutex`. Compilado com `go build -o cache cache.go`:

```
ana@vm:~/locks$ ./cache mutex 200
mutex work 200: 800000 reads in 641ms
ana@vm:~/locks$ ./cache rw 200
rw    work 200: 800000 reads in 200ms
ana@vm:~/locks$ ./cache mutex 0
mutex work   0: 800000 reads in 65ms
ana@vm:~/locks$ ./cache rw 0
rw    work   0: 800000 reads in 79ms
```

**Com 200 passos de trabalho sob a trava, a trava de leitura foi três vezes mais rápida**: 641
milissegundos contra 200. Com o mutex comum, as oito goroutines faziam fila para trabalhar uma de
cada vez; com a trava de leitura, quatro delas trabalhavam ao mesmo tempo, uma por processador.

**Sem trabalho sob a trava, o `RWMutex` foi mais lento**: 79 milissegundos contra 65. Um `RWMutex`
tem mais contabilidade que um `Mutex`, porque conta os seus leitores, e quando a seção crítica é uma
única consulta a um map essa contabilidade é quase todo o custo. Então um `RWMutex` não é uma
melhoria de graça. Ele compensa quando os leitores são muitos e seguram a trava tempo suficiente
para se sobrepor, e o jeito de saber é medir, como aqui.

## As regras que vêm junto

A documentação de `sync.RWMutex` acrescenta duas regras que quem lê código precisa conhecer:

- **Um escritor esperando barra leitores novos.** Assim que uma goroutine está bloqueada em `Lock`,
  as chamadas seguintes de `RLock` esperam até esse escritor ter a sua vez. Sem isso um fluxo
  constante de leitores poderia manter um escritor do lado de fora para sempre.
- **Uma trava de leitura não vira trava de escrita.** Uma goroutine que segura `RLock` e chama `Lock`
  espera todos os leitores saírem, ela mesma incluída, e por isso espera para sempre. Solte a trava
  de leitura, tome a de escrita e confira de novo o que tinha lido, já que outro escritor pode ter
  passado no meio.

A mesma regra do mutex comum vale para os dois: **um `RLock` é liberado por exatamente um
`RUnlock`**, e o `defer` é o jeito de ter certeza disso.
