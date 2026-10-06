---
title: Funções como valores, com ou sem nome
version: 1
---

Uma função em Go é um valor, como um `int` ou uma slice. **Ela tem um tipo, pode ficar numa
variável, pode ser passada para outra função e devolvida por uma.** O tipo se escreve como a
assinatura da função, sem os nomes: `func(int) int` é qualquer função que recebe um `int` e devolve
um. E uma função não precisa de nome para existir. Escrita no lugar, `func(n int) int { return n +
10 }` é uma **função literal**, também chamada de função anônima.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"cmp\"\n\t\"fmt\"\n\t\"slices\"\n)\n\nfunc apply(nums []int, f func(int) int) []int {\n\tout := make([]int, 0, len(nums))\n\tfor _, n := range nums {\n\t\tout = append(out, f(n))\n\t}\n\treturn out\n}\n",
      "note": "**`f func(int) int` é um parâmetro cujo tipo é uma função.** `apply` não sabe o que `f` faz; chama `f(n)` para cada elemento e junta os resultados."
    },
    {
      "code": "\nfunc square(n int) int {\n\treturn n * n\n}\n",
      "note": "Uma função comum, com nome. O tipo dela é `func(int) int`, então ela cabe no parâmetro de `apply`."
    },
    {
      "code": "\nfunc main() {\n\tnums := []int{1, 2, 3}\n\tfmt.Println(apply(nums, square))\n",
      "note": "`square` sem parênteses é a própria função, passada como valor. Com parênteses, `square(2)`, seria uma chamada, e `apply` receberia um `int`."
    },
    {
      "code": "\tfmt.Println(apply(nums, func(n int) int { return n + 10 }))\n",
      "note": "Uma função literal, escrita onde é usada. Ela não tem nome porque nada mais vai chamá-la."
    },
    {
      "code": "\n\ttwice := func(n int) int { return 2 * n }\n\tfmt.Printf(\"%T\\n\", twice)\n\tfmt.Println(apply(nums, twice))\n",
      "note": "Uma literal guardada numa variável. `%T` imprime o tipo dela, `func(int) int`, o mesmo tipo de `square`."
    },
    {
      "code": "\n\twords := []string{\"banana\", \"fig\", \"apple\", \"kiwi\"}\n\tslices.SortFunc(words, func(a, b string) int {\n\t\treturn cmp.Compare(len(a), len(b))\n\t})\n\tfmt.Println(words)\n}\n",
      "note": "**Onde valores de função se pagam: a biblioteca padrão pede um.** `slices.SortFunc` ordena na ordem que você quiser, e a literal diz qual: pelo comprimento, a mais curta primeiro."
    }
  ],
  "output": "[1 4 9]\n[11 12 13]\nfunc(int) int\n[2 4 6]\n[fig kiwi apple banana]"
}
```

A função de comparação tem um contrato, e o `go doc` o enuncia:

```
ana@vm:~/closures-anon$ go doc slices.SortFunc | head -4
package slices // import "slices"

func SortFunc[S ~[]E, E any](x S, cmp func(a, b E) int)
    SortFunc sorts the slice x in ascending order as determined by the cmp
```

Os colchetes são generics, que as lições 30 e 31 ensinam; por ora leia `E` como "o tipo do
elemento", aqui `string`. A parte que interessa a esta seção é o último parâmetro, `cmp func(a, b
E) int`: uma função que recebe dois elementos e devolve um `int`. O resto dessa documentação diz o
que o `int` significa, negativo quando `a` vem antes, positivo quando `b` vem antes, zero quando
são iguais, e `cmp.Compare` devolve exatamente isso para quaisquer dois valores ordenáveis. A
documentação também diz que a ordenação **não é garantidamente estável**: duas palavras do mesmo
comprimento podem sair em qualquer ordem. As quatro palavras acima têm quatro comprimentos
diferentes, então a saída é a mesma em toda execução. `slices.SortStableFunc` mantém os elementos
iguais na ordem original.

## Uma função nil

O valor zero de um tipo função é `nil`; a lição 6 o imprimiu como `(func())(nil)`. Uma função
`nil` é uma variável sem nada para chamar, e chamá-la para o programa:

```go
package main

import "fmt"

func main() {
	var onDone func()
	fmt.Println(onDone == nil)
	onDone()
	fmt.Println("not reached")
}
```

```
ana@vm:~/closures-nil$ go run .
true
panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x0 pc=0x499e2b]

goroutine 1 [running]:
main.main()
	/home/ana/closures-nil/main.go:8 +0x4b
exit status 2
```

A linha 8 é `onDone()`. O compilador não tem como pegar isso, porque se uma variável guarda uma
função só se sabe com o programa rodando. A lição 36 explica o que é um panic e a lição 37 lê um
rastro como este linha a linha. **Um callback opcional, um valor de função que quem chama pode
omitir, é conferido com `!= nil` antes de ser chamado.**

Essa comparação é a única que uma função permite:

```go
package main

import "fmt"

func square(n int) int {
	return n * n
}

func main() {
	f := square
	g := square
	fmt.Println(f == g)
}
```

```
ana@vm:~/closures-cmp$ go run .
# example.com/closures-cmp
./main.go:12:14: invalid operation: f == g (func can only be compared to nil)
```

`f` e `g` guardam a mesma função, e ainda assim o compilador se recusa a dizer isso. A
consequência é prática: uma função não pode ser chave de map, já que as chaves da lição 14 precisam
ser comparáveis, e não há como perguntar se um valor de função é "aquele que você registrou antes".
