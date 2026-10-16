---
title: Esperar em vários canais ao mesmo tempo
version: 1
---

Todo recebimento até aqui esperou num canal só. Um programa que faz a mesma pergunta a dois
servidores quer a resposta que chegar primeiro, e um recebimento no canal do primeiro servidor
ficaria parado ali mesmo com a resposta do segundo já esperando. **`select` espera em várias
operações de canal ao mesmo tempo e executa a primeira que puder andar.** Ele parece um `switch`, e
cada `case` é um envio ou um recebimento.

## A primeira resposta ganha

Duas goroutines fazem o papel de dois servidores: uma responde depois de 120 milissegundos, a outra
depois de 80. `main` pega a resposta que chegar primeiro, salvo como `first.go`:

```go
// Command first asks two slow sources and takes whichever answers first.
package main

import (
	"fmt"
	"time"
)

func ask(name string, delay time.Duration, out chan<- string) {
	time.Sleep(delay)
	out <- name
}

func main() {
	start := time.Now()
	primary := make(chan string, 1)
	mirror := make(chan string, 1)
	go ask("primary", 120*time.Millisecond, primary)
	go ask("mirror", 80*time.Millisecond, mirror)

	select {
	case v := <-primary:
		fmt.Println("answer from", v)
	case v := <-mirror:
		fmt.Println("answer from", v)
	}
	fmt.Println("after", time.Since(start).Round(10*time.Millisecond))
}
```

```
ana@vm:~/select$ ./first
answer from mirror
after 80ms
```

`answer from mirror`, depois de 80 milissegundos: o `select` esperou nos dois recebimentos, e no
momento em que o valor do espelho chegou, aquele caso rodou e o `select` terminou. **O outro caso
simplesmente não foi escolhido.** A resposta do primário chegou 40 milissegundos depois num canal que
ninguém leu de novo. É por isso que os dois canais têm espaço para um valor: a goroutine que perdeu
consegue terminar o envio e retornar, em vez de esperar para sempre alguém que já foi embora, que é
o vazamento com que a lição 4 terminou. A lição 6 transforma isso em regra.

Um `select` sem nenhum caso pronto bloqueia até um ficar pronto, exatamente como um recebimento só.
**Ele bloqueia em todos ao mesmo tempo**, e o primeiro que ficar possível ganha.

## Quando mais de um está pronto

Se vários casos podem andar no momento em que o `select` roda, ele não pega o primeiro escrito.
**Ele escolhe um dos casos prontos ao acaso**, de modo uniforme. Este programa mantém dois canais
cheios e roda o `select` dez mil vezes, contando que caso ele pegou, salvo como `fair.go`:

```go
// Command fair counts which case select picks when both are always ready.
package main

import "fmt"

func main() {
	a := make(chan int, 1)
	b := make(chan int, 1)
	counts := map[string]int{}
	for range 10_000 {
		a <- 1
		b <- 1
		select {
		case <-a:
			counts["a"]++
			<-b
		case <-b:
			counts["b"]++
			<-a
		}
	}
	fmt.Println(counts)
}
```

```
ana@vm:~/select$ ./fair
map[a:4932 b:5068]
ana@vm:~/select$ ./fair
map[a:5004 b:4996]
```

Duas execuções, duas divisões, cada uma perto da metade: 4932 contra 5068, depois 5004 contra 4996.
Os dois casos estavam prontos todas as vezes, e o runtime escolheu entre eles ao acaso. **Esse acaso é
de propósito: se o `select` sempre preferisse o primeiro caso escrito, um primeiro canal ocupado
poderia deixar o segundo sem vez para sempre.** Também quer dizer que não dá para dar prioridade a um
caso escrevendo-o primeiro. Um programa que precisa de prioridade confere o canal importante num
`select` próprio, com um `default`, antes do geral; a seção 04 mostra o caso `default`.
