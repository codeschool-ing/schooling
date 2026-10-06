---
title: Como o `append` faz uma slice crescer
version: 1
---

Uma slice costuma ser descrita como um array dinâmico que se redimensiona sozinho, e essa descrição
esconde a única coisa que vale saber. **Nada numa slice se redimensiona. Quando o array enche, o
`append` aloca um array novo e maior, copia todos os elementos para ele e devolve uma slice sobre a
cópia.** O array antigo fica onde estava. A documentação da própria função embutida diz isso, e não
diz nada sobre quanto maior:

```
ana@vm:~/slices-grow$ go doc builtin.append
package builtin // import "builtin"

func append(slice []Type, elems ...Type) []Type
    The append built-in function appends elements to the end of a slice.
    If it has sufficient capacity, the destination is resliced to accommodate
    the new elements. If it does not, a new underlying array will be allocated.
    Append returns the updated slice. It is therefore necessary to store the
    result of append, often in the variable holding the slice itself:

        slice = append(slice, elem1, elem2)
        slice = append(slice, anotherSlice...)

    As a special case, it is legal to append a string to a byte slice, like
    this:

        slice = append([]byte("hello "), "world"...)

```

"It is therefore necessary to store the result" é a regra a que a lição 11 chegou pelo outro lado.
Um array novo significa um ponteiro novo na slice, e só a slice que o `append` devolve tem esse
ponteiro.

## Vendo acontecer

Este programa acrescenta 2.000 números, um de cada vez, e imprime uma linha sempre que a capacidade
muda. O laço `for` é assunto da lição 17; leia como "para cada `i` de 0 a 1999".

```go
package main

import "fmt"

func main() {
	var s []int
	last := -1
	for i := 0; i < 2000; i++ {
		s = append(s, i)
		if cap(s) != last {
			fmt.Printf("len %4d  cap %4d\n", len(s), cap(s))
			last = cap(s)
		}
	}
}
```

```
ana@vm:~/slices-grow$ go run .
len    1  cap    4
len    5  cap    8
len    9  cap   16
len   17  cap   32
len   33  cap   64
len   65  cap  128
len  129  cap  256
len  257  cap  512
len  513  cap  848
len  849  cap 1280
len 1281  cap 1792
len 1793  cap 2560
```

Dois mil appends e doze linhas: a capacidade mudou doze vezes, então o `append` criou doze arrays
e copiou para cada um deles. Todos os outros appends escreveram em espaço que já existia, e é por
isso que acrescentar um elemento de cada vez não é o desastre que parece. A tabela se lê em três
partes.

**De 8 a 512, cada array novo tem o dobro do anterior.** É a regra que está no código-fonte do
runtime, que vem junto com o toolchain, numa função chamada `nextslicecap`:

```
ana@vm:~/slices-grow$ grep -n "^func nextslicecap" -A 15 /usr/local/go/src/runtime/slice.go
326:func nextslicecap(newLen, oldCap int) int {
327-	newcap := oldCap
328-	doublecap := newcap + newcap
329-	if newLen > doublecap {
330-		return newLen
331-	}
332-
333-	const threshold = 256
334-	if oldCap < threshold {
335-		return doublecap
336-	}
337-	for {
338-		// Transition from growing 2x for small slices
339-		// to growing 1.25x for large slices. This formula
340-		// gives a smooth-ish transition between the two.
341-		newcap += (newcap + 3*threshold) >> 2
```

Abaixo de capacidade 256 a resposta é `doublecap`. De 256 em diante, a linha 341 soma um quarto da
capacidade mais 192 (`3*threshold` é 768, e `>> 2` divide por quatro), então o fator cai de 2 em
direção a 1,25 conforme a slice cresce. Em 256 exatos isso ainda dá 512, e é por isso que o append
de número 257 também dobrou. As linhas 329 e 330 cuidam de acrescentar muitos elementos de uma vez:
se nem o dobro bastar, a capacidade nova é simplesmente o comprimento pedido.

**Depois de 512 os números deixam de ser redondos, e a fórmula não é o motivo.** Ela diz
`512 + (512 + 768) / 4`, que dá 832. Mas 832 `int`s são 6.656 bytes, e o alocador de memória de Go
não entrega qualquer tamanho que você pedir; ele arredonda para cima, para uma lista fixa de
**classes de tamanho**. A lista também está no código-fonte:

```
ana@vm:~/slices-grow$ sed -n "6p;53,55p" /usr/local/go/src/internal/runtime/gc/sizeclasses.go
// class  bytes/obj  bytes/span  objects  tail waste  max waste  min align
//    47       6144       24576        4           0     12.48%       2048
//    48       6528       32768        5         128      6.23%        128
//    49       6784       40960        6         256      4.36%        128
```

6.528 bytes não cabem 6.656, então o array tem 6.784 bytes, e o `append` usa tudo: 6.784 dividido
por 8 bytes por `int` dá 848. O mesmo arredondamento transforma os 1.252 da fórmula em 1.280 na
linha seguinte.

## A primeira linha é do compilador

A regra começaria em 1 para o primeiro elemento, e a tabela começa em 4. Esse primeiro array foi
escolhido antes de o runtime ser consultado: o compilador dá a uma slice que nunca sai da sua função
um buffer de 32 bytes para os primeiros elementos, e 32 bytes comportam quatro `int`s. Acrescente
uma linha no fim que guarda `s` numa variável de pacote, e o mesmo laço começa diferente:

```
ana@vm:~/slices-grow-kept$ go run . | head -6
len    1  cap    1
len    2  cap    2
len    3  cap    3
len    4  cap    4
len    5  cap    8
len    9  cap   16
```

Onde um valor mora, e como o compilador decide isso, é a lição 24. O ponto aqui é mais estreito:
**as capacidades são escolhidas pelo compilador e pelo runtime do Go que você está rodando, e nenhum
programa deve depender delas.** A documentação promete um array grande o bastante e mais nada.
Código que precisa de uma capacidade diz isso, com `make`, que é a seção 04.
