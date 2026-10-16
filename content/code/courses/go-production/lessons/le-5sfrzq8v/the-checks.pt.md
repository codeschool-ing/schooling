---
title: Bugs que compilam e rodam
version: 1
---

Cada programa desta seção **compila, roda e imprime algo com cara de resposta**. É isso que faz deles
um caso para ferramenta: um programa que quebra na primeira execução é corrigido antes de alguém fazer
commit, e estes não quebram. Cada um é salvo em `~/vetted` ao lado do `report`, executado uma vez para
você ver o que o bug faz, e depois mostrado ao vet.

## `printf`, de novo: um erro embrulhado que não se acha

O analisador `printf` da seção 02 também conhece o `%w`, o verbo que o `fmt.Errorf` usa para embrulhar
um erro dentro de outro. Salve `notfound/main.go`:

```go
// Command notfound wraps an error and then asks what it was.
package main

import (
	"errors"
	"fmt"
)

// NotFound says which path had nothing behind it.
type NotFound struct{ Path string }

func (e NotFound) Error() string { return e.Path + ": not found" }

func open(path string) error {
	return fmt.Errorf("open: %w", &NotFound{path})
}

func main() {
	err := open("/api/orders/43")
	var nf NotFound
	fmt.Println(err)
	fmt.Println("is NotFound:", errors.As(err, &nf))
}
```

```
ana@vm:~/vetted$ go run ./notfound
open: /api/orders/43: not found
is NotFound: false
ana@vm:~/vetted$ go vet ./notfound
notfound/main.go:15:27: %w wants operand of error type NotFound, not pointer type *NotFound (defeats errors.Is)
```

A mensagem sai bonita e a pergunta recebe a resposta errada. **`Error` tem receptor por valor, então o
tipo de erro é `NotFound`, e o `open` embrulhou um `*NotFound`**, outro tipo, que o `errors.As` não
casa com um alvo `NotFound`. Quem transforma um `NotFound` num 404 transformaria este num 500. Essa
checagem é nova no Go 1.27 e, como a seção 02 disse, só vale para arquivos cujo módulo declara pelo
menos essa versão. A correção é `fmt.Errorf("open: %w", NotFound{path})`.

## `copylocks`: um mutex que não trava nada

Um tipo que carrega um `sync.Mutex` só é seguro enquanto todo mundo usa o mesmo mutex.
`counter/main.go`:

```schooling-example
{
  "language": "go",
  "file": "counter/main.go",
  "parts": [
    {
      "code": "// Command counter counts requests per path from several goroutines.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"sync\"\n)\n\n// Counter is safe for concurrent use. Or so its author thought.\ntype Counter struct {\n\tmu sync.Mutex\n\tn  map[string]int\n}\n",
      "note": "Um mutex ao lado do mapa que ele protege: o formato de sempre, e correto desde que todo chamador trave o mesmo mutex."
    },
    {
      "code": "func (c Counter) Add(path string) {\n\tc.mu.Lock()\n\tdefer c.mu.Unlock()\n\tc.n[path]++\n}\n",
      "note": "**O receptor é um valor, então cada chamada trabalha numa cópia do `Counter`, mutex incluído.** Cada goroutine trava um mutex que mais ninguém segura. O mapa também é copiado, mas um valor de mapa é uma referência a uma tabela só, então as oito escrevem na mesma."
    },
    {
      "code": "func main() {\n\tc := Counter{n: map[string]int{}}\n\tvar wg sync.WaitGroup\n\tfor range 8 {\n\t\twg.Go(func() {\n\t\t\tfor range 10000 {\n\t\t\t\tc.Add(\"/login\")\n\t\t\t}\n\t\t})\n\t}\n\twg.Wait()\n\tfmt.Println(c.n[\"/login\"])\n}",
      "note": "Oito goroutines somando dez mil vezes cada. O `wg.Go`, do Go 1.25, faz o `Add`, o `go` e o `Done` numa chamada só. Um contador correto imprime 80000."
    }
  ]
}
```

```
ana@vm:~/vetted$ go run ./counter 2>&1 | head -1
fatal error: concurrent map writes
ana@vm:~/vetted$ go vet ./counter
counter/main.go:15:9: Add passes lock by value: example.com/vetted/counter.Counter contains sync.Mutex
```

`fatal error` é a checagem do próprio runtime pegando duas goroutines escrevendo num mapa ao mesmo
tempo, e ela encerrou o processo em todas as execuções aqui, com um dump de goroutines abaixo da linha
que o `head` guardou. **Um teste que chamasse `Add` de uma goroutine só passaria**, e é exatamente esse
o teste que a seção 04 escreve. O vet não precisa rodar nada: ele vê um método cujo receptor é um valor
de um tipo que contém um lock, e isso basta. A correção é um receptor ponteiro, `func (c *Counter) Add`.
O detector de corrida da lição 16 de `go-concurrency` acha o mesmo bug, mas só quando um teste por
acaso faz duas goroutines passarem por ele.

## `lostcancel`: um contexto que vive mais que a chamada

O `context.WithTimeout` devolve uma função que libera o timer do contexto, e ela precisa ser chamada
em todos os caminhos. `fetch/main.go`:

```go
// Command fetch waits for a slow answer, but not forever.
package main

import (
	"context"
	"errors"
	"fmt"
	"time"
)

func slow(ctx context.Context) error {
	select {
	case <-time.After(50 * time.Millisecond):
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}

func fetch(parent context.Context, path string) error {
	ctx, cancel := context.WithTimeout(parent, 2*time.Second)
	if path == "" {
		return errors.New("no path to fetch")
	}
	defer cancel()
	return slow(ctx)
}

func main() {
	fmt.Println(fetch(context.Background(), "/api/orders"))
	fmt.Println(fetch(context.Background(), ""))
}
```

