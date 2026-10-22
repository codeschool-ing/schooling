---
title: A corrida que só um teste encontra
version: 1
---

As corridas até aqui estavam em programas que rodam as próprias goroutines. **A maioria das
corridas não é assim. Elas moram num tipo que é seguro quando uma goroutine o usa e errado quando
duas usam**, e o programa que faria duas o usarem ao mesmo tempo é um servidor que ainda não existe.
Nada no próprio pacote roda de forma concorrente, então rodá-lo com `-race` não encontra nada. Um
teste tem de fazer as goroutines se encontrarem, e `go test -race` tem de observar.

A lição 25 começa o pacote `testing` de verdade. Esta seção só precisa de três fatos dele: um teste
é uma função chamada `TestAlgumaCoisa` num arquivo terminado em `_test.go`, ele relata uma falha
com `t.Errorf` ou `t.Fatalf`, e `go test` roda toda função assim de um pacote.

## Um cache que vai bem sozinho

O pacote guarda as respostas de uma consulta lenta, para que cada chave seja consultada uma vez.
Ele mora no diretório `cache` dentro de `~/races`, salvo como `cache/cache.go`:

```go
// Package cache remembers the answers of a slow lookup.
package cache

// Cache asks lookup once per key and remembers the answer.
type Cache struct {
	lookup func(string) string
	seen   map[string]string
}

// New returns an empty Cache in front of lookup.
func New(lookup func(string) string) *Cache {
	return &Cache{lookup: lookup, seen: map[string]string{}}
}

// Get returns the answer for key, asking lookup only the first time.
func (c *Cache) Get(key string) string {
	if v, ok := c.seen[key]; ok {
		return v
	}
	v := c.lookup(key)
	c.seen[key] = v
	return v
}
```

Dois testes ao lado dele. O primeiro confere a promessa do comentário, uma consulta por chave. O
segundo é o assunto desta seção: ele chama `Get` de seis goroutines ao mesmo tempo, com algumas
chaves repetidas, que é o que faria um servidor atendendo seis requisições. Salvo como
`cache/cache_test.go`:

```go
package cache

import (
	"strings"
	"sync"
	"testing"
)

func TestGet(t *testing.T) {
	calls := 0
	c := New(func(k string) string { calls++; return strings.ToUpper(k) })
	for range 3 {
		if got := c.Get("go"); got != "GO" {
			t.Fatalf("Get(%q) = %q, want %q", "go", got, "GO")
		}
	}
	if calls != 1 {
		t.Errorf("lookup ran %d times, want 1", calls)
	}
}

func TestGetFromManyGoroutines(t *testing.T) {
	c := New(strings.ToUpper)
	var wg sync.WaitGroup
	for _, k := range []string{"a", "b", "a", "c", "b", "a"} {
		wg.Go(func() {
			if got := c.Get(k); got != strings.ToUpper(k) {
				t.Errorf("Get(%q) = %q", k, got)
			}
		})
	}
	wg.Wait()
}
```

## Verde, e errado

```
ana@vm:~/races$ go test ./cache
ok  	example.com/races/cache	0.002s
ana@vm:~/races$ go test -count=5 ./cache
ok  	example.com/races/cache	0.002s
```

**Seis execuções que passam, e o tipo está quebrado.** Toda resposta que os testes conferiram
estava certa, porque uma resposta errada nunca foi o risco: o risco eram duas goroutines escrevendo
no map no mesmo instante, o que uma conferência das respostas não enxerga. `-count=5` rodou os
testes cinco vezes seguidas, e pedir de novo não ajudou, porque o que decide o resultado é o tempo,
e o tempo foi gentil todas as vezes.

Com o detector, os mesmos testes falham:

