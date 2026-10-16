---
title: Fechando, estágio por estágio
version: 1
---

Todo estágio da seção 02 terminava a sua goroutine com `defer close(out)`, e todo estágio menos o
primeiro lia a entrada com `range`. Esses dois hábitos juntos são tudo o que faz um pipeline
desligar: **cada estágio fecha o canal em que envia, depois que a entrada dele fechou**, e o
fechamento desce a corrente um estágio por vez. Nenhum estágio precisa saber quantos estágios há,
nem quantos itens.

O programa abaixo é o pipeline da seção 02 com uma linha impressa em cada fechamento. Ele é salvo em
`~/pipeline/cascade` como `cascade.go`:

```go
// Command cascade shows each stage closing its output after its input closed.
package main

import "fmt"

func gen(nums ...int) <-chan int {
	out := make(chan int)
	go func() {
		defer func() { fmt.Println("gen: no more numbers, closing"); close(out) }()
		for _, n := range nums {
			out <- n
		}
	}()
	return out
}

func sq(in <-chan int) <-chan int {
	out := make(chan int)
	go func() {
		defer func() { fmt.Println("sq:  input closed, closing"); close(out) }()
		for n := range in {
			out <- n * n
		}
	}()
	return out
}

func main() {
	for v := range sq(gen(1, 2)) {
		fmt.Println("main:", v)
	}
	fmt.Println("main: range over")
}
```

```
ana@vm:~/pipeline$ go run ./cascade
gen: no more numbers, closing
main: 1
main: 4
sq:  input closed, closing
main: range over
```

Os fechamentos vieram na ordem do pipeline, `gen` e depois `sq`, e o `range` do `main` terminou por
último. A linha de `gen` saiu antes de o `main` ter impresso qualquer coisa, e não há nada de errado
nisso: `gen` entregou o segundo número assim que `sq` o pegou e fechou na sequência, enquanto `sq` e
`main` ainda passavam os quadrados adiante. **A ordem das linhas de goroutines diferentes é a ordem
em que chegaram ao `Println`, e não a ordem dos dados**, como a lição 1 mostrou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um pipeline de três estágios, gen, sq e main, ligados por dois canais. Os valores andam da esquerda para a direita. O fechamento anda no mesmo sentido: gen fecha a saída quando não tem mais números; o range de sq sobre esse canal então termina, e sq fecha a própria saída; o range do main sobre ela então termina. O cancelamento é o outro sentido: quando o main para antes, um contexto avisa gen e sq para pararem de enviar.\"><defs><marker id=\"l15cascade-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15cascade-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l15cascade-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"70\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">gen</text><rect x=\"290\" y=\"70\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sq</text><rect x=\"550\" y=\"70\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main</text><path d=\"M172 95 H287\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15cascade-phosphor)\"></path><text x=\"230\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">chan int</text><path d=\"M432 95 H547\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15cascade-phosphor)\"></path><text x=\"490\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">chan int</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">valores</text><path d=\"M300 44 H420\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15cascade-phosphor)\"></path><text x=\"100\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">1. acabaram os números: close</text><text x=\"360\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">2. o range termina: close</text><text x=\"620\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">3. o range termina</text><path d=\"M190 146 H262\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l15cascade-amber)\"></path><path d=\"M450 146 H530\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l15cascade-amber)\"></path><rect x=\"30\" y=\"196\" width=\"660\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">parar antes vai no outro sentido: ctx.Done() em todo envio</text><path d=\"M620 192 V180 H100 V172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l15cascade-paper-dim)\"></path></svg>", "caption": "O fechamento viaja com os dados, um estágio por vez; cada estágio fecha só o canal em que envia."}
```

Três regras fazem a cascata funcionar, e cada uma, quebrada, é uma falha da lição 14:

- **Um estágio fecha só a própria saída.** Fechar a entrada seria um receptor fechando um canal em
  que outro envia: o panic `send on closed channel`.
- **Ele fecha depois que a entrada se esgota**, o que `range` mais `defer close(out)` dão de graça.
- **Ele fecha em toda saída da sua goroutine.** O `defer` garante isso mesmo quando um estágio
  retorna antes, de que a seção 04 precisa.

## Um estágio largo

Um pipeline anda na velocidade do seu estágio mais lento, então o lento é o que vale espalhar. **Um
estágio pode ter fan-out por dentro**: várias goroutines leem a entrada dele, como na lição 13, e a
saída dele é fechada quando todas terminaram, como na lição 14. Visto de fora, continua sendo um
estágio, um canal de entrada e um de saída. Ele é salvo em `~/pipeline/wide` como `wide.go`:

```go
// Command wide runs the slow middle stage of a pipeline on three goroutines.
package main

import (
	"fmt"
	"sync"
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

// slowSq squares each number on `width` goroutines, and closes once all of them are done.
func slowSq(in <-chan int, width int) <-chan int {
	out := make(chan int)
	var wg sync.WaitGroup
	for range width {
		wg.Go(func() {
			for n := range in {
				time.Sleep(30 * time.Millisecond)
				out <- n * n
			}
		})
	}
	go func() {
		wg.Wait()
		close(out)
	}()
	return out
}

func main() {
	for _, width := range []int{1, 3} {
		start := time.Now()
		sum := 0
		for v := range slowSq(gen(6), width) {
			sum += v
		}
		fmt.Printf("width %d: sum %d in %v\n", width, sum, time.Since(start).Round(10*time.Millisecond))
	}
}
```

```
ana@vm:~/pipeline$ go run ./wide
width 1: sum 91 in 180ms
width 3: sum 91 in 60ms
```

Seis itens de 30 milissegundos levaram 180 numa goroutine e 60 em três. A soma é a mesma, 91,
porque a adição não liga para a ordem, e com três goroutines enviando nada mantém os quadrados na
ordem da entrada. Um estágio cuja ordem de saída importa precisa do índice da lição 13. O
fechamento do estágio largo é o `WaitGroup` com a goroutine que fecha do `merge` da lição 14,
porque três goroutines enviam em `out` e só algo que as conta sabe quando a última terminou.
