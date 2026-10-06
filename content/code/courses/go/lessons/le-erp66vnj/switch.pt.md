---
title: switch, sem cair no caso seguinte
version: 1
---

Em C, Java e JavaScript, um `case` segue direto para o próximo a menos que termine com `break`, e
esquecer o `break` é um bug clássico. **Em Go um `case` termina sozinho.** O programa roda o
primeiro caso que casa e depois sai do `switch`, sem nada para escrever. Este programa, em
`~/cond-switch`, classifica dias:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command days says what kind of day each one is.\npackage main\n\nimport \"fmt\"\n\nfunc main() {\n\tfor _, d := range []string{\"mon\", \"sat\", \"fri\", \"sun\", \"xyz\"} {\n\t\tswitch d {\n",
      "note": "`switch d` compara `d` com cada caso, um de cada vez, de cima para baixo. O valor e os casos precisam ser de tipos que se possam comparar, aqui todos strings."
    },
    {
      "code": "\t\tcase \"sat\", \"sun\":\n\t\t\tfmt.Println(d, \"weekend\")\n",
      "note": "**Um caso pode listar vários valores, separados por vírgulas**, e casa se qualquer um deles casar. É o que quem programa em C escreve como dois casos, com o primeiro vazio para cair no seguinte."
    },
    {
      "code": "\t\tcase \"fri\":\n\t\t\tfmt.Println(d, \"almost the weekend\")\n\t\tcase \"mon\", \"tue\", \"wed\", \"thu\":\n\t\t\tfmt.Println(d, \"weekday\")\n",
      "note": "Nenhum `break` em lugar nenhum. Depois que `\"sat\"` imprimiu `weekend`, o programa não seguiu para o caso `\"fri\"` logo abaixo."
    },
    {
      "code": "\t\tdefault:\n\t\t\tfmt.Println(d, \"not a day\")\n\t\t}\n\t}\n}\n",
      "note": "O `default` só roda quando nenhum caso casou, onde quer que esteja escrito; um `switch` pode ter no máximo um, e ele costuma ficar por último, onde quem lê o procura."
    }
  ],
  "output": "mon weekday\nsat weekend\nfri almost the weekend\nsun weekend\nxyz not a day\n"
}
```

```
ana@vm:~/cond-switch$ go run .
mon weekday
sat weekend
fri almost the weekend
sun weekend
xyz not a day
```

Como cada caso é uma escolha separada, o mesmo valor em dois casos é um engano, e quando os valores
são constantes o compilador o encontra:

```go
	switch d {
	case "sat", "sun":
		fmt.Println(d, "weekend")
	case "fri", "sat":
		fmt.Println(d, "going out")
	}
```

```
ana@vm:~/cond-dup$ go build
# example.com/dup
./main.go:10:14: duplicate case "sat" (constant of type string) in expression switch
	./main.go:8:7: previous case
```

Um `break` continua permitido num caso, e a lição 18 mostrou o que ele faz ali: sai do `switch` e
de mais nada, o que dentro de um laço quase nunca é o que se queria.

## Com inicialização

Um `switch` aceita um comando curto antes do seu valor, exatamente como um `if` faz na seção 03, e
os nomes que ele declara duram até a chave de fechamento. Este programa, em `~/cond-ext`, diz o tipo
de um arquivo pela extensão:

```go
// Command kind names the kind of each file from its extension.
package main

import (
	"fmt"
	"path/filepath"
	"strings"
)

