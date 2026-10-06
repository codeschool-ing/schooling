---
title: Toda variável começa em zero
version: 1
---

Quem já viu C espera que uma variável que ninguém atribuiu guarde o que estava antes naquela
memória, e quem já viu JavaScript espera `undefined`. Go não tem nenhum dos dois. **Toda variável
recebe o valor zero do seu tipo no momento em que é declarada.** Não existe em Go variável não
inicializada, nem valor que signifique "ainda não definido", a menos que você projete um.

O valor zero depende só do tipo. Este programa declara uma variável de cada tipo que você vai
encontrar neste curso e imprime o tipo e o valor de cada uma, sem atribuir nada:

```go
// Command zero prints the zero value of one variable of each kind.
package main

import "fmt"

type point struct {
	X, Y  int
	Label string
}

func show(v any) {
	fmt.Printf("%-16T %#v\n", v, v)
}

func main() {
	var i int
	var f float64
	var ok bool
	var s string
	var p *int
	var sl []int
	var m map[string]int
	var fn func()
	var err error
	var arr [3]int
	var pt point

	show(i)
	show(f)
	show(ok)
	show(s)
	show(p)
	show(sl)
	show(m)
	show(fn)
	show(err)
	show(arr)
	show(pt)
	show(point{X: 2})

	fmt.Println(len(sl), len(m), m["missing"], sl == nil)
}
```

`show` recebe um valor de qualquer tipo (`any` é o assunto da lição 28) e o imprime com dois verbos
do `fmt`: `%T` é o tipo do valor e `%#v` é o valor escrito do jeito que o código-fonte Go o
escreveria, e é por isso que a string sai como `""` e não como nada.

```
ana@vm:~/zero$ go run .
int              0
float64          0
bool             false
string           ""
*int             (*int)(nil)
[]int            []int(nil)
map[string]int   map[string]int(nil)
func()           (func())(nil)
<nil>            <nil>
[3]int           [3]int{0, 0, 0}
main.point       main.point{X:0, Y:0, Label:""}
main.point       main.point{X:2, Y:0, Label:""}
0 0 0 true
```

Leia em três grupos.

**Números são `0`, booleanos são `false` e strings são `""`.** O `float64` aparece como `0` e não
`0.0` porque é assim que o `%#v` escreve um float sem nada depois da vírgula; o valor é o mesmo.

**Ponteiros, slices, maps, funções e interfaces são `nil`.** `nil` não é um valor único
compartilhado por todos eles. É o valor zero de cada um desses tipos separadamente, e por isso o
`%#v` o escreve com o tipo junto: `[]int(nil)` e `map[string]int(nil)` são coisas diferentes. A
linha do `error` é a estranha, com `<nil>` nas duas colunas: uma interface que não guarda nada não
tem tipo para informar. As lições 28 e 32 voltam a isso, porque uma interface que guarda um
ponteiro nil não é esta interface vazia e não é igual a `nil`.

**Um array ou uma struct é zero até o fim.** Cada elemento do array é um zero de `int`, e cada
campo da struct é o zero do seu próprio tipo. Um literal de struct que nomeia só alguns campos,
como `point{X: 2}`, deixa os outros em zero, e por isso você vai ver código Go que preenche só os
campos que importam.

A última linha mostra que `nil` é um valor que dá para usar. O tamanho de um slice nil é 0, o de
um map nil é 0, e ler uma chave de um map nil devolve o valor zero do map, aqui `0`. Escrever num
map nil é a única dessas operações que falha, com um panic, e a lição 14 mostra isso.

## Um valor zero pronto para usar

Como toda variável começa em zero, quem escreve um tipo Go decide o que o zero significa, e os
bons tipos fazem ele significar "vazio e pronto". Dois tipos da biblioteca padrão que você vai usar
muito não precisam de preparo nenhum:

```go
package main

import (
	"bytes"
	"fmt"
	"strings"
)

func main() {
	var sb strings.Builder
	sb.WriteString("built ")
	sb.WriteString("from nothing")
	fmt.Println(sb.String(), sb.Len())

	var buf bytes.Buffer
	buf.WriteString("no constructor needed")
	fmt.Println(buf.String())
}
```

```
ana@vm:~/zero-useful$ go run .
built from nothing 18
no constructor needed
ana@vm:~/zero-useful$ go doc strings.Builder | head -8
package strings // import "strings"

type Builder struct {
	// Has unexported fields.
}
    A Builder is used to efficiently build a string using Builder.Write methods.
    It minimizes memory copying. The zero value is ready to use. Do not copy a
    non-zero Builder.
```

**"The zero value is ready to use" é uma frase que a biblioteca padrão escreve de propósito**, e o
`go doc` é onde você a encontra. O `bytes.Buffer` diz o mesmo, e o `sync.Mutex` também, a trava do
curso `go-concurrency`, cujo valor zero é um mutex destravado. O map é o contraexemplo do programa
lá de cima: o valor zero dele pode ser lido e não escrito, então um map que você pretende preencher
é criado antes com `make`, e a lição 14 trata disso.

O hábito que vale levar daqui é uma pergunta para fazer a todo tipo que você escrever: se alguém
declarar um com `var` e nunca atribuir nada, ele ainda funciona? Quando a resposta é sim, o seu
tipo não precisa de construtor, e um campo que você esqueceu de preencher não faz mal nenhum.
