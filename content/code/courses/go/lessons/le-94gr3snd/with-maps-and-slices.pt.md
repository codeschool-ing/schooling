---
title: Ponteiros, maps e slices
version: 1
---

A lição 22 mostrou que um valor de map e um valor de slice já carregam um ponteiro, e é por isso que
uma função consegue mudar as chaves de um map ou os elementos de uma slice sem receber endereço
nenhum. Os ponteiros desta lição encontram esses dois tipos em três lugares, e cada um tem uma regra
que parece arbitrária até você ver o que há por baixo.

## Uma função que faz o append por quem chamou

O `addFour` da lição 11 fazia append na sua cópia de uma slice, e o comprimento de quem chamou ficava
em 3. Um ponteiro para a slice resolve isso pelo outro lado: a função recebe o endereço da variável
slice de quem chamou e guarda ali o resultado do `append`.

```go
package main

import "fmt"

func addTo(s *[]int, v int) {
	*s = append(*s, v)
}

func main() {
	nums := []int{1, 2, 3}
	addTo(&nums, 4)
	fmt.Println(nums, len(nums))
}
```

```
ana@vm:~/pointers-append$ go run .
[1 2 3 4] 4
```

`*s` é o próprio `nums` de quem chamou, então atribuir a ele muda o comprimento de quem chamou e,
quando o `append` precisou mudar de lugar, também o ponteiro de quem chamou. Funciona, e **o hábito
da biblioteca padrão é o outro formato, uma função que devolve a slice nova**: o `append` faz assim,
e o `slices.Insert` também, cuja assinatura o `go doc slices.Insert` imprime como
`func Insert[S ~[]E, E any](s S, i int, v ...E) S`. Uma slice devolvida mostra a mudança na chamada,
como `nums = withFour(nums)` fez na lição 11, que é o mesmo argumento que a lição 22 fez para
structs.

Onde `*[]T` aparece de fato é como argumento de uma função que preenche o que você entrega a ela. O
`json.Unmarshal(data, &list)` recebe o endereço de `list` porque precisa definir a slice, com
comprimento e tudo; a documentação dele diz que devolve um erro quando o valor não é um ponteiro.
JSON é a lição 15.

## Um elemento de map não tem endereço

Um elemento de slice é uma variável para a qual você pode apontar. Um elemento de map, não:

```go
package main

import "fmt"

type Player struct {
	Name  string
	Score int
}

func main() {
	nums := []int{1, 2, 3}
	n := &nums[0]

	ages := map[string]int{"ana": 30}
	a := &ages["ana"]

	players := map[string]Player{"ana": {Name: "Ana", Score: 10}}
	players["ana"].Score = 11

	fmt.Println(*n, *a)
}
```

```
ana@vm:~/pointers-map$ go run .
# example.com/mapaddr
./main.go:15:8: invalid operation: cannot take address of ages["ana"] (map index expression of type int)
./main.go:18:2: cannot assign to struct field players["ana"].Score in map
```

A linha 12, `&nums[0]`, compilou; só as duas linhas de map foram recusadas. A razão está no
runtime, não na gramática. **Um map muda as suas entradas de lugar quando cresce**: `grow`, em
`/usr/local/go/src/internal/runtime/maps/table.go`, aloca uma tabela nova, põe nela cada elemento da
antiga e descarta a antiga. Um ponteiro para um elemento levaria então a uma tabela que o map não
usa mais, e por isso o compilador não deixa você criar um. A linha 18 é a mesma regra numa forma que
surpreende mais gente: mudar um campo de uma struct guardada num map exigiria essa struct como
variável, e `players["ana"]` é um valor lido do map, não uma variável.

Há dois jeitos de contornar, e os dois aparecem em código de verdade:

```go
package main

import "fmt"

type Player struct {
	Name  string
	Score int
}

func main() {
	players := map[string]Player{"ana": {Name: "Ana", Score: 10}}
	p := players["ana"]
	p.Score++
	players["ana"] = p
	fmt.Println(players["ana"])

	byName := map[string]*Player{"ana": {Name: "Ana", Score: 10}}
	byName["ana"].Score++
	fmt.Println(*byName["ana"])
}
```

