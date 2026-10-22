---
title: Quanto custa uma chamada
version: 1
---

Uma chamada ao C parece qualquer outra chamada no código, `C.add1(x)`, e o instinto é dar a ela o
preço de uma. **Ela custa mais de trinta vezes uma chamada Go, por um motivo que nenhuma flag de
compilador remove.** Go e C discordam sobre pilhas e sobre quem manda numa thread, então cada
chamada precisa atravessar de um arranjo para o outro e voltar. Numa função que faz trabalho de
verdade, a travessia some dentro dele. Numa função pequena chamada num laço, a travessia é o laço.

## A travessia, medida

O pacote abaixo tem uma função trivial escrita duas vezes, uma em Go e outra em C, e três maneiras
de calcular o checksum CRC-32 do log de 20.000 linhas com a zlib. `cost/cost.go`:

```schooling-example
{
  "language": "go",
  "file": "cost/cost.go",
  "parts": [
    {
      "code": "// Package cost measures what it costs to call C from Go.\npackage cost\n",
      "note": "Um pacote, e não um comando, porque quem mede são os benchmarks. Eles ficam no `cost_test.go` e o cgo fica aqui: o comando go recusa um arquivo de teste que importe `\"C\"`, então o C chega a um teste por funções comuns como estas."
    },
    {
      "code": "/*\n#cgo LDFLAGS: -lz\n#include <zlib.h>\n\nstatic int add1(int x) { return x + 1; }\n\n// crc_lines makes the same crc32 calls as CRCLines, one per line, with the\n// loop on this side: lens holds the length of each of the n lines in buf.\nstatic uLong crc_lines(const Bytef *buf, const uInt *lens, size_t n) {\n\tuLong c = 0;\n\tfor (size_t i = 0; i < n; i++) {\n\t\tc = crc32(c, buf, lens[i]);\n\t\tbuf += lens[i];\n\t}\n\treturn c;\n}\n*/\nimport \"C\"\n\nimport \"unsafe\"\n",
      "note": "Duas funções C. `add1` quase não faz nada, para que medi-la seja medir a travessia. `crc_lines` faz exatamente as chamadas a `crc32` que o `CRCLines` abaixo faz, uma por linha, com o laço escrito em C."
    },
    {
      "code": "// GoAdd1 returns x+1. The directive stops the compiler from inlining it,\n// so that a benchmark of it measures a real call.\n//\n//go:noinline\nfunc GoAdd1(x int) int { return x + 1 }\n",
      "note": "**A referência: o mesmo trabalho de `add1`, como chamada Go.** Sem `//go:noinline` o compilador colaria `x + 1` dentro do laço do benchmark e não sobraria chamada para medir."
    },
    {
      "code": "// CAdd1 returns x+1, computed by a C function.\nfunc CAdd1(x int) int { return int(C.add1(C.int(x))) }\n"
    },
    {
      "code": "// CRCLines returns the CRC-32 of the lines joined together, calling zlib's\n// crc32 once per line: one crossing into C for every line.\nfunc CRCLines(lines [][]byte) uint32 {\n\tvar c C.uLong\n\tfor _, l := range lines {\n\t\tc = C.crc32(c, (*C.Bytef)(unsafe.Pointer(&l[0])), C.uInt(len(l)))\n\t}\n\treturn uint32(c)\n}\n",
      "note": "Uma travessia por linha. O `crc32` recebe como primeiro argumento o checksum acumulado, então 20.000 chamadas seguidas dão o checksum do arquivo inteiro."
    },
    {
      "code": "// Lengths returns the length of each line, in the type crc_lines reads.\nfunc Lengths(lines [][]byte) []C.uInt {\n\tlens := make([]C.uInt, len(lines))\n\tfor i, l := range lines {\n\t\tlens[i] = C.uInt(len(l))\n\t}\n\treturn lens\n}\n",
      "note": "**Agrupar significa dar ao C tudo o que ele precisa de uma vez.** Uma fatia de `C.uInt` é memória Go sem ponteiros, então `&lens[0]` pode ser emprestado ao C por uma chamada, como o `&buf[0]` da seção 03."
    },
    {
      "code": "// CRCLinesInC makes the same crc32 calls as CRCLines from a loop written\n// in C: one crossing, however many lines there are. data is the lines\n// joined together.\nfunc CRCLinesInC(data []byte, lens []C.uInt) uint32 {\n\treturn uint32(C.crc_lines((*C.Bytef)(unsafe.Pointer(&data[0])), &lens[0], C.size_t(len(lens))))\n}\n"
    },
    {
      "code": "// CRC returns the CRC-32 of data, asking zlib once.\nfunc CRC(data []byte) uint32 {\n\treturn uint32(C.crc32(0, (*C.Bytef)(unsafe.Pointer(&data[0])), C.uInt(len(data))))\n}",
      "note": "Uma travessia, e uma chamada a `crc32` sobre o arquivo todo."
    }
  ]
}
```

Os benchmarks, no estilo da lição 29 de `go-concurrency`, primeiro conferem que todas as maneiras
de calcular o checksum concordam com o `hash/crc32` da biblioteca padrão, e só então as medem.
`cost/cost_test.go`:

```go
package cost

