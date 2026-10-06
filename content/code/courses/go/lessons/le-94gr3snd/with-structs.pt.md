---
title: Ponteiros para structs
version: 1
---

A maioria dos ponteiros de um programa Go aponta para structs. Uma função que precisa mudar uma
struct recebe um ponteiro para ela, e o código que monta uma struct muitas vezes quer o endereço
dela logo de saída. Go deixa as duas coisas curtas o bastante para que alguém vindo de C talvez nem
perceba que há um ponteiro ali, porque **não existe `->`: o ponto funciona igual numa struct e num
ponteiro para ela.**

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\ntype Player struct {\n\tName  string\n\tScore int\n}\n\nfunc win(p *Player) {\n\tp.Score++\n}\n",
      "note": "O `win` da lição 22 recebia um `Player` e mudava uma cópia. Este recebe um `*Player`. **`p.Score` num ponteiro segue o ponteiro por você**: quer dizer `(*p).Score`, e ninguém escreve a forma longa."
    },
    {
      "code": "\nfunc main() {\n\tana := Player{Name: \"Ana\", Score: 10}\n\twin(&ana)\n\tfmt.Println(ana)\n",
      "note": "`win(&ana)` entrega o endereço de `ana`, e o jogador de quem chamou agora tem 11."
    },
    {
      "code": "\n\tbia := &Player{Name: \"Bia\"}\n\twin(bia)\n\tfmt.Println(bia, bia.Score, (*bia).Score)\n",
      "note": "**`&Player{...}` cria uma struct e devolve o seu endereço numa expressão só**, então `bia` é um `*Player`. `fmt.Println` imprime um ponteiro para struct como a struct com `&` na frente, `&{Bia 1}`, e as duas grafias do campo leem 1."
    },
    {
      "code": "\n\tcarla := new(Player)\n\tcarla.Name = \"Carla\"\n\tfmt.Println(*carla)\n",
      "note": "`new(Player)` cria um `Player` com todos os campos no valor zero e devolve o seu endereço, o mesmo que `&Player{}`."
    },
    {
      "code": "\n\ttwin := &Player{Name: \"Bia\", Score: 1}\n\tfmt.Println(bia == twin, *bia == *twin)\n}\n",
      "note": "**`==` entre dois ponteiros pergunta se eles levam à mesma variável**, não se os valores por trás deles batem. `bia == twin` é `false`; `*bia == *twin` compara as structs e é `true`."
    }
  ],
  "output": "{Ana 11}\n&{Bia 1} 1 1\n{Carla 0}\nfalse true"
}
```

```
ana@vm:~/pointers-struct$ go run .
{Ana 11}
&{Bia 1} 1 1
{Carla 0}
false true
```

Três jeitos de obter um `*Player` apareceram nesse programa: `&ana` para uma variável que já
existe, `&Player{...}` para uma struct criada na hora e `new(Player)` para uma zerada, que diz o
mesmo que `&Player{}`. A abreviação do ponto também alcança arrays. A lição 13 indexou um `*[4]int`
como `p[0]`, que é `(*p)[0]` escrito curto.

A última linha é a que vale guardar. `bia` e `twin` guardam jogadores iguais e são ponteiros
diferentes, então `bia == twin` é `false`. **Comparar ponteiros compara endereços**; para comparar
aquilo para que apontam, siga os dois, como `*bia == *twin` fez.

## Um ponteiro para um valor que não tem variável

Um campo ponteiro é o jeito de costume de dizer que um valor pode estar ausente: `nil` quer dizer
"não informado", e qualquer outra coisa é o valor. Preenchê-lo levava duas linhas, porque o `&`
precisa de uma variável e uma constante não é uma:

```go
package main

import "fmt"

type Options struct {
	Limit *int
}

func describe(o Options) string {
	if o.Limit == nil {
		return "no limit"
	}
	return fmt.Sprint("limit ", *o.Limit)
}

func main() {
	fmt.Println(describe(Options{}))
	fmt.Println(describe(Options{Limit: &10}))
}
```

```
ana@vm:~/pointers-new$ go run .
# example.com/options
./main.go:18:39: invalid operation: cannot take address of 10 (untyped int constant)
```

O `new` aceita uma expressão além de um tipo, e `new(10)` cria um `int` valendo 10 e devolve o seu
endereço:

```go
	fmt.Println(describe(Options{Limit: new(10)}))
```

```
ana@vm:~/pointers-new$ go run .
no limit
limit 10
ana@vm:~/pointers-new$ go mod edit -go=1.25 && go run .
# example.com/options
./main.go:18:38: new(10) requires go1.26 or later (-lang was set to go1.25; check go.mod)
```

**`new(expr)` é do Go 1.26 em diante.** O segundo comando voltou a linha `go` do módulo para 1.25,
e o compilador respondeu com a versão de que o recurso precisa; a lição 2 mostrou essa linha
escolhendo como linguagem o módulo é compilado. Num módulo cuja linha `go` é mais antiga que isso,
o mesmo campo é preenchido primeiro com uma variável: `n := 10`, depois `Limit: &n`. O
`go doc builtin.new` descreve as duas formas.

## Quando uma struct é passada por ponteiro

Duas razões justificam o ponteiro, e a lição 22 nomeou as duas. A função precisa mudar a struct de
quem chamou, como `win`; ou a struct é grande o bastante para a cópia custar alguma coisa. A lição
22 mediu isso: uma struct de 16 bytes foi copiada dentro do custo da própria chamada, e uma de 1.024
bytes levou 15,51 ns. Todo o resto é passado por valor, o que mantém a struct de quem chamou fora do
alcance da função. A mesma escolha volta nos métodos, onde um receptor ponteiro é o jeito de um
método mudar o valor em que foi chamado: a lição 26 trata dessa escolha.
