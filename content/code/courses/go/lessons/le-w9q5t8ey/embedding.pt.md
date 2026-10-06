---
title: Um campo com tipo e sem nome
version: 1
---

Todo campo das structs da lição 15 tinha um nome e um tipo. **Deixe o nome de fora, escreva só o
tipo, e o campo fica embutido**: a struct de fora passa a guardar um valor inteiro daquele tipo, e
os campos do valor de dentro podem ser alcançados como se fossem da struct de fora. Embutir é só
isso, e o programa abaixo mostra cada pedaço:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\ntype Person struct {\n\tName  string\n\tEmail string\n}\n",
      "note": "Uma struct comum com dois campos, do tipo que a lição 15 declarou."
    },
    {
      "code": "\ntype Employee struct {\n\tPerson\n\tCompany string\n}\n",
      "note": "**`Person` sozinho numa linha é um campo com tipo e sem nome.** O campo tem nome mesmo assim, embora ninguém o tenha escrito: um campo embutido se chama como o seu tipo, então este se chama `Person`."
    },
    {
      "code": "\nfunc main() {\n\te := Employee{\n\t\tPerson:  Person{Name: \"Ana\", Email: \"ana@example.com\"},\n\t\tCompany: \"Acme\",\n\t}\n",
      "note": "Num literal, o campo embutido é preenchido como qualquer outro, por esse nome e com um valor `Person` inteiro."
    },
    {
      "code": "\tfmt.Println(e.Name, e.Person.Name)\n\tfmt.Println(e.Email)\n",
      "note": "**`e.Name` é a forma curta de `e.Person.Name`.** Os campos de `Person` são **promovidos** para `Employee`, então a grafia curta os encontra; as duas imprimem `Ana`, e `e.Email` funciona do mesmo jeito."
    },
    {
      "code": "\n\te.Name = \"Ana Lima\"\n\tfmt.Println(e.Person.Name)\n",
      "note": "A grafia curta não é uma cópia. Atribuir a `e.Name` mudou `e.Person.Name`, porque são um campo só, escrito de dois jeitos."
    },
    {
      "code": "\n\tfmt.Printf(\"%+v\\n\", e)\n}\n",
      "note": "`%+v` imprime os nomes dos campos e mostra o que o valor é de fato: um `Employee` tem dois campos, `Person` e `Company`, e `Name` mora dentro de `Person`."
    }
  ],
  "output": "Ana Ana\nana@example.com\nAna Lima\n{Person:{Name:Ana Lima Email:ana@example.com} Company:Acme}"
}
```

A última linha da saída é a que vale guardar para o resto da lição. **A promoção é um atalho na
grafia e nada mais**: nenhum campo foi copiado para `Employee`, e não existe `Name` no nível de
fora. O compilador vê `e.Name`, não acha campo chamado `Name` no próprio `Employee`, procura dentro
do `Person` embutido e o encontra lá.

## Escrevendo o literal do jeito curto

Nomear `Person:` e montar um `Person` inteiro dentro do literal é trabalhoso quando você só quer
preencher três campos. O Go 1.27 aceita os nomes promovidos diretamente:

```go
package main

import "fmt"

type Person struct {
	Name  string
	Email string
}

type Employee struct {
	Person
	Company string
}

func main() {
	e := Employee{Name: "Ana", Email: "ana@example.com", Company: "Acme"}
	fmt.Printf("%+v\n", e)
}
```

```
ana@vm:~/embed-literal$ go run .
{Person:{Name:Ana Email:ana@example.com} Company:Acme}
ana@vm:~/embed-literal$ go mod edit -go=1.26
ana@vm:~/embed-literal$ go run .
# example.com/embed-literal
./main.go:16:16: use of promoted field Person.Name in struct literal of type Employee requires go1.27 or later (-lang was set to go1.26; check go.mod)
./main.go:16:29: use of promoted field Person.Email in struct literal of type Employee requires go1.27 or later (-lang was set to go1.26; check go.mod)
```

O valor construído é o mesmo de antes, com `Name` e `Email` dentro de `Person`. A segunda execução
é o mesmo arquivo depois que `go mod edit -go=1.26` reescreveu a linha `go` do `go.mod`, e o
compilador o recusou. **A linha `go` decide em que versão da linguagem um módulo está escrito**,
que é o assunto da lição 2, e a mensagem diz isso com todas as letras: `check go.mod`. O Go 1.27
saiu em agosto de 2026, então o código escrito antes disso, ou para um módulo cuja linha `go` é
mais antiga, usa a forma longa, porque era a única que compilava.

As duas formas não se misturam para uma mesma struct embutida. Preencher `Person` e depois mais
um dos seus campos é recusado, já que os dois estariam escrevendo
o mesmo campo duas vezes:

```go
	e := Employee{Person: Person{Name: "Ana"}, Email: "ana@example.com"}
```

```
ana@vm:~/embed-mix$ go run .
# example.com/embed-mix
./main.go:16:45: cannot specify promoted field Email and enclosing embedded field Person
```

## Métodos também são promovidos

Um tipo pode ter funções presas a ele, chamadas métodos, e é na lição 25 que eles começam. Embutir
promove métodos exatamente como promove campos: um método declarado em `Person` pode ser chamado
num `Employee`, e a lição 25 volta a esta lição para mostrar isso. Por ora basta saber que **tudo o que
`e.Algo` encontra na struct embutida, campo ou método, é encontrado pela mesma busca**, e
a seção 03 diz exatamente até que profundidade essa busca vai.
