---
title: Funções variádicas: qualquer quantidade de argumentos
version: 1
---

A lição 20 disse que uma chamada precisa passar exatamente tantos argumentos quantos são os
parâmetros da função. Mesmo assim, `fmt.Println` já recebeu um argumento, três e cinco neste curso
sem reclamar. A lição 4 imprimiu a assinatura dela, `func Println(a ...any) (n int, err error)`, e
o `...` é a explicação. **Um parâmetro escrito `...T` aceita qualquer quantidade de argumentos do
tipo `T`, e dentro da função ele é uma slice comum, `[]T`.** Uma função com um parâmetro assim se
chama **variádica**.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc sum(nums ...int) int {\n\ttotal := 0\n\tfor _, n := range nums {\n\t\ttotal += n\n\t}\n\treturn total\n}\n",
      "note": "`nums ...int` junta todo `int` que quem chama passar. O corpo percorre `nums` como qualquer slice; o loop `for range` é da lição 17."
    },
    {
      "code": "\nfunc show(nums ...int) {\n\tfmt.Printf(\"%T %v len=%d nil=%v\\n\", nums, nums, len(nums), nums == nil)\n}\n",
      "note": "Uma segunda função, só para ver o que um parâmetro variádico é de fato: o tipo, o conteúdo, o comprimento e se é `nil`."
    },
    {
      "code": "\nfunc main() {\n\tfmt.Println(sum(), sum(5), sum(1, 2, 3))\n",
      "note": "Zero argumentos, um, três: todos válidos. `sum()` dá 0 porque o loop não tem nada para somar."
    },
    {
      "code": "\tshow()\n\tshow(1, 2)\n",
      "note": "**Sem argumentos, o parâmetro é uma slice `nil`**, a distinção da lição 12: comprimento 0 e `nil=true`. Com dois, é um `[]int` de comprimento 2, montado para esta chamada."
    },
    {
      "code": "\n\tscores := []int{7, 8, 9}\n\tfmt.Println(sum(scores...))\n}\n",
      "note": "**Uma slice que você já tem é passada com `...` depois dela.** `scores...` entrega a `sum` a própria slice, não os elementos um a um."
    }
  ],
  "output": "0 5 6\n[]int [] len=0 nil=true\n[]int [1 2] len=2 nil=false\n24"
}
```

O `append`, que a lição 11 apresentou, também é variádico, e é por isso que `append(s, 1, 2, 3)`
acrescenta três elementos de uma vez e `append(a, b...)` acrescenta a slice `b` inteira a `a`.

## Três regras que o compilador cobra

```go
package main

import "fmt"

func sum(nums ...int) int {
	total := 0
	for _, n := range nums {
		total += n
	}
	return total
}

func label(nums ...int, unit string) string {
	return unit
}

func main() {
	scores := []int{7, 8, 9}
	fmt.Println(sum(scores))

	words := []string{"go", "vet"}
	fmt.Println(words...)
}
```

```
ana@vm:~/closures-varerr$ go run .
# example.com/closures-varerr
./main.go:13:17: can only use ... with final parameter
./main.go:19:18: cannot use scores (variable of type []int) as int value in argument to sum
./main.go:22:14: cannot use words (variable of type []string) as []any value in argument to fmt.Println
```

Um erro para cada regra:

1. **Só o último parâmetro pode ser variádico.** Do contrário não haveria como saber onde `nums`
   termina e `unit` começa, então `label` é recusada já na declaração.
2. **Uma slice não se espalha sozinha.** `sum(scores)` passa um argumento, um `[]int`, onde `sum`
   quer valores `int`. O `...` depois de `scores` é o que diz "estes são os argumentos".
3. **A slice já precisa ser do tipo do parâmetro.** `Println` recebe `...any`, então `words...`
   teria de ser um `[]any`. Um `[]string` é outro tipo, e Go não converte uma slice elemento por
   elemento por você, a regra que a lição 10 enunciou para valores isolados. Passar as palavras
   uma a uma, `fmt.Println(words[0], words[1])`, funciona, porque cada string vira um `any` por
   conta própria. A lição 28 trata de `any`.

## `s...` passa a sua slice, não uma cópia dela

A regra 2 tem uma consequência fácil de não ver. Quando os argumentos são escritos um a um, Go
monta uma slice nova para guardá-los. Quando você passa `scores...`, ele não monta nada: **o
parâmetro é a sua slice, com o seu array por trás**, e uma função que escreve nos elementos dela
escreve nos seus.

```go
package main

import "fmt"

func double(nums ...int) {
	for i := range nums {
		nums[i] *= 2
	}
}

func main() {
	a, b, c := 1, 2, 3
	double(a, b, c)
	fmt.Println(a, b, c)

	scores := []int{1, 2, 3}
	double(scores...)
	fmt.Println(scores)
}
```

```
ana@vm:~/closures-share$ go run .
1 2 3
[2 4 6]
```

A mesma função, chamada de dois jeitos. Com `a, b, c` ela dobrou os elementos de uma slice criada
para a chamada, e `a`, `b` e `c` mantiveram seus valores. Com `scores...` ela dobrou os elementos de
`scores`. É a regra da lição 11 sobre um parâmetro slice, vista de outro ângulo: a função recebe
uma cópia das três palavras da slice, e o ponteiro nelas leva ao array de quem chamou. Tudo o que a
lição 12 disse sobre duas slices sobre o mesmo array vale aqui também, inclusive um `append`
dentro da função escrevendo na capacidade sobrando que pertence a quem chamou.

Então uma função variádica que só lê os argumentos pode ser chamada de qualquer um dos dois
jeitos. **Uma que escreve neles deve dizer isso na documentação**, porque quem passa uma slice com
`...` vê as escritas e quem lista valores não vê.
