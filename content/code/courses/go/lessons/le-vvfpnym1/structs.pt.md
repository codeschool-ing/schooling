---
title: Declarar, preencher e comparar uma struct
version: 1
---

Quem chega de Java ou de Python costuma ler uma struct como uma classe sem os métodos. A lição 1
disse que Go não tem classes, e uma struct não está tentando ser uma. **Uma struct é um valor feito
de campos com nome, cada um com seu tipo, e mais nada**: nenhum construtor roda quando uma é criada,
e copiá-la copia os campos. Métodos de um tipo são a lição 25, e também não moram na declaração da
struct.

A lição 14 guardou valores sob chaves que o programa escolhe em tempo de execução. Os campos de uma
struct são o contrário: os nomes estão fixos no código-fonte, e o compilador confere cada uso de um
deles.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\ntype Point struct {\n\tX, Y int\n}\n\ntype Book struct {\n\tTitle  string\n\tAuthor string\n\tPages  int\n\tTags   []string\n}\n",
      "note": "**`type Nome struct { … }` declara um tipo novo com um campo por linha**, o nome primeiro e o tipo depois. Campos do mesmo tipo podem dividir uma linha, como faz `X, Y int`. Os espaços a mais que alinham os tipos de `Book` são obra do `gofmt`."
    },
    {
      "code": "\nfunc main() {\n\tp := Point{X: 3, Y: 4}\n\tq := Point{3, 4}\n\tvar origin Point\n\tfmt.Println(p, q, origin, p == q)\n",
      "note": "Três jeitos de obter um `Point`. **Um literal com nome dos campos** diz que valor vai em cada um. Um literal sem eles preenche os campos na ordem da declaração. `var` dá o valor zero, cada campo no seu próprio zero, como a lição 6 mostrou. Duas structs são iguais quando cada campo é."
    },
    {
      "code": "\n\tp.X = 10\n\tfmt.Println(p.X, p, p == q)\n",
      "note": "Um campo é lido e escrito com um ponto. Mudar `p.X` muda só `p`: `q` era um valor separado desde o início, então os dois deixam de ser iguais."
    },
    {
      "code": "\n\tb := Book{Title: \"Dom Casmurro\", Author: \"Machado de Assis\"}\n\tfmt.Printf(\"%v\\n%+v\\n\", b, b)\n}\n",
      "note": "**Campos que o literal não nomeia ficam no valor zero**, aqui `Pages` e `Tags`. `%v` imprime só os valores, o que fica difícil de ler quando a struct tem alguns campos; `%+v` põe o nome de cada campo na frente do valor."
    }
  ],
  "output": "{3 4} {3 4} {0 0} true\n10 {10 4} false\n{Dom Casmurro Machado de Assis 0 []}\n{Title:Dom Casmurro Author:Machado de Assis Pages:0 Tags:[]}"
}
```

`Tags` saiu como `[]`, e é uma slice nil: ninguém lhe deu valor. A lição 12 mostrou que o `fmt` não
distingue uma slice nil de uma vazia, e a seção 03 mostra alguém que distingue.

## Dê nome aos campos

`Point{3, 4}` é mais curto que `Point{X: 3, Y: 4}`, e serve para um tipo seu, de dois campos, que
nunca vai mudar. Para uma struct de outro pacote é uma armadilha. O pacote pode acrescentar um
campo, mesmo um não exportado, e todo literal que dependia da ordem deixa de compilar, no seu
código, depois de uma atualização que você não escreveu. O `go vet` avisa:

```go
package main

import (
	"fmt"
	"net"
)

func main() {
	addr := net.TCPAddr{net.IPv4(127, 0, 0, 1), 8080, ""}
	fmt.Println(addr.String())
}
```

```
ana@vm:~/structs-unkeyed$ go run .
127.0.0.1:8080
ana@vm:~/structs-unkeyed$ go vet; echo $?
main.go:9:10: net.TCPAddr struct literal uses unkeyed fields
1
```

O programa funciona hoje. Ninguém que o leia sabe o que é aquele `""` sem abrir a documentação de
`net.TCPAddr`, e essa é a outra metade do aviso do vet. **Escreva o nome dos campos em todo literal
de struct de um tipo que você não declarou**, e na maioria dos que declarou.

## Quando o `==` é recusado

`p == q` comparou dois `Point` campo a campo. Isso só funciona quando todo campo pode ser
comparado, e a regra é a que a lição 14 deu para chaves de map:

```go
package main

import "fmt"

type Book struct {
	Title string
	Tags  []string
}

func main() {
	a := Book{Title: "Dom Casmurro"}
	b := Book{Title: "Dom Casmurro"}
	fmt.Println(a == b)
}
```

```
ana@vm:~/structs-eq$ go run .
# example.com/eq
./main.go:13:14: invalid operation: a == b (struct containing []string cannot be compared)
```

**Uma struct é comparável exatamente quando todos os seus campos são.** Um campo slice basta para
perder o `==`, e com ele o direito de ser chave de map. A lição 14 prometeu que structs com campos
comparáveis podem ser chave, e um `Point` é o exemplo natural: uma posição numa grade, contada a cada
vez que um caminho passa por ela.

```go
package main

import "fmt"

type Point struct {
	X, Y int
}

func main() {
	path := []Point{{0, 0}, {0, 1}, {1, 1}, {0, 1}, {0, 0}, {0, 1}}
	visits := map[Point]int{}
	for i := 0; i < len(path); i++ {
		visits[path[i]]++
	}
	fmt.Println(visits)
	fmt.Println(visits[Point{X: 0, Y: 1}], visits[Point{X: 5, Y: 5}])
}
```

```
ana@vm:~/structs-key$ go run .
map[{0 0}:2 {0 1}:3 {1 1}:1]
3 0
```

Dentro de `[]Point{…}` os elementos podem dispensar o nome do tipo e escrever só `{0, 1}`, já que o
tipo da slice já diz o que eles são. A contagem é o `m[k]++` da lição 14, com uma struct inteira
como chave: `{0 1}` foi visitado três vezes, e `{5 5}`, nunca visitado, é lido como contagem zero.

## Uma struct sem nome

Um tipo struct pode ser escrito onde é usado, sem declaração `type`. Isso é uma **struct anônima**,
e serve para um valor de que se precisa num lugar só:

```go
package main

import "fmt"

func main() {
	origin := struct {
		Lat, Lon float64
	}{-23.55, -46.63}
	fmt.Printf("%+v\n", origin)

	cases := []struct {
		name string
		want int
	}{
		{"ana", 3},
		{"bruno", 5},
		{"jo", 3},
	}
	for i := 0; i < len(cases); i++ {
		got := len(cases[i].name)
		fmt.Println(cases[i].name, got, got == cases[i].want)
	}
}
```

```
ana@vm:~/structs-anon$ go run .
{Lat:-23.55 Lon:-46.63}
ana 3 true
bruno 5 true
jo 2 false
```

A segunda é a forma que você mais vai ver: uma slice de structs anônimas usada como tabela, uma
linha por caso, cada uma com uma entrada e a resposta esperada. A última linha está errada de
propósito, e o programa diz isso. Testes para o `go test` muitas vezes são escritos exatamente
nessa tabela, e testes são assunto do curso `go-concurrency`. Quando a mesma forma é necessária em
dois lugares, dê um nome a ela com `type`.
