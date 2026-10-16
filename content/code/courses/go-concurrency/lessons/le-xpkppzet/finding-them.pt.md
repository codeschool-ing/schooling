---
title: Achando um vazamento, e onde ele está
version: 1
---

Uma contagem diz que alguma coisa vazou. Ela não diz o quê. **O runtime sabe dizer a linha em que
cada goroutine está parada**, e como as goroutines de um vazamento estão todas paradas na mesma
linha, a resposta costuma saltar aos olhos. Esta seção faz três perguntas ao runtime, da mais barata
à mais precisa.

## Quantas: `runtime.NumGoroutine`

A seção 02 já a usou. Um número, barato o bastante para ler a cada requisição, e o que vale a pena
pôr num painel: **um serviço em repouso que tem mais goroutines a cada hora está vazando**, seja lá
o que mais for verdade. O que ele não sabe dizer é que goroutines são essas.

## Onde: o perfil de goroutines

O pacote `runtime/pprof` mantém vários perfis, e o chamado `goroutine` é uma lista de todas as
goroutines com a pilha em que cada uma está parada. Pedido com nível de depuração 1, ele agrupa as
goroutines que compartilham uma pilha e as conta. O programa abaixo vaza exatamente como o
`first.go` vazou e depois imprime um perfil; o nome do perfil vem da linha de comando e, sem
argumento, é `goroutine`. Salvo como `find.go`:

```go
// Command find leaks the way first.go does, then asks the runtime where.
package main

import (
	"fmt"
	"os"
	"runtime/pprof"
	"time"
)

func ask(server int) string {
	time.Sleep(time.Duration(server) * 10 * time.Millisecond)
	return fmt.Sprint("answer from server ", server)
}

func first() string {
	ch := make(chan string)
	for s := 1; s <= 3; s++ {
		go func() { ch <- ask(s) }()
	}
	return <-ch
}

func main() {
	for range 100 {
		first()
	}
	time.Sleep(100 * time.Millisecond)
	profile := "goroutine"
	if len(os.Args) > 1 {
		profile = os.Args[1]
	}
	pprof.Lookup(profile).WriteTo(os.Stdout, 1)
}
```

```
ana@vm:~/leaks$ go run find.go
goroutine profile: total 201
200 @ 0x47d82a 0x41421c 0x413e17 0x4dea1e 0x483561
#	0x4dea1d	main.first.func1+0x3d	/home/ana/leaks/find.go:19

1 @ 0x440e11 0x47cb9d 0x4cc871 0x4cc545 0x4c94a9 0x4de9bd 0x44aa27 0x483561
#	0x4cc870	runtime/pprof.writeRuntimeProfile+0xb0	/usr/local/go/src/runtime/pprof/pprof.go:848
#	0x4cc544	runtime/pprof.writeGoroutine+0x44	/usr/local/go/src/runtime/pprof/pprof.go:781
#	0x4c94a8	runtime/pprof.(*Profile).WriteTo+0x148	/usr/local/go/src/runtime/pprof/pprof.go:405
#	0x4de9bc	main.main+0x7c				/home/ana/leaks/find.go:33
#	0x44aa26	runtime.main+0x426			/usr/local/go/src/runtime/proc.go:302

```

Leia de cima para baixo. `total 201` é o mesmo número que `NumGoroutine` daria. Depois, uma entrada
por pilha distinta, da maior para a menor: **200 goroutines paradas na linha 19 de `find.go`**, que
é `go func() { ch <- ask(s) }()`, dentro da função literal que o compilador chamou de
`main.first.func1`. A outra entrada é o próprio `main`, pego no ato de escrever o perfil. Duzentas
goroutines num mesmo envio são o vazamento, com endereço.

Num servidor você não imprimiria isso no terminal. O pacote `net/http/pprof` serve os mesmos perfis
por HTTP, e a lição 12 de `go-production` trata disso; a leitura é a mesma.

## Quais estão presas de vez: o perfil de vazamentos

O perfil de goroutines lista todas as goroutines, as saudáveis também, e num servidor ocupado o
vazamento é uma entrada entre milhares. O Go 1.27 tem um segundo perfil, `goroutineleak`, que lista
só as goroutines que ele consegue provar que nunca mais vão rodar. Escrevê-lo dispara uma coleta de
lixo que procura goroutines bloqueadas num canal, numa trava ou num `WaitGroup` que **nenhuma
goroutine ainda em execução consegue alcançar**: se ninguém pode enviar, receber ou destravar nunca
mais, a espera não tem como acabar. O mesmo programa, pedindo esse perfil:

```
ana@vm:~/leaks$ go run find.go goroutineleak
goroutineleak profile: total 200
200 @ 0x47d82a 0x41421c 0x413e17 0x4dea1e 0x483561
#	0x4dea1d	main.first.func1+0x3d	/home/ana/leaks/find.go:19

```

As 200 e mais nada. `main` não aparece, porque `main` está rodando.

**A prova é sobre alcance, e esse também é o limite dela.** Se o canal ainda pode ser alcançado de
algum lugar, o coletor não consegue provar que ninguém vai usá-lo, e não diz nada. Aqui o canal fica
numa variável do pacote em vez de numa local, e todas as goroutines continuam vazando, salvo como
`hidden.go`:

```go
// Command hidden leaks like first.go, but through a channel a global variable keeps.
package main

import (
	"fmt"
	"os"
	"runtime"
	"runtime/pprof"
	"time"
)

var answers = make(chan string)

func ask(server int) string {
	time.Sleep(time.Duration(server) * 10 * time.Millisecond)
	return fmt.Sprint("answer from server ", server)
}

func first() string {
	for s := 1; s <= 3; s++ {
		go func() { answers <- ask(s) }()
	}
	return <-answers
}

func main() {
	for range 100 {
		first()
	}
	time.Sleep(100 * time.Millisecond)
	fmt.Println("goroutines:", runtime.NumGoroutine())
	pprof.Lookup("goroutineleak").WriteTo(os.Stdout, 1)
}
```

```
ana@vm:~/leaks$ go run hidden.go
goroutines: 201
goroutineleak profile: total 0
```

Duzentas goroutines vazadas e um perfil de vazamentos com zero. Uma variável global vive tanto
quanto o programa, então, até onde o coletor sabe, alguém ainda pode receber de `answers`. **Um perfil
de vazamentos vazio significa nenhum vazamento que ele conseguiu provar, e não nenhum vazamento.** A
contagem e o perfil de goroutines continuam vendo essas 200, e é por isso que o número barato fica
no painel.
