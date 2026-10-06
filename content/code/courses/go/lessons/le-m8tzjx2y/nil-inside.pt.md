---
title: Uma interface que guarda nil não é nil
version: 1
---

A lição 6 imprimiu o valor zero de uma interface como `<nil>`, e prometeu que uma interface que
guarda um ponteiro nil é outra coisa. A maioria das pessoas supõe que as duas são uma coisa só: pôs
um nil numa interface, a interface é nil. **Essa é a imagem errada, e a verificação que deveria
pegar a diferença a deixa passar.** Aqui estão as duas, lado a lado:

```go
package main

import "fmt"

type Player struct {
	Name string
}

func main() {
	var e any
	var p *Player
	var v any = p

	fmt.Println(e == nil, p == nil, v == nil)
	fmt.Printf("%T %v\n", e, e)
	fmt.Printf("%T %v\n", v, v)
	fmt.Println(v == (*Player)(nil))
}
```

```
ana@vm:~/any-nil$ go run .
true true false
<nil> <nil>
*main.Player <nil>
true
```

`p` é nil e `v` guarda `p`, e ainda assim `v == nil` é falso. A segunda e a terceira linhas dizem
por quê. `e` não tem tipo, e o `%T` imprime `<nil>` para ela. `v` tem um tipo, `*main.Player`, e
o seu valor é um ponteiro nil desse tipo. As duas imprimem `<nil>` com `%v`, e é isso que torna o
caso tão difícil de notar num log.

A seção 02 descreveu um valor de interface como duas palavras, uma para o tipo e outra para o
valor. **`== nil` numa interface pergunta se as duas palavras estão vazias**, e um ponteiro nil
deixa vazia a palavra do valor enquanto preenche a palavra do tipo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três valores de interface, cada um desenhado com as suas duas palavras, o tipo e o valor. var e any não guarda tipo nem valor, e e == nil é true. var v any = 42 guarda o tipo int e o valor 42, e v == nil é false. var v any = p, em que p é um *Player nil, guarda o tipo *main.Player e um ponteiro nil como valor, e v == nil continua false, porque a palavra do tipo não está vazia.\"><text x=\"30\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a instrução</text><text x=\"320\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">palavra do tipo</text><text x=\"470\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">palavra do valor</text><text x=\"625\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">== nil</text><text x=\"30\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">var e any</text><rect x=\"245\" y=\"40\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><rect x=\"395\" y=\"40\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"320\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nenhum</text><text x=\"470\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nenhum</text><text x=\"625\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">true</text><text x=\"30\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">var v any = 42</text><rect x=\"245\" y=\"96\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"395\" y=\"96\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">int</text><text x=\"470\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">42</text><text x=\"625\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">false</text><text x=\"30\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">var v any = p</text><rect x=\"245\" y=\"152\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"395\" y=\"152\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">*main.Player</text><text x=\"470\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ponteiro nil</text><text x=\"625\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">false</text><text x=\"30\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">p é um *Player nil: o valor é nil, o tipo não</text><text x=\"30\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">só uma interface sem tipo é nil</text></svg>", "caption": "Um valor de interface são duas palavras. Ele só é igual a nil quando as duas estão vazias, e um ponteiro nil ainda preenche a palavra do tipo."}
```

A última linha do programa compara `v` com uma interface que guarda a mesma coisa, um `*Player`
nil, e essa comparação é verdadeira. É a pergunta certa para esse valor. Raramente é escrita,
porque o código que precisa fazê-la em geral não sabe que tipo de ponteiro recebeu.

## Onde isso morde

Ninguém escreve `var v any = p` para depois testar `v` contra nil. O que se escreve de fato é uma
função cujo resultado é uma interface, devolvendo um ponteiro que por acaso é nil:

```go
package main

import "fmt"

type Player struct {
	Name string
}

var players = map[string]*Player{"ana": {Name: "Ana"}}

func find(name string) *Player {
	return players[name]
}

func lookup(name string) any {
	p := find(name)
	return p
}

func main() {
	for _, name := range []string{"ana", "zoe"} {
		if r := lookup(name); r != nil {
			fmt.Println(name, "found:", r)
		} else {
			fmt.Println(name, "not found")
		}
	}
	r := lookup("zoe")
	fmt.Println(r.(*Player).Name)
}
```

```
ana@vm:~/any-nil-func$ go vet && go run .
ana found: &{Ana}
zoe found: <nil>
panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x0 pc=0x499ffb]

goroutine 1 [running]:
main.main()
	/home/ana/any-nil-func/main.go:29 +0x15b
exit status 2
```

Não há `zoe` no map, então `find` devolveu um `*Player` nil. O `return p` em `lookup` pôs esse
ponteiro no resultado `any`, com tipo e tudo. Quem chamou testou `r != nil`, o teste passou, e o
programa anunciou que tinha encontrado `<nil>`. O `go vet` não disse nada, porque nada aqui quebra
uma regra. A última linha vai um passo além: a asserção `r.(*Player)` dá certo, já que um
`*Player` é exatamente o que `r` guarda, e ler `.Name` através de um ponteiro nil é o panic que a
lição 23 mostrou.

A correção é decidir, dentro da função, o que "nada" quer dizer, e devolver para isso o nil da
própria interface:

```go
package main

import "fmt"

type Player struct {
	Name string
}

var players = map[string]*Player{"ana": {Name: "Ana"}}

func find(name string) *Player {
	return players[name]
}

func lookup(name string) any {
	p := find(name)
	if p == nil {
		return nil
	}
	return p
}

func main() {
	for _, name := range []string{"ana", "zoe"} {
		if r := lookup(name); r != nil {
			fmt.Println(name, "found:", r)
		} else {
			fmt.Println(name, "not found")
		}
	}
}
```

```
ana@vm:~/any-nil-fix$ go run .
ana found: &{Ana}
zoe not found
```

`return nil` numa função cujo resultado é `any` devolve uma interface sem tipo, e `r != nil` passa
a querer dizer o que diz. A correção mais simples é o conselho da seção 03: `find` já devolve um
`*Player`, e quem compara um `*Player` com nil recebe uma resposta verdadeira toda vez. **Uma
função não deve devolver um ponteiro nil como interface**, e o jeito mais fácil de manter essa
regra é devolver o tipo concreto.

Isso pesa mais com a interface que você vai usar mais do que qualquer outra. `error` é uma
interface, e uma função que devolve o seu próprio tipo de erro nil como `error` devolve um erro que
não é nil. A lição 32 mostra isso acontecendo, e são as mesmas duas palavras da figura acima.
