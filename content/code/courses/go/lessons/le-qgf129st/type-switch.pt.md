---
title: O type switch
version: 1
---

A seção 03 fez uma pergunta por asserção. Um valor que pode ser qualquer um de seis tipos pediria
seis asserções seguidas, cada uma com o seu `ok`. **Um `type switch` faz todas as perguntas de uma
vez: os seus casos são tipos, e roda o primeiro que casar com o tipo dinâmico do valor.** O `switch`
da lição 19 comparava valores; este compara tipos, e é a ferramenta para percorrer o
`map[string]any` da lição 28. O mesmo documento, cada valor impresso com aquilo que ele acabou sendo:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"encoding/json\"\n\t\"fmt\"\n\t\"maps\"\n\t\"slices\"\n\t\"strings\"\n)\n\nfunc walk(x any, depth int) {\n\tpad := strings.Repeat(\"  \", depth)\n",
      "note": "`walk` recebe `any` porque um documento decodificado pode ser qualquer coisa em qualquer profundidade. `depth` só define o recuo."
    },
    {
      "code": "\tswitch v := x.(type) {\n\tcase nil:\n\t\tfmt.Println(pad + \"null\")\n",
      "note": "**`switch v := x.(type)` é um switch cujos casos são tipos.** Em cada caso, `v` é `x` convertido para o tipo daquele caso. `case nil` casa com uma interface que não guarda nada, que é o que o `Unmarshal` guarda para `null`."
    },
    {
      "code": "\tcase bool:\n\t\tfmt.Println(pad+\"bool\", v)\n\tcase float64:\n\t\tfmt.Println(pad+\"number\", v)\n\tcase string:\n\t\tfmt.Printf(\"%sstring %q\\n\", pad, v)\n",
      "note": "Aqui `v` é um `bool`, um `float64` e uma `string`, um de cada vez, então cada caso pode usá-lo como tal: `%q` numa string, sem nenhuma asserção escrita."
    },
    {
      "code": "\tcase []any:\n\t\tfmt.Println(pad+\"array of\", len(v))\n\t\tfor _, e := range v {\n\t\t\twalk(e, depth+1)\n\t\t}\n",
      "note": "Um array chega como `[]any`, e `v` é esse slice: `len(v)` e `range v` compilam aqui e em nenhum outro lugar da função. Cada elemento volta para `walk`."
    },
    {
      "code": "\tcase map[string]any:\n\t\tfmt.Println(pad+\"object of\", len(v))\n\t\tfor _, k := range slices.Sorted(maps.Keys(v)) {\n\t\t\tfmt.Println(pad + \"  \" + k + \":\")\n\t\t\twalk(v[k], depth+2)\n\t\t}\n",
      "note": "Um objeto chega como `map[string]any`. As chaves são ordenadas com o `slices.Sorted(maps.Keys(v))` da lição 14, porque a ordem de um map muda de uma execução para outra."
    },
    {
      "code": "\tdefault:\n\t\tfmt.Printf(\"%sunexpected %T\\n\", pad, v)\n\t}\n}\n\n",
      "note": "`default` fica com todo tipo que nenhum caso nomeou. O `Unmarshal` nunca produz um, então esta linha é o programa dizendo que chegou algo que ele não esperava."
    },
    {
      "code": "func main() {\n\tdata := []byte(`{\"name\": \"Ana\", \"age\": 31, \"admin\": false,\n\t\t\"tags\": [\"go\", \"sql\"], \"boss\": null}`)\n\n\tvar doc any\n\tif err := json.Unmarshal(data, &doc); err != nil {\n\t\tfmt.Println(err)\n\t\treturn\n\t}\n\twalk(doc, 0)\n}\n",
      "note": "`doc` desta vez é um `any` simples, não um map, já que um documento JSON não precisa ser um objeto."
    }
  ],
  "output": "object of 5\n  admin:\n    bool false\n  age:\n    number 31\n  boss:\n    null\n  name:\n    string \"Ana\"\n  tags:\n    array of 2\n      string \"go\"\n      string \"sql\""
}
```

Leia a saída junto com o código. `doc` era um objeto, então rodou o caso `map[string]any`, que
imprimiu cinco chaves em ordem. `age` saiu como `number 31` pelo caso `float64`, que é o tipo que a
lição 28 disse que todo número JSON vira. `boss` casou com `case nil`, e `tags` casou com `[]any` e
mandou as suas duas strings de volta para `walk`, um nível mais fundo.

A variável é o que torna isto melhor que uma fila de asserções. **Dentro de cada caso, `v` tem o
tipo que aquele caso nomeia**, então o caso `string` pode passá-la ao `%q`, e o caso `[]any` pode
pegar o seu comprimento e percorrê-la. Há um `v` por caso, declarado pela linha do `switch`, e
nenhum `.(T)` em outro lugar da função.

## Quando um caso nomeia mais de um tipo

Um caso pode listar vários tipos, do jeito que um switch de valores lista vários valores. Aí `v`
não pode ter todos eles ao mesmo tempo:

```go
package main

