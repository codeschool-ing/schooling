---
title: Conjuntos de métodos, e o String que o fmt nunca chama
version: 1
---

O bug da seção 02 pelo menos aparecia na saída, como uma contagem parada em 0. Este muda o que um programa imprime e não
produz erro, nem aviso, nem reclamação do `go vet`. O tipo é uma quantia de dinheiro em centavos
inteiros, e o seu método `String` é declarado no ponteiro:

```go
package main

import "fmt"

type Money struct {
	Cents int64
}

func (m *Money) String() string {
	return fmt.Sprintf("R$ %d,%02d", m.Cents/100, m.Cents%100)
}

func main() {
	price := Money{Cents: 1990}
	fmt.Println(price)
	fmt.Println(&price)
	fmt.Println(price.String())
}
```

```
ana@vm:~/receivers-print$ go run .
{1990}
R$ 19,90
R$ 19,90
ana@vm:~/receivers-print$ go vet; echo $?
0
```

Três linhas que parecem que deveriam concordar, e a primeira ignorou o método. A última é a fácil:
`price.String()` é uma chamada sobre uma variável, então o compilador toma `&price` por você, como a
seção 02 mostrou. As duas primeiras pedem uma frase sobre como o `fmt` encontra um método `String`.

## O que o fmt procura

O `fmt` não conhece o seu tipo. Ele faz uma pergunta a cada valor que imprime, e o `go doc` mostra
a pergunta:

```
ana@vm:~/receivers-print$ go doc fmt.Stringer
package fmt // import "fmt"

type Stringer interface {
	String() string
}
    Stringer is implemented by any value that has a String method, which defines
    the “native” format for that value. The String method is used to print
    values passed as an operand to any format that accepts a string or to an
    unformatted printer such as Print.

```

`fmt.Stringer` é uma **interface**: um tipo descrito só pelos métodos que um valor precisa ter. A
lição 27 trata de interfaces; para esta seção uma frase basta. `fmt.Println` recebe os argumentos
como `...any`, então cada argumento chega como uma cópia, e `handleMethods` em
`/usr/local/go/src/fmt/print.go` pergunta se esse valor satisfaz `Stringer`. Um `*Money` satisfaz.
**Um `Money` não, porque um `Money` não tem método `String`: o método pertence a `*Money`.** Então o
`fmt` recorre a imprimir os campos da struct, `{1990}`, que é uma saída perfeitamente válida e o
motivo de nada ter reclamado.

## O conjunto de métodos

Quais métodos um valor "tem" é uma lista definida, e a linguagem a chama de **conjunto de métodos**
(*method set*) do tipo:

| um valor do tipo | tem estes métodos no seu conjunto de métodos |
|---|---|
| `Money` | os métodos declarados com receptor `Money` |
| `*Money` | os métodos declarados com receptor `Money` **e** com receptor `*Money` |

O ponteiro fica com os dois porque, a partir de um endereço, o compilador sempre alcança o valor e
pode copiá-lo para um método por valor. O valor fica só com os seus porque o outro sentido precisa
de um endereço. A cópia que o `fmt` guarda não tem um que sirva a alguém: ela não é a variável
`price`, e um método de ponteiro que a mudasse mudaria algo que ninguém nunca vai olhar. É o bug da
seção 02 de novo, e **Go não deixa que ele aconteça em silêncio através de uma interface: em vez
disso, deixa os métodos de ponteiro fora do conjunto de métodos do valor.**

O `&` automático da seção 02 não é exceção a isso. Ele vale para uma chamada escrita sobre uma
variável, onde há um endereço. Um valor guardado numa interface não é uma variável que você
escreveu.

## Quando o compilador diz

O `fmt.Println` aceita qualquer coisa, então não tinha motivo para recusar. Peça um `fmt.Stringer`
explicitamente, declarando uma variável desse tipo, e o conjunto de métodos é verificado onde você
pode ver:

```go
package main

import "fmt"

type Money struct {
	Cents int64
}

func (m *Money) String() string {
	return fmt.Sprintf("R$ %d,%02d", m.Cents/100, m.Cents%100)
}

func main() {
	price := Money{Cents: 1990}
	var s fmt.Stringer = price
	fmt.Println(s)
}
```

```
ana@vm:~/receivers-iface$ go build
# example.com/iface
./main.go:15:23: cannot use price (variable of struct type Money) as fmt.Stringer value in variable declaration: Money does not implement fmt.Stringer (method String has pointer receiver)
```

O parêntese no fim é o diagnóstico inteiro. `Money` tem um método `String` no sentido de que
`price.String()` compila, e não tem um no seu conjunto de métodos. `var s fmt.Stringer = &price`
compilaria. Também compilaria a mudança que faz as três linhas do primeiro programa concordarem, um
receptor por valor:

```go
package main

import "fmt"

type Money struct {
	Cents int64
}

func (m Money) String() string {
	return fmt.Sprintf("R$ %d,%02d", m.Cents/100, m.Cents%100)
}

func main() {
	price := Money{Cents: 1990}
	var s fmt.Stringer = price
	fmt.Println(price)
	fmt.Println(&price)
	fmt.Println(s)
}
```

```
ana@vm:~/receivers-value$ go run .
R$ 19,90
R$ 19,90
R$ 19,90
```

`String` só lê a quantia, então nunca precisou de ponteiro. Com receptor por valor ele está no
conjunto de métodos de `Money` e, pela tabela acima, no de `*Money` também, e todo jeito de
imprimir o preço o encontra. **Um método que não muda o seu receptor e é declarado no ponteiro
custa exatamente isto: os valores do tipo deixam de satisfazer interfaces que parecem satisfazer.**
A seção 04 transforma isso numa regra de escolha.
