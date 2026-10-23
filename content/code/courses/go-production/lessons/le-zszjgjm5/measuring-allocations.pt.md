---
title: Medindo alocações
version: 1
---

A seção 04 ajustou o coletor, e descobriu que a maior alavanca não era ajuste nenhum. **O trabalho do
coletor é proporcional ao que o programa aloca e guarda, então a medição que leva a algum lugar é a
das alocações**, e o Go tem uma ferramenta para cada escala: o processo inteiro, uma função, e a
linha de código responsável. Elas não são intercambiáveis, e a mais antiga tem um custo que as outras
não têm.

## O processo inteiro: MemStats ou runtime/metrics

`runtime.ReadMemStats`, que a lição 24 do curso `go` usou, preenche uma struct com a contabilidade do
runtime. `runtime/metrics`, que o `~/mem-stacks` e o `slowest` usaram, lê o mesmo tipo de número por
nome. A diferença que importa em produção está no corpo da primeira função:

```
ana@vm:~/mem-stats$ sed -n 356,365p /usr/local/go/src/runtime/mstats.go
func ReadMemStats(m *MemStats) {
	_ = m.Alloc // nil check test before we switch stacks, see issue 61158
	stw := stopTheWorld(stwReadMemStats)

	systemstack(func() {
		readmemstats_m(m)
	})

	startTheWorld(stw)
}
```

**`ReadMemStats` para o mundo** para tirar um retrato consistente: toda goroutine, pelo tempo que a
cópia levar. `metrics.Read` só pega uma trava própria, e o programa continua rodando enquanto ela
lê. Um benchmark de cada uma, em `~/mem-stats`, um módulo próprio com um único arquivo de teste.
Salve-o como `stats_test.go`:

```go
package memstats

import (
	"runtime"
	"runtime/metrics"
	"testing"
)

func BenchmarkReadMemStats(b *testing.B) {
	var m runtime.MemStats
	for b.Loop() {
		runtime.ReadMemStats(&m)
	}
}

func BenchmarkMetricsRead(b *testing.B) {
	s := []metrics.Sample{
		{Name: "/gc/heap/allocs:bytes"},
		{Name: "/gc/heap/allocs:objects"},
		{Name: "/gc/cycles/total:gc-cycles"},
	}
	for b.Loop() {
		metrics.Read(s)
	}
}
```

```
ana@vm:~/mem-stats$ go test -bench . -benchmem
goos: linux
goarch: amd64
pkg: example.com/memstats
cpu: Intel(R) Xeon(R) Processor
BenchmarkReadMemStats-4   	  171919	     11398 ns/op	       0 B/op	       0 allocs/op
BenchmarkMetricsRead-4    	 3624614	       338.8 ns/op	       0 B/op	       0 allocs/op
PASS
ok  	example.com/memstats	3.198s
```

**11.398 nanossegundos contra 338,8, mais de trinta vezes mais**, e a lenta parou todas as goroutines
do programa durante parte disso. Um programa que lê sua memória uma vez por minuto para um painel
pode usar qualquer uma. Um que lê a cada requisição deve usar `runtime/metrics`, que além disso põe
a unidade em cada chave e documenta cada métrica em `go doc runtime/metrics`. As duas colunas da
direita são a próxima ferramenta.

## Uma função: benchmarks que contam

`-benchmem` acrescenta `B/op` e `allocs/op` a todo benchmark da execução. `b.ReportAllocs()` os
acrescenta a um benchmark sempre, com a flag ou sem ela, o que serve a um benchmark cujo assunto
inteiro é alocação. O `keep.Load` recebe uma dica de quantas linhas esperar, e a seção 04 sempre
passou 0. Um benchmark das duas formas, ao lado do `keep.go`, lê o mesmo log de 100.000 linhas do
benchmark da lição 12. Salve-o como `internal/keep/keep_test.go`:

```go
package keep_test

import (
	"bytes"
	"os"
	"strconv"
	"testing"

	"example.com/hits/internal/keep"
	"example.com/hits/internal/tally"
)

func BenchmarkLoad(b *testing.B) {
	data, err := os.ReadFile("testdata/access.log")
	if err != nil {
		b.Fatal(err)
	}
	lines := bytes.Count(data, []byte("\n"))
	for _, hint := range []int{0, lines} {
		b.Run("hint="+strconv.Itoa(hint), func(b *testing.B) {
			b.ReportAllocs()
			for b.Loop() {
				if _, err := keep.Load(bytes.NewReader(data), hint); err != nil {
					b.Fatal(err)
				}
			}
		})
	}
}

func TestBySlowestDoesNotAllocate(t *testing.T) {
	entries := []tally.Entry{{Duration: 3}, {Duration: 1}, {Duration: 2}}
	allocs := testing.AllocsPerRun(100, func() { keep.BySlowest(entries) })
	if allocs != 0 {
		t.Errorf("BySlowest allocates %v times a call, want 0", allocs)
	}
}
```

