---
title: Timeouts
version: 1
---

Um recebimento sem ninguém enviando espera para sempre, e a lição 4 mostrou como isso dá errado em
silêncio. **Um timeout é mais um caso num `select`: um canal que entrega um valor quando o tempo
acaba.** `time.After(d)` devolve exatamente isso, um canal em que chega um valor depois de `d`.

## Uma operação, um limite

O trabalho leva 500 milissegundos e quem chama vai esperar 200, salvo como `timeout.go`:

```go
// Command timeout gives up on a slow result after 200 milliseconds.
package main

import (
	"fmt"
	"time"
)

func main() {
	start := time.Now()
	result := make(chan string, 1)
	go func() {
		time.Sleep(500 * time.Millisecond) // the slow work
		result <- "done"
	}()

	select {
	case r := <-result:
		fmt.Println("result:", r)
	case <-time.After(200 * time.Millisecond):
		fmt.Println("timed out")
	}
	fmt.Println("after", time.Since(start).Round(10*time.Millisecond))
}
```

```
ana@vm:~/select$ ./timeout
timed out
after 200ms
```

O trabalho precisava de 500 milissegundos, o timer disparou em 200, e o `select` pegou esse caso.
**Quem chamou recebeu a resposta, `timed out`, no prazo.** Repare que a goroutine lenta não foi
parada: ela continuou dormindo, e depois enviou `"done"` num canal que ninguém ia ler. O buffer de
um é o que deixa ela terminar esse envio e retornar. Parar o próprio trabalho, em vez de só deixar de
esperar por ele, é tarefa do pacote `context`, na lição 10.

## Um limite por passo, ou um limite para o todo

O lugar onde o `time.After` é escrito decide o que ele limita, e a diferença é fácil de não ver. Cinco
resultados chegam com 100 milissegundos de intervalo. O primeiro laço dá 150 milissegundos a cada
recebimento; o segundo dá 350 à coleta inteira, salvo como `budget.go`:

```go
// Command budget compares a timeout per receive with one deadline for all of them.
package main

import (
	"fmt"
	"time"
)

func results() <-chan int {
	out := make(chan int)
	go func() {
		for i := 1; i <= 5; i++ {
			time.Sleep(100 * time.Millisecond)
			out <- i
		}
		close(out)
	}()
	return out
}

func main() {
	start := time.Now()
	in := results()
	got := 0
perStep:
	for {
		select {
		case _, ok := <-in:
			if !ok {
				break perStep
			}
			got++
		case <-time.After(150 * time.Millisecond):
			break perStep
		}
	}
	fmt.Println("per step: got", got, "after", time.Since(start).Round(10*time.Millisecond))

	start = time.Now()
	in = results()
	got = 0
	deadline := time.After(350 * time.Millisecond)
overall:
	for {
		select {
		case _, ok := <-in:
			if !ok {
				break overall
			}
			got++
		case <-deadline:
			break overall
		}
	}
	fmt.Println("overall: got", got, "after", time.Since(start).Round(10*time.Millisecond))
}
```

```
ana@vm:~/select$ ./budget
per step: got 5 after 500ms
overall: got 3 after 350ms
```

Os mesmos cinco resultados, duas respostas diferentes. **Com o `time.After` dentro do laço, cada
passada do `select` cria um timer novo de 150 milissegundos**, e cada resultado chegou 100
milissegundos depois do anterior, então nenhum timer chegou a disparar. Os cinco entraram, depois de
500 milissegundos, e uma fonte que mandasse um resultado a cada 140 milissegundos para sempre nunca
levaria timeout. **Com o timer criado uma vez, antes do laço, ele mede a coleta inteira**: três
resultados até 350 milissegundos, e então o caso do prazo rodou e o laço terminou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"O budget.go numa linha do tempo de 0 a 500 milissegundos. Os resultados chegam em 100, 200, 300, 400 e 500. Com um timeout de 150 milissegundos por recebimento, cada janela recomeça depois de cada resultado, nenhuma janela vence, e os cinco chegam. Com um prazo único em 350 milissegundos para o laço inteiro, os resultados de 1 a 3 chegam e o prazo encerra o laço antes dos resultados 4 e 5.\"><defs><marker id=\"l05budget-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"60\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">resultados chegam</text><rect x=\"158.0\" y=\"34\" width=\"24\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"170.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">1</text><rect x=\"268.0\" y=\"34\" width=\"24\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"280.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">2</text><rect x=\"378.0\" y=\"34\" width=\"24\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"390.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">3</text><rect x=\"488.0\" y=\"34\" width=\"24\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"500.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">4</text><rect x=\"598.0\" y=\"34\" width=\"24\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"610.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">5</text><text x=\"60\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">time.After dentro do laço: 150 ms por recebimento</text><rect x=\"60.0\" y=\"98\" width=\"165.0\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"170.0\" y=\"112\" width=\"165.0\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"280.0\" y=\"98\" width=\"165.0\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"390.0\" y=\"112\" width=\"165.0\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"500.0\" y=\"98\" width=\"165.0\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"672\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">pegou 5</text><text x=\"60\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">time.After antes do laço: 350 ms para tudo</text><rect x=\"60.0\" y=\"170\" width=\"385.0\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><path d=\"M445.0 30 V196\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"457.0\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">pegou 3</text><path d=\"M60 222 H630\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05budget-paper-dim)\"></path><path d=\"M60.0 217 V227\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 ms</text><path d=\"M170.0 217 V227\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"170.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100 ms</text><path d=\"M280.0 217 V227\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"280.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200 ms</text><path d=\"M390.0 217 V227\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"390.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300 ms</text><path d=\"M500.0 217 V227\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"500.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400 ms</text><path d=\"M610.0 217 V227\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"610.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">500 ms</text><text x=\"445.0\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">350 ms</text></svg>", "caption": "Dentro do laço, cada recebimento começa 150 ms novos; antes do laço, um relógio só de 350 ms corre para a coleta inteira."}
```

Nenhum dos dois está errado. Um limite por passo serve para "desista se o fluxo ficar quieto"; um
limite para o todo serve para "tenho 350 milissegundos para responder a quem me chamou". O que
importa é escolher de propósito, e um handler de requisição quase sempre quer o segundo. A lição 10
expressa esse segundo tipo com um prazo de context, que viaja por toda função que a requisição chama.

Os laços também usam um rótulo, `perStep:` e `overall:`. Um `break` simples dentro de um `select` sai
do `select`, não do `for` em volta dele, então o `break` com rótulo é o que encerra o laço. A lição 18
de `go` trata de rótulos.