import (
	"bytes"
	"hash/crc32"
	"os"
	"slices"
	"testing"
)

var sink int

func BenchmarkGoAdd1(b *testing.B) {
	for i := range b.N {
		sink = GoAdd1(i)
	}
}

func BenchmarkCAdd1(b *testing.B) {
	for i := range b.N {
		sink = CAdd1(i)
	}
}

// BenchmarkCRC checksums the 20,000-line log four ways, and checks that all
// four agree with the standard library before it times any of them.
func BenchmarkCRC(b *testing.B) {
	data, err := os.ReadFile("../access.log")
	if err != nil {
		b.Fatal(err)
	}
	lines := slices.Collect(bytes.Lines(data))
	lens := Lengths(lines)
	want := crc32.ChecksumIEEE(data)
	cases := []struct {
		name string
		f    func() uint32
	}{
		{"zlib-per-line-from-Go", func() uint32 { return CRCLines(lines) }},
		{"zlib-per-line-from-C", func() uint32 { return CRCLinesInC(data, lens) }},
		{"zlib-once", func() uint32 { return CRC(data) }},
		{"hash-crc32", func() uint32 { return crc32.ChecksumIEEE(data) }},
	}
	for _, c := range cases {
		b.Run(c.name, func(b *testing.B) {
			if got := c.f(); got != want {
				b.Fatalf("got %08x, want %08x", got, want)
			}
			b.SetBytes(int64(len(data)))
			for range b.N {
				c.f()
			}
		})
	}
}
```

```
ana@vm:~/cgo$ go test -run=^$ -bench=. -count=1 ./cost
goos: linux
goarch: amd64
pkg: example.com/cgo/cost
cpu: Intel(R) Xeon(R) Processor
BenchmarkGoAdd1-4   	1000000000	         0.7894 ns/op
BenchmarkCAdd1-4    	46889370	        28.70 ns/op
BenchmarkCRC/zlib-per-line-from-Go-4         	     585	   2121470 ns/op	 431.24 MB/s
BenchmarkCRC/zlib-per-line-from-C-4          	     636	   1857619 ns/op	 492.49 MB/s
BenchmarkCRC/zlib-once-4                     	    6520	    174377 ns/op	5246.50 MB/s
BenchmarkCRC/hash-crc32-4                    	   64395	     19476 ns/op	46974.37 MB/s
PASS
ok  	example.com/cgo/cost	7.713s
```

**`GoAdd1` levou 0,7894 ns e `CAdd1` levou 28,70 ns**, para o mesmo `x + 1`. Essa razão, de
umas 36 para 1 nesta execução e na casa dos trinta em toda execução nesta máquina, é a
travessia sozinha; as casas decimais mudam de uma execução para outra. O que os 28,70 ns pagam
é uma sequência, descrita nos comentários do início de `runtime/cgocall.go`, no código-fonte do Go:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"Uma chamada do Go para a função C add1, em seis passos. Na pilha da goroutine: 1, CAdd1 chama _Cfunc_add1, o invólucro que o cgo escreveu; 2, runtime.cgocall chama entersyscall, e o escalonador pode entregar o processador a outra thread. 3, asmcgocall troca para a pilha de sistema da thread. 4, add1 roda ali, compilada pelo gcc. 5, a pilha volta. 6, exitsyscall espera um processador e retorna. Uma chamada Go à mesma função levou 0,79 ns; esta ida e volta levou 28,70 ns.\"><defs><marker id=\"c4p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"c4a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"330\" height=\"300\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"370\" y=\"20\" width=\"330\" height=\"300\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a pilha da goroutine</text><text x=\"535\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a pilha de sistema da thread, g0</text><text x=\"185\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pequena, cresce, o runtime a move</text><text x=\"535\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vem do sistema operacional; o C roda aqui</text><rect x=\"40\" y=\"75\" width=\"290\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">1</text><text x=\"195\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CAdd1 → _Cfunc_add1</text><text x=\"195\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o invólucro que o cgo escreveu</text><rect x=\"40\" y=\"135\" width=\"290\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">2</text><text x=\"195\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">runtime.cgocall</text><text x=\"195\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">entersyscall: o P pode ir a outra thread</text><rect x=\"390\" y=\"195\" width=\"290\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"406\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">4</text><text x=\"545\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">add1(x)</text><text x=\"545\" y=\"227\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">C, compilado pelo gcc</text><rect x=\"40\" y=\"255\" width=\"290\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">6</text><text x=\"195\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">exitsyscall</text><text x=\"195\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">espera um P e retorna</text><path d=\"M185 119 L185 131\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#c4p)\"></path><path d=\"M330 179 L470 191\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#c4a)\"></path><text x=\"440\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3  troca de pilha</text><path d=\"M470 239 L330 255\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#c4a)\"></path><text x=\"440\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">5  volta de pilha</text><text x=\"360\" y=\"346\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o mesmo x + 1 como chamada Go: 0,79 ns</text><text x=\"360\" y=\"370\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">como chamada ao C, passos 1 a 6: 28,70 ns</text></svg>", "caption": "Uma chamada ao C é uma chamada mais uma passagem pelo escalonador e uma troca de pilha, na ida e na volta."}
```

