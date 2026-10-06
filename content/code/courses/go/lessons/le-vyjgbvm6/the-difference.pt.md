---
title: Uma cópia, ou a própria coisa
version: 1
---

Quem vem de Java ou Python lê `c.IncByValue()` como "faça isto com `c`", do jeito que `this` e
`self` funcionam por lá. **Em Go um receptor é um parâmetro, e a lição 22 disse o que todo
parâmetro é: uma cópia.** Um método declarado em `Counter` recebe um `Counter` só dele, e o que ele
muda, muda nessa cópia. Um método declarado em `*Counter` recebe um endereço, e as mudanças feitas
por esse endereço caem na variável de quem chamou. O programa abaixo tem um de cada, em
`~/receivers`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\ntype Counter struct {\n\tn int\n}\n",
      "note": "Uma struct com um campo só, para que cada mudança fique fácil de ver."
    },
    {
      "code": "\nfunc (c Counter) IncByValue() {\n\tc.n++\n\tfmt.Println(\"  inside IncByValue:\", c.n)\n}\n",
      "note": "**Um receptor por valor: `c` é um `Counter` do próprio método**, preenchido a partir daquilo sobre o que o método foi chamado. Ele soma um e imprime o que contou."
    },
    {
      "code": "\nfunc (c *Counter) Inc() {\n\tc.n++\n}\n",
      "note": "**Um receptor ponteiro: `c` é um `*Counter`**, o endereço de um `Counter` que mora em outro lugar. `c.n` passa por esse endereço, do jeito que `p.Field` fazia na lição 23."
    },
    {
      "code": "\nfunc main() {\n\tvar c Counter\n\tc.IncByValue()\n\tc.IncByValue()\n\tfmt.Println(\"after IncByValue:\", c.n)\n",
      "note": "Duas chamadas com o receptor por valor. Cada uma imprime 1, e `c.n` continua 0 depois: as duas chamadas contaram uma cópia."
    },
    {
      "code": "\n\tc.Inc()\n\tc.Inc()\n\tfmt.Println(\"after Inc:\", c.n)\n",
      "note": "Duas chamadas com o receptor ponteiro, sobre a mesma variável, escritas do mesmo jeito. Desta vez `c.n` vale 2."
    },
    {
      "code": "\n\tp := &c\n\tp.IncByValue()\n\tfmt.Println(\"after p.IncByValue:\", c.n)\n",
      "note": "Chamar o método por valor através de um ponteiro não muda a regra. O método ainda recebe uma cópia, daquilo para onde `p` aponta: imprime 3 e `c.n` fica em 2."
    },
    {
      "code": "\n\tfmt.Printf(\"%T\\n%T\\n\", Counter.IncByValue, (*Counter).Inc)\n}\n",
      "note": "**As expressões de método da lição 25 mostram o que um receptor é: o primeiro parâmetro.** O `%T` imprime os tipos delas, e a única diferença entre os dois é o asterisco."
    }
  ],
  "output": "  inside IncByValue: 1\n  inside IncByValue: 1\nafter IncByValue: 0\nafter Inc: 2\n  inside IncByValue: 3\nafter p.IncByValue: 2\nfunc(main.Counter)\nfunc(*main.Counter)"
}
```

```
ana@vm:~/receivers$ go run .
  inside IncByValue: 1
  inside IncByValue: 1
after IncByValue: 0
after Inc: 2
  inside IncByValue: 3
