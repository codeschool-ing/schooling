---
title: Vários resultados, e o que você descarta
version: 1
---

Na maioria das linguagens uma função devolve um valor, e a função que precisa entregar dois os
empacota antes num objeto, num array ou numa tupla. **Uma função Go pode devolver vários valores
diretamente**, e os resultados vêm listados entre parênteses depois dos parâmetros. Nada é
empacotado: quem chama recebe valores separados e dá um nome a cada um.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"strconv\"\n\t\"unicode/utf8\"\n)\n\nfunc divmod(a, b int) (int, int) {\n\treturn a / b, a % b\n}\n",
      "note": "**Dois tipos de resultado entre parênteses, e um `return` com dois valores separados por vírgula.** `divmod` devolve o quociente e o resto de uma divisão inteira, os dois numa chamada só."
    },
    {
      "code": "\nfunc main() {\n\tq, r := divmod(17, 5)\n\tfmt.Println(q, r)\n",
      "note": "Quem chama dá nome aos dois resultados à esquerda do `:=`, na mesma ordem: `q` é 3 e `r` é 2."
    },
    {
      "code": "\tfmt.Println(divmod(17, 5))\n",
      "note": "Uma chamada com vários resultados pode ir direto para outra função quando preenche exatamente os parâmetros dela. `fmt.Println` aceita qualquer quantidade de valores, então imprime os dois."
    },
    {
      "code": "\n\tn, err := strconv.Atoi(\"42\")\n\tfmt.Println(n, err)\n\tn, err = strconv.Atoi(\"42x\")\n\tfmt.Println(n, err)\n",
      "note": "**A forma que você mais vai encontrar: um valor e um `error`.** `strconv.Atoi` converte texto em `int`. Quando dá certo, `err` é `nil`; quando não consegue, `n` é 0 e `err` diz por quê."
    },
    {
      "code": "\n\tch, size := utf8.DecodeRuneInString(\"épée\")\n\tfmt.Printf(\"%c %d\\n\", ch, size)\n}\n",
      "note": "A chamada que a lição 9 usou: a primeira rune da string e quantos bytes ela ocupou, `é` e 2."
    }
  ],
  "output": "3 2\n3 2\n42 <nil>\n0 strconv.Atoi: parsing \"42x\": invalid syntax\né 2"
}
```

`(T, error)` é o jeito de Go relatar uma falha. Não há exceções para lançar e capturar: uma função
que pode falhar devolve um `error` como último resultado, e `nil` quer dizer que não falhou. As
duas linhas de `"42"` e `"42x"` mostram os dois lados desse contrato. **Leia o erro antes de
confiar no valor**, porque um `Atoi` que falhou ainda devolve um número, e 0 parece um número
perfeitamente bom. As lições 32 a 35 tratam de erros: o que é o tipo, como conferir e como
acrescentar contexto. Esta seção só precisa da forma.

## Dois resultados não cabem num lugar só

Uma chamada com vários resultados não é um valor que guarda dois. São dois valores, e o compilador
recusa todo lugar que só tem espaço para um:

```go
package main

import (
	"fmt"
	"strconv"
)

func divmod(a, b int) (int, int) {
	return a / b, a % b
}

func main() {
	q := divmod(17, 5)
	fmt.Println("17 / 5 is", divmod(17, 5))
	n := strconv.Atoi("42")
	fmt.Println(q, n)
}
```

```
ana@vm:~/funcs-mismatch$ go run .
# example.com/funcs-mismatch
./main.go:13:7: assignment mismatch: 1 variable but divmod returns 2 values
./main.go:14:27: multiple-value divmod(17, 5) (value of type (int, int)) in single-value context
./main.go:15:7: assignment mismatch: 1 variable but strconv.Atoi returns 2 values
```

O primeiro e o terceiro erros são o mesmo engano: um nome à esquerda, dois valores à direita. O
segundo é o que surpreende. `fmt.Println(divmod(17, 5))` funcionou no programa acima, e pôr uma
string na frente quebrou tudo. **Uma chamada com vários resultados só pode se espalhar pelos
argumentos de uma função quando é a lista inteira de argumentos.** Misturada com qualquer outra
coisa, ela precisa ir antes para variáveis. O tipo que a mensagem imprime, `(int, int)`, é uma
lista de resultados e não um tipo de que você possa declarar uma variável. Go não tem tuplas.

O terceiro erro é o que protege você. Escrever `n := strconv.Atoi("42")` é o que alguém faz quando
esquece que a conversão pode falhar, e Go torna impossível compilar esse esquecimento.

## O identificador vazio: descartar de propósito

Às vezes você quer mesmo só um resultado. Todo nome à esquerda do `:=` tem de ser usado, como a
lição 5 mostrou para variáveis, então dar nome a um resultado e depois ignorá-lo impede o build:

```go
package main

import "fmt"

func divmod(a, b int) (int, int) {
	return a / b, a % b
}

func main() {
	q, r := divmod(17, 5)
	fmt.Println(q)
}
```

```
ana@vm:~/funcs-unread$ go run .
# example.com/funcs-unread
./main.go:10:5: declared and not used: r
```

A resposta é `_`, o **identificador vazio** (*blank identifier*). Ele ocupa um lugar à esquerda de
uma atribuição e joga o valor fora. Não é uma variável, e você pode escrevê-lo quantas vezes
precisar:

```go
package main

import (
	"fmt"
	"strconv"
)

func divmod(a, b int) (int, int) {
	return a / b, a % b
}

func main() {
	_, r := divmod(17, 5)
	fmt.Println(r)

	n, _ := strconv.Atoi("42x")
	fmt.Println(n + 1)
}
```

```
ana@vm:~/funcs-blank$ go run .
2
1
```

O primeiro `_` é inofensivo: o resto era tudo o que se queria. O segundo é o motivo de o `_` pedir
cuidado. `"42x"` não é um número, o `Atoi` disse isso no erro, o `_` jogou o erro fora, e o
programa seguiu com 0 e imprimiu 1 como se nada tivesse acontecido. **Descartar um `error` com `_`
é decidir que a falha não pode acontecer ou não importa, e só deve ser escrito quando você sabe
dizer qual das duas.** A lição 12 fez isso com `json.Marshal` numa slice de strings: as falhas que
a documentação dele lista são channels, funções, números complexos, NaN e ciclos, e uma slice de
strings não tem nenhum deles.

## Todo caminho tem de retornar

Uma função com resultados tem de terminar cada caminho que passa por ela com um `return`. O
compilador confere os caminhos, e não raciocina sobre valores para isso:

```go
package main

import "fmt"

func sign(n int) string {
	if n < 0 {
		return "negative"
	}
	if n > 0 {
		return "positive"
	}
}

func main() {
	fmt.Println(sign(-3))
}
```

```
ana@vm:~/funcs-missing$ go run .
# example.com/funcs-missing
./main.go:12:1: missing return
```

Quando `n` é 0, nenhum dos `if` retorna, e a função chega à chave de fechamento, na linha 12, sem
nada para entregar. Go não devolve um valor zero por conta própria ali; ele se recusa a compilar
até que o caso do zero diga o que devolve.
