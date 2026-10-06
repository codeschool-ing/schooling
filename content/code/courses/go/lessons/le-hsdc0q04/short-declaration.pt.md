---
title: A forma curta, e o que ela recusa
version: 1
---

`:=` parece o operador de atribuição do Pascal, e quem conhece `=` de outras linguagens o lê como
"atribuir". **Em Go, `:=` declara, e `=` só atribui.** `name := "Ana"` cria uma variável chamada
`name`, dá a ela o tipo de `"Ana"` e guarda o valor, tudo num passo só. É o mesmo que
`var name = "Ana"`, e é a forma que quase todo código Go usa dentro de funções:

```go
package main

import "fmt"

func main() {
	name := "Ana"
	count := 3
	ratio := 1
	exact := 1.0
	x, y := 1, 2
	y, z := 3, 4

	fmt.Println(name, count, x, y, z)
	fmt.Printf("%T %T %T\n", count, ratio, exact)
}
```

```
ana@vm:~/vars-short$ go run .
Ana 3 1 3 4
int int float64
```

Os tipos vêm dos valores, como no `var` sem tipo: `1` dá um `int` e `1.0` um `float64`. É por isso
que a seção 02 precisou de `var` com tipo para ter um `float64` guardando 1.

A penúltima declaração é a que vale ler duas vezes. `y, z := 3, 4` tem `y` do lado esquerdo, e `y`
já existe. **`:=` com vários nomes exige que pelo menos um deles seja novo, e os outros são
simplesmente atribuídos.** Então `z` foi criada, `y` passou a valer 3, e o `fmt.Println` imprimiu
`1 3 4` para `x`, `y` e `z`. A regra mostra o seu valor a partir da lição 32, onde quase toda
chamada devolve um resultado e um erro, e uma função faz várias chamadas assim em sequência com o
mesmo `err`.

## Três recusas

`:=` é um comando, e comandos moram dentro de funções. No nível do pacote só cabem declarações, as
linhas que começam com `var`, `const`, `type`, `func` ou `import`, então a forma curta falha ali
antes de o compilador sair da análise sintática:

```go
package main

import "fmt"

port := 8080

func main() {
	fmt.Println(port)
}
```

```
ana@vm:~/vars-outside$ go run .; echo $?
# example.com/vars-outside
./main.go:5:1: syntax error: non-declaration statement outside function body
1
```

Linha 5, coluna 1: o começo de `port`. A correção é `var port = 8080`, que é uma declaração.

A segunda recusa é `:=` sem nada novo do lado esquerdo. `n` já existe aqui, então não há o que
declarar:

```go
package main

import "fmt"

func main() {
	n := 1
	n := 2
	fmt.Println(n)
}
```

```
ana@vm:~/vars-again$ go run .; echo $?
# example.com/vars-again
./main.go:7:4: no new variables on left side of :=
1
```

A coluna 4 é onde o `:=` fica na linha 7. **O que se queria era quase sempre `n = 2`**, uma
atribuição à variável que já está lá, e a mensagem aponta os dois caracteres a trocar.

A terceira é a que a lição 4 prometeu. Uma variável declarada dentro de uma função e nunca lida é
erro de compilação, seja qual for a forma que a declarou:

```go
package main

import "fmt"

var spare = "never read"

func main() {
	total := 10
	count := 3
	fmt.Println(total)
}
```

```
ana@vm:~/vars-unused$ go run .; echo $?
# example.com/vars-unused
./main.go:9:2: declared and not used: count
1
```

`count` foi recusada e `spare` não. **A regra vale só para variáveis dentro de funções**; uma no
nível do pacote pode ficar sem ser lida sem reclamação. Dentro de uma função, uma variável não usada
é quase sempre um engano, como um resultado que você queria imprimir ou um erro de digitação no
nome de outra que você usou, e o compilador a trata como tal.

## Uma variável nova onde você queria a velha

`:=` declara uma variável nova no bloco em que foi escrito, mesmo quando existe uma variável de
mesmo nome fora desse bloco. Isso se chama **sombreamento** (shadowing), e é a origem de um bug
clássico de Go, em que um `err` definido dentro do corpo de um laço nunca chega ao `err` de fora. A lição 6
trata de blocos e escopo e mostra esse bug capturado. Por ora, o hábito que o evita é o de cima:
quando um nome já existe e você quer mudá-lo, escreva `=`.

Então, dentro de uma função, `:=` é o padrão e `var` fica para os três casos da seção 02. Fora de
uma função, `var` é tudo o que há.
