---
title: Parâmetros: o nome, depois o tipo
version: 1
---

Quem chega de C, Java ou C# escreve um parâmetro como `int width`, o tipo primeiro. **Go escreve ao
contrário: `width int`, o nome e depois o tipo.** A mesma ordem atravessa a linguagem inteira, no
`var n int` da lição 5 e em toda lista de parâmetros, e se lê da esquerda para a direita do jeito
que você falaria: width, um int. Aqui está um programa pequeno com quatro funções, em `~/funcs`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc area(width int, height int) int {\n\treturn width * height\n}\n",
      "note": "**`func`, o nome, os parâmetros entre parênteses, depois o tipo do resultado.** `area` recebe dois `int` e devolve um. O `return` entrega o valor e encerra a função."
    },
    {
      "code": "\nfunc perimeter(width, height int) int {\n\treturn 2 * (width + height)\n}\n",
      "note": "Parâmetros vizinhos do mesmo tipo podem compartilhá-lo: `width, height int` quer dizer que os dois são `int`. É a forma que a maior parte do código Go usa."
    },
    {
      "code": "\nfunc label(name string, width, height int, unit string) string {\n\treturn fmt.Sprintf(\"%s: %d%s\", name, area(width, height), unit)\n}\n",
      "note": "O agrupamento funciona em qualquer ponto da lista. Um tipo vale para os nomes escritos logo antes dele, até o tipo anterior: `name` é `string`, `width` e `height` são `int`, `unit` é `string`."
    },
    {
      "code": "\nfunc ruler() {\n\tfmt.Println(\"----------\")\n}\n",
      "note": "Sem parâmetros e sem resultado: parênteses vazios e nada depois deles. Uma função que não devolve nada não precisa de `return`."
    },
    {
      "code": "\nfunc main() {\n\tfmt.Println(area(3, 4), perimeter(3, 4))\n\truler()\n\tfmt.Println(label(\"kitchen\", 3, 4, \" m2\"))\n}\n",
      "note": "Uma chamada passa os argumentos na ordem dos parâmetros, e todos eles: não há nomes na chamada e nada pode ficar de fora."
    }
  ],
  "output": "12 14\n----------\nkitchen: 12 m2"
}
```

A ordem das declarações não importa. `label` chama `area`, que está acima dela, mas `main` está no
fim e poderia muito bem estar no começo: uma função é visível no pacote inteiro, o escopo de pacote
da lição 6.

## Digitado do jeito de C

O compilador não diz "ordem errada" quando um parâmetro vem com o tipo primeiro. Ele lê o que você
escreveu, e o que você escreveu é sintaxe válida que quer dizer outra coisa:

```go
package main

import "fmt"

func area(int width, int height) int {
	return width * height
}

func main() {
	fmt.Println(area(3, 4))
}
```

```
ana@vm:~/funcs-c$ go run .
# example.com/funcs-c
./main.go:5:15: undefined: width
./main.go:5:22: int redeclared in this block
	./main.go:5:11: other declaration of int
./main.go:5:26: undefined: height
./main.go:6:9: undefined: width
./main.go:6:17: undefined: height
```

Leia os erros com a regra em mente e cada um faz sentido. `int width` declara um parâmetro
**chamado** `int`, de um tipo chamado `width`, e não existe tipo chamado `width`. O segundo
`int height` declara outro parâmetro chamado `int`, que é a redeclaração na linha 5, coluna 22.
`int` é um nome predeclarado e não uma palavra-chave, o ponto que a lição 6 levantou sobre o escopo
universal, então nada impede um parâmetro de usá-lo. **Quando uma lista de erros não faz sentido,
veja se algum parâmetro foi escrito com o tipo primeiro.**

## Sem valores padrão, sem sobrecarga

Dois recursos que muitas linguagens têm faltam de propósito. Um parâmetro não pode ter valor
padrão:

```go
package main

import "fmt"

func greet(name string, greeting string = "Hello") {
	fmt.Println(greeting+",", name)
}