**A pilha de uma goroutine é pequena e se move.** Ela começa com poucos kilobytes, e o runtime a
copia para um lugar maior quando ela cresce, ajustando cada ponteiro para dentro dela. Código C
compilado pelo `gcc` supõe uma pilha grande que fica no lugar, então não pode rodar na de uma
goroutine. Toda thread do Go tem uma segunda pilha para o trabalho do próprio runtime, a `g0`,
alocada pelo sistema operacional, e o `asmcgocall` troca para ela pelo tempo da chamada C. Em volta
dessa troca, `entersyscall` e `exitsyscall` avisam o escalonador que esta thread foi para onde ele
não consegue acompanhar, como faz uma chamada de sistema. Enquanto isso, o espaço de processador, o
P, pode rodar outras goroutines, e depois ele precisa ser recuperado.

## Agrupar, e o que isso pode e não pode economizar

`CRCLines` e `CRCLinesInC` fazem as mesmas 20.000 chamadas a `crc32` sobre os mesmos bytes. A única
diferença é de que lado da linha o laço está: 20.000 travessias contra uma.

| benchmark | travessias | tempo por checksum do log |
|---|---|---|
| `zlib-per-line-from-Go` | 20.000 | 2,12 ms |
| `zlib-per-line-from-C` | 1 | 1,86 ms |
| `zlib-once` | 1 | 0,174 ms |
| `hash-crc32` | 0 | 0,019 ms |

