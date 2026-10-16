---
title: O caso default, e o canal nil
version: 1
---

Um `select` com um caso `default` nunca espera. **Se nenhum outro caso pode andar naquele instante,
o `default` roda no lugar**, e o `select` acaba. Isso transforma qualquer envio ou recebimento numa
tentativa: faça se der para fazer agora, senão faça outra coisa.

## Tentar sem esperar

Um uso comum é um envio que nunca pode segurar quem envia, como uma atualização de progresso que
pode ser descartada se ninguém estiver ouvindo ainda. Aqui o canal tem espaço para dois e quem envia
oferece cinco, salvo como `try.go`:

```go
// Command try offers five updates to a channel with room for two, without waiting.
package main

import "fmt"

func main() {
	updates := make(chan int, 2)
	for i := 1; i <= 5; i++ {
		select {
		case updates <- i:
			fmt.Println("queued", i)
		default:
			fmt.Println("dropped", i)
		}
	}
	close(updates)
	for u := range updates {
		fmt.Println("received", u)
	}
}
```

```
ana@vm:~/select$ ./try
queued 1
queued 2
dropped 3
dropped 4
dropped 5
received 1
received 2
```

Os dois primeiros envios acharam espaço e entraram na fila. Os outros três acharam o buffer cheio e,
em vez de esperar, rodaram o `default`. **Nada bloqueou, em momento nenhum**, e quem recebe depois
pegou exatamente as duas atualizações que couberam. Se descartar é aceitável é uma decisão sobre os
dados: uma porcentagem de progresso pode ser descartada, um pedido não. Um recebimento funciona do
mesmo jeito: `case v := <-ch` com um `default` lê um valor se houver um ali e senão segue.

## Um default num laço é um laço ocupado

A tentação é pôr um `select` com `default` num laço `for` e "conferir de vez em quando". O laço então
nunca espera nada: gira tão rápido quanto o processador deixa. Dois programas esperam um segundo pelo
mesmo valor, um com um recebimento que bloqueia e outro com `default` num laço, salvo como
`patient.go`:

```go
// Command patient waits one second for a value with a blocking receive.
package main

import (
	"fmt"
	"time"
)

func main() {
	ch := make(chan int)
	go func() {
		time.Sleep(time.Second)
		ch <- 1
	}()
	fmt.Println("got", <-ch)
}
```

e como `restless.go`:

```go
// Command restless waits one second for a value by polling with default.
package main

import (
	"fmt"
	"time"
)

func main() {
	ch := make(chan int)
	go func() {
		time.Sleep(time.Second)
		ch <- 1
	}()
	polls := 0
	for {
		select {
		case v := <-ch:
			fmt.Println("got", v, "after", polls, "polls")
			return
		default:
			polls++
		}
	}
}
```

```
ana@vm:~/select$ time ./patient
got 1

real	0m1.002s
user	0m0.003s
sys	0m0.000s
ana@vm:~/select$ time ./restless
got 1 after 316410547 polls

real	0m1.007s
user	0m0.994s
sys	0m0.009s
```

Os dois levaram um segundo de relógio, a linha `real`. A diferença está em `user`, o tempo que o
processador passou rodando o programa: **3 milissegundos para o recebimento que bloqueia, 994 para o
laço que fica perguntando.** O `restless` rodou o `select` 316.410.547 vezes para descobrir o que o
`patient` ficou sabendo de graça, e manteve um processador em carga total o segundo inteiro. Num
notebook isso é ventoinha e bateria; num servidor, um processador tirado de todas as outras
goroutines.

Então `default` é para uma tentativa só, não para esperar. Se o laço não tem mais nada a fazer, um
recebimento simples ou um `select` sem `default` espera sem gastar nada.

## Um canal nil desliga um caso

Mais um fato completa o `select`. **Um envio ou recebimento num canal nil bloqueia para sempre**,
então um caso num canal nil nunca pode ser escolhido. Pôr `nil` numa variável de canal é, portanto, o
jeito de desligar um caso enquanto os outros continuam. Aqui duas entradas terminam em momentos
diferentes, e cada uma vira `nil` quando fecha, salvo como `both.go`:

```go
// Command both drains two channels that close at different times.
package main

import "fmt"

func numbers(from, to int) <-chan int {
	out := make(chan int)
	go func() {
		for i := from; i <= to; i++ {
			out <- i
		}
		close(out)
	}()
	return out
}

func main() {
	a, b := numbers(1, 2), numbers(10, 14)
	for a != nil || b != nil {
		select {
		case v, ok := <-a:
			if !ok {
				fmt.Println("a closed")
				a = nil
				continue
			}
			fmt.Println("a", v)
		case v, ok := <-b:
			if !ok {
				fmt.Println("b closed")
				b = nil
				continue
			}
			fmt.Println("b", v)
		}
	}
}
```

```
ana@vm:~/select$ ./both
b 10
b 11
b 12
b 13
b 14
b closed
a 1
a 2
a closed
```

Todos os valores das duas entradas chegaram, cada close foi informado uma vez, e o laço terminou
quando as duas variáveis eram `nil`. **Sem o `a = nil`, um `a` fechado deixaria o caso dele pronto
para sempre**, devolvendo zero e `false` a cada passada, e o laço giraria exatamente como o
`restless`. Com ele, o caso sai do `select`, e a próxima passada só espera em `b`.

Esta execução pegou todo o `b` antes de qualquer `a`: as duas goroutines estavam prontas, e a ordem
em que os valores vieram é escolha do escalonador, como sempre. A lição 14 parte desse padrão para
juntar canais cujo número não se sabe de antemão.
