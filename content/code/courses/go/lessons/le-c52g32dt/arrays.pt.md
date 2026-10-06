---
title: Um array é o seu comprimento
version: 1
---

Para quem vem de Python ou JavaScript, a palavra *array* quer dizer uma lista que cresce quando
você acrescenta algo. **Um array em Go tem um número fixo de elementos, e esse número faz parte do
tipo.** `[3]int` e `[4]int` são tão diferentes para o compilador quanto `int` e `string`, e todo o
resto sobre arrays decorre disso. Um programa mostra as quatro coisas que importam:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc zero(a [3]int) {\n\ta[0] = 0\n}\n",
      "note": "Uma função que recebe um array de três `int` e zera o primeiro elemento. O tipo do parâmetro se escreve `[3]int`, com o comprimento na frente."
    },
    {
      "code": "\nfunc main() {\n\ta := [3]int{1, 2, 3}\n\tfmt.Printf(\"%v %T %d\\n\", a, a, len(a))\n",
      "note": "**O comprimento faz parte do tipo.** `%T` imprime `[3]int`, e `len(a)` vale 3 enquanto o programa rodar: um array nunca cresce nem encolhe."
    },
    {
      "code": "\n\tb := a\n\tb[0] = 99\n\tfmt.Println(a, b)\n",
      "note": "**Atribuir um array copia todos os elementos.** `b` é um segundo array, então mudá-lo deixa `a` como estava: a saída é `[1 2 3] [99 2 3]`."
    },
    {
      "code": "\n\tfmt.Println(a == [3]int{1, 2, 3}, a == b)\n",
      "note": "Dois arrays do mesmo tipo se comparam com `==`, elemento a elemento. `a` é igual a um `[3]int{1, 2, 3}` novo e já não é igual a `b`."
    },
    {
      "code": "\n\tzero(a)\n\tfmt.Println(a)\n}\n",
      "note": "**Uma função recebe a sua própria cópia do array.** `zero` mudou o primeiro elemento dessa cópia, e o `a` de `main` continua começando com 1."
    }
  ],
  "output": "[1 2 3] [3]int 3\n[1 2 3] [99 2 3]\ntrue false\n[1 2 3]"
}
```

Então um array se comporta como um valor único que por acaso tem partes, do jeito que um `int` se
comporta. Copiar, comparar e passar para uma função funcionam sobre ele inteiro de uma vez.

## O que o compilador sabe sobre um array

Como o comprimento está no tipo, o compilador o conhece durante a compilação, e três enganos são
pegos antes de qualquer coisa rodar:

```go
package main

import "fmt"

func main() {
	a := [3]int{1, 2, 3}
	b := [4]int{1, 2, 3, 4}
	a = b

	n := len(b)
	var c [n]int

	fmt.Println(a[3], c, n)
}
```

```
ana@vm:~/arrays-type$ go run .
# example.com/arrays-type
./main.go:8:6: cannot use b (variable of type [4]int) as [3]int value in assignment
./main.go:11:9: invalid array length n
./main.go:13:16: invalid argument: index 3 out of bounds [0:3]
```

A linha 8 é a regra do tipo: um `[4]int` não cabe onde vai um `[3]int`. A linha 11 diz que o
comprimento precisa ser uma constante, porque um tipo não pode depender de um valor que o programa
calcula enquanto roda; `n` vale 4, e o compilador recusa mesmo assim. A linha 13 lê o quarto
elemento de um array de três, e como o índice e o comprimento são constantes, o compilador consegue
ver que passou do fim. `[0:3]` é o jeito dele de dizer que os índices válidos começam em 0 e param
antes de 3.

Essa última é a melhor qualidade dos arrays. **Um índice constante é conferido contra o comprimento
durante a compilação**, e uma classe inteira de bugs de índice fora do intervalo nunca chega a
rodar.

## Por que você raramente vê um

Um comprimento fixo é uma promessa forte, e a maioria dos dados não a cumpre: uma lista de
usuários, as linhas de um arquivo e os resultados de uma busca têm um comprimento que ninguém
conhece de antemão. Uma função escrita para `[3]int` nem pode ser chamada com um `[4]int`. É por
isso que código Go comum é cheio de slices, a seção 03, e usa arrays onde o tamanho faz mesmo parte
do que o dado é. Um hash SHA-256 tem sempre 32 bytes, e a lição 13 mostra `sha256.Sum256`
devolvendo um como um array exatamente desse comprimento.
