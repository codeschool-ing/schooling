---
title: byte e rune são números com uma função
version: 1
---

Quem chega de C ou Java procura um tipo `char`, uma letra numa caixinha. Go não tem. **Tem dois
nomes para inteiros, `byte` e `rune`, e uma letra em Go é um desses inteiros.** A documentação na
sua máquina diz isso numa linha cada:

```
ana@vm:~/runes-short$ go doc builtin.byte
package builtin // import "builtin"

type byte = uint8
    byte is an alias for uint8 and is equivalent to uint8 in all ways. It is
    used, by convention, to distinguish byte values from 8-bit unsigned integer
    values.

ana@vm:~/runes-short$ go doc builtin.rune
package builtin // import "builtin"

type rune = int32
    rune is an alias for int32 and is equivalent to int32 in all ways. It is
    used, by convention, to distinguish character values from integer values.

```

O `=` em `type byte = uint8` faz de `byte` um segundo nome para `uint8`, e não um tipo novo; a
lição 10 é onde essa diferença importa. Os dois nomes existem para dizer a quem lê para que serve
um número. Um `byte` é um pedaço de dado bruto, de 0 a 255. Uma `rune` é um **code point**: o
número que o Unicode dá a um caractere, que precisa de mais espaço que um byte porque existem
muito mais de 256 deles.

## Uma letra entre aspas simples é um número

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tvar b byte = 'A'\n\tr := 'A'\n",
      "note": "**Uma letra entre aspas simples é um literal de rune, e o valor dele é o code point da letra**: `'A'` é 65. Declarado como `byte`, ele é guardado num byte; com `:=` e sem tipo, `r` vira uma `rune`."
    },
    {
      "code": "\tfmt.Println(b, r)\n",
      "note": "O `Println` imprime números como números, e os dois são 65."
    },
    {
      "code": "\tfmt.Printf(\"%T %T\\n\", b, r)\n",
      "note": "`%T` dá o nome dos tipos, e diz `uint8` e `int32`: os apelidos são esses tipos, com os nomes que a linguagem deu a eles primeiro."
    },
    {
      "code": "\tfmt.Printf(\"%c %U %q\\n\", r, r, r)\n",
      "note": "Três verbos imprimem um número como texto. `%c` desenha o caractere, `%U` escreve o code point como as tabelas do Unicode escrevem, e `%q` o põe entre aspas como no código Go."
    },
    {
      "code": "\tfmt.Println('a'-'A', 'A'+2)\n\tfmt.Printf(\"%c\\n\", 'A'+2)\n}\n",
      "note": "Como uma rune é um número, aritmética funciona nela. O `a` minúsculo fica 32 code points depois do `A` maiúsculo, e `'A'+2` é 67, que o `%c` desenha como `C`."
    }
  ],
  "output": "65 65\nuint8 int32\nA U+0041 'A'\n32 67\nC"
}
```

Aritmética com letras é antiga e continua útil: `'a' - 'A'` é a distância entre as duas caixas no
ASCII, então somar 32 a uma letra ASCII maiúscula dá a minúscula. Nada disso é truque. O literal de
rune foi um número o tempo todo, e o `%c` é só um jeito de imprimi-lo.

## Uma rune, e quantos bytes

Um code point e os bytes que o guardam são números diferentes, e a primeira letra acentuada mostra
isso:

```go
package main

import "fmt"

func main() {
	e := 'é'
	fmt.Printf("%d %c %U\n", e, e, e)
	fmt.Println(len("e"), len("é"), len("€"), len("\U0001F642"))
	fmt.Printf("% x\n", "é")
	fmt.Printf("% x\n", "€")
}
```

```
ana@vm:~/runes-utf8$ go run .
233 é U+00E9
1 2 3 4
c3 a9
e2 82 ac
```

`'é'` é a rune 233, U+00E9. Ponha a mesma letra numa string e o `len` diz 2, porque **uma string Go
guarda UTF-8, e o UTF-8 gasta de um a quatro bytes por code point**. ASCII puro ocupa um, `é` dois,
o símbolo do euro três, e U+1F642, o rosto levemente sorridente escrito aqui como escape, quatro. O
verbo `% x` imprime os bytes de uma string em hexadecimal, separados por espaço: `é` é guardado
como `c3 a9`, e nenhum dos dois é `e9`, que é 233. A codificação espalha os bits do code point por
dois bytes, com marcas que dizem onde cada caractere começa.

Então `len` numa string conta bytes, não letras. A lição 9 trata das strings em si, inclusive de
como contar as runes delas; esta seção só precisa do fato de que as duas contagens diferem assim
que o texto sai do ASCII.

## Aspas simples, aspas duplas

`'é'` e `"é"` são coisas diferentes: um literal entre aspas simples é uma rune, um número, e um
entre aspas duplas é uma string. Um literal de rune também precisa caber onde você o põe, e duas
destas três declarações não compilam:

```go
package main

import "fmt"

func main() {
	var b byte = 'é'
	var euro byte = '€'
	pair := 'ab'
	fmt.Println(b, euro, pair)
}
```

```
ana@vm:~/runes-quotes$ go run .
# example.com/quotes
./main.go:7:18: cannot use '€' (untyped rune constant 8364) as byte value in variable declaration (overflows)
./main.go:8:10: more than one character in rune literal
```

O símbolo do euro é o code point 8364 e um `byte` vai só até 255, então o compilador recusa, com o
número na mensagem. `'ab'` são dois caracteres onde cabe um. A linha que ele não recusou é a
armadilha: `var b byte = 'é'` compila, porque 233 cabe num byte. **Esse byte guarda o code point,
que não é o jeito como `é` fica guardado numa string** — numa string ele era `c3 a9`. Guarde
caracteres em runes e dados brutos em bytes, e os dois nunca se misturam por acidente.
