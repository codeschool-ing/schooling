---
title: Um tipo ao qual todo valor pertence
version: 1
---

Para quem vem de Python ou JavaScript, `any` parece o lugar onde Go para de conferir tipos: uma
variável que aceita o que você puser nela. Ela aceita mesmo o que você puser nela. **Mas `any` é um
tipo, como `int` é um tipo, e o compilador confere cada uso dele.** O incomum é o pouco que ele
deixa você fazer, e a seção 03 trata disso.

A lição 27 deu a regra das interfaces: um tipo satisfaz uma interface quando tem todos os métodos
que ela lista, e nada precisa ser declarado. `any` é a interface que não lista método nenhum. Todo
tipo tem todos os zero métodos, então todo valor em Go a satisfaz, de um `int` a uma struct sua:

```go
package main

import "fmt"

type Player struct {
	Name  string
	Score int
}

func main() {
	var v any
	fmt.Printf("%-12T %v\n", v, v)

	v = 42
	fmt.Printf("%-12T %v\n", v, v)

	v = "Ana"
	fmt.Printf("%-12T %v\n", v, v)

	v = []int{1, 2, 3}
	fmt.Printf("%-12T %v\n", v, v)

	v = Player{Name: "Ana", Score: 10}
	fmt.Printf("%-12T %v\n", v, v)

	things := []any{42, "Ana", 2.5, true, nil}
	fmt.Println(len(things), things)
}
```

```
ana@vm:~/any$ go run .
<nil>        <nil>
int          42
string       Ana
[]int        [1 2 3]
main.Player  {Ana 10}
5 [42 Ana 2.5 true <nil>]
```

Leia a coluna da esquerda. `v` foi declarada uma vez, como `any`, e o tipo dela nunca mudou. O que
mudou foi o tipo do valor guardado nela, que Go chama de **tipo dinâmico**, e é esse que o `%T`
imprime. A lição 22 mediu um `any` em 16 bytes: uma palavra diz que tipo está guardado e a outra
guarda o valor. A primeira linha é uma variável do tipo `any` antes de qualquer coisa ser posta
nela, sem tipo e sem valor, impressa `<nil>` duas vezes. A seção 04 volta a essa linha, porque uma
interface sem tipo dentro não é a mesma coisa que uma interface guardando um nil.

A última linha é um slice de `any`. Cada um dos seus cinco elementos é um valor de interface
próprio, e cada um carrega o seu tipo dinâmico, então um só slice guarda um número, uma string, um
float, um booleano e nada.

## `any` e `interface{}` são um tipo só

Código mais antigo, e boa parte da biblioteca padrão, escreve `interface{}`: o tipo interface com
nada entre as chaves. `any` é um segundo nome para ele:

```go
package main

import "fmt"

func main() {
	var v any = 1
	var w interface{} = "one"
	v = w
	fmt.Printf("%T %T %v\n", &v, &w, v)
}
```

```
ana@vm:~/any-alias$ go doc builtin.any
package builtin // import "builtin"

type any = interface{}
    any is an alias for interface{} and is equivalent to interface{} in all
    ways.

func recover() any
ana@vm:~/any-alias$ go run .
*interface {} *interface {} one
ana@vm:~/any-alias$ go mod edit -go=1.17 && go build
# example.com/alias
./main.go:6:8: predeclared any requires go1.18 or later (-lang was set to go1.17; check go.mod)
```

O `=` em `type any = interface{}` faz dele um alias, o tipo de declaração que a lição 10 separou de
um tipo novo. Por isso `v = w` atribui uma à outra sem conversão, e o `%T` imprime o mesmo tipo
para um ponteiro de cada, pelo nome longo, `*interface {}`. O nome é mais novo que o tipo: com a
linha `go` do `go.mod` recuada para 1.17, o compilador recusa o programa que tinha acabado de
rodar, porque `any` chegou no Go 1.18. A lição 2 mostrou essa linha escolhendo em que versão da
linguagem um módulo é escrito. Em qualquer coisa mais nova, escreve-se `any`; quando você ler
`interface{}` em código antigo, leia como a mesma palavra.

## Onde você já o encontrou

A lição 4 leu no `go doc` a assinatura de `fmt.Println`,
`func Println(a ...any) (n int, err error)`: qualquer quantidade de argumentos, cada um de qualquer
tipo. A lição 15 chamou `json.Unmarshal(data []byte, v any)`, que recebe o destino como `any` porque
precisa aceitar um ponteiro para qualquer struct que você tenha declarado. **Os dois são o uso certo
de `any`: a função aceita de fato todo tipo, e descobre em tempo de execução o que recebeu.**

"Todo tipo" não se estende a slices de todo tipo, porém. Um `[]string` não é um `[]any`, e
passá-lo com `...`, do jeito que a lição 21 passou um slice para uma função variádica, é recusado:

