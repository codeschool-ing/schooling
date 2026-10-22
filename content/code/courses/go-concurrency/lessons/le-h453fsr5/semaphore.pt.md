---
title: Um canal com buffer como limite
version: 1
---

Um pool mantém um conjunto fixo de goroutines e as alimenta. Há um segundo jeito de limitar a
concorrência, que mantém uma goroutine por tarefa e limita quantas podem **trabalhar** ao mesmo
tempo. Ele se chama semáforo: um contador de lugares livres, tomado antes do trabalho e devolvido
depois. **Em Go um canal com buffer é um semáforo sem código extra**: enviar toma um lugar, e
bloqueia quando não há nenhum; receber devolve um.

As tarefas são as do `unbounded.go`, e o limite é cinquenta de novo, salvo como `semaphore.go`:

```go
// Command semaphore starts one goroutine per job but lets only 50 work at once.
package main

import (
	"fmt"
	"os"
	"sync"
	"sync/atomic"
	"time"
)

func job() error {
	f, err := os.Open("/etc/hostname")
	if err != nil {
		return err
	}
	defer f.Close()
	time.Sleep(50 * time.Millisecond)
	return nil
}

func main() {
	start := time.Now()
	sem := make(chan struct{}, 50)
	var failed atomic.Int64
	var wg sync.WaitGroup
	for range 1000 {
		sem <- struct{}{}
		wg.Go(func() {
			defer func() { <-sem }()
			if job() != nil {
				failed.Add(1)
			}
		})
	}
	wg.Wait()
	fmt.Println("jobs: 1000  limit: 50  failed:", failed.Load(), " took:", time.Since(start).Round(10*time.Millisecond))
}
```

`sem` tem espaço para cinquenta structs vazias; uma `struct{}` não ocupa memória, porque o único
trabalho do canal é contar. O laço envia **antes** de iniciar cada goroutine, então o quinquagésimo
primeiro envio espera até alguma tarefa terminar e o recebimento adiado dela liberar um lugar.
`atomic.Int64` é um contador em que muitas goroutines podem somar com segurança sem trava, o assunto
da lição 8.

```
ana@vm:~/pool$ (ulimit -n 256; ./semaphore)
jobs: 1000  limit: 50  failed: 0  took: 1.04s
```

O mesmo resultado do `pool.go` sob o mesmo limite: nada falhou, em cerca de um segundo.

## Qual escolher

A diferença é onde a espera acontece, e o que existe enquanto ela dura.

| | pool de workers | semáforo |
|---|---|---|
| goroutines vivas | os workers, um número fixo | no máximo o limite, mais o laço que as inicia |
| quem espera quando está cheio | a produtora, enviando em `jobs` | o laço, enviando em `sem` |
| o estado próprio de uma tarefa | passado pelo canal | capturado pela closure, como em qualquer goroutine |
| encaixe natural | um fluxo de tarefas que não acaba, vindo de uma fila | uma lista conhecida de tarefas, cada uma uma chamada de função |

**Tome o lugar antes do `go`, não dentro da goroutine.** Se o envio em `sem` fosse a primeira linha
da goroutine, o laço iniciaria as mil goroutines de uma vez e só o trabalho delas esperaria. Os
arquivos estariam a salvo, mas mil goroutines existiriam, cada uma segurando o que a sua tarefa
carrega. Tomar o lugar no laço é o que mantém limitada também a contagem de goroutines.

Fora da biblioteca padrão, o módulo `golang.org/x/sync` oferece a mesma ideia como um tipo,
`semaphore.Weighted`, e o `errgroup.Group` tem um `SetLimit` que faz isso e guarda o primeiro erro.
Este curso fica dentro da biblioteca padrão; a lição 13 constrói à mão o tratamento de erros para
trabalho distribuído.
