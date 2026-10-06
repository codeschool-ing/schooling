---
title: Listas de parâmetros de tipo, e o que a inferência enxerga
version: 1
---

A lição 30 escreveu uma função genérica com um parâmetro de tipo. A maioria das funções genéricas
que você vai escrever ou ler tem mais de um. Uma lista de parâmetros de tipo funciona como uma lista
de parâmetros comum, com tipos no lugar de valores: nomes, depois o que cada um pode ser, entre
colchetes, entre o nome da função e os parâmetros comuns dela. O `Map` abaixo aplica uma função a cada
elemento de uma slice, e precisa de dois parâmetros de tipo, porque os elementos que entram e os que
saem podem ser diferentes. Em `~/generic2`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"strconv\"\n)\n\nfunc Map[T, U any](xs []T, f func(T) U) []U {\n",
      "note": "**Dois parâmetros de tipo, `T` e `U`, com uma restrição em comum.** `T, U any` é a mesma abreviação de `a, b int` numa lista comum. A assinatura então amarra os dois: entra um `[]T`, uma função de `T` para `U`, sai um `[]U`."
    },
    {
      "code": "\tout := make([]U, 0, len(xs))\n\tfor _, x := range xs {\n\t\tout = append(out, f(x))\n\t}\n\treturn out\n}\n",
      "note": "Dentro do corpo, `T` e `U` são tipos como quaisquer outros: `make([]U, …)` cria uma slice do que `U` for, a pré-alocação da lição 12."
    },
    {
      "code": "\nfunc Make[T any](n int) []T {\n\treturn make([]T, n)\n}\n",
      "note": "Um parâmetro de tipo que aparece **só no resultado**. Guarde isso, porque o próximo bloco de saída depende disso."
    },
    {
      "code": "\nfunc main() {\n\tages := []int{41, 7, 23}\n\tlabels := Map(ages, strconv.Itoa)\n\tfmt.Printf(\"%q %T\\n\", labels, labels)\n",
      "note": "**Inferência: o compilador lê os tipos nos argumentos.** `ages` é um `[]int`, então `T` é `int`; `strconv.Itoa` é uma `func(int) string`, então `U` é `string`. O resultado é um `[]string`."
    },
    {
      "code": "\n\thalves := Map(ages, func(n int) float64 { return float64(n) / 2 })\n\tfmt.Println(halves)\n",
      "note": "O mesmo `Map`, o mesmo `T`, outro `U`: a função literal (lição 21) devolve `float64`, então esta chamada dá um `[]float64`."
    },
    {
      "code": "\n\tnames := Make[string](2)\n\tfmt.Printf(\"%q %T\\n\", names, names)\n",
      "note": "**Instanciação explícita: o tipo escrito entre colchetes na chamada.** `Make` não tem argumento de onde ler `T`, então quem chama o informa."
    },
    {
      "code": "\n\ttoText := Map[int, string]\n\tfmt.Printf(\"%T\\n\", toText)\n}\n",
      "note": "Instanciar sem chamar. `Map[int, string]` é um valor de função comum com todos os tipos preenchidos, e o `%T` imprime a assinatura dele."
    }
  ],
  "output": "[\"41\" \"7\" \"23\"] []string\n[20.5 3.5 11.5]\n[\"\" \"\"] []string\nfunc([]int, func(int) string) []string"
}
```

Escrever `Map[int, string]` dá a função com `T` igual a `int` e `U` igual a `string`, e o compilador
faz exatamente isso, sem mostrar, em cada chamada de `main` que não cita tipos. Preencher um
parâmetro de tipo se chama **instanciação**; inferência é o compilador descobrindo com o que
preencher.

## O que a inferência não enxerga

Uma crença comum é que o compilador descobre o tipo a partir de onde o resultado vai parar, de modo
que `var labels []string = Make(2)` lhe diria que `T` é `string`. Não diz. **A inferência lê os
argumentos da chamada, e nada fora da chamada.** As mesmas duas funções, em `~/generic2-infer`, sem
os colchetes:

```go
func main() {
	names := Make(2)
	var labels []string = Make(2)
	toText := Map
	fmt.Println(names, labels, toText)
}
```

```
ana@vm:~/generic2-infer$ go run .
# example.com/generic2-infer
./main.go:18:15: in call to Make, cannot infer T (declared at ./main.go:13:11)
./main.go:19:28: in call to Make, cannot infer T (declared at ./main.go:13:11)
./main.go:20:12: cannot use generic function Map without instantiation
```

`Make(2)` tem um argumento, um `int`, e `T` não aparece em lugar nenhum da lista de parâmetros, então
não há de onde inferi-lo, e o tipo declarado de `labels` na linha 19 não ajuda. A mensagem cita o
parâmetro de tipo e aponta para a linha 13, coluna 11, onde `T` foi declarado. O terceiro erro é a
mesma lacuna vista de outro lado. `Map` sozinho não é uma função que se possa guardar, só uma receita
para uma; guardá-lo exige todos os tipos preenchidos, como `toText := Map[int, string]` fez.

Quando aparece `cannot infer`, o conserto é o que o `main` acima usou: escrever os tipos entre
colchetes. Eles vão na ordem em que a função os declarou, e você pode parar antes do fim.
Chamar `Map[int]` com `ages` e `f` fixaria `T` e ainda deixaria `U` para ser lido em `f`.

## Todo uso de `T` tem de concordar

O `ShowAll` da lição 30 foi recusado porque um parâmetro de tipo é um único tipo por chamada. A regra
vale para números também, e ali ela pega muita gente. Este é o `Biggest` da lição 2, em
`~/generic2-mix`:

```go
package main

import "fmt"

func Biggest[T int | float64](a, b T) T {
	if a > b {
		return a
	}
	return b
}

func main() {
	top := Biggest(3, 2.5)
	fmt.Printf("%v %T\n", top, top)

	var count int = 3
	var price float64 = 2.5
	fmt.Println(Biggest(count, price))
}
```

```
ana@vm:~/generic2-mix$ go run .
# example.com/generic2-mix
./main.go:18:29: in call to Biggest, type float64 of price does not match inferred type int for T
```

A linha 18 foi recusada e a 13 não, e a diferença são as constantes sem tipo da lição 5. `3` e `2.5`
ainda não têm tipo próprio, então o compilador está livre para escolher um que sirva para os dois, e
escolhe `float64`. `count` e `price` são variáveis com tipo. A primeira fixou `T` como `int`, a segunda
discordou, e **Go não converte nada por você, genérico ou não**, que é a regra da lição 10. Com a
chamada trocada por `Biggest(float64(count), price)`, a conversão escrita onde se pode ver, as duas
linhas rodam:

```
ana@vm:~/generic2-mix$ go run .
3 float64
3
```

O `%T` confirma o que o compilador escolheu para as constantes: `T` era `float64`, e um `float64`
inteiro é impresso sem ponto decimal. A segunda linha é a mesma comparação, feita entre dois valores
que foram declarados com tipos diferentes e tiveram de ser levados a um só à mão.
