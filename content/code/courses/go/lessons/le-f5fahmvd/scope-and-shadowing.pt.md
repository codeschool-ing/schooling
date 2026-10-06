---
title: Escopo, e a variável que esconde outra
version: 1
---

Um nome em Go é visível do ponto em que é declarado até o fim do bloco que o contém, e em nenhum
outro lugar. **Um bloco é, quase sempre, um par de chaves**, e blocos se aninham. Um nome declarado
num bloco interno pode reaproveitar um nome de um bloco externo, e dentro do bloco interno o novo
esconde o antigo. Isso se chama sombreamento (shadowing), é permitido, silencioso e a origem de um
bug bem conhecido, mostrado no fim desta seção.

## Cinco níveis, de fora para dentro

| escopo | o que é declarado ali | visível em |
|---|---|---|
| universo | os nomes pré-declarados: `int`, `string`, `len`, `true`, `nil`, `iota`, … | todo arquivo de todo pacote |
| pacote | tudo o que é declarado fora de uma função, em qualquer arquivo do pacote | todo arquivo daquele pacote |
| arquivo | os imports | aquele arquivo só |
| função | parâmetros, resultados e as variáveis do corpo | aquela função |
| bloco | o que é declarado dentro de chaves, e na primeira cláusula de um `if`, `for` ou `switch` | aquele bloco |

O `go doc builtin` lista o universo: documenta `len`, `nil`, `iota` e o resto como se fossem um
pacote, embora ninguém nunca importe um. A linha do meio é a que pega as pessoas de surpresa, então
aqui está um pacote de dois arquivos, `~/zero-scope`:

```go
package main

import "fmt"

var limit = 3

func main() {
	x := 1
	if x < limit {
		x := x
		x += 10
		fmt.Println("inside: ", x)
	}
	fmt.Println("outside:", x)
	report()
}
```

```go
package main

func report() {
	fmt.Println("report sees limit =", limit)
}
```

```
ana@vm:~/zero-scope$ go run .
# example.com/scope
./report.go:4:2: undefined: fmt
```

O `report.go` usa `limit`, declarado no outro arquivo, e o compilador não reclama disso. Usa `fmt`
também, e isso é recusado. **Um nome do nível do pacote é compartilhado por todos os arquivos do
pacote; um import pertence só ao arquivo que o escreveu.** Acrescente `import "fmt"` ao `report.go`
e o programa roda:

```go
package main

import "fmt"

func report() {
	fmt.Println("report sees limit =", limit)
}
```

```
ana@vm:~/zero-scope$ go run .
inside:  11
outside: 1
report sees limit = 3
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Cinco escopos aninhados nos dois arquivos de ~/zero-scope. O universo guarda os nomes pré-declarados, como int, len, true, nil e iota. Dentro dele, o pacote main guarda limit, main e report, visíveis dos dois arquivos. Cada arquivo tem o seu próprio import de fmt. A função main declara x, e o bloco do if dentro dela declara um segundo x que esconde o primeiro. A função report vê limit, mas não x.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"310\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"22\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">universo</text><text x=\"90\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">int  len  true  nil  iota  …</text><rect x=\"28\" y=\"46\" width=\"664\" height=\"262\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">pacote</text><text x=\"94\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main:  var limit   func main   func report</text><rect x=\"46\" y=\"84\" width=\"390\" height=\"212\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"58\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">arquivo</text><text x=\"119\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main.go:  import &quot;fmt&quot;</text><rect x=\"452\" y=\"84\" width=\"222\" height=\"212\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"464\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">arquivo</text><text x=\"525\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">report.go:  import &quot;fmt&quot;</text><rect x=\"64\" y=\"122\" width=\"354\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"76\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">função</text><text x=\"130\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main:  x := 1</text><rect x=\"470\" y=\"122\" width=\"186\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"482\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">função</text><text x=\"536\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">report</text><text x=\"563\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">vê limit; não vê x</text><rect x=\"82\" y=\"162\" width=\"318\" height=\"104\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"94\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">bloco</text><text x=\"141\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">if x &lt; limit { … }</text><text x=\"100\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">x := x</text><text x=\"160\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um segundo x, que esconde o primeiro</text><text x=\"100\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">x += 10</text></svg>", "caption": "Os escopos de ~/zero-scope, do mais externo para dentro. Um nome é visível na caixa que o declara e em todas as caixas dentro dela; uma caixa que declara o mesmo nome de novo esconde o de fora."}
```

