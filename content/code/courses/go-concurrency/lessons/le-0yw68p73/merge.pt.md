---
title: Juntando canais num só
version: 1
---

O fan-out, na lição 13, mandou um fluxo para muitas goroutines. **O fan-in é o contrário: muitos
canais juntados num só**, para que um único laço leia o que qualquer um deles produzir, na ordem em
que chegar. É assim que um programa escuta várias fontes ao mesmo tempo sem saber de antemão qual
vai falar primeiro: três sensores, várias réplicas de um serviço, os workers de um fan-out mandando
os resultados para casa.

A forma é uma goroutine por entrada, cada uma copiando a sua entrada para uma saída compartilhada,
e mais uma goroutine que fecha a saída quando todas as copiadoras terminaram. O programa abaixo
junta três fontes que produzem em ritmos diferentes. Ele é salvo em `~/fanin/merge` como
`merge.go`:

```go
// Command merge reads three sources through one channel.
package main

import (
	"fmt"
	"sync"
	"time"
)

// source sends n readings named after it, one every gap, then closes its channel.
func source(name string, n int, gap time.Duration) <-chan string {
	out := make(chan string)
	go func() {
		defer close(out)
		for i := 1; i <= n; i++ {
			time.Sleep(gap)
			out <- fmt.Sprintf("%s-%d", name, i)
		}
	}()
	return out
}

// merge copies every value of every input onto one output, and closes it when all inputs are done.
func merge[T any](inputs ...<-chan T) <-chan T {
	out := make(chan T)
	var wg sync.WaitGroup
	for _, in := range inputs {
		wg.Go(func() {
			for v := range in {
				out <- v
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
	start := time.Now()
	all := merge(
		source("disk", 3, 30*time.Millisecond),
		source("net", 4, 20*time.Millisecond),
		source("cpu", 2, 50*time.Millisecond),
	)
	for reading := range all {
		fmt.Printf("%5v  %s\n", time.Since(start).Round(10*time.Millisecond), reading)
	}
	fmt.Println("all sources closed")
}
```

```
ana@vm:~/fanin$ go run ./merge
 20ms  net-1
 30ms  disk-1
 40ms  net-2
 50ms  cpu-1
 60ms  net-3
 60ms  disk-2
 80ms  net-4
 90ms  disk-3
100ms  cpu-2
all sources closed
```

Nove leituras chegaram por um canal só, em ordem de tempo: `net` a cada 20 milissegundos, `disk` a
cada 30, `cpu` a cada 50. **O `main` nunca menciona as três fontes pelo nome**; ele percorre um
canal e recebe da fonte que produziu por último. E o laço dele terminou sozinho, imprimindo
`all sources closed`, porque o canal juntado foi fechado no momento certo.

O `merge` é genérico, `[T any]`, como a lição 31 de `go` mostrou para funções: ele copia valores de
qualquer tipo, e nada nele depende de as leituras serem strings. Cada entrada ganha uma goroutine
própria porque cada uma pode travar a qualquer momento, esperando a sua fonte, e uma goroutine
esperando uma entrada não pode segurar as outras.

A parte que decide se o `merge` está correto é a última goroutine que ele inicia:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Como o merge do merge.go fecha a saída. Três canais de entrada, disk, net e cpu, cada um lido por uma goroutine copiadora própria que envia cada valor para o único canal de saída, out. Cada copiadora chama Done num WaitGroup quando a entrada dela fecha. Uma quarta goroutine espera o WaitGroup e só fecha out depois que as três copiadoras terminaram; o main percorre out até esse fechamento.\"><defs><marker id=\"l14merge-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14merge-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l14merge-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"90\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">disk</text><rect x=\"180\" y=\"40\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copiadora</text><path d=\"M112 58 H177\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-wire)\"></path><path d=\"M312 58 L417 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-phosphor)\"></path><rect x=\"20\" y=\"110\" width=\"90\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">net</text><rect x=\"180\" y=\"110\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copiadora</text><path d=\"M112 128 H177\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-wire)\"></path><path d=\"M312 128 L417 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-phosphor)\"></path><rect x=\"20\" y=\"180\" width=\"90\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cpu</text><rect x=\"180\" y=\"180\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copiadora</text><path d=\"M112 198 H177\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-wire)\"></path><path d=\"M312 198 L417 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-phosphor)\"></path><rect x=\"420\" y=\"110\" width=\"90\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"465\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">out</text><rect x=\"560\" y=\"110\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main</text><text x=\"630\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">percorre até out fechar</text><path d=\"M512 128 H557\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-phosphor)\"></path><text x=\"310\" y=\"260\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Done() quando a entrada fecha</text><path d=\"M245 218 V244\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"330\" y=\"240\" width=\"270\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"465\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">espera as três, depois close(out)</text><path d=\"M465 238 V149\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-amber)\"></path><path d=\"M314 260 H327\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-wire)\"></path></svg>", "caption": "O merge do merge.go. Só a goroutine que sabe que todas as copiadoras terminaram pode fechar a saída."}
```

**A saída só pode ser fechada quando nada mais vai enviar nela**, e com três copiadoras isso
significa quando as três terminaram. Nenhuma copiadora sabe isso das outras, então nenhuma delas
fecha. O `WaitGroup` as conta, e uma goroutine separada espera a contagem chegar a zero e então
chama `close(out)`. Tem de ser uma goroutine separada: se o próprio `merge` chamasse `wg.Wait()`,
ele travaria antes de devolver `out`, e ninguém estaria lendo `out` para as copiadoras enviarem. A
seção 04 mostra os dois jeitos como as pessoas erram isso.
