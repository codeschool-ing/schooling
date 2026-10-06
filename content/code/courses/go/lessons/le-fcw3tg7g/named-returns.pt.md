---
title: Resultados com nome e o return vazio
version: 1
---

`divmod` devolvia `(int, int)`, e nada nessa assinatura diz qual `int` é o quociente. Os resultados
de uma função podem ter nomes, exatamente como os parâmetros, e a biblioteca padrão os usa onde os
tipos sozinhos deixariam o leitor adivinhando:

```
ana@vm:~/funcs-multi$ go doc strings.Cut
package strings // import "strings"

func Cut(s, sep string) (before, after string, found bool)
    Cut slices s around the first instance of sep, returning the text before and
    after sep. The found result reports whether sep appears in s. If sep does
    not appear in s, cut returns s, "", false.

```

`(before, after string, found bool)` são três resultados, agrupados como os parâmetros, e os nomes
fazem o trabalho de uma frase: duas strings, a parte antes do separador e a parte depois, e se ele
foi encontrado. Com `(string, string, bool)` você teria de ler o comentário para saber a ordem. O
`Println` da lição 4 tinha o mesmo tipo de assinatura, `(n int, err error)`.

## O que um nome dá a um resultado

**Um resultado com nome é uma variável, declarada quando a função começa e iniciada com o seu
valor zero.** O corpo da função pode atribuir a ela como a qualquer outra variável, e um `return`
sem nada depois, um **return vazio** (*bare return*), devolve o que os resultados com nome guardam
naquele momento:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"strings\"\n)\n\nfunc nothing() (n int, s string, err error) {\n\treturn\n}\n",
      "note": "**Nada é atribuído, e o `return` vazio ainda devolve três valores**: o zero de cada tipo, da lição 6. Os resultados existem desde a primeira linha da função."
    },
    {
      "code": "\nfunc setting(line string) (key, value string, ok bool) {\n\tkey, value, ok = strings.Cut(line, \"=\")\n",
      "note": "`key`, `value` e `ok` já estão declarados, então a atribuição é `=`, não `:=`. `strings.Cut` preenche os três de uma vez."
    },
    {
      "code": "\tkey = strings.TrimSpace(key)\n\tvalue = strings.TrimSpace(value)\n\treturn\n}\n",
      "note": "Os resultados são alterados ali mesmo, e o `return` vazio devolve os valores que eles têm agora: sem os espaços em volta do `=`."
    },
    {
      "code": "\nfunc main() {\n\tn, s, err := nothing()\n\tfmt.Printf(\"%d %q %v\\n\", n, s, err)\n\tfmt.Println(setting(\"port = 8080\"))\n\tfmt.Println(setting(\"verbose\"))\n}\n",
      "note": "Quem chama não vê diferença. Os nomes pertencem à função; fora dela, `setting` devolve três valores como qualquer outra função."
    }
  ],
  "output": "0 \"\" <nil>\nport 8080 true\nverbose  false"
}
```

A última linha tem dois espaços de propósito. `"verbose"` não tem `=`, então o `strings.Cut`
devolveu a linha inteira como `before`, um `after` vazio e `false`, como a documentação dizia, e o
`Println` pôs um espaço de cada lado da string vazia.

## Quando os nomes atrapalham

O return vazio se lê bem numa função de cinco linhas, em que os resultados estão visíveis na tela.
Numa função de quarenta linhas, não: quem chega ao `return` tem de rolar para cima para saber o que
ele devolve, e depois procurar no corpo a última atribuição a cada nome.

Ele também esbarra no sombreamento, o bug que a lição 6 descreveu, e o compilador só pega parte
dele. Aqui o `:=` dentro do `if` declara um `n` novo e um `err` novo, e o return vazio está dentro
desse bloco:

```go
package main

import (
	"fmt"
	"strconv"
)

func port(s string) (n int, err error) {
	if s != "" {
		n, err := strconv.Atoi(s)
		if err != nil {
			return
		}
		fmt.Println("parsed", n)
	}
	return
}

func main() {
	fmt.Println(port("8080"))
}
```

```
ana@vm:~/funcs-shadow$ go run .
# example.com/funcs-shadow
./main.go:12:4: result parameter n not in scope at return
	./main.go:10:3: inner declaration of var n int
./main.go:12:4: result parameter err not in scope at return
	./main.go:10:6: inner declaration of var err error
```

O `return` da linha 12 devolveria o `n` e o `err` de fora, que nunca receberam valor, enquanto os
valores que a função acabou de calcular estão nos de dentro. **O compilador recusa um return vazio
quando um resultado com nome está escondido por outra variável de mesmo nome.** Isso pega um return,
não o bug. Escreva o de dentro por extenso, como `return n, err`, e o compilador fica satisfeito,
porque você disse qual `n` queria:

```go
package main

import (
	"fmt"
	"strconv"
)

func port(s string) (n int, err error) {
	if s != "" {
		n, err := strconv.Atoi(s)
		if err != nil {
			return n, err
		}
		fmt.Println("parsed", n)
	}
	return
}

func main() {
	fmt.Println(port("8080"))
}
```

```
ana@vm:~/funcs-shadow2$ go vet && go run .
parsed 8080
0 <nil>
```

O `go vet` não tem nada a dizer, a função leu 8080, e quem chamou recebeu 0. O return vazio lá
embaixo está fora do `if`, onde nada esconde os resultados, então devolve o `n` e o `err` de fora,
a que ninguém atribuiu nada. **A correção é `=` em vez de `:=`**, para que o `if` atribua aos
resultados em vez de declarar variáveis novas ao lado deles.

O hábito que a maior parte do código Go segue, então, cabe numa frase. **Dê nome aos resultados
quando os nomes documentam alguma coisa**, como em `strings.Cut`, e use o return vazio só numa
função curta o bastante para ser lida de relance. Nomes postos para documentar não obrigam você a
usar a forma vazia; `return before, after, true` é perfeitamente válido numa função com resultados
nomeados.

## A única coisa que só um nome permite

Um resultado com nome é uma variável que ainda existe depois que a instrução `return` rodou, e um
recurso de Go chega até ela ali. O `defer` agenda uma chamada para rodar quando a função retorna, e
uma função adiada pode alterar um resultado com nome na saída:

```go
package main

import "fmt"

func answer() (n int) {
	defer func() {
		n++
	}()
	return 41
}

func main() {
	fmt.Println(answer())
}
```

```
ana@vm:~/funcs-defer$ go run .
42
```

`return 41` põe 41 em `n`. Depois a função adiada roda, soma um a `n`, e só então quem chamou
recebe `n`, agora 42. Com um resultado `(int)` sem nome, a função adiada não teria nome nenhum para
alterar. O `func() { … }()` escrito dentro de `answer` é uma função literal, que a lição 21
explica. O `defer` em si, e o uso de verdade desse padrão, transformar um panic num `error` antes
que ele saia da função, são da lição 36.
