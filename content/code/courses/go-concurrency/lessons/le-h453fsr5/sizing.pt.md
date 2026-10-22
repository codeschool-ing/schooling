---
title: Quantos workers
version: 1
---

O `pool.go` escolheu cinquenta workers porque cinquenta arquivos de cada vez ficavam folgados abaixo
do limite. Essa é uma das duas perguntas que decidem o tamanho de um pool, e a outra é em que a
tarefa gasta o tempo. **Uma tarefa que calcula quer mais ou menos um worker por processador; uma
tarefa que espera quer tantos workers quanto aquilo que ela espera aguentar.** O programa abaixo mede
as duas coisas, com 64 tarefas e um número de workers dado na linha de comando, salvo como
`size.go`:

```go
// Command size runs 64 jobs on a given number of workers and times them.
//
//	./size cpu 4     jobs that compute
//	./size wait 16   jobs that wait
package main

import (
	"fmt"
	"os"
	"strconv"
	"sync"
	"time"
)

// compute keeps one processor busy for about 30 ms.
func compute() {
	var x uint64
	for range 40_000_000 {
		x = x*6364136223846793005 + 1
	}
	sink = x
}

var sink uint64

// wait stands in for a request to another machine.
func wait() { time.Sleep(20 * time.Millisecond) }

func main() {
	job := compute
	if os.Args[1] == "wait" {
		job = wait
	}
	workers, _ := strconv.Atoi(os.Args[2])

	start := time.Now()
	jobs := make(chan int)
	var wg sync.WaitGroup
	for range workers {
		wg.Go(func() {
			for range jobs {
				job()
			}
		})
	}
	for i := range 64 {
		jobs <- i
	}
	close(jobs)
	wg.Wait()
	fmt.Printf("%-4s %2d workers: %v\n", os.Args[1], workers, time.Since(start).Round(time.Millisecond))
}
```

`os.Args[1]` e `os.Args[2]` são as duas palavras depois do nome do programa; a lição 21 trata linhas
de comando direito, com o pacote `flag`. O laço `for range jobs` e o fechamento são a forma da seção
02, sem os resultados.

## Trabalho que calcula

```
ana@vm:~/pool$ for w in 1 2 4 8 16; do ./size cpu $w; done
cpu   1 workers: 2.039s
cpu   2 workers: 1.033s
cpu   4 workers: 572ms
cpu   8 workers: 543ms
cpu  16 workers: 560ms
```

Um worker levou 2,039 segundos, cerca de 32 milissegundos por tarefa. Dois cortaram pela metade,
quatro quase cortaram pela metade de novo, para 572 milissegundos, e **depois de quatro os ganhos
pararam**: oito e dezesseis workers levaram 543 e 560, a poucas dezenas de milissegundos de quatro,
que é o ruído entre duas execuções. O laboratório tem quatro processadores, e o `GOMAXPROCS` deixa
quatro goroutines calcularem ao mesmo tempo, como a lição 1 mostrou. Um quinto worker não tem
processador onde rodar e só reveza com os outros, o que acrescenta trocas e não economiza nada. Para
trabalho assim, **`runtime.GOMAXPROCS(0)` é o tamanho de partida**.

## Trabalho que espera

```
ana@vm:~/pool$ for w in 1 4 16 64; do ./size wait $w; done
wait  1 workers: 1.295s
wait  4 workers: 324ms
wait 16 workers: 102ms
wait 64 workers: 20ms
```

Cada tarefa dorme 20 milissegundos, então 64 delas uma de cada vez levaram 1,295 segundo. Aqui todo
worker a mais ajudou, até 20 milissegundos com 64 workers: uma rodada só, todas as tarefas esperando
ao mesmo tempo. **Um worker que espera não precisa de processador**, o `wait.go` da lição 1 de novo,
então o número de processadores não impõe teto.

O teto vem daquilo que as tarefas esperam. Uma espera pode ser compartilhada por qualquer número de
goroutines; um banco de dados que aceita cem conexões não pode, nem uma API que permite dez
requisições por segundo vindas de você, nem um disco. Então, para trabalho que espera, o tamanho do
pool é **o limite da coisa do outro lado**, menos o que mais a usa, e vale escrever esse motivo ao
lado do número.

## Meça, depois escolha

As duas execuções discordam de propósito, e tarefas reais raramente são puras. Uma tarefa que
decodifica um arquivo quase só calcula; uma que chama três serviços quase só espera; a maioria é uma
mistura. O método é o usado aqui: **rode a tarefa real com alguns tamanhos, dobrando a cada vez, e
pare onde o tempo para de cair** ou onde o recurso do outro lado começa a recusar. Benchmarks, a
lição 29, são como tornar essa medida repetível.
