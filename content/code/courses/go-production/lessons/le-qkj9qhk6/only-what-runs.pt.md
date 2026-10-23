---
title: Ele só vê o que roda
version: 1
---

O modelo mental comum do detector de corrida é o de um verificador que lê o código e acha as
corridas nele. **Ele não lê nada. Ele observa uma execução do programa**, registra cada acesso que o
código instrumentado faz e acusa dois acessos de goroutines diferentes que nada ordenou. Uma corrida
numa linha que a execução nunca alcançou, ou numa linha que só uma goroutine alcançou, não aconteceu
naquela execução, e o detector não tem nada a dizer sobre ela. Então um `go test -race` verde
significa "nenhuma corrida no que estes testes fizeram o código fazer", e o que os testes fazem o
código fazer é escolha sua.

## Dois testes que não conseguem vê-la

Os dois parecem testes razoáveis do `CountParallel`. O primeiro fixa o número de workers em um, para
que o resultado nunca dependa de tempo. O segundo passa zero, do jeito que o `pcount` o chama.
Salvo ao lado dos outros, `internal/tally/quiet_test.go`:

```go
package tally

import "testing"

// One worker, so that the test cannot be flaky.
func TestCountParallelOneWorker(t *testing.T) { checkParallel(t, 1) }

// One worker per CPU, the way pcount calls it.
func TestCountParallelDefault(t *testing.T) { checkParallel(t, 0) }
```

O código ainda tem a corrida da seção 02. O primeiro teste, com o detector observando:

```
ana@vm:~/race-hits$ go test -race -count=1 -run OneWorker -v ./internal/tally
=== RUN   TestCountParallelOneWorker
--- PASS: TestCountParallelOneWorker (0.00s)
PASS
ok  	example.com/hits/internal/tally	1.016s
```

**Passou, com `-race`, num código que tem uma corrida.** Com um worker há uma goroutine tocando `s`,
e uma corrida precisa de duas. O teste não está errado sobre o que confere; ele só nunca roda o
código de forma concorrente, e o detector só consegue acusar o que rodou.

O segundo teste é mais sutil, porque ver ou não a corrida depende da máquina. `taskset -c 0` roda um
comando só na primeira CPU, a situação de um programa numa máquina virtual com uma CPU, ou num runner
de CI que recebeu uma:

```
ana@vm:~/race-hits$ nproc; taskset -c 0 nproc
4
1
ana@vm:~/race-hits$ taskset -c 0 go test -race -count=1 -run Default ./internal/tally
ok  	example.com/hits/internal/tally	1.011s
```

Numa CPU, `runtime.GOMAXPROCS(0)` vale 1, então "um worker por CPU" é um worker e a corrida nunca
acontece. Nas quatro, o mesmo teste, o mesmo código e a mesma flag falham:

```
ana@vm:~/race-hits$ go test -race -count=1 -run Default ./internal/tally 2>&1 | tail -4
    testing.go:1865: race detected during execution of test
FAIL
FAIL	example.com/hits/internal/tally	0.020s
FAIL
```

**Se o CI pega isso ou não depende do tamanho da máquina que ele por acaso recebe**, e isso não é
uma propriedade que alguém escolheu.

A documentação de `runtime.GOMAXPROCS`, que `go doc runtime.GOMAXPROCS` imprime, diz como esse
número é escolhido: as CPUs lógicas, a máscara de afinidade de CPU que o `taskset` define e, no
Linux, a cota de CPU do contêiner. Ela também diz que uma cota nunca leva o padrão abaixo de 2, a não
ser que a máquina ou a máscara tenha menos de duas CPUs, então um contêiner limitado a uma CPU numa
máquina grande ainda recebe dois workers. Uma máquina virtual de uma CPU, ou uma máscara de
afinidade como a de cima, recebe um.

Uma CPU não é obstáculo para o outro teste:

```
ana@vm:~/race-hits$ taskset -c 0 go test -race -count=1 -v ./internal/tally 2>&1 | grep -E "^(---|ok|FAIL)"
--- FAIL: TestCountParallel (0.00s)
--- PASS: TestCountParallelOneWorker (0.00s)
--- PASS: TestCountParallelDefault (0.00s)
FAIL
FAIL	example.com/hits/internal/tally	0.011s
FAIL
```

O `TestCountParallel` pede dois workers, e duas goroutines numa CPU continuam se revezando em
`s.Lines` sem lock entre elas, então o detector acusa. **O detector precisa de duas goroutines, não
de duas CPUs.** Ele segue a ordem dos eventos, não o relógio: dois acessos que nada ordenou são uma
corrida tenham eles acontecido a um nanossegundo ou a uma fatia de tempo inteira um do outro.

## `-cpu` e `-count`

O `go test -cpu` recebe uma lista de valores para `GOMAXPROCS` e roda cada teste uma vez por valor.
Isso coloca o segundo teste para correr na mesma CPU única:

