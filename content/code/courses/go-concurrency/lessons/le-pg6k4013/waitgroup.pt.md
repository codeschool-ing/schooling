---
title: Esperando goroutines com um WaitGroup
version: 1
---

Toda lição até aqui usou `wg.Go` e `wg.Wait` e prometeu os detalhes para cá. **Um `sync.WaitGroup` é
um contador de goroutines ainda rodando, com um `Wait` que bloqueia até o contador voltar a zero.**
`Add` o aumenta, `Done` o diminui em um, e o `wg.Go`, novo no Go 1.25, faz as duas coisas por você
em volta de uma função.

## O caminho longo

Antes do Go 1.25 todo programa escrevia as três chamadas à mão, e a maior parte do código que você
vai ler ainda faz isso. Salvo como `wait.go`:

```go
// Command wait downloads three pretend files and waits for all of them, the long way.
package main

import (
	"fmt"
	"sync"
	"time"
)

func download(name string) {
	time.Sleep(20 * time.Millisecond)
	fmt.Println("downloaded", name)
}

func main() {
	var wg sync.WaitGroup
	for _, name := range []string{"a.txt", "b.txt", "c.txt"} {
		wg.Add(1)
		go func() {
			defer wg.Done()
			download(name)
		}()
	}
	wg.Wait()
	fmt.Println("all three done")
}
```

```
ana@vm:~/waitonce$ go run wait.go
downloaded b.txt
downloaded a.txt
downloaded c.txt
all three done
```

`wg.Add(1)` roda no `main`, antes de a goroutine começar; `defer wg.Done()` é a primeira linha da
goroutine, então roda seja qual for o jeito como ela termina. Os três downloads terminaram numa
ordem que ninguém escolheu, o ponto da lição 1 de novo, e `all three done` veio depois de todos.
**`wg.Go(f)` é exatamente esse padrão**, um `Add(1)` antes de iniciar `f` e um `Done` depois que ela
retorna, e não deixa espaço para nenhum dos dois erros abaixo.

## O `Add` uma linha atrasado

A variação tentadora move o `Add` para dentro da goroutine, ao lado do `Done`, onde parece mais
arrumado. Salvo como `late.go`:

```go
// Command late calls Add inside the goroutine, which is one line too late.
package main

import (
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

func main() {
	var finished atomic.Int64
	var wg sync.WaitGroup
	for range 5 {
		go func() {
			wg.Add(1)
			defer wg.Done()
			time.Sleep(10 * time.Millisecond)
			finished.Add(1)
		}()
	}
	wg.Wait()
	fmt.Println("finished when Wait returned:", finished.Load())
}
```

```
ana@vm:~/waitonce$ go run late.go
finished when Wait returned: 0
ana@vm:~/waitonce$ go vet late.go
late.go:16:10: WaitGroup.Add called from inside new goroutine
```

**Cinco goroutines iniciadas, e o `Wait` retornou antes de qualquer uma terminar.** O `main` chegou
ao `Wait` com o contador ainda em zero, porque nenhuma goroutine tinha sido escalonada para rodar o
seu `Add`. Um contador em zero significa nada a esperar, então o `Wait` retornou na hora. A regra é
que **o `Add` tem de acontecer antes do `go`**, na goroutine que vai chamar o `Wait`. O `go vet`
conhece essa regra, como mostra o segundo comando, e o `wg.Go` a torna impossível de quebrar.

## Um contador abaixo de zero

O erro oposto, um `Done` a mais que os `Add`, não tem nada de silencioso. Salvo como `negative.go`:

```go
// Command negative calls Done once more than it called Add.
package main

import "sync"

func main() {
	var wg sync.WaitGroup
	wg.Add(1)
	wg.Done()
	wg.Done()
}
```

```
ana@vm:~/waitonce$ go run negative.go
panic: sync: negative WaitGroup counter

goroutine 1 [running]:
sync.(*WaitGroup).Add(0xc25eaf9e000, 0xffffffffffffffff)
	/usr/local/go/src/sync/waitgroup.go:118 +0x23a
sync.(*WaitGroup).Done(...)
	/usr/local/go/src/sync/waitgroup.go:156
main.main()
	/home/ana/waitonce/negative.go:10 +0x58
exit status 2
```

O contador teria ido a menos um, e o `WaitGroup` entra em pânico em vez de permitir. Em código real a
causa é um `Done` num caminho que também retorna cedo por outro `defer`, ou uma goroutine iniciada
duas vezes para um único `Add`. E como um mutex, um `WaitGroup` não pode ser copiado depois do
primeiro uso: uma função que recebe um usa `*sync.WaitGroup`, ou o `Done` diminui o contador de uma
cópia e o `Wait` original espera para sempre.
