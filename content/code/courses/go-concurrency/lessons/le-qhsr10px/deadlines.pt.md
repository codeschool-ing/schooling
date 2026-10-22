---
title: Prazos, timeouts e por que parou
version: 1
---

A lição 5 pôs um timeout num `select` com `time.After`. Isso cobre uma espera. Uma requisição que
chama três serviços, cada um por meio de duas funções, precisa de **um orçamento para o todo**, e
cada espera lá dentro deve desistir quando o orçamento acabar. **`context.WithTimeout(parent, d)` é
um contexto que se cancela sozinho depois de `d`; `context.WithDeadline(parent, t)` faz o mesmo no
instante `t`.** O primeiro é escrito em termos do segundo.

## Uma consulta com orçamento

O programa abaixo dá 100 milissegundos a uma consulta lenta. Ele usa `WithTimeoutCause`, do Go 1.21,
que também registra um erro seu como motivo. Salvo como `deadline.go`:

```go
// Command deadline gives a slow lookup 100 ms, and asks afterwards why it stopped.
package main

import (
	"context"
	"errors"
	"fmt"
	"time"
)

var errSlowDNS = errors.New("lookup budget of 100ms spent")

// lookup pretends to ask a slow server, and gives up when ctx is done.
func lookup(ctx context.Context) (string, error) {
	select {
	case <-time.After(300 * time.Millisecond):
		return "192.0.2.10", nil
	case <-ctx.Done():
		return "", ctx.Err()
	}
}

func main() {
	ctx, cancel := context.WithTimeoutCause(context.Background(), 100*time.Millisecond, errSlowDNS)
	defer cancel()

	d, ok := ctx.Deadline()
	fmt.Println("has a deadline:", ok, " in about", time.Until(d).Round(10*time.Millisecond))

	start := time.Now()
	addr, err := lookup(ctx)
	fmt.Printf("addr %q after %v\n", addr, time.Since(start).Round(10*time.Millisecond))
	fmt.Println("err:", err)
	fmt.Println("is DeadlineExceeded:", errors.Is(err, context.DeadlineExceeded))
	fmt.Println("cause:", context.Cause(ctx))
}
```

```
ana@vm:~/ctx$ go run deadline.go
has a deadline: true  in about 100ms
addr "" after 100ms
err: context deadline exceeded
is DeadlineExceeded: true
cause: lookup budget of 100ms spent
```

Leia as linhas em ordem:

- **`Deadline()` informou o orçamento**, cerca de 100 milissegundos a partir do momento da
  pergunta. Código lá no fundo da chamada pode usá-lo para decidir não começar algo que não termina
  a tempo.
- `lookup` desistiu depois de 100 milissegundos, e não dos 300 que o servidor dela levaria, porque o
  `select` dela também esperava `ctx.Done()`.
- **`Err()` disse `context deadline exceeded`**, e `errors.Is(err, context.DeadlineExceeded)` é como
  o código deve testar isso, já que quem chama mais acima pode embrulhar o erro.
- **`context.Cause` devolveu o erro passado a `WithTimeoutCause`**, que diz qual orçamento acabou.
  `Err()` só pode ser um de dois valores, então num programa com vários prazos ele não sabe dizer de
  quem era. O mesmo par existe para o cancelamento manual: `WithCancelCause` devolve um `cancel(err)`
  que registra uma causa.

Um filho só consegue apertar um prazo. **`WithTimeout` num contexto que já tem um prazo mais cedo
mantém o mais cedo**, então uma função lá no fundo da chamada não consegue se dar mais tempo do que
quem a chamou tinha.

## O `cancel` que você precisa chamar

`WithTimeout` também devolve uma função `cancel`, e é tentador descartá-la, já que o contexto vai se
cancelar sozinho de qualquer jeito. Até o prazo ele segura um timer e um lugar na lista de filhos do
pai. Salvo como `lost.go`:

```go
// Command lost forgets to call the cancel function it was given.
package main

import (
	"context"
	"fmt"
	"time"
)

func main() {
	ctx, _ := context.WithTimeout(context.Background(), time.Second)
	fmt.Println(ctx.Err())
}
```

```
ana@vm:~/ctx$ go vet lost.go
lost.go:11:7: the cancel function returned by context.WithTimeout should be called, not discarded, to avoid a context leak
```

**O `go vet` recusa o `cancel` descartado pelo nome.** Num servidor que cria um contexto por
requisição com um timeout longo e nunca o cancela, esses timers e entradas se acumulam até cada
prazo passar. `defer cancel()` na linha seguinte à chamada `With…` é o hábito, como no
`deadline.go`.
