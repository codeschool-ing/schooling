---
title: Um Employee não é um Person
version: 1
---

Quem já viu classes em Java, Python ou C++ lê `Employee` como uma subclasse: ele estende `Person`,
então um funcionário *é* uma pessoa e pode ir a qualquer lugar onde se espera uma pessoa. **Embutir
não é herdar, e o compilador diz isso na primeira vez que você se apoia nessa ideia.** Aqui está uma
função que cumprimenta um `Person`, recebendo um `Employee`:

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

func greet(p Person) {
	fmt.Println("Hello,", p.Name)
}

func main() {
	e := Employee{Name: "Ana", Email: "ana@example.com", Company: "Acme"}
	greet(e)
}
```

```
ana@vm:~/embed-notis$ go run .
# example.com/embed-notis
./main.go:21:8: cannot use e (variable of struct type Employee) as Person value in argument to greet
```

`Employee` e `Person` são dois tipos struct diferentes, e um valor de um não pode ser usado onde se
espera o outro, assim como um `int` não pode ser passado onde se espera uma `string`. Numa
linguagem com herança, essa chamada é a razão de ser da hierarquia. Em Go, **um `Employee` tem um
`Person` dentro dele, e essa é a única relação entre os dois tipos.**

Então você entrega a parte, e não o todo. O campo embutido tem nome, `Person`, e `e.Person` é um
valor `Person` completo:

```go
func main() {
	e := Employee{Name: "Ana", Email: "ana@example.com", Company: "Acme"}
	greet(e.Person)

	c := e
	c.Name = "Bia"
	fmt.Println(e.Name, c.Name)
}
```

```
ana@vm:~/embed-part$ go run .
Hello, Ana
Ana Bia
```

A segunda metade desse `main` mostra onde o `Person` mora. `c := e` copiou o funcionário, e mudar
o nome por meio de `c` não mexeu em `e`. **O `Person` fica guardado dentro do `Employee`, campo
por campo, e copiar a struct de fora copia junto a de dentro.** Não é uma referência a uma
pessoa guardada em outro lugar. E `greet` recebeu uma cópia da parte, como toda função Go recebe uma
cópia do que lhe passam, que é o assunto da lição 22.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"O valor e, do tipo Employee, é uma caixa com dois campos: um Person embutido, que é ele mesmo uma caixa com Name &quot;Ana&quot; e Email &quot;ana@example.com&quot;, e Company &quot;Acme&quot;. e.Name e e.Person.Name apontam ambos para o Name dentro do Person: um campo, duas grafias. greet(e.Person) aponta para a caixa Person inteira e recebe uma cópia dessa parte. greet(e) aponta para a caixa de fora e é recusado, porque um Employee não é um Person.\"><defs><marker id=\"em-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"em-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"330\" height=\"236\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"48\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">e  Employee</text><rect x=\"48\" y=\"68\" width=\"294\" height=\"124\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"64\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Person</text><path d=\"M64 104 L326 104\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"70\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Name</text><text x=\"326\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;Ana&quot;</text><path d=\"M64 146 L326 146\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"70\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Email</text><text x=\"326\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;ana@example.com&quot;</text><path d=\"M48 212 L342 212\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"64\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Company</text><text x=\"326\" y=\"238\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;Acme&quot;</text><text x=\"420\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">greet(e.Person)</text><text x=\"420\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">recebe uma cópia desta parte</text><path d=\"M412 70 L346 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#em-phosphor)\"></path><text x=\"420\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">e.Name</text><text x=\"476\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">e.Person.Name</text><text x=\"420\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um campo, duas grafias</text><path d=\"M412 126 L332 126\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#em-phosphor)\"></path><text x=\"420\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">greet(e)</text><text x=\"420\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">recusado: um Employee não é um Person</text><path d=\"M412 234 L364 234\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#em-amber)\"></path></svg>", "caption": "Um Employee guarda um Person inteiro dentro dele. e.Name alcança essa parte, greet(e.Person) entrega uma cópia da parte, e greet(e) é recusado, porque o todo é de outro tipo."}
```

## A parte nunca fica sabendo do todo

`greet` recebeu um `Person`, e é só isso que ela tem. Ela não pode pedir a empresa, porque um
`Person` não tem empresa, e nada dentro do `Person` sabe que ele foi recortado de um `Employee`.
Essa é a diferença mais funda em relação à herança. Uma classe que herda pode mudar o que o código
da classe mãe faz quando esse código roda. **Uma struct embutida é sempre só ela mesma.** A struct
de fora pode acrescentar campos ao redor dela, e não tem como mexer no que ela faz.

É isso que "composição" quer dizer no título desta lição: um tipo construído pondo outros tipos
dentro dele. A lição 1 disse que Go não tem classes nem herança, e esta é a ferramenta que ele
oferece no lugar. Ela cobre a metade da herança que trata de reaproveitar, ganhar os campos e os
métodos de um tipo que você já tem sem escrevê-los de novo. A outra metade, deixar tipos diferentes
ocuparem o lugar uns dos outros, pertence às interfaces, e a lição 27 é onde uma função aprende a
aceitar qualquer coisa que saiba fazer o que ela precisa.
