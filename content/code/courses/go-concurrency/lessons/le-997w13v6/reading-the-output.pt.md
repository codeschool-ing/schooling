---
title: Lendo um relatório, linha a linha
version: 1
---

Um relatório de corrida parece um stack trace, e o reflexo é rolar até o fim atrás do erro. **Não há
erro no fim. Um relatório são dois acessos e dois lugares de nascimento**, e cada linha dele
responde a uma de quatro perguntas: o que foi tocado, o que o tocou antes, e de onde veio cada uma
das duas goroutines. Lido nessa ordem, um relatório aponta o conserto quase sempre.

O programa é um contador que uma goroutine vai aumentando enquanto `main` o lê, o formato de um
servidor que conta requisições enquanto outra coisa informa a contagem. Salvo como `stats.go`:

```go
// Command stats counts requests in one goroutine while main reports them.
package main

import (
	"fmt"
	"time"
)

type stats struct {
	served int
}

func main() {
	s := &stats{}
	go serve(s)
	time.Sleep(10 * time.Millisecond)
	fmt.Println("served so far:", s.served)
}

func serve(s *stats) {
	for {
		s.served++
		time.Sleep(time.Millisecond)
	}
}
```

Rodado normalmente e depois com o detector:

```
ana@vm:~/races$ go run stats.go
served so far: 10
ana@vm:~/races$ go run -race stats.go
==================
WARNING: DATA RACE
Read at 0x00c00009e028 by main goroutine:
  main.main()
      /home/ana/races/stats.go:17 +0xe8

Previous write at 0x00c00009e028 by goroutine 8:
  main.serve()
      /home/ana/races/stats.go:22 +0x44
  main.main.gowrap1()
      /home/ana/races/stats.go:15 +0xe

Goroutine 8 (running) created at:
  main.main()
      /home/ana/races/stats.go:15 +0xa4
==================
served so far: 11
Found 1 data race(s)
exit status 66
```

A execução normal imprimiu um número plausível e nada mais. Essa é toda a dificuldade das corridas:
**o programa sem o detector não deu sinal nenhum de que algo estava errado.**

## As quatro partes

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"O relatório de corrida do stats.go dividido nas suas quatro partes. Um: Read at um endereço by main goroutine, em main.main na linha 17 do stats.go, o acesso que completou a corrida. Dois: Previous write no mesmo endereço by goroutine 8, em main.serve na linha 22 do stats.go, o acesso que nada ordenou em relação ao primeiro. Três: Goroutine 8 created at main.main, linha 15 do stats.go, onde a outra goroutine nasceu. Quatro: Found 1 data race(s), a contagem, e exit status 66.\"><defs><marker id=\"l16rep-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l16rep-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l16rep-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"400\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Read at 0x00c00009e028 by main goroutine:</text><text x=\"34\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">  main.main()  stats.go:17</text><path d=\"M424 46.0 H452\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16rep-phosphor)\"></path><text x=\"462\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1  o que foi tocado, e onde</text><text x=\"476\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o acesso que completou a corrida</text><rect x=\"20\" y=\"98\" width=\"400\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Previous write at 0x00c00009e028 by goroutine 8:</text><text x=\"34\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">  main.serve()  stats.go:22</text><text x=\"34\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">  main.main.gowrap1()  stats.go:15</text><path d=\"M424 133.0 H452\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16rep-amber)\"></path><text x=\"462\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2  o que o tocou antes</text><text x=\"476\" y=\"142.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nada o ordenou em relação ao 1</text><rect x=\"20\" y=\"194\" width=\"400\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Goroutine 8 (running) created at:</text><text x=\"34\" y=\"229\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">  main.main()  stats.go:15</text><path d=\"M424 220.0 H452\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16rep-paper-dim)\"></path><text x=\"462\" y=\"211.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3  onde a outra goroutine nasceu</text><text x=\"476\" y=\"229.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o comando go que a iniciou</text><rect x=\"20\" y=\"262\" width=\"400\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"279\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Found 1 data race(s)</text><text x=\"34\" y=\"297\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">exit status 66</text><path d=\"M424 288.0 H452\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16rep-paper-dim)\"></path><text x=\"462\" y=\"279.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4  a contagem</text><text x=\"476\" y=\"297.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">e status 66 na saída</text></svg>", "caption": "Um relatório, quatro perguntas. As linhas 17 e 22 do stats.go são o diagnóstico; a linha 15 diz quem iniciou a segunda goroutine."}
```

**`Read at 0x00c00009e028 by main goroutine`** é o acesso que completou a corrida, e a pilha
embaixo dele diz onde: `main.main()`, linha 17 do `stats.go`, que é o `fmt.Println` que lê
`s.served`. O endereço é o lugar da variável na memória. Ele muda a cada execução e só importa para
casá-lo com o próximo bloco.

**`Previous write at 0x00c00009e028 by goroutine 8`** é o outro acesso ao mesmo endereço, o que nada
ordenou em relação ao primeiro. A pilha dele se lê de cima para baixo: `main.serve()` na linha 22,
que é `s.served++`, chamada de `main.main.gowrap1()` na linha 15. Esse segundo quadro é o invólucro
do runtime em volta do comando `go serve(s)`, e a linha 15 é esse comando.

**`Goroutine 8 (running) created at`** é o lugar de nascimento da outra goroutine: `main.main()` na
linha 15 de novo, o comando `go`. Um relatório dá o lugar de nascimento de toda goroutine que cita,
menos o de `main`, que ninguém criou. `(running)` diz que a goroutine ainda estava viva quando o
relatório foi escrito; `(finished)` diria que ela já tinha retornado.

**A última linha é a contagem**, `Found 1 data race(s)`, seguida do status 66. O programa ainda
imprimiu o seu número, `11` naquela execução, porque o detector relata e deixa o programa seguir.

Então o relatório cita a variável duas vezes, por duas linhas de código: a linha 17 a lê numa
goroutine e a linha 22 a escreve em outra, e nada faz uma acontecer antes da outra. Essa frase é o
diagnóstico, e o conserto da seção 04 desta lição sai dela.

## Quando uma pilha para dentro do runtime

Nem todo relatório é tão arrumado. Aqui várias goroutines contam as palavras de algumas linhas num
único map, salvo como `tally.go`:

```go
// Command tally counts words from several goroutines into one map.
package main

