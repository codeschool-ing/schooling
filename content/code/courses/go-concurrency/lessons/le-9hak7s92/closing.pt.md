---
title: Fechar um canal
version: 1
---

Um receptor muitas vezes precisa saber uma coisa além dos valores: **que não vem mais nenhum**. É
isso que `close(ch)` diz. Ele não destrói o canal nem joga fora o que está nele. Ele marca o canal
como encerrado, e todo recebimento depois do último valor responde na hora em vez de esperar.

## O que um recebimento diz depois do close

A forma de dois valores de um recebimento, `v, ok := <-ch`, informa que tipo de resposta veio. O
programa abaixo põe dois valores num canal com espaço para os dois, um canal com buffer do tipo que
a lição 4 explica, fecha o canal e recebe quatro vezes, salvo como `closed.go`:

```go
// Command closed receives from a channel after it has been closed.
package main

import "fmt"

func main() {
	ch := make(chan string, 2)
	ch <- "first"
	ch <- "second"
	close(ch)

	for range 4 {
		v, ok := <-ch
		fmt.Printf("%q %v\n", v, ok)
	}
}
```

```
ana@vm:~/channels$ go run closed.go
"first" true
"second" true
"" false
"" false
```

Os dois primeiros recebimentos pegaram os dois valores enviados, com `ok` verdadeiro. **Depois disso
o canal estava fechado e vazio, e todo recebimento seguinte respondeu na hora com o zero value do
tipo do elemento e `ok` falso**: `""` para uma string, `0` para um int. Ele não bloqueia mais e não
se esgota. É por isso que o `ok` importa: sem ele, um receptor não distingue uma string vazia que
alguém enviou da string vazia que um canal fechado entrega.

Repare na ordem. Fechar não descartou `"first"` nem `"second"`; valores enviados antes do `close`
continuam sendo entregues, e só depois o canal começa a responder `false`.

## Dois erros que dão panic

Fechar é uma declaração sobre o futuro, então só pode ser feita uma vez, e só por um lado que não vai
enviar de novo. Enviar num canal fechado dá panic, salvo como `sendclosed.go`:

```go
// Command sendclosed sends on a channel that is already closed.
package main

func main() {
	ch := make(chan int, 1)
	close(ch)
	ch <- 1
}
```

e fechá-lo uma segunda vez também dá panic, salvo como `closetwice.go`:

```go
// Command closetwice closes the same channel twice.
package main

func main() {
	ch := make(chan int)
	close(ch)
	close(ch)
}
```

```
ana@vm:~/channels$ go run sendclosed.go
panic: send on closed channel

goroutine 1 [running]:
main.main()
	/home/ana/channels/sendclosed.go:7 +0x3a
exit status 2
ana@vm:~/channels$ go run closetwice.go
panic: close of closed channel

goroutine 1 [running]:
main.main()
	/home/ana/channels/closetwice.go:7 +0x30
exit status 2
```

Os dois são panics, e os dois encerram o programa, como a lição 2 mostrou que todo panic faz. **A
regra que eles impõem é que só o lado que envia fecha, e uma vez só.** Um receptor que fecha um canal
nunca tem certeza de que nenhum remetente está prestes a enviar, e um envio perdido depois disso é
este panic em produção. Também não existe função que pergunte se um canal está fechado: quando a
resposta chegasse, já poderia estar desatualizada.

Então quem fecha é uma decisão de projeto, tomada uma vez: **a goroutine dona dos envios fecha,
quando terminou de enviar tudo.** Se várias goroutines enviam num canal, nenhuma pode fechá-lo
sozinha, e a lição 14 mostra o formato que resolve isso.

## Um canal com uma direção só

Os tipos podem carregar essa regra, e então o compilador a impõe. `chan<- int` é um canal em que quem
o tem só pode enviar, e `<-chan int` um de que só pode receber. Um `chan int` comum se converte em
qualquer dos dois ao ser passado a uma função. Aqui uma função feita só para esvaziar um canal tenta
enviar nele, salvo como `oops.go`:

```go
// Command oops sends on a channel its function was given only to receive from.
package main

func drain(in <-chan int) {
	in <- 1
}

func main() {}
```

```
ana@vm:~/channels$ go build oops.go
# command-line-arguments
./oops.go:5:2: invalid operation: cannot send to receive-only channel <-chan int in (variable of type <-chan int)
```

O compilador recusou antes de qualquer coisa rodar, e deu o nome da operação e do tipo. Escrever
`<-chan int` numa assinatura não custa nada e deixa o papel de cada função legível desde a primeira
linha: `split`, na seção 04, recebe um `chan<- string` porque só envia e fecha. **Só o lado de envio
pode fechar um canal com direção**, o que o compilador também confere, e que é a regra acima virada
em tipos.
