---
title: Fechando o canal juntado
version: 1
---

Uma junção tem uma pergunta fácil de errar nas duas direções: **quando fechar a saída.** Feche cedo
demais e uma copiadora que ainda roda envia num canal fechado. Nunca feche e quem percorre a saída
espera para sempre. Os dois erros parecem razoáveis no código, e os dois têm uma mensagem exata.

## Cedo demais

O lugar óbvio para o `close(out)` é logo depois do laço de uma copiadora, onde a entrada que ela
copiava acabou de fechar. O programa abaixo faz isso, com uma entrada rápida de uma leitura e uma
lenta de três. É salvo em `~/fanin/early` como `early.go`:

```go
// Command early closes the merged channel as soon as the first input is done.
package main

import (
	"fmt"
	"time"
)

func source(name string, n int, gap time.Duration) <-chan string {
	out := make(chan string)
	go func() {
		defer close(out)
		for i := 1; i <= n; i++ {
			time.Sleep(gap)
			out <- fmt.Sprintf("%s-%d", name, i)
		}
	}()
	return out
}

func merge(inputs ...<-chan string) <-chan string {
	out := make(chan string)
	for _, in := range inputs {
		go func() {
			for v := range in {
				out <- v
			}
			close(out) // wrong: the other inputs may still be sending
		}()
	}
	return out
}

func main() {
	all := merge(source("fast", 1, 10*time.Millisecond), source("slow", 3, 20*time.Millisecond))
	for reading := range all {
		fmt.Println(reading)
	}
	time.Sleep(100 * time.Millisecond)
	fmt.Println("main is done")
}
```

```
ana@vm:~/fanin$ go run ./early
slow-1
fast-1
panic: send on closed channel

goroutine 38 [running]:
main.merge.func1()
	/home/ana/fanin/early/early.go:26 +0x51
created by main.merge in goroutine 1
	/home/ana/fanin/early/early.go:24 +0x45
exit status 2
```

A copiadora da entrada rápida terminou primeiro e fechou `out`. A copiadora da entrada lenta ainda
rodava, e o envio seguinte dela, na linha 26 do `early.go`, `out <- v`, bateu num canal fechado.
**Um envio num canal fechado provoca panic**, como a lição 3 mostrou, e um panic em qualquer
goroutine encerra o programa inteiro. As duas linhas sob `goroutine 38` dizem qual goroutine foi, e
onde o `merge` a iniciou, na linha 24. Termine primeiro a copiadora que terminar, o resultado é o
mesmo, porque uma copiadora não tem como saber que as outras acabaram.

## Nunca

O erro oposto é deixar o `close` de fora. Toda entrada fecha direito, as copiadoras terminam, e a
saída fica aberta. É salvo em `~/fanin/never` como `never.go`:

```go
// Command never merges two inputs and never closes the result.
package main

import "fmt"

func numbers(from, n int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for i := from; i < from+n; i++ {
			out <- i
		}
	}()
	return out
}

func merge(inputs ...<-chan int) <-chan int {
	out := make(chan int)
	for _, in := range inputs {
		go func() {
			for v := range in {
				out <- v
			}
		}()
	}
	return out
}

func main() {
	for v := range merge(numbers(1, 2), numbers(10, 2)) {
		fmt.Println(v)
	}
	fmt.Println("done")
}
```

```
ana@vm:~/fanin$ go run ./never
1
2
10
11
fatal error: all goroutines are asleep - deadlock!

goroutine 1 [chan receive]:
main.main()
	/home/ana/fanin/never/never.go:30 +0xba
exit status 2
```

Os quatro valores chegaram. Então o `main` voltou ao seu `range`, na linha 30, atrás de um quinto,
as copiadoras já tinham retornado, e nada mais no programa podia enviar. O runtime percebeu que
todas as goroutines estavam paradas e encerrou o programa com a mensagem de deadlock da lição 4,
dando o nome da única goroutine que restava e do que ela esperava: `chan receive`.

**Aqui o runtime pegou o erro porque o `main` era a única goroutine que sobrou.** Num servidor,
onde sempre há outras goroutines vivas, o mesmo erro não levanta nada: a goroutine que percorre a
saída simplesmente espera para sempre, o que é um vazamento no sentido da lição 6, encontrado só
contando goroutines.

## A regra

A saída de uma junção é fechada exatamente uma vez, pelo código que sabe que todos os remetentes
terminaram. Na seção 02 foi uma goroutine esperando um `WaitGroup` que as copiadoras decrementam. No
merge com `select` da seção 03 não há canal de saída para fechar, porque o laço é o consumidor. Os
dois seguem a regra da lição 3, de que quem envia fecha, estendida a um canal com vários
remetentes: **o último remetente fecha, e só algo que os conta sabe qual é o último.**