## x := x

Dentro do `if`, `x := x` declara um segundo `x` e o começa como cópia do primeiro. Parece uma
instrução que não faz nada, e faz algo preciso: o novo `x` só entra em escopo quando a declaração
dele termina, então o `x` da direita ainda é o de fora. Somar 10 ao `x` de dentro não mudou nada
lá fora, e é por isso que o programa imprimiu `11` dentro e `1` fora. Você vai ver `x := x` em
código Go mais antigo que entrega uma variável de laço a uma função; a lição 21 explica por que o
Go 1.22 tornou a maioria desses casos desnecessária.

O universo também pode ser sombreado, porque `len`, `int` e `true` são nomes pré-declarados e não
palavras-chave. Nada impede você de chamar uma variável de `len`, até precisar da função:

```go
package main

import "fmt"

func main() {
	len := 3
	fmt.Println(len("abc"))
}
```

```
ana@vm:~/zero-universe$ go build
# example.com/universe
./main.go:7:14: invalid operation: cannot call len (variable of type int): int is not a function
```

## O err sombreado

Esta função deveria somar uma lista de números escritos como texto e parar, com um erro, no
primeiro que não for número. O `strconv.Atoi` transforma uma string num `int` e devolve um erro
quando não consegue; a lição 10 o apresenta direito.

```go
// Command total adds up its arguments and should stop at the first bad one.
package main

import (
	"fmt"
	"strconv"
)

func total(args []string) (int, error) {
	sum := 0
	var err error
	for _, a := range args {
		n, err := strconv.Atoi(a)
		if err != nil {
			break
		}
		sum += n
	}
	return sum, err
}

func main() {
	fmt.Println(total([]string{"1", "2", "x", "4"}))
}
```

```
ana@vm:~/zero-shadow$ go run .
3 <nil>
ana@vm:~/zero-shadow$ go vet; echo $?
0
```

Parou em `"x"`, como devia, e depois não informou erro nenhum. **O `:=` dentro do laço declarou um
`n` novo e um `err` novo**, porque o corpo do laço é um bloco próprio e os dois nomes eram novos
para ele. O `err` que recebeu a falha foi o de dentro, e ele saiu de escopo no fim da iteração. O
`err` que `total` devolveu foi o de fora, que nada nunca atribuiu, então continuava no valor zero,
`nil`.

Nada pegou o erro. O `err` de dentro é usado pelo `if`, então o "declared and not used" do
compilador, da lição 5, não tinha o que dizer, e o `go vet` saiu com 0. A correção é deixar de
precisar da variável de fora e retornar de onde o erro é conhecido:

```go
func total(args []string) (int, error) {
	sum := 0
	for _, a := range args {
		n, err := strconv.Atoi(a)
		if err != nil {
			return sum, err
		}
		sum += n
	}
	return sum, nil
}
```

```
ana@vm:~/zero-shadow$ go run .
3 strconv.Atoi: parsing "x": invalid syntax
```

**Quando um `:=` aparece dentro de um bloco, pergunte de cada nome à esquerda dele se você queria
uma variável nova.** Onde você queria a de fora, escreva `=` e declare antes com `var` o que for
novo. Onde, como aqui, a variável de fora só existia para levar um valor para fora do bloco, a
correção mais limpa costuma ser retornar lá de dentro.