**Levar o laço para o C economizou 0,26 ms**, cerca de 12% do tempo. É menos que os
0,57 ms que 20.000 travessias de 28,70 ns preveriam, então tome o número da função vazia
pelo que ele é: a travessia no seu ponto mais exposto, um teto e não um preço. Cada chamada também
fez uns 90 ns de trabalho de `crc32`, então a travessia nunca foi o custo principal aqui.
**A razão que decide se agrupar compensa é a travessia contra o trabalho feito por chamada.** Uma
função C cujo trabalho leva o mesmo tempo que a travessia passa metade do tempo atravessando; uma
que roda por um milissegundo nem percebe.

A linha seguinte é a lição maior. O `zlib-once` entrega à zlib o arquivo inteiro numa chamada e
leva 0,174 ms, 11 vezes mais rápido que as duas versões por linha, porque a zlib é mais
rápida sobre um buffer grande do que sobre muitos pequenos. Agrupar através do cgo costuma
significar exatamente isto: **desenhar a chamada para que o C receba um buffer inteiro, um vetor,
um lote de trabalho**, e deixá-lo fazer o laço onde o laço é barato.

A última linha é a que vale lembrar na hora de decidir se usa C. **O `hash/crc32` calculou o mesmo
checksum em 0,019 ms, 9 vezes mais rápido que o melhor da zlib**, sem cgo. Em amd64 ele usa
a instrução de multiplicação sem transporte do processador, `PCLMULQDQ`, a partir de assembly da
biblioteca padrão, coisa que a zlib compilada pelo Ubuntu não faz. "C é mais rápido" é uma crença
que vale medir antes de pagar por ela; a seção 06 volta a isso.

## Uma chamada bloqueada prende uma thread

A travessia tem um segundo custo, que um benchmark de função rápida não mostra. Enquanto uma
goroutine está dentro do C, a thread embaixo dela pertence ao C. Se a função C bloqueia, esperando
um disco, uma trava ou a rede, a thread bloqueia junto, e o escalonador inicia outra thread para o
código Go continuar rodando. O `threads/main.go` inicia 100 goroutines que dormem meio segundo, no
Go ou no `usleep` do C. Enquanto elas dormem, ele lê de `/proc` o número de threads do processo:

```go
// Command threads starts 100 goroutines that each sleep for half a second,
// either in Go or inside a C function, and counts the process's threads
// while they sleep.
package main

/*
#include <unistd.h>
*/
import "C"

import (
	"bytes"
	"fmt"
	"os"
	"sync"
	"time"
)

func main() {
	inC := len(os.Args) > 1 && os.Args[1] == "c"
	var wg sync.WaitGroup
	for range 100 {
		wg.Go(func() {
			if inC {
				C.usleep(500000)
			} else {
				time.Sleep(500 * time.Millisecond)
			}
		})
	}
	time.Sleep(250 * time.Millisecond)
	status, _ := os.ReadFile("/proc/self/status")
	for line := range bytes.Lines(status) {
		if bytes.HasPrefix(line, []byte("Threads:")) {
			fmt.Printf("%s", line)
		}
	}
	wg.Wait()
}
```

```
ana@vm:~/cgo$ go build -o bin/ ./threads && bin/threads && bin/threads c
Threads:	6
Threads:	104
```

**Seis threads para 100 goroutines dormindo no Go; 104 quando elas dormem no C.**
Uma goroutine dormindo em `time.Sleep` fica estacionada pelo escalonador e custa poucos kilobytes
de pilha. Uma goroutine dormindo no C custa uma thread do sistema operacional, com pilha própria. A
documentação do pacote `net` dá isso como motivo para o Go preferir o próprio resolvedor de DNS ao
da biblioteca C: "a blocked DNS request consumes only a goroutine, while a blocked C call consumes
an operating system thread". Um servidor que chama uma função C bloqueante em cada handler de
requisição descobre isso como uma contagem de threads que acompanha o tráfego.
