---
title: Quando um parâmetro de tipo é a ferramenta errada
version: 1
---

Quando uma linguagem tem generics, um reflexo comum é tornar genérica toda função que poderia ser,
com o argumento de que não custa nada e talvez ajude um dia. **Custa alguma coisa em cada linha**:
uma assinatura genérica é mais difícil de ler que uma comum, e um parâmetro de tipo que só representa
um tipo é esse custo pago por nada. A lição 14 encontrou esta assinatura:

```
ana@vm:~/generics-std$ go doc maps.Keys | head -3
package maps // import "maps"

func Keys[Map ~map[K]V, K comparable, V any](m Map) iter.Seq[K]
```

Três parâmetros de tipo e duas restrições, para que um único `Keys` sirva para todo map de todo
programa. Para a biblioteca padrão, que milhares de programas chamam, é uma boa troca. Uma função do
seu próprio programa, chamada de dois lugares com um `map[string]int`, fica mais clara como
`func keys(m map[string]int) []string`.

Então a ordem do trabalho é a que a seção 02 seguiu. **Escreva a função para o tipo que você tem.**
Quando aparece uma segunda cópia e o `diff` entre as duas mostra só tipos, como mostrou para
`SumInts` e `SumFloats`, esse é o momento de escrever `Sum[T]`. A duplicação é a evidência, e sem ela
o parâmetro de tipo é um palpite sobre o futuro.

## Contêineres e algoritmos, ou comportamento

A linha útil passa entre dois tipos de código.

**Código genérico faz a mesma coisa qualquer que seja o tipo.** Somar, ordenar, buscar numa slice,
juntar as chaves de um map: o código move valores de um lado para o outro e os compara, e nunca
pergunta o que eles são. Um **contêiner** é o segundo caso: uma pilha, uma fila, um cache, qualquer
estrutura que guarda valores de um tipo e os devolve. A lição 31 constrói um `Stack[T]`.

**Código de interface faz uma coisa diferente para cada tipo.** Uma função que escreve num
`io.Writer` não se importa se os bytes vão parar num arquivo ou num buffer; ela chama `Write` e o tipo
decide o que isso quer dizer. Isso é comportamento, e a lição 27 mostrou que interfaces são a
ferramenta para ele.

Os dois se parecem quando uma restrição tem um método, porque uma interface também pode ser
restrição. `~/generics-when` escreve a mesma função dos dois jeitos: uma vez com um parâmetro de
tipo restrito por `fmt.Stringer`, outra com um parâmetro `fmt.Stringer` comum. Depois chama cada uma
com dois tipos que têm método `String`, o `Celsius` da lição 10, que aqui ganha um próprio, e um
`time.Duration`.

```go
package main

import (
	"fmt"
	"time"
)

type Celsius float64

func (c Celsius) String() string {
	return fmt.Sprintf("%.1fC", float64(c))
}

func ShowAll[T fmt.Stringer](items ...T) {
	for _, it := range items {
		fmt.Println(it.String())
	}
}

func ShowEach(items ...fmt.Stringer) {
	for _, it := range items {
		fmt.Println(it.String())
	}
}

func main() {
	room := Celsius(21.5)
	wait := 90 * time.Second
	ShowEach(room, wait)
	ShowAll(room, wait)
}
```

```
ana@vm:~/generics-when$ go run .
# example.com/generics-when
./main.go:30:16: in call to ShowAll, type time.Duration of wait does not match inferred type Celsius for T
```

`ShowEach` não reclamou. `ShowAll` reclamou, e a mensagem diz por quê: **um parâmetro de tipo
representa um único tipo por chamada**. O compilador concluiu que `T` era `Celsius` pelo primeiro
argumento, e então `wait` era de outro tipo. Para o `Sum` essa regra é exatamente a certa, porque
somar um `Celsius` com um `time.Duration` é o erro de unidade que a lição 10 tornou impossível. Para
imprimir, é uma restrição sem propósito: a função só chama `String`, e os dois tipos têm um.

Com a última chamada trocada por `ShowAll(room, room+1)`, dois valores de um mesmo tipo, as duas
funções rodam:

```
ana@vm:~/generics-when$ go run .
21.5C
1m30s
21.5C
22.5C
```

`ShowAll` não sabe fazer nada a mais que `ShowEach` e aceita menos. **Quando o corpo só chama
métodos, a interface comum diz a mesma coisa com menos colchetes e aceita mais chamadores.**

Três sinais de que um parâmetro de tipo não está se pagando:

- ele aparece uma vez na assinatura, como tipo de um parâmetro. uma função `F[T fmt.Stringer]` cujo
  único parâmetro é `v T` faz o trabalho de `func F(v fmt.Stringer)`;
- todo chamador do programa usa o mesmo tipo para ele;
- o corpo pergunta qual é o tipo, com um type switch sobre o valor. É o `SumAny` da seção 02 de novo,
  e devolve a conferência em tempo de execução que os parâmetros de tipo existem para eliminar.

E os sinais de que está: um contêiner que guarda valores de um tipo escolhido por quem chama, ou um
algoritmo sobre slices, maps ou valores que de outro modo seria copiado uma vez por tipo. Nos dois
casos o parâmetro de tipo aparece mais de uma vez, ligando um argumento a outro argumento ou ao
resultado, como `T` ligou o `[]T` que entra no `Sum` ao `T` que sai.
