---
title: Endereços, & e *
version: 1
---

Quem já viu ponteiros em C costuma chegar com um aviso junto: ponteiros são onde programas quebram,
leem memória que já foi liberada e passam do fim de um array. **Um ponteiro em Go é um endereço com
um tipo, e a linguagem deixa de fora o que tornava os de C perigosos**: não há aritmética com ele, e
a variável para a qual ele aponta continua viva enquanto o ponteiro existir. O que sobra é a única
coisa de que a lição 22 precisava e não tinha, um jeito de uma função alcançar a variável de quem
chamou em vez de uma cópia dela:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc double(n *int) {\n\t*n = *n * 2\n}\n",
      "note": "**`*int` é o tipo \"ponteiro para um `int`\".** O parâmetro continua sendo uma cópia, como a lição 22 disse, e o que ele copia é um endereço. `*n` segue esse endereço, então `*n = *n * 2` lê o `int` que está do outro lado, dobra e escreve de volta lá."
    },
    {
      "code": "\nfunc main() {\n\tx := 21\n\tp := &x\n\tfmt.Printf(\"%T\\n\", p)\n\tfmt.Println(*p, p == &x)\n",
      "note": "**`&x` é o endereço de `x`**, e `%T` imprime o seu tipo, `*int`. `*p` lê `x` através dele: 21. Dois ponteiros são iguais quando levam à mesma variável, então `p == &x` é `true`."
    },
    {
      "code": "\n\t*p = 30\n\tfmt.Println(x)\n",
      "note": "Escrever através de `p` escreve em `x`. Nada atribuiu a `x` pelo nome, e ele imprime 30."
    },
    {
      "code": "\n\tdouble(&x)\n\tfmt.Println(x)\n}\n",
      "note": "O conserto do `double` da lição 22: passe o endereço, e a função escreve na variável de quem chamou. `x` agora vale 60."
    }
  ],
  "output": "*int\n21 true\n30\n60"
}
```

```
ana@vm:~/pointers$ go run .
*int
21 true
30
60
```

O asterisco faz dois trabalhos, e distinguir os dois é quase toda a leitura. **Num tipo, `*int` diz
"ponteiro para um `int`"; numa expressão, `*p` segue o ponteiro até a variável do outro lado.** O
`&` só aparece em expressões, e vai no sentido contrário: de uma variável para o seu endereço. `*p`
é uma variável por direito próprio, então pode ficar à esquerda do `=`, como em `*p = 30`.

## nil: o ponteiro para nada

Um ponteiro declarado sem valor é `nil`, o valor zero de todo tipo ponteiro. Imprimi-lo não faz mal.
Segui-lo, sim:

```go
package main

import "fmt"

func main() {
	var p *int
	fmt.Println(p == nil, p)
	fmt.Println(*p)
}
```

```
ana@vm:~/pointers-nil$ go run .
true <nil>
panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x0 pc=0x499e46]

goroutine 1 [running]:
main.main()
	/home/ana/pointers-nil/main.go:8 +0x66
exit status 2
```

`addr=0x0` é o endereço que o programa tentou ler: nil, que variável nenhuma jamais tem. O
processador recusou, o sistema operacional mandou o sinal `SIGSEGV`, e o runtime de Go o
transformou no panic da linha de cima, apontando a linha 8, onde está o `*p`. As lições 36 e 37
leem panics e os seus rastros por inteiro. **Um ponteiro nil pode ser impresso e comparado, e
segui-lo interrompe o programa.** Por trás do panic há um ponteiro que algum caminho do código nunca
preencheu, e é por isso que um ponteiro que pode ser nil é testado com `p != nil` antes que algo o
siga.

## Sem aritmética

Em C, `p + 1` é o elemento depois daquele para o qual `p` aponta, que é como um laço percorre um
array e como ele passa do fim. Go recusa as duas grafias:

```go
package main

import "fmt"

func main() {
	nums := [3]int{10, 20, 30}
	p := &nums[0]
	p++
	q := p + 1
	fmt.Println(*p, *q)
}
```

```
ana@vm:~/pointers-arith$ go run .
# example.com/arith
./main.go:8:2: invalid operation: p++ (non-numeric type *int)
./main.go:9:7: invalid operation: p + 1 (mismatched types *int and untyped int)
```

Para o compilador um ponteiro não é um número, então não tem `++` nem `+`. Para andar por um array
você o indexa, `nums[1]`, e as verificações de limite das lições 11 e 12 vêm junto com o índice. A
biblioteca padrão tem, sim, um jeito de somar a um endereço, `unsafe.Add`, no pacote cujo nome é o
aviso; nada neste curso precisa dele.

## Devolvendo o endereço de uma variável local

Em C, uma função que devolve o endereço de uma das suas próprias variáveis locais devolve um bug: a
memória da variável é reaproveitada assim que a função retorna. Em Go é uma coisa comum de escrever:

```go
package main

import "fmt"

func newCounter() *int {
	n := 0
	return &n
}

func main() {
	a := newCounter()
	b := newCounter()
	*a++
	*a++
	*b++
	fmt.Println(*a, *b, a == b)
}
```

```
ana@vm:~/pointers-local$ go run .
2 1 false
```

Cada chamada criou um `n` novo e devolveu o endereço dele, então `a` e `b` levam a dois contadores
diferentes: um incrementado duas vezes, o outro uma. **Uma variável em Go vive enquanto algo ainda
puder alcançá-la**, seja qual for a função em que foi declarada. Como o compilador arranja isso, e o
que custa, é a lição 24.
