---
title: range, e o que ele entrega
version: 1
---

Python percorre uma lista com `for lang in langs` e entrega cada elemento. A linha de Go que parece
a mesma, `for lang := range langs`, não faz isso: **com uma variável só, o `range` sobre uma slice
dá os índices, não os elementos.** Os nomes que você escolhe não mudam isso. Aqui estão as três
formas de escrever, lado a lado:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tlangs := []string{\"Go\", \"C\", \"Python\"}\n\n\tfor i, lang := range langs {\n\t\tfmt.Println(i, lang)\n\t}\n",
      "note": "**Duas variáveis recebem o índice e o elemento.** O `range` os produz a cada volta, em ordem, do índice 0 até o último."
    },
    {
      "code": "\n\tfor lang := range langs {\n\t\tfmt.Print(\" \", lang)\n\t}\n\tfmt.Println()\n",
      "note": "Uma variável só recebe apenas o índice. Aqui ela se chama `lang`, e mesmo assim guarda 0, 1 e 2, que é a linha da saída que o hábito de Python não espera."
    },
    {
      "code": "\n\tfor _, lang := range langs {\n\t\tfmt.Print(\" \", lang)\n\t}\n\tfmt.Println()\n}\n",
      "note": "Para ter só os elementos, descarte o índice com `_`, o identificador vazio. Declarar `i` e nunca usá-lo seria o erro de compilação da lição 5."
    }
  ],
  "output": "0 Go\n1 C\n2 Python\n 0 1 2\n Go C Python"
}
```

## O valor é uma cópia

A cada volta, o `range` atribui o elemento à variável de valor, e uma atribuição em Go copia. Então
a variável guarda uma cópia do elemento, e mudá-la muda a cópia. Com uma slice das structs da lição
15, a diferença passa fácil despercebida:

```go
package main

import "fmt"

type Player struct {
	Name  string
	Score int
}

func main() {
	team := []Player{{"Ana", 10}, {"Bia", 7}}

	for _, p := range team {
		p.Score += 5
	}
	fmt.Println(team)

	for i := range team {
		team[i].Score += 5
	}
	fmt.Println(team)
}
```

```
ana@vm:~/loops-copy$ go run .
[{Ana 10} {Bia 7}]
[{Ana 15} {Bia 12}]
ana@vm:~/loops-copy$ go vet; echo $?
0
```

O primeiro laço somou 5 à pontuação de cada jogadora, e o time impresso em seguida tem as
pontuações antigas. `p` foi uma cópia de `team[0]` e depois de `team[1]`, cada uma jogada fora no
fim da sua volta. O segundo laço escreveu pelo índice, `team[i].Score`, que é o próprio elemento
dentro da slice, e esse ficou. O `go vet` saiu com 0: um laço que muda a própria cópia é válido e
às vezes intencional, então nada avisa você. **Para mudar os elementos de uma slice num laço,
escreva em `s[i]`, nunca na variável de valor.**

## A slice é lida uma vez

O `range` olha a sua slice uma vez, antes da primeira volta, e decide ali quantas voltas vai haver.
Um laço que faz `append` na slice que está percorrendo não fica correndo atrás do próprio rabo:

```go
package main

import "fmt"

func main() {
	nums := []int{1, 2, 3}
	for _, n := range nums {
		nums = append(nums, n*10)
	}
	fmt.Println(nums)
}
```

```
ana@vm:~/loops-once$ go run .
[1 2 3 10 20 30]
```

Três voltas, porque `nums` tinha três elementos quando o laço começou, e três novos no fim. Um laço
de três cláusulas é diferente exatamente nesse ponto: a condição dele é testada de novo antes de
cada volta, como a figura da seção 02 mostrou. Escrito como `for i := 0; i < len(nums); i++` com o
mesmo `append` dentro, `len(nums)` cresceria um a cada volta, tão rápido quanto `i`, e o laço nunca
terminaria. Essa versão não foi executada no laboratório, por esse motivo.

## Um par novo de variáveis a cada volta

Desde o Go 1.22, **cada volta de um laço ganha o seu próprio `i` e o seu próprio `lang`**,
variáveis novas que por acaso têm os mesmos nomes, em vez de um par só sobrescrito de novo e de
novo. Dentro do corpo não dá para notar a diferença, e nada nesta lição depende dela. Ela importa
quando alguma coisa segura uma variável do laço depois que a volta dela acabou. A lição 2 rodou um
programa cuja saída mudou quando só a linha `go` do `go.mod` passou de 1.21 para 1.22, e a lição
21, sobre closures, explica o que estava segurando a variável.
