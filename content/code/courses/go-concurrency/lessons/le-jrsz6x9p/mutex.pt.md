---
title: O mutex, e a cópia que o quebra
version: 1
---

A lição 1 terminou com o `count.go`: quatro goroutines somando num mesmo número, e cinco totais
errados diferentes. As lições 3 a 7 evitaram esse problema passando valores por canais, para que só
uma goroutine segurasse cada um. Às vezes o desenho mais simples é mesmo uma variável que várias
goroutines alteram. **Um mutex torna isso seguro deixando uma goroutine de cada vez entrar no
código entre `Lock` e `Unlock`**, a seção crítica, e fazendo toda outra goroutine esperar no `Lock`
até ele ficar livre.

## O `count.go`, consertado

O mesmo programa, com um `sync.Mutex` em volta do incremento, salvo como `count.go`:

```go
// Command count is lesson 1's count.go with a mutex around the shared number.
package main

import (
	"fmt"
	"sync"
)

func main() {
	total := 0
	var mu sync.Mutex
	var wg sync.WaitGroup
	for range 4 {
		wg.Go(func() {
			for range 100_000 {
				mu.Lock()
				total++
				mu.Unlock()
			}
		})
	}
	wg.Wait()
	fmt.Println("total:", total)
}
```

```
ana@vm:~/locks$ for i in 1 2 3; do go run count.go; done
total: 400000
total: 400000
total: 400000
ana@vm:~/locks$ go run -race count.go
total: 400000
```

Três execuções, três respostas certas, e o detector de corridas da lição 1 não tem nada a relatar:
o programa imprimiu o total e nenhum aviso. `mu.Lock()` e `mu.Unlock()` em volta de `total++`
transformam a leitura, a soma e a escrita num passo só, até onde as outras goroutines conseguem
ver. Destravar também publica a mudança: o que uma goroutine escreveu antes do `Unlock` fica visível
para a próxima depois do seu `Lock`, que é a promessa que a lição 1 listou.

Três hábitos vêm junto:

- **O valor zero é um mutex destravado.** `var mu sync.Mutex` está pronto para uso, sem construtor,
  e o mesmo vale para uma struct que contém um.
- **`defer mu.Unlock()` logo depois do `Lock`** em qualquer função com mais de uma linha. Um `return`
  antecipado ou um pânico entre os dois deixaria o mutex travado, e toda goroutine que viesse depois
  esperaria para sempre, a mesma forma do `close` pulado da lição 6.
- **Mantenha a seção crítica curta.** Tudo o que está dentro dela roda uma goroutine de cada vez.
  Trabalho que não toca os dados compartilhados, uma conta, uma linha de log, uma chamada de rede,
  fica do lado de fora.

## Um mutex não pode ser copiado

A maior parte do código põe o mutex ao lado dos dados que ele protege, numa struct, com métodos que
o travam. Esta versão comete um erro, salvo como `copied.go`:

```go
// Command copied keeps its counter and its mutex in a struct, and makes one mistake.
package main

import (
	"fmt"
	"sync"
)

// Counter is safe for use by several goroutines, if its methods are written right.
type Counter struct {
	mu sync.Mutex
	n  int
}

// Inc has a value receiver, so it works on a copy of the Counter.
func (c Counter) Inc() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.n++
}

func main() {
	var c Counter
	var wg sync.WaitGroup
	for range 4 {
		wg.Go(func() {
			for range 100_000 {
				c.Inc()
			}
		})
	}
	wg.Wait()
	fmt.Println("total:", c.n)
}
```

```
ana@vm:~/locks$ go run copied.go
total: 0
ana@vm:~/locks$ go vet copied.go
copied.go:16:9: Inc passes lock by value: command-line-arguments.Counter contains sync.Mutex
```

**Quatrocentas mil chamadas e um total de zero.** `Inc` tem um receptor por valor, `(c Counter)`,
então cada chamada trabalha numa cópia nova da struct inteira, mutex incluído. Ela trava o mutex da
cópia, incrementa o `n` da cópia e joga a cópia fora. O original nunca muda. Nada quebra e o
detector de corridas fica quieto, porque cada cópia é tocada por uma goroutine só.

O `go vet`, o verificador que a lição 4 de `go` apresentou, conhece esse erro pelo nome. Ele aponta o
receptor e diz por quê. O conserto é um receptor ponteiro, `func (c *Counter) Inc()`, e a regra por
trás dele vale para mais do que métodos: **depois que um mutex foi usado, o valor que o contém não
pode ser copiado**, seja por um receptor por valor, por uma atribuição ou passando a struct por
valor a uma função.
