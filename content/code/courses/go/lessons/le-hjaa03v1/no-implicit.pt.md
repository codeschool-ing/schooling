---
title: Dois números que não se somam
version: 1
---

A maioria das linguagens que você talvez conheça converte números em silêncio quando dois de tipos
diferentes se encontram. C transforma um `int` em `long` antes de somar, Java alarga um `int` para
`double`, JavaScript tem um tipo de número só, para começo de conversa. O hábito que isso deixa é
esperar que quaisquer dois números se somem. **Go não converte um valor de um tipo para outro a
menos que você escreva a conversão**, e da primeira vez essa regra parece o compilador fazendo
birra.

Aqui estão três variáveis de três tipos numéricos, e duas linhas que as combinam:

```go
package main

import "fmt"

func main() {
	var count int = 3
	var total int64 = 10
	var price float64 = 2.5

	fmt.Println(total + count)
	fmt.Println(price * count)
}
```

```
ana@vm:~/convert$ go run .; echo $?
# example.com/convert
./main.go:10:14: invalid operation: total + count (mismatched types int64 and int)
./main.go:11:14: invalid operation: price * count (mismatched types float64 and int)
1
```

As duas linhas são recusadas, e a primeira merece uma segunda olhada. A lição 7 mostrou que `int`
tem 64 bits nesta máquina, exatamente a largura de `int64`, então nenhum valor se perderia na soma.
**O compilador não está conferindo tamanhos, está conferindo tipos**, e `int` e `int64` são dois
tipos diferentes, seja qual for a largura. O mesmo programa precisa compilar numa máquina em que
`int` tem 32 bits, e uma regra que dependesse da máquina o faria compilar numa e falhar na outra.

A correção é dizer em que tipo a conta acontece, convertendo um dos lados:

```go
	fmt.Println(total + int64(count))
	fmt.Println(price * float64(count))
```

```
ana@vm:~/convert-fixed$ go run .
13
7.5
```

`int64(count)` é uma conversão: o valor de `count`, como `int64`. A seção 03 trata do que isso faz
com um valor; o que importa aqui é que ela está escrita na linha, onde quem lê
`total + int64(count)` vê que dois tipos se encontraram e qual deles ganhou.

## Por que o compilador insiste

Uma conversão implícita é uma decisão que a linguagem toma por você, numa linha que não a mostra.
Em C, comparar um `-1` com sinal com um `1` sem sinal converte o `-1` num número positivo enorme
antes, e então `-1 < 1u` é falso. Go elimina esse tipo de surpresa recusando-se a escolher. O custo
é escrever um pouco mais em contas com tipos misturados. Em troca, **todo lugar onde dois tipos se
encontram fica visível no código**, e em geral é justamente ali que um bug de unidade ou de
precisão se esconderia.

## As constantes são a exceção

Se todo número tivesse de ser convertido, `price * 3` precisaria virar `price * float64(3)`, e
ninguém aguentaria. A lição 5 mostrou que uma constante escrita sem tipo é **sem tipo** (*untyped*),
e uma constante sem tipo assume o tipo do que encontrar, desde que o valor caiba. Uma constante
declarada com tipo abriu mão disso:

```go
package main

import "fmt"

func main() {
	var price float64 = 2.5
	count := 3
	const n = 3
	const m int = 3

	fmt.Println(price * 3)
	fmt.Println(price * n)
	fmt.Println(price * m)
	fmt.Println(count * 2.5)
}
```

```
ana@vm:~/convert-const$ go run .
# example.com/convert-const
./main.go:13:14: invalid operation: price * m (mismatched types float64 and int)
./main.go:14:22: 2.5 (untyped float constant) truncated to int
```

O compilador apontou as linhas 13 e 14 e mais nenhuma, então as linhas 11 e 12 foram aceitas: o
literal `3` e a constante `n` viraram `float64` para encontrar `price`. A linha 13 é recusada pelo
mesmo motivo que `price * count` lá em cima, porque `m` agora é um `int`, constante ou não.

A linha 14 é a outra metade da regra. `2.5` é sem tipo, então tenta virar `int` para encontrar
`count`, e não consegue sem perder o `.5`. **Uma constante sem tipo só se converte quando o valor
sobrevive à viagem**, e o compilador diz `truncated` em vez de multiplicar por 2 em silêncio. Se
você queria 7.5, a conversão vai em `count`: `float64(count) * 2.5`.