after p.IncByValue: 2
func(main.Counter)
func(*main.Counter)
```

`IncByValue` compila, roda e informa uma contagem de 1 toda vez, então nada parece errado visto de
dentro dele. O método fez exatamente o que diz, numa variável que sumiu quando ele retornou. **Um
receptor por valor que atribui a um campo é quase sempre um bug**, e o compilador aceita sem dizer
nada, porque mudar um parâmetro é permitido em qualquer lugar de Go.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Duas chamadas sobre a variável c de main, um Counter. Em c.IncByValue(), o receptor por valor é um segundo Counter, copiado de c quando a chamada começa: o método conta a cópia até 1, e o c de main continua com 0. Em c.Inc(), o receptor ponteiro guarda o endereço de c, então c.n++ dentro do método escreve no c de main, que passa a valer 1.\"><defs><marker id=\"rv-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"rv-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">c.IncByValue()</text><text x=\"150\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">receptor por valor</text><rect x=\"40\" y=\"48\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c</text><text x=\"158\" y=\"65\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n: 0</text><text x=\"105\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">variável de main</text><rect x=\"300\" y=\"48\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"312\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c Counter</text><text x=\"418\" y=\"65\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n: 1</text><text x=\"365\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o receptor</text><path d=\"M170 65 L296 65\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rv-amber)\"></path><text x=\"233\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">copiado na chamada</text><text x=\"470\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o método conta a sua cópia;</text><text x=\"470\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o c de main não é tocado,</text><text x=\"470\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">e a cópia é descartada</text><path d=\"M20 150 L700 150\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">c.Inc()</text><text x=\"85\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">receptor ponteiro</text><rect x=\"40\" y=\"200\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c</text><text x=\"158\" y=\"217\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n: 1</text><text x=\"105\" y=\"247\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">variável de main</text><rect x=\"300\" y=\"200\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"314\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">•</text><text x=\"326\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c *Counter</text><text x=\"365\" y=\"247\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o receptor</text><path d=\"M308 217 L174 217\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rv-phosphor)\"></path><text x=\"240\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o endereço de c</text><text x=\"470\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">c.n++ passa pelo</text><text x=\"470\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">endereço e escreve no</text><text x=\"470\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">próprio c de main</text></svg>", "caption": "Um receptor por valor é uma cópia feita para a chamada; um receptor ponteiro é o endereço da variável sobre a qual o método foi chamado."}
```

## O & que você não escreveu

`c` é um `Counter`, e `Inc` quer um `*Counter`. A chamada `c.Inc()` compila mesmo assim, porque Go
a reescreve como `(&c).Inc()`: quando um método precisa de um ponteiro e você o chama sobre uma
variável, o compilador toma o endereço da variável por você. Funciona no outro sentido também.
`p.IncByValue()` é `(*p).IncByValue()`, e a saída mostra o que isso custa: o método copiou o
`Counter` para onde `p` aponta, contou a cópia até 3 e deixou `c` em 2.

É por isso que os dois tipos de método parecem idênticos na chamada. **Se uma chamada pode mudar a
sua variável é decidido pela declaração do método, e isso não aparece no lugar da chamada.** Ler o
receptor é o único jeito de saber, e o `go doc` o imprime junto de cada método, como mostra a
seção 04.

## Onde não há endereço para tomar

O `&` automático precisa de algo com endereço. Um elemento de map e um literal não têm nenhum que
Go entregue, então chamar um método de ponteiro sobre qualquer um dos dois é recusado:

```go
package main

import "fmt"

type Counter struct {
	n int
}

func (c *Counter) Inc() {
	c.n++
}

func main() {
	byName := map[string]Counter{"ana": {}}
	byName["ana"].Inc()

	Counter{}.Inc()

	list := []Counter{{}, {}}
	list[0].Inc()
	fmt.Println(list)
}
```

```
ana@vm:~/receivers-addr$ go build
# example.com/addr
./main.go:15:16: cannot call pointer method Inc on Counter
./main.go:17:12: cannot call pointer method Inc on Counter
```

Dois erros, nas linhas 15 e 17, e nenhum na linha 20. A lição 23 mostrou `&nums[0]` aceito e
`&ages["ana"]` recusado, e esta é a mesma regra alcançada por uma chamada de método. Um elemento
de slice mora num array que fica onde está. As entradas de um map, não: quando um map cresce, o
runtime as copia para uma tabela nova (`grow` em
`/usr/local/go/src/internal/runtime/maps/table.go`), e um endereço entregue antes disso apontaria
para a antiga. Um literal como `Counter{}` é um valor que nunca foi guardado numa variável, então
não há nada cujo endereço possa ser tomado.

A correção também é a da lição 23: **guarde ponteiros no map, para que o elemento já seja um
endereço.**

```go
package main

import "fmt"

type Counter struct {
	n int
}

func (c *Counter) Inc() {
	c.n++
}

func main() {
	byName := map[string]*Counter{"ana": {}}
	byName["ana"].Inc()
	byName["ana"].Inc()

	list := []Counter{{}, {}}
	list[0].Inc()
	fmt.Println(byName["ana"].n, list)
}
```

```
ana@vm:~/receivers-addr-fix$ go run .
2 [{1} {0}]
```

`{}` dentro de um literal `map[string]*Counter` é a forma curta de `&Counter{}`, então cada entrada
começa como o endereço de um `Counter` novo. As duas chamadas passam por esse endereço e a contagem
chega a 2, e `list[0].Inc()` mudou o primeiro elemento do slice no lugar.
