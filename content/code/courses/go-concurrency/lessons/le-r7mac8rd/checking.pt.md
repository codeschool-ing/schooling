---
title: Onde um laço olha
version: 1
---

Um contexto não para nada sozinho. **Cancelar fecha um canal e registra um motivo; o código que faz o
trabalho é que tem de olhar.** Uma função que recebe `ctx` e nunca o consulta aceita o parâmetro e
ignora o pedido, e o prazo de quem chamou passa com o trabalho ainda rodando. A pergunta, para todo
laço que pode demorar, é onde ele olha.

O programa abaixo roda dois laços de 300 itens, cada item um milissegundo de trabalho, com um
contexto que termina depois de 50 milissegundos. Um laço nunca pergunta; o outro pergunta antes de
cada item. Ele é salvo em `~/propagate/loop` como `loop.go`:

```go
// Command loop cancels two loops at the same moment and times how long each takes to notice.
package main

import (
	"context"
	"fmt"
	"time"
)

// step stands for one unit of real work: a millisecond of it.
func step() { time.Sleep(time.Millisecond) }

// deaf never asks its context anything.
func deaf(ctx context.Context, items int) int {
	done := 0
	for range items {
		step()
		done++
	}
	return done
}

// polite asks before every item.
func polite(ctx context.Context, items int) int {
	done := 0
	for range items {
		if ctx.Err() != nil {
			break
		}
		step()
		done++
	}
	return done
}

func run(name string, f func(context.Context, int) int) {
	ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
	defer cancel()
	start := time.Now()
	n := f(ctx, 300)
	fmt.Printf("%-6s did %3d of 300 items and returned after %v\n",
		name, n, time.Since(start).Round(10*time.Millisecond))
}

func main() {
	run("deaf", deaf)
	run("polite", polite)
}
```

```
ana@vm:~/propagate$ go run ./loop
deaf   did 300 of 300 items and returned after 350ms
polite did  47 of 300 items and returned after 50ms
```

`deaf` recebeu ordem de parar aos 50 milissegundos e terminou os 300 itens mesmo assim, voltando aos
350. Quem o chamou já tinha desistido do resultado havia muito, então 300 milissegundos de trabalho
foram jogados fora, e num servidor eles teriam sido tirados de requisições que ainda esperavam.
`polite` fez 47 itens e voltou aos 50 milissegundos, a menos de um item do prazo. **A distância entre
o prazo e o retorno é o custo de um passo**, porque é quanto o laço anda entre duas olhadas.

## Dois jeitos de olhar

São dois, e cada um serve para um tipo de passo.

- **`ctx.Err() != nil`** no topo de cada iteração, como faz `polite`, quando cada passo é cálculo
  ou uma chamada que volta sozinha. Ele pergunta sem esperar, e uma resposta não nula também é o
  motivo a devolver: `context.Canceled` ou `context.DeadlineExceeded`.
- **Um `select` com `case <-ctx.Done()`**, como `fetch` fez na seção 02, quando o passo é uma
  ESPERA: por um canal, um timer, um resultado de outra goroutine. Um laço parado num recebimento
  simples não está rodando código nenhum que pudesse consultar `ctx.Err()`, então o único jeito de
  perceber o cancelamento durante a espera é esperar `Done()` ao mesmo tempo. A lição 5 montou esse
  `select`.

Onde o próprio passo recebe um contexto, como uma requisição feita com `http.NewRequestWithContext`
na lição 12, ele olha por você e devolve o erro do contexto quando este termina. **Passar `ctx` para
uma chamada assim conta como olhar**, e é mais um motivo para ele entrar em toda chamada.

## Com que frequência

Olhar custa pouco: `ctx.Err()` lê um valor que o contexto guarda. Não é de graça, e um laço cujo
passo é uma única soma não precisa perguntar um bilhão de vezes. A regra útil é sobre tempo, não
sobre contagem: **olhe com frequência suficiente para que o laço passe do prazo por uma quantia que
não incomode ninguém.** Um passo de um milissegundo, como aqui, passou por menos de um. Um laço de
passos muito rápidos pode olhar a cada mil, e um passo que leva um segundo precisa de uma olhada
dentro dele, por um contexto repassado mais abaixo.

Mais um lugar importa, e é fácil de esquecer: **antes de começar um trabalho caro.** Uma função
chamada com um contexto que já terminou deve devolver o erro na hora, em vez de abrir um arquivo,
iniciar uma goroutine ou enviar uma requisição cuja resposta ninguém está esperando.
