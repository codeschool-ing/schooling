---
title: Métodos como valores, e métodos promovidos
version: 1
---

A lição 21 passou funções adiante como valores: guardadas numa variável, entregues ao
`slices.SortFunc`. Um método pode ser usado do mesmo jeito, em duas grafias parecidas que dão coisas
diferentes. Juntas, elas mostram o que um receptor é de verdade. O programa está em
`~/methods-values`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"strings\"\n)\n\ntype Rect struct {\n\tW, H float64\n}\n\nfunc (r Rect) Area() float64 {\n\treturn r.W * r.H\n}\n",
      "note": "O `Rect` da seção 02, com o seu único método."
    },
    {
      "code": "\ntype Shift int\n\nfunc (s Shift) Rotate(r rune) rune {\n\tif r < 'a' || r > 'z' {\n\t\treturn r\n\t}\n\treturn 'a' + (r-'a'+rune(s))%26\n}\n",
      "note": "Um `int` definido cujo método anda `s` posições no alfabeto com uma letra minúscula, voltando de `z` para `a`, e deixa qualquer outra coisa como está."
    },
    {
      "code": "\nfunc main() {\n\tr := Rect{W: 3, H: 4}\n\tarea := r.Area\n\tfmt.Printf(\"%T  %v\\n\", area, area())\n",
      "note": "**`r.Area` sem os parênteses é um method value**: uma função com o receptor já preenchido. O tipo dela é `func() float64`, sem parâmetros, porque `r` faz parte dela."
    },
    {
      "code": "\tfmt.Printf(\"%T  %v\\n\", Rect.Area, Rect.Area(r))\n",
      "note": "**`Rect.Area`, citado pelo tipo, é uma method expression**, e o tipo dela é `func(main.Rect) float64`. O receptor virou o que sempre foi por baixo: o primeiro parâmetro."
    },
    {
      "code": "\n\tr.W = 10\n\tfmt.Println(area(), r.Area())\n",
      "note": "`area` continua dizendo 12 depois que `r` mudou. O receptor foi copiado para o method value quando `r.Area` foi avaliado, e um receptor por valor é uma cópia, que é o assunto da lição 26."
    },
    {
      "code": "\n\tfmt.Println(strings.Map(Shift(13).Rotate, \"hello, gopher\"))\n}\n",
      "note": "Um method value vai a qualquer lugar onde se quer uma função do tipo dele. `strings.Map` quer uma `func(rune) rune`, e `Shift(13).Rotate` é uma, levando o seu 13 junto."
    }
  ],
  "output": "func() float64  12\nfunc(main.Rect) float64  12\n12 40\nuryyb, tbcure\n"
}
```

A assinatura do `strings.Map` diz o que ele quer, e o method value se encaixa sem nenhum invólucro:

```
ana@vm:~/methods-values$ go doc strings.Map | head -4
package strings // import "strings"

func Map(mapping func(rune) rune, s string) string
    Map returns a copy of the string s with all its characters modified
```

A method expression é a prova mais forte da primeira frase da seção 02. `r.Area()` e `Rect.Area(r)`
são a mesma chamada, escrita de dois jeitos; **um método é uma função cujo primeiro parâmetro é
escrito antes do nome**, e a sintaxe do ponto é como Go deixa você chamá-la sobre um valor. A lição
26 usa method expressions para comparar os dois tipos de receptor lado a lado.

O method value é o que você vai encontrar com mais frequência. Uma função que quer um callback pode
receber o método de um valor que tem estado, sem nada a declarar: um `Shift` que lembra o seu 13, o
método de um logger que lembra onde escreve. As closures da lição 21 faziam o mesmo trabalho com uma
função literal, e um method value é a grafia mais curta quando o método já existe.

## Métodos promovidos

A lição 16 embutiu um `Person` num `Employee` e viu `e.Name` promovido da struct interna. Métodos são
promovidos pela mesma busca, e a regra da seção 04 da lição 16 decide qual vence quando dois têm o
mesmo nome: o mais raso. O programa em `~/methods-embed` tem um `Person` com dois métodos, um
`Contractor` que embute `Person` e não acrescenta nada, e um `Employee` que embute `Person` e declara
o próprio `Greet`:

```go
type Person struct {
	Name string
}

