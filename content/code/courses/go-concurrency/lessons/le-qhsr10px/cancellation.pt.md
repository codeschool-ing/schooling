---
title: Cancelamento, do jeito do context
version: 1
---

A lição 6 terminou num canal `done` feito à mão: o dono o fecha, e toda goroutine que escuta para. O
pacote `context` é essa ideia com uma forma padronizada, para que uma função escrita por uma pessoa
possa ser parada por código escrito por outra. **Um `context.Context` carrega um canal `Done` que se
fecha quando o trabalho deve parar, e um `Err` que diz por quê.** Toda função que pode esperar recebe
um, e escuta.

## Quatro métodos e uma árvore

A interface é pequena. `Done()` devolve um canal que é fechado quando o contexto é cancelado. `Err()`
é `nil` até lá, e depois diz como terminou, `context.Canceled` ou `context.DeadlineExceeded`.
`Deadline()` informa um prazo, se houver, o assunto da seção 03, e `Value(key)` é o da seção 04.

Contextos formam uma árvore. **`context.Background()` é a raiz**, vazia e nunca cancelada, e cada
função `With…` faz um filho do contexto que recebe. `context.WithCancel(parent)` devolve o filho e
uma função `cancel`. Chamar `cancel` fecha o `Done` do filho, e dos filhos desse filho, até o fim;
nunca toca no pai.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A árvore de contextos do cancel.go. context.Background é a raiz e nunca é cancelado. ctx é feito a partir dela com WithCancel, e child é feito a partir de ctx com WithCancel. Um worker escuta ctx e outro escuta child. Chamar cancel em ctx fecha o Done de ctx e de child, então os dois workers param; a raiz não é tocada.\"><defs><marker id=\"l10tree-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10tree-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l10tree-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">context.Background()</text><text x=\"150\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nunca é cancelado</text><rect x=\"40\" y=\"120\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">ctx</text><text x=\"150\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">WithCancel(Background)</text><rect x=\"40\" y=\"220\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">child</text><text x=\"150\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">WithCancel(ctx)</text><path d=\"M150 72 V118\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10tree-wire)\"></path><path d=\"M150 172 V218\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10tree-wire)\"></path><rect x=\"420\" y=\"120\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"505\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">worker do pai</text><text x=\"505\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">parou</text><rect x=\"420\" y=\"220\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"505\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">worker do filho</text><text x=\"505\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">parou</text><path d=\"M262 145 H418\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l10tree-phosphor)\"></path><path d=\"M262 245 H418\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l10tree-phosphor)\"></path><text x=\"340\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Done</text><text x=\"340\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Done</text><text x=\"610\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cancel() fecha o Done aqui…</text><path d=\"M610 72 Q 610 100 262 128\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10tree-amber)\"></path><text x=\"340\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">…e em todo filho abaixo</text><path d=\"M300 280 Q 285 255 264 250\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10tree-amber)\"></path></svg>", "caption": "cancel.go: cancelar um contexto cancela os filhos dele, nunca o pai."}
```

## Dois workers, uma chamada

O programa abaixo inicia um worker num contexto e outro num filho dele, e depois cancela só o pai.
Salvo como `cancel.go`:

```go
// Command cancel stops two workers by cancelling the context they were given.
package main

import (
	"context"
	"fmt"
	"sync"
	"time"
)

// work does one step every 30 ms until its context is cancelled.
func work(ctx context.Context, name string) {
	steps := 0
	for {
		select {
		case <-ctx.Done():
			fmt.Printf("%s stopped after %d steps: %v\n", name, steps, ctx.Err())
			return
		case <-time.After(30 * time.Millisecond):
			steps++
		}
	}
}

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	child, cancelChild := context.WithCancel(ctx)
	defer cancelChild()

	var wg sync.WaitGroup
	wg.Go(func() { work(ctx, "parent's worker") })
	wg.Go(func() { work(child, "child's worker") })

	time.Sleep(100 * time.Millisecond)
	cancel()
	wg.Wait()
	fmt.Println("child's Err after the parent was cancelled:", child.Err())
}
```

```
ana@vm:~/ctx$ go run cancel.go
parent's worker stopped after 3 steps: context canceled
child's worker stopped after 3 steps: context canceled
child's Err after the parent was cancelled: context canceled
```

**Uma chamada de `cancel` parou os dois workers**, o do filho incluído, e o `Err` do filho virou
`context.Canceled` sem que ninguém o cancelasse diretamente. Cada worker deu três passos nos 100
milissegundos antes do cancelamento, e o `select` em `work` é o que o deixou ouvir a notícia entre
um passo e outro: uma goroutine que nunca olha o `Done` não pode ser parada por contexto nenhum.

Dois hábitos aparecem no `main`. **A função que cria um contexto cancelável chama o `cancel` dele**,
aqui com `defer cancelChild()`, mesmo quando outra pessoa pode cancelar antes; chamá-lo duas vezes
não faz mal. E o `cancel` é chamado pelo dono, nunca pelo worker: o worker só escuta. A lição 11
trata de passar o contexto por todas as camadas de um programa, para que a escuta chegue ao código
que de fato espera.
