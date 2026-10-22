---
title: Quando um pedaço falha
version: 1
---

Com uma goroutine só, um erro é simples: devolva-o, e o trabalho para. Com vinte pedaços de
trabalho espalhados por quatro workers, a falha de um pedaço levanta três perguntas. **Os outros
devem parar? Quem fica sabendo por quê? E o que acontece com os erros que já estavam a caminho?** As
respostas de costume são sim, quem chamou, e eles são guardados, e a biblioteca padrão tem uma
ferramenta para cada uma.

O programa abaixo verifica vinte arquivos com quatro workers. Ler um arquivo leva 20 milissegundos,
e os arquivos 3 e 4 estão danificados. Ele é salvo em `~/fanout/firsterr` como `firsterr.go`:

```go
// Command firsterr checks twenty files with four workers and stops at the first bad one.
package main

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

// check stands for verifying one file: reading it takes 20ms, and files 3 and 4 are damaged.
func check(ctx context.Context, file int) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	time.Sleep(20 * time.Millisecond)
	if file == 3 || file == 4 {
		return fmt.Errorf("file %d: checksum mismatch", file)
	}
	return nil
}

func main() {
	ctx, cancel := context.WithCancelCause(context.Background())
	defer cancel(nil)

	files := make(chan int)
	var checked atomic.Int64
	var mu sync.Mutex
	var errs []error

	var wg sync.WaitGroup
	for range 4 {
		wg.Go(func() {
			for f := range files {
				err := check(ctx, f)
				if errors.Is(err, context.Canceled) {
					continue
				}
				if err != nil {
					mu.Lock()
					errs = append(errs, err)
					mu.Unlock()
					cancel(err)
					continue
				}
				checked.Add(1)
			}
		})
	}

feed:
	for f := 1; f <= 20; f++ {
		select {
		case files <- f:
		case <-ctx.Done():
			break feed
		}
	}
	close(files)
	wg.Wait()

	fmt.Println("checked cleanly:", checked.Load(), "of 20")
	fmt.Println("cause:", context.Cause(ctx))
	fmt.Println("all errors:")
	fmt.Println(errors.Join(errs...))
}
```

```
ana@vm:~/fanout$ go run ./firsterr
checked cleanly: 2 of 20
cause: file 4: checksum mismatch
all errors:
file 4: checksum mismatch
file 3: checksum mismatch
```

**O primeiro erro parou o resto.** Os arquivos 1 a 4 estavam sendo lidos quando o primeiro
danificado falhou; aquele worker chamou `cancel(err)`, e daí em diante três coisas se recusaram a
começar trabalho novo. O `check` volta na hora quando o contexto já terminou, que é o "antes de
começar um trabalho caro" da lição 11. O laço que alimenta, no `main`, espera `ctx.Done()` ao lado
do envio, então para de distribuir arquivos. E um worker que recebeu `context.Canceled` de volta o
pula, porque um cancelamento não é uma das falhas que estão sendo relatadas. Dois arquivos foram
verificados sem problema de vinte. Esse número muda de uma execução para outra: quando os dois
arquivos bons terminam um instante antes dos danificados, os workers deles pegam os dois seguintes
antes de o cancelamento chegar, e outras execuções deste programa imprimiram 4.

**`context.WithCancelCause` guarda o motivo.** Um `cancel()` comum deixa `ctx.Err()` dizendo
`context canceled` e nada mais. `cancel(err)` registra o erro que causou o cancelamento, e
`context.Cause(ctx)` o devolve: aqui, `file 4: checksum mismatch`, a falha que chamou `cancel`
primeiro. Chamadas seguintes do mesmo `cancel` não mudam nada, então a causa é o primeiro motivo,
que costuma ser o que alguém quer ler.

**`errors.Join` guarda o resto.** Os arquivos 3 e 4 foram lidos ao mesmo tempo e falharam ao mesmo
tempo, então cancelar não podia evitar a segunda falha, e descartá-la esconderia um arquivo
danificado. Os workers juntaram cada erro de verdade sob uma trava, e o `errors.Join` os
transformou num erro só, que se imprime um por linha. `errors.Is` e `errors.As` olham dentro de um
erro juntado, então quem chamou ainda pode perguntar se algum deles era de um tipo específico.

O módulo `golang.org/x/sync` tem um pacote, `errgroup`, que embrulha essa forma: iniciar
goroutines, cancelar no primeiro erro, devolvê-lo. Ele fica fora da biblioteca padrão, e este curso
não usa nenhum; o programa acima é o que um pacote assim faz por baixo.