```
ana@vm:~/race-hits$ taskset -c 0 go test -race -count=1 -cpu 1,4 -run Default -v ./internal/tally 2>&1 | grep -E "^(=== RUN|---|ok|FAIL)"
=== RUN   TestCountParallelDefault
--- PASS: TestCountParallelDefault (0.00s)
=== RUN   TestCountParallelDefault
--- FAIL: TestCountParallelDefault (0.00s)
FAIL
FAIL	example.com/hits/internal/tally	0.011s
FAIL
```

Duas execuções do `TestCountParallelDefault`: com `-cpu 1` ele passou, e com `-cpu 4` falhou, num
comando ainda preso a uma CPU pelo `taskset`. **O `-cpu` define o número que o código vê, não o
número de CPUs que a máquina tem**, então qualquer código que se dimensiona pelo `GOMAXPROCS` pode
ser levado ao seu caminho concorrente em qualquer lugar. Use `-v` junto, como acima, porque sem `-v`
um teste que passa num valor e falha em outro imprime uma única linha `--- FAIL` e nenhuma pista de
qual valor falhou.

O `go test -count=N` é a outra repetição, e o `go help testflag` o descreve como rodar "each test,
benchmark, and fuzz seed n times"; junto com `-cpu`, ele roda n vezes para cada valor. Ele vale a
pena quando o caminho com corrida depende de tempo, um desvio que só roda se uma goroutine chegar a
algum ponto antes de outra, de modo que algumas execuções passam por ali e outras não. Esta corrida
não precisa dele: sempre que existem dois workers, toda execução a acusa. **O `-count=1` tem um
segundo trabalho no CI**, que a seção 05 mostra: é o jeito documentado de impedir o `go test` de
responder pelo cache.

## A correção, e a execução que a prova

Os dois contadores fazem parte de `s`, e todo worker escreve neles, então eles vão para baixo do
mesmo lock que os mapas. A seção 04 mede esta versão corrigida, com o detector ligado e desligado.
Editado, salvo de novo como `internal/tally/parallel.go`:

```go
package tally

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"runtime"
	"sync"
)

// CountParallel does what Count does, with several workers parsing the
// lines at once. With workers below 1 it starts one per CPU, as GOMAXPROCS
// counts them. It reports every line it cannot parse, not only the first.
func CountParallel(r io.Reader, workers int) (Summary, error) {
	if workers < 1 {
		workers = runtime.GOMAXPROCS(0)
	}
	var lines []string
	sc := bufio.NewScanner(r)
	for sc.Scan() {
		lines = append(lines, sc.Text())
	}
	if err := sc.Err(); err != nil {
		return Summary{}, err
	}

	s := Summary{ByStatus: map[int]int{}, ByPath: map[string]int{}}
	errs := make([]error, workers)
	var mu sync.Mutex
	var wg sync.WaitGroup
	for w := range workers {
		wg.Go(func() {
			for i := w; i < len(lines); i += workers {
				e, err := Parse(lines[i])
				if err != nil {
					errs[w] = errors.Join(errs[w], fmt.Errorf("line %d: %w", i+1, err))
					continue
				}
				mu.Lock() // everything in s is shared: all of it under the lock
				s.Lines++
				s.Total += e.Duration
				s.ByStatus[e.Status]++
				s.ByPath[e.Path]++
				mu.Unlock()
			}
		})
	}
	wg.Wait()
	return s, errors.Join(errs...)
}
```

A única mudança é a posição do `mu.Lock()`, agora acima de `s.Lines++`, e o comentário dele, que
agora diz por que o lock cobre tudo. Depois, a execução que prova a correção, em três valores de
`GOMAXPROCS`, três vezes cada, com o detector ligado e todos os pacotes do módulo incluídos:

```
ana@vm:~/race-hits$ go test -race -count=3 -cpu 1,2,4 ./...
ok  	example.com/hits	1.019s
ok  	example.com/hits/internal/tally	1.022s
?   	example.com/hits/tools/genlog	[no test files]
?   	example.com/hits/tools/pcount	[no test files]
ana@vm:~/race-hits$ go build -o pcount ./tools/pcount && for i in 1 2 3 4 5 6; do ./pcount < access.log; done
20000 lines, 1h6m37.778s in total
20000 lines, 1h6m37.778s in total
20000 lines, 1h6m37.778s in total
20000 lines, 1h6m37.778s in total
20000 lines, 1h6m37.778s in total
20000 lines, 1h6m37.778s in total
```

**Nove execuções de cada teste com o detector observando, e nada a acusar**; o `pcount` agora
imprime 20.000 linhas e o mesmo total, `1h6m37.778s`, seis vezes em seis. Os dois testes quietos
ficam no arquivo. Com a correção, nenhum deles tem mais corrida para achar, mas o
`TestCountParallelDefault` com `-cpu 1,2,4` exercita o caminho padrão em todos os tamanhos, e é esse
o teste que teria pegado o bug num runner de uma CPU.