import (
	"fmt"
	"strings"
	"sync"
)

func main() {
	lines := []string{"the cat sat", "the dog ran", "a cat ran", "the end"}
	counts := map[string]int{}
	var wg sync.WaitGroup
	for _, line := range lines {
		wg.Go(func() {
			for _, w := range strings.Fields(line) {
				counts[w]++
			}
		})
	}
	wg.Wait()
	fmt.Println(counts)
}
```

Três execuções normais concordam, e estão certas. Com o detector houve quatro relatórios, então
esta execução define `GORACE=halt_on_error=1`, que para o programa no primeiro:

```
ana@vm:~/races$ for i in 1 2 3; do go run tally.go; done
map[a:1 cat:2 dog:1 end:1 ran:2 sat:1 the:3]
map[a:1 cat:2 dog:1 end:1 ran:2 sat:1 the:3]
map[a:1 cat:2 dog:1 end:1 ran:2 sat:1 the:3]
ana@vm:~/races$ GORACE=halt_on_error=1 go run -race tally.go; echo "exit: $?"
==================
WARNING: DATA RACE
Read at 0x00c0000a20f0 by goroutine 8:
  runtime.mapaccess2_faststr()
      /usr/local/go/src/internal/runtime/maps/runtime_faststr.go:120 +0x0
  runtime.mapaccess1_faststr()
      /usr/local/go/src/internal/runtime/maps/runtime_faststr.go:115 +0x17

Previous write at 0x00c0000a20f0 by goroutine 11:
  runtime.mapassign_faststr()
      /usr/local/go/src/internal/runtime/maps/runtime_faststr.go:261 +0x0
  main.main.func1()
      /home/ana/races/tally.go:17 +0xcc

Goroutine 8 (running) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72

Goroutine 11 (finished) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72
==================
exit status 66
exit: 1
```

**As execuções normais imprimiram a contagem correta três vezes**, com uma corrida no programa todas
as vezes: as goroutines eram tão curtas que mal se sobrepuseram, e a sorte fez o resto. O detector
não precisa de sorte. Ele viu duas goroutines mexerem no mesmo map sem nada entre elas.

Três coisas neste relatório diferem do anterior. Os quadros começam com
`runtime.mapaccess2_faststr` e `runtime.mapassign_faststr`: o próprio código do map, dentro do
runtime, é onde a memória foi de fato tocada. **Pule os quadros do runtime e procure a primeira
linha dos seus próprios arquivos**: `tally.go:17`, `counts[w]++`, embaixo da escrita anterior pela
goroutine 11.

A leitura pela goroutine 8 nem chega aos seus arquivos; a pilha dela para dentro do código de map
do runtime. Isso acontece, e aqui não custa nada, porque basta um lado citar a sua linha: os dois
lados tocaram o mesmo endereço, então os dois são o mesmo `counts[w]++`. E os lugares de nascimento
apontam para `sync.(*WaitGroup).Go()`, a linha da biblioteca padrão que iniciou a goroutine por
você, que é onde toda goroutine iniciada por `wg.Go` diz ter nascido. `(finished)` ao lado da
goroutine 11 diz que ela já tinha retornado quando o relatório foi escrito.

`GORACE` é como o detector recebe opções em tempo de execução, e `halt_on_error=1` é a que vale
conhecer: um relatório é mais fácil de ler que quatro, e você os conserta um de cada vez de
qualquer jeito. O status 66 passa pelo `go run`, que então sai com 1, como mostra a última linha.