func main() {
	greet("Ana")
}
```

```
ana@vm:~/funcs-default$ go run .
# example.com/funcs-default
./main.go:5:41: syntax error: unexpected = in parameter list; possibly missing comma or )
```

E duas funções do mesmo pacote não podem ter o mesmo nome, nem com parâmetros diferentes:

```go
package main

import "fmt"

func area(side int) int {
	return side * side
}

func area(width, height int) int {
	return width * height
}

func main() {
	fmt.Println(area(3), area(3, 4))
}
```

```
ana@vm:~/funcs-overload$ go run .
# example.com/funcs-overload
./main.go:9:6: area redeclared in this block
	./main.go:5:6: other declaration of area
./main.go:14:31: too many arguments in call to area
	have (number, number)
	want (int)
```

O segundo erro decorre do primeiro. O compilador ficou com a primeira `area`, a de um parâmetro,
então a chamada `area(3, 4)` na linha 14 passou a ser uma chamada com um argumento a mais.

O que Go faz no lugar disso aparece na biblioteca padrão. Onde outra linguagem teria uma função com
um argumento opcional, ou três versões de um nome, Go tem várias funções, cada uma com seu próprio
nome e exatamente os parâmetros de que precisa:

```
ana@vm:~/funcs-overload$ go doc strings | grep -E '^func (Index|IndexByte|IndexRune|Split|SplitN)\('
func Index(s, substr string) int
func IndexByte(s string, c byte) int
func IndexRune(s string, r rune) int
func Split(s, sep string) []string
func SplitN(s, sep string, n int) []string
```

`SplitN` é o `Split` com o argumento que um valor padrão teria escondido, e `IndexByte` e
`IndexRune` são o `Index` para as duas outras coisas que você pode procurar. **Em Go um nome
corresponde a uma função, então ler uma chamada diz exatamente qual código roda**, sem ter de
descobrir qual versão os tipos escolhem.

## Os argumentos têm de bater

Uma chamada precisa passar exatamente tantos argumentos quantos são os parâmetros, cada um de um
tipo que o parâmetro aceita. O compilador confere toda chamada:

```go
package main

import "fmt"

func area(width, height int) int {
	return width * height
}

func main() {
	fmt.Println(area(3))
	fmt.Println(area(3, 4, 5))
	fmt.Println(area(3, "4"))
}
```

```
ana@vm:~/funcs-args$ go run .
# example.com/funcs-args
./main.go:10:19: not enough arguments in call to area
	have (number)
	want (int, int)
./main.go:11:25: too many arguments in call to area
	have (number, number, number)
	want (int, int)
./main.go:12:22: cannot use "4" (untyped string constant) as int value in argument to area
```

`have` é o que a chamada passou e `want` é a lista de parâmetros da função. `number` é como a
mensagem descreve uma constante sem tipo como `3`, que ainda pode virar `int` (lição 5). `"4"` é
uma string, e nenhuma conversão acontece sozinha, a regra de que a lição 10 tratou.

Uma coisa é permitida, e você talvez esperasse que fosse recusada. A lição 5 mostrou uma variável
local declarada e nunca usada impedindo o build. **Um parâmetro que nunca é usado não é erro**:

```go
package main

import "fmt"

func area(width, height int, unit string) int {
	return width * height
}

func main() {
	fmt.Println(area(3, 4, "m2"))
}
```

```
ana@vm:~/funcs-unusedparam$ go vet && go run .
12
```

Nem o compilador nem o `go vet` falam de `unit`. A lista de parâmetros é um contrato com quem
chama, e às vezes uma função precisa aceitar um valor de que não precisa, porque sua assinatura tem
de casar com outra coisa. A lição 21 passa funções como valores, e lá isso acontece o tempo todo.

Todo argumento chega como uma cópia do valor que quem chamou passou. A lição 11 mostrou o que isso
quer dizer para um array e uma slice, e a lição 22 faz disso a regra para todo tipo.