func (p Person) Greet() string {
	return "Hello, I am " + p.Name
}

func (p Person) Introduce() string {
	return p.Greet() + "."
}

type Contractor struct {
	Person
	Agency string
}

type Employee struct {
	Person
	Company string
}

func (e Employee) Greet() string {
	return e.Person.Greet() + " from " + e.Company
}

func main() {
	c := Contractor{Person: Person{Name: "Caio"}, Agency: "Temps"}
	e := Employee{Person: Person{Name: "Ana"}, Company: "Acme"}

	fmt.Println(c.Greet())
	fmt.Println(e.Greet())
	fmt.Println(e.Person.Greet())
	fmt.Println(e.Introduce())
}
```

```
ana@vm:~/methods-embed$ go run .
Hello, I am Caio
Hello, I am Ana from Acme
Hello, I am Ana
Hello, I am Ana.
```

`Contractor` não tem `Greet`, então `c.Greet()` é promovido de `Person`. `Employee` tem um na
profundidade 0, então `e.Greet()` o acha primeiro, e `e.Person.Greet()` ainda chega ao de dentro pelo
caminho completo, que é como o `Greet` do próprio `Employee` se apoia nele.

A quarta linha é a que vale guardar. **Um método promovido roda sobre o valor embutido, não sobre o
de fora.** `e.Introduce()` é `e.Person.Introduce()`: o receptor `p` dele é um `Person`, então o
`p.Greet()` lá dentro é o `Greet` de `Person`, e o de `Employee` nunca é consultado. Numa linguagem
com herança a chamada normalmente iria para a versão do tipo de fora. Em Go o método não tem como
saber que há um `Employee` em volta dele, que é o ponto da seção 03 da lição 16 sobre embutir, agora
com métodos:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"Duas chamadas sobre e, um Employee que embute um Person. e.Greet() acha o Greet declarado no próprio Employee, na profundidade 0, e imprime Hello, I am Ana from Acme. e.Introduce() não acha Introduce em Employee, então ele é promovido do Person embutido e recebe e.Person. Lá dentro, p.Greet() chama o Greet de Person, porque p é um Person; o Greet de Employee nunca é consultado, e a linha impressa é Hello, I am Ana.\"><defs><marker id=\"pm-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"70\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a chamada</text><text x=\"330\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o método que roda</text><text x=\"590\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que imprimiu</text><text x=\"70\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">e.Greet()</text><rect x=\"220\" y=\"44\" width=\"220\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">func (e Employee) Greet()</text><text x=\"330\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">declarado em Employee: profundidade 0, achado primeiro</text><path d=\"M120 62 L217 62\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pm-phosphor)\"></path><text x=\"590\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Hello, I am Ana from Acme</text><text x=\"70\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">e.Introduce()</text><rect x=\"206\" y=\"118\" width=\"248\" height=\"178\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"222\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Person</text><rect x=\"220\" y=\"136\" width=\"220\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">func (p Person) Introduce()</text><path d=\"M138 152 L217 152\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pm-phosphor)\"></path><text x=\"330\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">declarado no Person embutido: promovido</text><rect x=\"220\" y=\"244\" width=\"220\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">func (p Person) Greet()</text><path d=\"M330 198 L330 241\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pm-phosphor)\"></path><text x=\"340\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">p.Greet()</text><text x=\"590\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Hello, I am Ana.</text><text x=\"590\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">recebe e.Person, não e</text><text x=\"590\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">p é um Person, então este é o Greet de Person</text><text x=\"590\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o Greet de Employee nunca é consultado</text></svg>", "caption": "O programa em ~/methods-embed. Um método promovido roda sobre o valor embutido, e o que ele chama é decidido pelo tipo desse valor."}
```

Quando um tipo precisa de um comportamento que muda conforme o tipo em que é usado, embutir não é a
ferramenta. As interfaces da lição 27 são.