```
ana@vm:~/races$ go test -race ./cache > race.log 2>&1; echo $?
1
ana@vm:~/races$ head -17 race.log
==================
WARNING: DATA RACE
Read at 0x00c0001166c0 by goroutine 11:
  runtime.mapaccess2_faststr()
      /usr/local/go/src/internal/runtime/maps/runtime_faststr.go:120 +0x0
  example.com/races/cache.(*Cache).Get()
      /home/ana/races/cache/cache.go:17 +0x64
  example.com/races/cache.TestGetFromManyGoroutines.func1()
      /home/ana/races/cache/cache_test.go:27 +0x5e

Previous write at 0x00c0001166c0 by goroutine 13:
  runtime.mapassign_faststr()
      /usr/local/go/src/internal/runtime/maps/runtime_faststr.go:261 +0x0
  example.com/races/cache.(*Cache).Get()
      /home/ana/races/cache/cache.go:21 +0xdb
  example.com/races/cache.TestGetFromManyGoroutines.func1()
      /home/ana/races/cache/cache_test.go:27 +0x5e
```

`head -17` guardou os dois acessos do primeiro relatório, e eles se leem como a seção 03 ensinou. A
linha 21 do `cache.go` é `c.seen[key] = v`, a escrita; a linha 17 é `if v, ok := c.seen[key]; ok`,
a leitura. As duas pilhas sobem por `TestGetFromManyGoroutines.func1()` na linha 27 do teste, o
`c.Get(k)` dentro da goroutine. O fim da saída é o veredito do teste:

```
ana@vm:~/races$ tail -5 race.log
--- FAIL: TestGetFromManyGoroutines (0.00s)
    testing.go:1865: race detected during execution of test
FAIL
FAIL	example.com/races/cache	0.032s
FAIL
```

**`race detected during execution of test` transforma um relatório num teste que falha.** É isso
que torna o detector utilizável na CI: ninguém precisa ler a saída para a execução ficar vermelha.

## O conserto, e a execução que o prova

Todo acesso a `seen` acontece dentro de `Get`, então um mutex segurado durante o `Get` inteiro cobre
todos. Editado, salvo de novo como `cache/cache.go`:

```go
// Package cache remembers the answers of a slow lookup.
package cache

import "sync"

// Cache asks lookup once per key and remembers the answer.
// It is safe for use by several goroutines at once.
type Cache struct {
	lookup func(string) string
	mu     sync.Mutex
	seen   map[string]string
}

// New returns an empty Cache in front of lookup.
func New(lookup func(string) string) *Cache {
	return &Cache{lookup: lookup, seen: map[string]string{}}
}

// Get returns the answer for key, asking lookup only the first time.
func (c *Cache) Get(key string) string {
	c.mu.Lock()
	defer c.mu.Unlock()
	if v, ok := c.seen[key]; ok {
		return v
	}
	v := c.lookup(key)
	c.seen[key] = v
	return v
}
```

```
ana@vm:~/races$ go test -race -count=20 ./cache
ok  	example.com/races/cache	1.018s
```

Limpo, vinte vezes seguidas com o detector observando. O comentário de documentação agora diz o
que o tipo promete, e isso faz parte do conserto: quem usar `Cache` em seguida lê que ele é seguro
para várias goroutines sem abrir o arquivo.

Segurar a trava durante o `lookup` tem um preço. Duas goroutines pedindo duas chaves diferentes
esperam a consulta lenta uma da outra, e a lição 8 mostra como segurar uma trava por menos tempo, e
a lição 9 como `sync.Map` e `sync.OnceValue` mudam essa troca. **Correto primeiro, depois rápido**,
e o detector rodado de novo depois de toda mudança desse tipo.

## O hábito, e o fim da primeira metade

Três hábitos saem desta lição. Rode `go test -race ./...` a cada mudança, na CI e na sua máquina.
Escreva um teste que chama um tipo de várias goroutines sempre que o tipo disser que é seguro para
isso. E quando um relatório aparecer, leia os dois acessos dele antes de mexer no código.

**Esta lição fecha a metade de concorrência do curso**: goroutines, canais, `select`, o pacote
`sync`, `context`, os padrões e agora a ferramenta que confere todos eles. A lição 17 abre a
segunda metade, a biblioteca padrão de que um programa Go é feito, começando pelas duas interfaces
pelas quais quase toda ela lê e escreve.