func main() {
	for _, name := range []string{"main.go", "README.md", "logo.PNG", "Makefile"} {
		switch ext := strings.ToLower(filepath.Ext(name)); ext {
		case ".go":
			fmt.Println(name, "Go source")
		case ".png", ".jpg":
			fmt.Println(name, "image")
		case "":
			fmt.Println(name, "no extension")
		default:
			fmt.Println(name, "something else:", ext)
		}
	}
}
```

```
ana@vm:~/cond-ext$ go run .
main.go Go source
README.md something else: .md
logo.PNG image
Makefile no extension
```

O `filepath.Ext` devolve a extensão com o ponto, ou uma string vazia quando não há extensão, e o
`strings.ToLower` é o motivo de `logo.PNG` ter casado com `".png"`. O caso `default` usa `ext`, o
que nenhum código depois do `switch` poderia fazer.

## Sem valor nenhum

Um `switch` sem nada depois da palavra-chave compara cada caso com `true`. **Cada caso passa a ser
uma condição própria**, e a primeira que vale vence, o que faz dele o jeito arrumado de escrever uma
longa cadeia de `if`, `else if`, `else if`. Arrumado não é o mesmo que seguro, porque a primeira que
casa vence:

```go
// Command grade turns scores into grades.
package main

import "fmt"

func grade(score int) string {
	switch {
	case score >= 50:
		return "pass"
	case score >= 90:
		return "distinction"
	default:
		return "fail"
	}
}

func main() {
	for _, s := range []int{95, 70, 30} {
		fmt.Println(s, grade(s))
	}
}
```

```
ana@vm:~/cond-grade$ go run .
95 pass
70 pass
30 fail
```

95 é distinção e recebeu aprovação. `score >= 50` era verdadeiro para ele, e veio primeiro, então o
caso `distinction` nunca foi testado. Nada aqui é erro de compilação, porque os casos são condições
e o compilador não compara uma com a outra. Com condições que se sobrepõem, **ponha a mais estreita
primeiro**:

```go
	switch {
	case score >= 90:
		return "distinction"
	case score >= 50:
		return "pass"
	default:
		return "fail"
	}
```

```
ana@vm:~/cond-grade$ go run .
95 distinction
70 pass
30 fail
```

## fallthrough, quando você quer dizer isso

O comportamento antigo continua disponível, pelo nome. Um `fallthrough` como último comando de um
caso manda o programa para o corpo do caso seguinte. **Ele não testa o caso seguinte antes**, e é
essa a parte que surpreende:

```go
package main

import "fmt"

func main() {
	n := 5
	switch {
	case n > 3:
		fmt.Println(n, "is more than 3")
		fallthrough
	case n > 100:
		fmt.Println(n, "is more than 100")
	default:
		fmt.Println(n, "is something else")
	}
}
```

```
ana@vm:~/cond-fall$ go run .
5 is more than 3
5 is more than 100
```

O programa imprimiu que 5 é maior que 100. `n > 100` nunca foi avaliado: o `fallthrough` rodou o
corpo abaixo dele fosse o que fosse que a condição dissesse, e então parou, porque aquele corpo não
tinha `fallthrough` próprio. Um `fallthrough` no último caso não tem para onde ir, e é recusado:

```go
package main

import "fmt"

func main() {
	n := 5
	switch {
	case n > 3:
		fmt.Println(n, "is more than 3")
	default:
		fmt.Println(n, "is something else")
		fallthrough
	}
}
```

```
ana@vm:~/cond-fall$ go build
# example.com/fall
./main.go:12:3: cannot fallthrough final case in switch
```

Ele também é recusado em qualquer lugar que não seja o último comando de um caso, e no type switch
da lição 29. No código-fonte do próprio Go ele é raro, contado do jeito que a lição 18 contou o
`goto`:

```
ana@vm:~/cond-fall$ grep -rE --include=*.go '^\s*switch\b' /usr/local/go/src | grep -vc -e _test.go -e testdata
6471
ana@vm:~/cond-fall$ grep -rE --include=*.go '^\s*fallthrough\b' /usr/local/go/src | grep -vc -e _test.go -e testdata
234
```

234 contra 6.471 switches, mais ou menos um em vinte e oito, e uma lista de casos ou uma
reordenação quase sempre é a correção mais clara. Quando um caso deveria compartilhar o trabalho
de outro, liste os dois valores num caso só, como `"sat", "sun"` fez, ou leve o trabalho
compartilhado para uma função que os dois casos chamam.