```
ana@vm:~/pointers-mapfix$ go run .
{Ana 11}
{Ana 11}
```

O primeiro lê a struct como cópia, muda a cópia e a guarda de volta. O segundo guarda ponteiros no
map, então o map muda ponteiros de lugar quando cresce e os jogadores ficam onde estão;
`byName["ana"].Score++` segue o ponteiro até uma struct que é uma variável. Dentro do literal,
`{Name: "Ana", Score: 10}` é abreviação de `&Player{...}`, porque o tipo do elemento do map já diz
que ele é um ponteiro.

## Um ponteiro para dentro de uma slice pode ficar para trás

Um elemento de slice tem endereço, sim, e esse endereço pertence a um array específico. A lição 12
mostrou o `append` levando uma slice cheia para um array novo. Um ponteiro obtido antes da mudança
não vai junto:

```go
package main

import "fmt"

func main() {
	nums := []int{1, 2, 3}
	first := &nums[0]
	*first = 10
	fmt.Println(nums, len(nums), cap(nums))

	nums = append(nums, 4)
	*first = 100
	fmt.Println(nums, *first, first == &nums[0])
}
```

```
ana@vm:~/pointers-stale$ go run .
[10 2 3] 3 3
[10 2 3 4] 100 false
```

Antes do append, `first` e `nums[0]` são um mesmo `int`, e escrever 10 pelo ponteiro aparece na
slice. A slice está cheia, comprimento 3 e capacidade 3, então o `append` copia os três elementos
para um array novo e acrescenta o 4 lá. Depois disso, `*first = 100` escreve no array antigo,
`nums[0]` continua lendo 10, e `first == &nums[0]` é `false`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Antes do append, nums enxerga um array de três ints, 10, 2 e 3, e first aponta para o elemento 0 dele. O array está cheio, então o append copia 10, 2 e 3 para um array novo e acrescenta 4 lá, e nums passa a apontar para o array novo. first continua apontando para o elemento 0 do array antigo, então *first = 100 escreve no array antigo, e nums[0] continua 10.\"><defs><marker id=\"ps-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"ps-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ps-phosphor-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">nums = append(nums, 4)</text><text x=\"20\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">*first = 100</text><text x=\"260\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o array antigo</text><rect x=\"260\" y=\"70\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></rect><text x=\"284.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">100</text><rect x=\"308\" y=\"70\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"332.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"356\" y=\"70\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><rect x=\"40\" y=\"120\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">first</text><text x=\"116\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">•</text><path d=\"M118 135 L225 135 L225 85 L256 85\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#ps-amber)\"></path><path d=\"M284 102 L284 196\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ps-phosphor-dim)\"></path><path d=\"M332 102 L332 196\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ps-phosphor-dim)\"></path><path d=\"M380 102 L380 196\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ps-phosphor-dim)\"></path><text x=\"418\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">copiado pelo append</text><text x=\"246\" y=\"215\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um array novo</text><rect x=\"260\" y=\"200\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"284.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10</text><rect x=\"308\" y=\"200\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"332.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"356\" y=\"200\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><rect x=\"404\" y=\"200\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><rect x=\"40\" y=\"240\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">nums</text><text x=\"116\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">•</text><path d=\"M118 255 L284 255 L284 234\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#ps-phosphor)\"></path><text x=\"480\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nums foi para o array novo;</text><text x=\"480\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">first continua apontando para o antigo,</text><text x=\"480\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">então o 100 cai onde nums não olha mais</text></svg>", "caption": "Um ponteiro para um elemento de slice aponta para dentro de um array específico. Quando o append precisa mudar a slice de lugar, o ponteiro fica para trás."}
```

Nada quebrou, e nada vai quebrar: o array antigo continua vivo enquanto `first` apontar para dentro
dele, então o programa segue escrevendo numa memória que nenhuma slice mostra. **Um ponteiro para um
elemento de slice só vale até o próximo `append` que possa mudar a slice de lugar**, e o hábito
seguro é guardar o índice, `0`, e ler `nums[0]` de novo quando precisar.