`b.Run` cria dois sub-benchmarks, um sem dica e um com o número exato de linhas, contado uma vez com
`bytes.Count` antes de qualquer um começar. O teste no fim é a terceira ferramenta, e espera pelo seu
parágrafo. Rodado sem `-benchmem`:

```
ana@vm:~/mem-hits$ ./genlog -n 100000 > internal/keep/testdata/access.log
ana@vm:~/mem-hits$ go test -run "^$" -bench Load ./internal/keep
goos: linux
goarch: amd64
pkg: example.com/hits/internal/keep
cpu: Intel(R) Xeon(R) Processor
BenchmarkLoad/hint=0-4         	      22	  53056937 ns/op	53802259 B/op	  200033 allocs/op
BenchmarkLoad/hint=100000-4    	      46	  24474033 ns/op	20523557 B/op	  200003 allocs/op
PASS
ok  	example.com/hits/internal/keep	2.310s
```

As colunas de memória estão lá por causa do `ReportAllocs`. E elas contam duas histórias diferentes:

| | `hint=0` | `hint=100000` |
|---|---|---|
| ns/op | 53.056.937 | 24.474.033 |
| B/op | 53.802.259 | 20.523.557 |
| allocs/op | 200.033 | 200.003 |

**Trinta alocações a menos, 33 MB a menos, e menos da metade do tempo.** Quem contasse só alocações
diria que a dica não vale nada: 200.000 das alocações são as duas por linha da lição 12, a string do
`Text` e a fatia do `strings.Fields`, e a dica não toca em nenhuma delas. As trinta que ela removeu
eram enormes. Sem dica, o `append` faz a fatia crescer alocando um array maior e copiando o antigo
para dentro dele, e a regra do runtime para o quanto maior faz disso uma longa série numa fatia
grande:

```
ana@vm:~/mem-hits$ sed -n 337,341p /usr/local/go/src/runtime/slice.go
	for {
		// Transition from growing 2x for small slices
		// to growing 1.25x for large slices. This formula
		// gives a smooth-ish transition between the two.
		newcap += (newcap + 3*threshold) >> 2
```

Passados 256 elementos, cada array novo é cerca de um quarto maior que o anterior, então uma fatia de
100.000 entradas é montada através de uns trinta arrays, cada um copiado para o seguinte. **`B/op` vê
essas cópias; `allocs/op` conta cada uma delas como uma.** Leia as duas colunas, sempre.

## Uma linha de código: o perfil de heap

Quando um benchmark diz quanto e não onde, o perfil de heap diz onde. A lição 12 mostrou como obter
um e quais são as suas quatro visões; um comando basta para confirmar a leitura acima:

```
ana@vm:~/mem-hits$ go test -run "^$" -bench "Load/hint=0" -memprofile mem.out ./internal/keep > /dev/null && go tool pprof -top -sample_index=alloc_space mem.out | sed /^Time:/d | head -9
File: keep.test
Build ID: 78759425bf4cfa842ab0d3475d27dd21a0fb9aab
Type: alloc_space
Showing nodes accounting for 1249.59MB, 99.53% of 1255.46MB total
Dropped 19 nodes (cum <= 6.28MB)
      flat  flat%   sum%        cum   cum%
  935.07MB 74.48% 74.48%  1249.59MB 99.53%  example.com/hits/internal/keep.Load
  205.02MB 16.33% 90.81%   205.02MB 16.33%  strings.Fields
  109.51MB  8.72% 99.53%   109.51MB  8.72%  bufio.(*Scanner).Text (inline)
```

**O próprio `keep.Load` responde por 74,48% de todos os bytes alocados**, em flat: são os arrays que
o `append` fez crescer, atribuídos à função que o chamou. `strings.Fields` e `Scanner.Text` dividem o
resto, as duas por linha que a lição 12 encontrou.

## Um orçamento que os testes fazem cumprir

Certo código não deveria alocar nada, e o jeito de mantê-lo assim é um teste.
`testing.AllocsPerRun` chama uma função muitas vezes e devolve a média de alocações por chamada; a
lição 24 do curso `go` a chamou de `main`, e num teste ela vira uma regra. A última função do
`keep_test.go` prende o `BySlowest` a zero, porque ordenar no lugar não tem motivo para alocar:

```
ana@vm:~/mem-hits$ go test -count=1 -run Allocate -v ./internal/keep
=== RUN   TestBySlowestDoesNotAllocate
--- PASS: TestBySlowestDoesNotAllocate (0.00s)
PASS
ok  	example.com/hits/internal/keep	0.002s
```

Hoje ele passa. **No dia em que alguém mudar o `BySlowest` de um jeito que aloque**, o teste falha e
diz o número, muito antes de alguém fazer o perfil do programa que o chama. Copiar a fatia antes de
ordenar faria isso, ou passá-la por uma interface que o compilador não enxerga. Um orçamento de
0 é o mais rígido; uma função que precisa alocar uma vez pode ser presa a 1 do mesmo jeito.
