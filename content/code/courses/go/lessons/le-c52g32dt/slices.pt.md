---
title: Uma slice é uma janela para um array
version: 1
---

A primeira descrição que se ouve de uma slice é "um array dinâmico", um array que cresce. É a
imagem errada, e a maioria das surpresas com slices vem de acreditar nela. **Uma slice não guarda
elemento nenhum. É um valor pequeno que aponta para dentro de um array que outro alguém guarda**, e
diz quanto desse array ela mostra. Fatiar um array com `a[low:high]` cria uma:

```go
package main

import "fmt"

func main() {
	a := [5]int{10, 20, 30, 40, 50}
	s := a[1:3]
	fmt.Printf("%v %T len=%d cap=%d\n", s, s, len(s), cap(s))

	s[0] = 99
	fmt.Println(a)

	t := a[2:5]
	t[0] = 77
	fmt.Println(s, t, a)

	fmt.Println(&s[0] == &a[1])
}
```

```
ana@vm:~/arrays-slice$ go run .
[20 30] []int len=2 cap=4
[10 99 30 40 50]
[99 77] [77 40 50] [10 99 77 40 50]
true
```

`a[1:3]` começa no índice 1 e para antes do índice 3, então `s` mostra dois elementos, `20` e `30`.
O tipo dela é `[]int`, sem número entre os colchetes: **o comprimento de uma slice é um valor que
ela carrega, não parte do tipo**, e é por isso que uma mesma função aceita slices de qualquer
comprimento.

Depois, `s[0] = 99` mudou `a`. Nada foi copiado quando `s` foi criada, então o primeiro elemento de
`s` *é* o segundo elemento de `a`. A última linha confirma: `&s[0] == &a[1]` pergunta se os dois
têm o mesmo endereço, e têm. `&` é assunto da lição 23; aqui ele só prova que os dois nomes levam
ao mesmo lugar da memória.

## Três palavras

O que uma slice guarda são exatamente três coisas, e a figura as desenha para `s`:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"O array a guarda cinco ints, 10, 99, 30, 40 e 50, nos índices 0 a 4. A slice s, feita com a[1:3], tem três palavras: um ponteiro para o elemento 1 de a, um comprimento 2 e uma capacidade 4. O comprimento cobre os elementos 1 e 2, que é o que s pode indexar; a capacidade vai do elemento 1 até o fim do array. A slice não guarda elementos próprios.\"><defs><marker id=\"sa-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"135.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a slice s</text><text x=\"227.0\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">s := a[1:3]</text><rect x=\"60\" y=\"40\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"74\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ptr</text><text x=\"190\" y=\"55\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">•</text><rect x=\"60\" y=\"70\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"74\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">len</text><text x=\"190\" y=\"85\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text><rect x=\"60\" y=\"100\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"74\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">cap</text><text x=\"190\" y=\"115\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">4</text><text x=\"135.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">três palavras, e nenhum elemento</text><text x=\"236\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o array a</text><text x=\"236\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">índice</text><rect x=\"250\" y=\"190\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">10</text><text x=\"290.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><rect x=\"330\" y=\"190\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"370.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">99</text><text x=\"370.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"410\" y=\"190\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"450.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">30</text><text x=\"450.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"490\" y=\"190\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">40</text><text x=\"530.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"570\" y=\"190\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">50</text><text x=\"610.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><path d=\"M196 55 L370.0 55 L370.0 164\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sa-phosphor)\"></path><path d=\"M330 238 L330 244 L490 244 L490 238\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"410\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">len(s) = 2</text><text x=\"410\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o que s[0] e s[1] leem</text><path d=\"M330 288 L330 294 L650 294 L650 288\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"490\" y=\"308\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">cap(s) = 4</text><text x=\"490\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">do começo de s até o fim do array</text></svg>", "caption": "Uma slice é um ponteiro para dentro de um array, um comprimento e uma capacidade. Escrever s[0] = 99 escreveu em a[1], porque é para lá que s aponta."}
```

- um ponteiro para o elemento onde a slice começa, aqui `a[1]`;
- um comprimento, `len(s)`, quantos elementos ela mostra, aqui 2. Ler `s[2]` está fora do
  intervalo, mesmo o array tendo um elemento ali;
- uma capacidade, `cap(s)`, quantos elementos existem de onde ela começa até o fim do array, aqui
  4.

A capacidade é o número que esta lição só apresenta. O que ela permite, e o que acontece quando uma
slice precisa de mais do que tem, são o assunto inteiro da lição 12.

**Duas slices do mesmo array dividem os elementos dele.** `t := a[2:5]` começa um elemento depois
de `s`, então `s[1]` e `t[0]` são os dois `a[2]`. Escrever 77 por `t` mudou o que `s` imprime e o
que `a` imprime, na terceira linha da saída. Ninguém escreveu em `s` nem em `a` pelo nome.

## Um literal de slice cria o array por você

A maioria das slices nunca é fatiada de um array que você declarou. Um literal de slice, os
colchetes sem nada dentro, monta um array por trás e devolve uma slice sobre ele inteiro:

```go
package main

import "fmt"

func main() {
	s := []int{1, 2, 3}
	fmt.Printf("%v %T len=%d cap=%d\n", s, s, len(s), cap(s))
}
```

```
ana@vm:~/arrays-literal$ go run .
[1 2 3] []int len=3 cap=3
```

O array continua lá; só não tem nome, então a slice é o único jeito de chegar até ele. Esse é o
caso comum, e é fácil esquecer que o array existe até duas slices o dividirem.

## Slices não se comparam

Arrays se compararam com `==` na seção 01. Slices não:

```go
package main

import "fmt"

func main() {
	s := []int{1, 2, 3}
	u := []int{1, 2, 3}
	fmt.Println(s == u)
}
```

```
ana@vm:~/arrays-equal$ go run .
# example.com/arrays-equal
./main.go:8:14: invalid operation: s == u (slice can only be compared to nil)
```

Duas slices poderiam ser iguais em dois sentidos que discordam: os mesmos elementos, ou a mesma
janela para o mesmo array. Em vez de escolher um, Go recusa os dois e deixa a escolha com você. O
`slices.Equal` da biblioteca padrão compara os elementos, e `nil`, a única comparação permitida, é
da lição 12.