```
ana@vm:~/vetted$ go run ./fetch
<nil>
no path to fetch
ana@vm:~/vetted$ go vet ./fetch
fetch/main.go:21:2: the cancel function is not used on all paths (possible context leak)
fetch/main.go:23:3: this return statement may be reached without using the cancel var defined on line 21
```

**As duas respostas estão certas, e esse é o problema**: o bug não tem saída. Cada chamada que pega o
retorno antecipado deixa um contexto e seu timer vivos por dois segundos, até o timeout disparar. Num
servidor que faz isso milhares de vezes por segundo, o vazamento é memória que cresce com o tráfego. O
vet lê o fluxo de controle, acha o caminho do `WithTimeout` até um `return` que nunca encontra o
`cancel` e aponta as duas linhas. Subir o `defer cancel()` para a linha logo depois do `WithTimeout`
resolve.

## `structtag`: um campo JSON com o nome errado

Uma tag de struct é uma string que o compilador não lê, e o `encoding/json` a lê em tempo de execução
com `reflect.StructTag.Get`, que desiste de uma tag que não consegue interpretar. `rows/main.go`:

```go
// Command rows prints the busiest paths as JSON.
package main

import (
	"encoding/json"
	"os"
)

type PathCount struct {
	Path string `json:"path"`
	Hits int    `json: "hits"`
}

func main() {
	rows := []PathCount{{"/login", 2576}, {"/health", 2541}}
	json.NewEncoder(os.Stdout).Encode(rows)
}
```

```
ana@vm:~/vetted$ go run ./rows
[{"path":"/login","Hits":2576},{"path":"/health","Hits":2541}]
ana@vm:~/vetted$ go vet ./rows
rows/main.go:11:2: struct field tag `json: "hits"` not compatible with reflect.StructTag.Get: bad syntax for struct tag value
```

Um espaço depois dos dois-pontos, e `Hits` saiu com o nome Go. **Nada falhou, porque uma tag malformada
conta como tag nenhuma**, e um cliente que lê `hits` agora não lê nada, ou lê zero. O vet interpreta
cada tag do jeito que o `reflect` interpretaria e diz onde ela deixou de fazer sentido.

## Quatro menores

`dedup/main.go` guarda uma cópia de cada caminho de uma lista ordenada:

```go
// Command dedup prints each path once, from a sorted list.
package main

import (
	"fmt"
	"slices"
)

func main() {
	paths := []string{"/", "/health", "/health", "/login", "/login", "/login"}
	slices.Compact(paths)
	fmt.Printf("%d paths: %q\n", len(paths), paths)
}
```

```
ana@vm:~/vetted$ go run ./dedup
6 paths: ["/" "/health" "/login" "" "" ""]
ana@vm:~/vetted$ go vet ./dedup
dedup/main.go:11:2: result of slices.Compact call not used
```

**`slices.Compact` devolve a fatia mais curta e não mexe no cabeçalho da fatia de quem chamou**, com a
parte final que deixou de usar zerada, então o programa imprimiu seis caminhos, três deles vazios. O
`unusedresult` mantém uma lista de funções da biblioteca padrão cujo resultado é o motivo de chamá-las,
entre elas `slices.Compact`, `fmt.Sprintf` e `errors.New`, e relata uma chamada que o joga fora. A
correção é `paths = slices.Compact(paths)`.

`header/main.go` lê um comprimento de 16 bits a partir de dois bytes:

```go
// Command header reads a 16-bit length from the first two bytes of a record.
package main

import "fmt"

func length(b []byte) uint16 {
	hi, lo := b[0], b[1]
	return uint16(hi<<8 | lo)
}

func main() {
	fmt.Println(length([]byte{0x01, 0x2c}))
}
```

```
ana@vm:~/vetted$ go run ./header
44
ana@vm:~/vetted$ go vet ./header
header/main.go:8:16: hi (8 bits) too small for shift of 8
```

`0x012c` é 300. **O deslocamento aconteceu em `hi`, um `byte`, antes da conversão**, então o byte alto
foi empurrado inteiro para fora dos seus oito bits e só o `lo`, 44, sobrou. O `shift` relata um
deslocamento do tamanho do tipo, ou maior. A correção é `uint16(hi)<<8 | uint16(lo)`.

`limit/main.go` deixa passar as primeiras `n` requisições, e traz dois erros:

```go
// Command limit lets the first n requests through and refuses the rest.
package main

import "fmt"

type Limiter struct {
	limit int
	seen  int
}

func NewLimiter(limit int) *Limiter {
	l := &Limiter{}
	l.limit = l.limit
	return l
}

func (l *Limiter) Allow() bool {
	l.seen++
	return l.seen <= l.limit
	fmt.Println("over the limit")
	return false
}

func main() {
	l := NewLimiter(3)
	fmt.Println(l.Allow(), l.Allow(), l.Allow())
}
```

```
ana@vm:~/vetted$ go run ./limit
false false false
ana@vm:~/vetted$ go vet ./limit
limit/main.go:13:2: self-assignment of l.limit
limit/main.go:20:2: unreachable code
```

Um limite de três recusou as três requisições. **`l.limit = l.limit` atribui o zero a ele mesmo**, onde
se queria `l.limit = limit`, e o `assign` relata qualquer `x = x`. O `return` acima do `Println` mata as
duas últimas linhas, o que o `unreachable` relata: aqui o código morto é uma linha de log que alguém
esperava ver, e a ausência dela teria sido a única pista. Nenhum dos dois é erro de compilação, porque o
Go rejeita uma variável não usada e não rejeita uma instrução não usada.
