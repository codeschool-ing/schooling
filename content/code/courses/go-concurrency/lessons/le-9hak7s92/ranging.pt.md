---
title: Percorrer um canal com range
version: 1
---

Um receptor que não sabe quantos valores vêm quer um laço que os pegue até quem envia dizer que
acabou. **`for v := range ch` é esse laço: recebe até o canal estar fechado e vazio, e então
termina.** É o recebimento de dois valores da seção 03, com a conferência do `ok` escrita por você.

## Um produtor e um consumidor

`split` envia cada palavra de um texto e depois fecha o canal; `main` percorre o canal com range,
salvo como `words.go`:

```go
// Command words sends some words on a channel and ranges over them.
package main

import (
	"fmt"
	"strings"
)

func split(text string, out chan<- string) {
	for _, w := range strings.Fields(text) {
		out <- w
	}
	close(out)
}

func main() {
	words := make(chan string)
	go split("share memory by communicating", words)
	for w := range words {
		fmt.Println(len(w), w)
	}
	fmt.Println("the channel is closed and drained")
}
```

```
ana@vm:~/channels$ go run words.go
5 share
6 memory
2 by
13 communicating
the channel is closed and drained
```

Quatro palavras, depois a linha que vem após o laço. **O laço terminou porque `split` fechou o
canal**, e só terminou depois de a última palavra ser recebida: um close nunca passa na frente de
valores já enviados. `split` recebe um `chan<- string`, então pode enviar e fechar e nada mais,
enquanto `main` segura o canal comum que criou.

Esse é o formato mais comum que um canal toma em código real: uma goroutine produz, outra consome, e
o `close` do produtor é a marca de fim dos dados. É a semente dos pipelines da lição 15, em que cada
etapa percorre o canal anterior com range e fecha o seguinte.

## Esquecer de fechar

O laço só termina porque `split` fechou o canal. Apagar essa única linha, com `sed`, dá um programa
que recebe as mesmas quatro palavras e depois espera uma quinta que ninguém vai enviar:

```
ana@vm:~/channels$ sed '/close(out)/d' words.go > forgot.go
ana@vm:~/channels$ go run forgot.go
5 share
6 memory
2 by
13 communicating
fatal error: all goroutines are asleep - deadlock!

goroutine 1 [chan receive]:
main.main()
	/home/ana/channels/forgot.go:18 +0x10a
exit status 2
```

**As palavras passaram mesmo assim; o laço é que nunca terminou.** Depois de `communicating`, `main`
esperou um quinto valor, `split` tinha retornado, e não sobrava goroutine nenhuma que pudesse enviar.
O runtime percebeu que toda goroutine do programa estava bloqueada e o parou com `fatal error: all
goroutines are asleep - deadlock!`, apontando `main` como presa em `[chan receive]` na linha 18, que
é o `range`.

Esse resgate só acontece porque todas as goroutines estavam presas. Num programa em que alguma outra
goroutine ainda está viva, digamos um servidor esperando conexões, o mesmo `close` esquecido deixa a
goroutine do range esperando para sempre, sem mensagem nenhuma. A lição 4 olha de perto o erro
fatal, e a lição 6 a versão silenciosa, que é um vazamento.

Daí saem duas regras, e elas são o range inteiro. **Quem envia fecha quando não tem mais nada a
enviar. Um receptor que usa range confia que ele vai fechar.**