```go
package main

import "fmt"

func main() {
	names := []string{"ana", "bia"}
	fmt.Println(names...)
}
```

```
ana@vm:~/any-slice$ go build
# example.com/slice
./main.go:7:14: cannot use names (variable of type []string) as []any value in argument to fmt.Println
```

Os elementos de um `[]string` são strings, uma depois da outra no array. Os elementos de um `[]any`
são valores de interface, cada um com um tipo e um valor. Nenhuma conversão transforma um array no
outro ali mesmo, então ter um `[]any` exige montar um slice novo e pôr cada string numa interface
pelo caminho. Go não esconde esse laço; você o escreve:

```go
package main

import "fmt"

func main() {
	names := []string{"ana", "bia"}
	args := make([]any, len(names))
	for i, n := range names {
		args[i] = n
	}
	fmt.Println(args...)
}
```

```
ana@vm:~/any-slice-fix$ go run .
ana bia
```

## Um documento JSON de formato desconhecido

A lição 15 decodificou JSON numa struct, cujos tipos de campo diziam ao `Unmarshal` o que montar. Às
vezes não há struct, porque o formato do documento não é conhecido quando o programa é escrito: um
arquivo de configuração que varia, a resposta de um serviço que muda. Aí o destino é um
`map[string]any`, e o `Unmarshal` escolhe sozinho o tipo de cada valor:

```go
package main

import (
	"encoding/json"
	"fmt"
)

func main() {
	data := []byte(`{"name": "Ana", "age": 31, "admin": false,
		"tags": ["go", "sql"], "boss": null, "id": 9007199254740993}`)

	var doc map[string]any
	if err := json.Unmarshal(data, &doc); err != nil {
		fmt.Println(err)
		return
	}
	for _, k := range []string{"name", "age", "admin", "tags", "boss", "id"} {
		fmt.Printf("%-6s %-14T %v\n", k, doc[k], doc[k])
	}
}
```

```
ana@vm:~/any-json$ go run .
name   string         Ana
age    float64        31
admin  bool           false
tags   []interface {} [go sql]
boss   <nil>          <nil>
id     float64        9.007199254740992e+15
ana@vm:~/any-json$ go doc encoding/json.Unmarshal | grep -A8 'into an interface value'
    To unmarshal JSON into an interface value, Unmarshal stores one of these in
    the interface value:

      - bool, for JSON booleans
      - float64, for JSON numbers
      - string, for JSON strings
      - []any, for JSON arrays
      - map[string]any, for JSON objects
      - nil for JSON null
```

`age` era `31` no JSON e voltou como `float64`. **Todo número JSON vira `float64`**, porque JSON
tem um tipo só de número, com ou sem ponto, e o `Unmarshal` não tem como saber que você queria um
`int`. `tags` voltou como `[]interface {}` e não como `[]string`, já que nada garante que o
próximo elemento também seja string. `boss` era `null` e virou uma interface que não guarda nada,
sem tipo nenhum.

A linha do `id` é a cara. O JSON dizia `9007199254740993` e o programa guarda
`9.007199254740992e+15`: o último dígito passou de 3 para 2, e `err` veio nil. Um `float64` guarda
52 bits de fração, como a lição 7 mostrou, então acima de 2⁵³, que é 9.007.199.254.740.992, ele já
não consegue guardar todo número inteiro. O inteiro seguinte é um dos que ele pula, e foi
arredondado para o vizinho. Ids de 64 bits vindos de um banco de dados são exatamente os números
que moram ali em cima.

Dois jeitos preservam o número, e o segundo é o preferível:

```go
package main

import (
	"encoding/json"
	"fmt"
	"strings"
)

type User struct {
	ID int64 `json:"id"`
}

func main() {
	data := `{"id": 9007199254740993}`

	var doc map[string]any
	dec := json.NewDecoder(strings.NewReader(data))
	dec.UseNumber()
	if err := dec.Decode(&doc); err != nil {
		fmt.Println(err)
		return
	}
	fmt.Printf("%T %v\n", doc["id"], doc["id"])

	var u User
	if err := json.Unmarshal([]byte(data), &u); err != nil {
		fmt.Println(err)
		return
	}
	fmt.Printf("%T %v\n", u.ID, u.ID)
}
```

```
ana@vm:~/any-json-number$ go run .
json.Number 9007199254740993
int64 9007199254740993
```

O `UseNumber` manda um decoder guardar cada número como `json.Number`, que é o texto do número,
deixado para você converter quando souber o que ele deve ser. Uma struct faz melhor: o campo
`int64` disse ao `Unmarshal` o que montar, e o número chegou inteiro. **Quando você conhece o
formato de um documento, decodifique numa struct.** `map[string]any` é para o documento que você
não consegue descrever, e a seção 03 mostra quanto custa lê-lo.
