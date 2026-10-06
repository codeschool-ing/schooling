---
title: break e continue
version: 1
---

Um laço em Go para quando a condição fica falsa ou quando o `range` se esgota, que são as formas
da lição 17. Dois comandos encerram as coisas antes. **O `break` encerra o laço inteiro; o
`continue` encerra só a volta atual**, e o laço segue com a próxima. Este programa, em `~/flow`,
usa os dois:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command total adds up the numbers in a list of lines, up to the line \"end\".\npackage main\n\nimport (\n\t\"fmt\"\n\t\"strconv\"\n)\n\nfunc main() {\n\tlines := []string{\"12\", \"\", \"7\", \"seven\", \"end\", \"40\"}\n\tsum := 0\n\tfor _, line := range lines {\n",
      "note": "Seis linhas de entrada, como um programa poderia lê-las de um arquivo. Só duas delas são números que devem contar: o `40` vem depois do marcador de fim."
    },
    {
      "code": "\t\tif line == \"end\" {\n\t\t\tbreak\n\t\t}\n",
      "note": "**O `break` sai do `for`, não do `if` em que está escrito.** Um `if` não é algo de que se sai; o `break` pertence ao laço mais próximo em volta dele, e o programa continua depois da chave que fecha esse laço."
    },
    {
      "code": "\t\tn, err := strconv.Atoi(line)\n\t\tif err != nil {\n\t\t\tfmt.Printf(\"skipping %q\\n\", line)\n\t\t\tcontinue\n\t\t}\n\t\tsum += n\n\t}\n",
      "note": "O `strconv.Atoi` da lição 10 devolve um erro para tudo que não é um número inteiro. **O `continue` pula o resto desta volta**, então `sum += n` nunca vê uma linha que falhou, e o laço segue para a próxima linha."
    },
    {
      "code": "\tfmt.Println(\"sum:\", sum)\n}\n",
      "note": "Onde o `break` cai: no primeiro comando depois do laço."
    }
  ],
  "output": "skipping \"\"\nskipping \"seven\"\nsum: 19\n"
}
```

```
ana@vm:~/flow$ go run .
skipping ""
skipping "seven"
sum: 19
```

12 e 7 dão 19. A linha vazia e `"seven"` foram puladas, uma volta de cada vez, e o `40` nunca foi
lido, porque o laço tinha acabado em `"end"`.

Os dois comandos mantêm o corpo de um laço plano. Sem o `continue`, o resto do corpo ficaria
dentro de um `else`, e cada verificação nova o empurraria um nível mais para a direita. Com ele,
cada motivo para pular uma linha é um `if` que termina cedo, e o trabalho para o qual o laço existe
fica na margem esquerda, onde quem lê o encontra.

## O que o continue pula, e o que não pula

Onde a próxima volta começa depende da forma de `for` que você escreveu. Na forma de três
cláusulas, o comando de pós-iteração, o `i++`, pertence ao laço e não ao corpo, então o `continue`
ainda o executa. Na forma só com condição, o incremento é uma linha comum do corpo, e **o
`continue` o pula como qualquer outra linha**. Aqui está o mesmo laço escrito dos dois jeitos, em
`~/flow-skip`:

```go
package main

import "fmt"

func main() {
	lines := []string{"12", "", "7"}

	for i := 0; i < len(lines); i++ {
		if lines[i] == "" {
			continue
		}
		fmt.Println("three clauses:", lines[i])
	}

	i := 0
	for i < len(lines) {
		if lines[i] == "" {
			continue
		}
		fmt.Println("condition only:", lines[i])
		i++
	}
}
```

O segundo laço nunca termina, então ele é compilado primeiro e executado sob o `timeout`, que o
mata depois de dois segundos e sai com status 124 para dizer que precisou fazer isso:

```
ana@vm:~/flow-skip$ go build
ana@vm:~/flow-skip$ timeout 2 ./skip; echo $?
three clauses: 12
three clauses: 7
condition only: 12
124
ana@vm:~/flow-skip$ go vet; echo $?
0
```

O primeiro laço imprimiu os dois números. O segundo imprimiu `12`, chegou à linha vazia com `i`
valendo 1 e voltou à condição sem nunca alcançar o `i++`: `i` continuou 1, a linha continuou vazia,
e o programa girou na mesma volta por dois segundos sem imprimir nada. O `go vet` não tinha nada a
dizer, porque nem o compilador nem o `vet` têm como saber que o laço deveria terminar.

Então, quando um laço move o próprio contador, mova-o antes que qualquer `continue` possa rodar, ou
escreva o laço na forma de três cláusulas, em que o comando de pós-iteração roda depois de toda
volta, inclusive de uma que o `continue` interrompeu.

## Um laço que se vê, na mesma função

O `break` e o `continue` agem sobre um laço que os envolve **na mesma função**. Uma função
auxiliar não consegue encerrar o laço de quem a chamou, seja qual for a chamada:

```go
package main

import "fmt"

func check(n int) {
	if n < 0 {
		break
	}
	if n == 0 {
		continue
	}
	fmt.Println(n)
}

func main() {
	for _, n := range []int{3, 0, -1, 5} {
		check(n)
	}
}
```

```
ana@vm:~/flow-outside$ go build
# example.com/outside
./main.go:7:3: break is not in a loop, switch, or select
./main.go:10:3: continue is not in a loop
```

As duas mensagens não são iguais, e a diferença é o assunto da seção 03. O `continue` pertence só
aos laços. O `break` também é permitido dentro de um `switch` e de um `select`, e dentro de um
deles sai daquele comando, e não de um laço em volta. (O `select` espera em channels, que são do
curso `go-concurrency`.) O jeito de parar o laço de quem chamou a partir de uma função auxiliar é
devolver algo que quem chamou confira, como um `bool`, e deixar que quem chamou escreva o `break`.