import "fmt"

func kind(x any) string {
	switch v := x.(type) {
	case nil:
		return "nothing"
	case int, float64:
		return fmt.Sprintf("a number held as %T", v)
	case string:
		return fmt.Sprintf("a string of %d bytes", len(v))
	default:
		return fmt.Sprintf("something else: %T", v)
	}
}

func main() {
	var p *int
	for _, x := range []any{nil, 3, 2.5, "olá", p, []int{1}} {
		fmt.Println(kind(x))
	}
}
```

```
ana@vm:~/assert-kind$ go run .
nothing
a number held as int
a number held as float64
a string of 4 bytes
something else: *int
something else: []int
```

Em `case int, float64`, `v` mantém o tipo de `x`, que é `any`. O `%T` ainda imprime `int` ou
`float64`, porque o `%T` informa o tipo dinâmico, mas o compilador vê um `any` e não permite mais
nada. Tentar fazer aritmética num caso assim mostra isso:

```go
package main

import "fmt"

func double(x any) any {
	switch v := x.(type) {
	case int, float64:
		return v * 2
	case string:
		fallthrough
	default:
		return nil
	}
}

func main() {
	fmt.Println(double(3))
}
```

```
ana@vm:~/assert-kind-bad$ go build
# example.com/double
./main.go:8:10: invalid operation: v * 2 (mismatched types any and untyped int)
./main.go:10:3: cannot fallthrough in type switch
```

`mismatched types any and untyped int` é o compilador dizendo o que `v` é naquele caso. A correção
é um caso por tipo, cada um com a sua aritmética. O segundo erro cumpre uma promessa da lição 19:
`fallthrough` é recusado num type switch, porque o caso seguinte receberia um `v` de outro tipo.

Duas linhas da saída de `kind` falam de nil. `case nil` casou com o primeiro elemento, uma
interface que não guarda nada. O quinto elemento era um `*int` nil, e foi para o `default` como
`something else: *int`. **`case nil` só casa com uma interface sem tipo dentro, a mesma regra do
`== nil` da lição 28**, e um ponteiro nil dentro de uma interface ainda tem tipo.

## A ordem dos casos faz parte do significado

Os casos são tentados de cima para baixo, e um valor pode casar com mais de um quando um caso nomeia
uma interface. O `fmt` depende dessa ordem. Sempre que imprime um valor com `%v`, `%s` ou um de
três outros verbos, ele roda um type switch para decidir se o valor tem um método que o descreve.
Aqui está um tipo com os dois métodos que ele procura, e as linhas do `fmt` que escolhem entre eles:

```go
package main

import "fmt"

type Both struct{}

func (Both) Error() string  { return "from Error" }
func (Both) String() string { return "from String" }

func main() {
	fmt.Println(Both{})
}
```

```
ana@vm:~/assert-fmt$ sed -n 656,668p /usr/local/go/src/fmt/print.go
			switch v := arg.(type) {
			case error:
				handled = true
				defer p.catchPanic(arg, verb, "Error")
				p.fmtString(arg, value, v.Error(), verb)
				return

			case Stringer:
				handled = true
				defer p.catchPanic(arg, verb, "String")
				p.fmtString(arg, value, v.String(), verb)
				return
			}
ana@vm:~/assert-fmt$ go run .
from Error
```

`error` é conferido antes de `Stringer`, então um tipo com os dois métodos imprime o seu `Error`.
`Both` tem um `Error` e um `String`, e o `fmt.Println` imprimiu `from Error`. Esse switch também é o
motivo de um método `String` mudar o que o `fmt` imprime para o seu tipo: o `fmt` pergunta a todo
valor que imprime desse jeito se ele é um `Stringer`, e um tipo com um método `String() string` é
um, sem declarar nada.

Assim as três ferramentas desta lição se encaixam. Uma interface montada por embutimento diz que
métodos um valor precisa ter. Uma asserção pergunta se um valor tem um tipo específico ou um método
a mais específico. Um `type switch` faz a mesma pergunta a uma lista de tipos, e dá a cada caso um
`v` do tipo que encontrou.
