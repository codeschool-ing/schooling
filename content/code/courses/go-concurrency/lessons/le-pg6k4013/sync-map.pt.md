---
title: Um map feito para uso concorrente
version: 1
---

Um map comum de Go não é seguro para uso concorrente, e ao contrário da maioria das corridas esta não
fica quieta. **O runtime verifica escritas simultâneas num map e para o programa com um erro fatal**,
que nenhum `recover` consegue pegar. Salvo como `crash.go`:

```go
// Command crash writes to an ordinary map from four goroutines with no lock.
package main

import (
	"fmt"
	"sync"
)

func main() {
	seen := map[int]bool{}
	var wg sync.WaitGroup
	for g := range 4 {
		wg.Go(func() {
			for i := range 100_000 {
				seen[g*100_000+i] = true
			}
		})
	}
	wg.Wait()
	fmt.Println("entries:", len(seen))
}
```

```
ana@vm:~/waitonce$ go run crash.go
fatal error: concurrent map writes

goroutine 19 [running]:
internal/runtime/maps.fatal({0x49dfd5?, 0x0?})
	/usr/local/go/src/runtime/panic.go:1195 +0x18
main.main.func1()
	/home/ana/waitonce/crash.go:15 +0x45
sync.(*WaitGroup).Go.func1()
	/usr/local/go/src/sync/waitgroup.go:258 +0x4a
created by sync.(*WaitGroup).Go in goroutine 1
	/usr/local/go/src/sync/waitgroup.go:238 +0x7d
exit status 2
```

`fatal error: concurrent map writes`, na linha 15, que é a atribuição. A verificação é barata e não
pega todo caso: duas escritas que nunca se sobrepõem no tempo passam por ela, e uma leitura durante
uma escrita pode produzir `concurrent map read and map write`. O detector de corridas, o assunto da
lição 16, relata todas elas. O conserto de costume é o que a lição 8 ensinou, um `sync.Mutex` ao lado
do map.

## `sync.Map`

A biblioteca padrão também tem um tipo de map com a trava dentro. Os métodos dele recebem e devolvem
`any`: `Store`, `Load`, `LoadOrStore`, `LoadAndDelete`, `Delete`, `Swap`, `CompareAndSwap`, `Range`
e `Clear`. O programa abaixo registra o primeiro visitante de cada página a partir de seis goroutines,
com `LoadOrStore`, que guarda um valor só se a chave estiver ausente e informa qual valor está lá.
Salvo como `syncmap.go`:

```go
// Command syncmap counts the first visitor of each page with a sync.Map.
package main

import (
	"fmt"
	"sync"
)

func main() {
	var first sync.Map // page -> name of the first visitor
	visits := []struct{ page, who string }{
		{"/home", "ana"}, {"/home", "bia"}, {"/docs", "caio"},
		{"/docs", "ana"}, {"/home", "caio"}, {"/blog", "bia"},
	}
	var wg sync.WaitGroup
	for _, v := range visits {
		wg.Go(func() {
			first.LoadOrStore(v.page, v.who)
		})
	}
	wg.Wait()

	who, ok := first.Load("/blog")
	fmt.Println("/blog:", who, ok)
	_, ok = first.Load("/about")
	fmt.Println("/about:", ok)
	n := 0
	first.Range(func(key, value any) bool {
		n++
		return true
	})
	fmt.Println("pages:", n)
}
```

```
ana@vm:~/waitonce$ go run syncmap.go
/blog: bia true
/about: false
pages: 3
```

Três páginas, seis visitas, e `/blog` teve um visitante, `bia`. Quem foi o primeiro em `/home` e
`/docs` dependeu de qual goroutine chegou primeiro ao `LoadOrStore`, então o programa não imprime
isso. Uma chave ausente é informada pelo segundo resultado, `false`, como no comma-ok de um map comum.

## Quando usar, e quando não

A documentação de `sync.Map` é invulgarmente direta sobre isso: **a maior parte do código deve usar
um map comum com a sua própria trava**, pela segurança de tipos e porque fica mais fácil manter outro
estado coerente com ele. O `sync.Map` é otimizado para dois casos:

1. uma chave é escrita uma vez e lida muitas, como num cache que só cresce;
2. várias goroutines leem, escrevem e sobrescrevem conjuntos **disjuntos** de chaves.

Nesses dois, ele pode significar muito menos espera que um map atrás de um único `Mutex` ou
`RWMutex`. Fora deles, ele perde os tipos do map, todo `Load` precisa de uma asserção de tipo, e o
`Range` não é um retrato de um único momento. Então a ordem de preferência é um map com um `Mutex`,
depois um `RWMutex` se a medição disser que leitores esperam, e o `sync.Map` quando o padrão de acesso
for um dos dois acima.
