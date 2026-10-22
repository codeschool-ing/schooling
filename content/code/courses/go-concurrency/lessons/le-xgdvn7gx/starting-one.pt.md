---
title: Iniciar uma, e o que o main deve a ela
version: 1
---

A palavra-chave `go` na frente de uma chamada de função inicia essa chamada como uma
**goroutine**: uma função que roda por conta própria, ao lado do código que a iniciou, que segue
em frente na hora sem esperar. A primeira imagem comum é que uma goroutine iniciada está segura até
terminar. **Não está: quando `main` retorna, o programa acaba, e toda goroutine ainda rodando acaba
junto**, no meio de uma linha se for o caso.

## O main não espera

O menor programa que mostra isso inicia uma goroutine e retorna, salvo como `early.go`:

```go
// Command early starts a goroutine and returns from main straight away.
package main

import "fmt"

func main() {
	go fmt.Println("hello from a goroutine")
	fmt.Println("main is done")
}
```

Cinco execuções:

```
ana@vm:~/goroutines$ go build -o early early.go
ana@vm:~/goroutines$ for i in 1 2 3 4 5; do ./early; done
main is done
main is done
main is done
main is done
main is done
```

Nenhuma saudação em cinco execuções. O comando `go` iniciou a goroutine e `main` seguiu direto
para o seu próprio `Println`, depois retornou, e retornar de `main` encerra o processo. A goroutine
tinha sido criada e ainda não tinha recebido um processador, e **nada no programa pediu a ninguém
que esperasse por ela**. Em outra execução, numa máquina mais ocupada ou mais ociosa, a saudação
pode escapar antes. Um programa cuja saída depende de qual dos dois ganha é o problema de ordem da
lição 1, um nível abaixo.

## Esperar de propósito

O conserto é fazer `main` esperar, e dizer pelo que espera. A lição 1 usou um `sync.WaitGroup`
para isso, e ele serve aqui também, salvo como `waited.go`:

```go
// Command waited starts a goroutine and waits for it before returning.
package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	wg.Go(func() { fmt.Println("hello from a goroutine") })
	wg.Wait()
	fmt.Println("main is done")
}
```

```
ana@vm:~/goroutines$ go build -o waited waited.go
ana@vm:~/goroutines$ for i in 1 2 3 4 5; do ./waited; done
hello from a goroutine
main is done
hello from a goroutine
main is done
hello from a goroutine
main is done
hello from a goroutine
main is done
hello from a goroutine
main is done
```

**Cinco execuções, cinco saudações, sempre antes de `main is done`**, porque `wg.Wait` não retorna
até a goroutine retornar. Essa ordem é prometida, e é isso que a lição 1 seção 04 chamou de
sincronização: `wg.Wait` retornar é um evento em que o programa pode confiar, e uma goroutine
"provavelmente rápida" não é. Pôr um `time.Sleep` em `main` também teria imprimido a saudação
nesta máquina, e seria um palpite sobre tempo escrito no código.

## O que o comando go faz com a sua chamada

Três detalhes do próprio comando pegam as pessoas desprevenidas.

- **Os argumentos são avaliados antes de a goroutine começar**, na goroutine que executa o comando
  `go`. `go show(x)` copia o valor que `x` tem naquele momento.
- **Os valores de retorno são jogados fora.** Não há como recolher o que uma goroutine retorna, e é
  por isso que resultados voltam por um canal (lição 3) ou por uma variável protegida por uma trava
  (lição 8).
- **Um panic em qualquer goroutine encerra o programa inteiro.** Ele não volta para a goroutine que
  a iniciou, e um `recover` em `main` não consegue pegá-lo.

Vale ver o terceiro uma vez, salvo como `crash.go`:

```go
// Command crash shows that a panic in a goroutine ends the program.
package main

import (
	"fmt"
	"sync"
)

func main() {
	defer fmt.Println("main's deferred call")
	var wg sync.WaitGroup
	wg.Go(func() {
		var m map[string]int
		m["oops"] = 1
	})
	wg.Wait()
	fmt.Println("main is done")
}
```

```
ana@vm:~/goroutines$ go run crash.go; echo "exit status: $?"
panic: assignment to entry in nil map [recovered, repanicked]

goroutine 7 [running]:
sync.(*WaitGroup).Go.func1.1()
	/usr/local/go/src/sync/waitgroup.go:251 +0x45
panic({0x55beb0?, 0x56e150?})
	/usr/local/go/src/runtime/panic.go:859 +0x125
main.main.func1()
	/home/ana/goroutines/crash.go:14 +0x28
sync.(*WaitGroup).Go.func1()
	/usr/local/go/src/sync/waitgroup.go:258 +0x4a
created by sync.(*WaitGroup).Go in goroutine 1
	/usr/local/go/src/sync/waitgroup.go:238 +0x7d
exit status 2
exit status: 1
```

O mapa nunca foi criado, então escrever nele dá panic, e o panic encerrou o programa com o status de
saída 2. O `exit status: 1` do próprio comando go vem depois, porque `go run` informa a falha do que
rodou. Vale achar duas linhas. `main.main.func1()` em `crash.go:14` é a linha que deu panic, e
`created by sync.(*WaitGroup).Go in goroutine 1` dá o nome da goroutine que iniciou esta: a
goroutine 1 é `main`. **`main is done` e `main's deferred call` nunca foram impressos.** A chamada
adiada pertence à goroutine de `main`, e o processo acabou debaixo dela. A anotação `[recovered,
repanicked]` vem de `wg.Go`, que pega o panic só para levantá-lo de novo a partir da goroutine que
falhou, e assim o trace aponta para o lugar certo.
