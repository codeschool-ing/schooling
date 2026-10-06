---
title: Dois campos com um nome só
version: 1
---

A seção 02 descreveu a promoção como uma busca: `e.Name` é procurado no próprio `Employee` e depois
dentro das structs embutidas nele. A busca vai nível por nível, e isso dá duas regras. **O campo
mais raso com um nome vence, e dois campos com o mesmo nome na mesma profundidade se anulam**, de
modo que usar esse nome é erro de compilação. As duas aparecem assim que um `Employee` embute uma
segunda struct com campos dos mesmos nomes da primeira:

```go
package main

import "fmt"

type Person struct {
	Name  string
	Email string
}

type Company struct {
	Name  string
	Email string
}

type Employee struct {
	Person
	Company
	Email string
}

func main() {
	e := Employee{
		Person:  Person{Name: "Ana", Email: "ana@example.com"},
		Company: Company{Name: "Acme", Email: "contact@acme.example"},
		Email:   "ana@acme.example",
	}
	fmt.Println(e.Email)
	fmt.Println(e.Person.Email, e.Company.Email)
	fmt.Println(e.Name)
}
```

```
ana@vm:~/embed-clash$ go run .
# example.com/embed-clash
./main.go:29:16: ambiguous selector e.Name
```

A linha 29 é o último `Println`. `Name` existe em `Person` e em `Company`, ambos um nível abaixo, e
**o compilador não escolhe um por você**: nenhum está mais perto, e a ordem em que os campos foram
declarados não tem direito de decidir. Repare no que não foi recusado. O tipo `Employee` compilou,
com os seus dois `Name` lá dentro, e as duas linhas de cima também, que usam `Email`. O erro está no
uso do nome ambíguo e em nenhum outro lugar.

`Email` está em três lugares e não deu problema. `Employee` declara um próprio, na profundidade
zero, que é mais rasa que a dos dois dentro de `Person` e `Company`, então `e.Email` quer dizer o
endereço de trabalho do funcionário. Os outros dois ficam escondidos da grafia curta, e continuam lá
para a longa. Escreva a grafia longa para `Name` também e o programa roda:

```go
	fmt.Println(e.Person.Name, e.Company.Name)
```

```
ana@vm:~/embed-depth$ go run .
ana@acme.example
ana@example.com contact@acme.example
Ana Acme
```

As duas regras protegem você de forma desigual, e vale saber para que lado. Se alguém mais tarde
acrescentar um campo `Name` a `Company`, todo `e.Name` do programa para de compilar, o que é
barulhento e seguro. Se alguém acrescentar um campo `Name` ao próprio `Employee`, todo `e.Name`
passa a ler o campo novo em silêncio, porque ele é mais raso. **Um campo acrescentado à struct de
fora pode mudar o que uma linha de código já existente lê, sem erro nenhum.**

## Onde ninguém recusa: JSON

O `json.Marshal`, da lição 15, trata uma struct embutida do jeito que o seletor trata: os campos
dela são escritos como se pertencessem à struct de fora, então um `Person` dentro de um `Employee`
produz chaves `"Name"` e `"Email"` como se fossem do próprio funcionário. Em geral é o que você
quer. Com o mesmo `Employee` de cima, e um `main` que o serializa em vez de imprimir campos:

```go
	b, err := json.Marshal(e)
	fmt.Println(string(b), err)
```

```
ana@vm:~/embed-json$ go run .
{"Email":"ana@acme.example"} <nil>
ana@vm:~/embed-json$ go vet; echo $?
0
```

**O nome sumiu, o da empresa também, e nada informou erro.** `err` é `nil` e o `go vet` saiu com 0.
`Email` saiu certo, pela mesma regra de profundidade que o compilador usa. Os dois `Name` eram o par
ambíguo, e onde o compilador recusou, o `encoding/json` descartou os dois. É comportamento
documentado, não bug, e a documentação diz isso com clareza:

```
ana@vm:~/embed-json$ go doc encoding/json.Marshal | grep -A1 'Otherwise there are'
    3) Otherwise there are multiple fields, and all are ignored; no error
    occurs.
```

A saída é uma tag de struct, a ferramenta da lição 15. Um campo embutido com um nome na tag deixa
de ser achatado; ele é escrito como um objeto sob esse nome, o que tira os campos dele da disputa:

```go
type Employee struct {
	Person
	Company `json:"company"`
	Email   string
}
```

```
ana@vm:~/embed-json-tag$ go run .
{"Name":"Ana","company":{"Name":"Acme","Email":"contact@acme.example"},"Email":"ana@acme.example"} <nil>
```

`Name` voltou, porque agora `Person` é a única struct embutida achatada, e a empresa guarda o
próprio nome e endereço dentro de `"company"`. **Quando uma struct embutida vai para JSON, confira
a saída uma vez com os próprios olhos**: um campo ambíguo quebra o build quando código Go o nomeia,
e não quebra nada quando o codificador o encontra.
