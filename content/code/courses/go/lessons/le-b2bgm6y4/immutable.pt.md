---
title: Uma string nunca muda
version: 1
---

Em C uma string é um array de caracteres, e um programa muda um deles escrevendo nele. As strings
de Go não funcionam assim, e o compilador avisa:

```go
package main

import "fmt"

func main() {
	s := "hello"
	s[0] = 'H'
	fmt.Println(s)
}
```

```
ana@vm:~/strings-mut$ go run .
# example.com/mut
./main.go:7:2: cannot assign to s[0] (neither addressable nor a map index expression)
```

**Os bytes de uma string ficam fixos quando ela é criada, e nada consegue mudá-los depois.** `s[0]`
pode ser lido, o que a seção 04 faz, e nunca escrito. Uma variável que guarda uma string pode
receber outra string, e é isso que "mudar" uma string quer dizer em Go: montar uma nova e
atribuí-la.

## O que uma variável string guarda

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"unsafe\"\n)\n\nfunc main() {\n",
      "note": "`unsafe` é o pacote que deixa um programa olhar o que a linguagem normalmente esconde. Aqui ele serve só para olhar."
    },
    {
      "code": "\ts := \"hello, world\"\n\tt := s\n\ts = \"H\" + s[1:]\n\tfmt.Println(s)\n\tfmt.Println(t)\n",
      "note": "`t := s` copia a string, e `s = \"H\" + s[1:]` monta uma nova e a atribui a `s`. `t` continua dizendo `hello, world`: **nada mexeu nos bytes a que ela se refere.**"
    },
    {
      "code": "\n\tfmt.Println(unsafe.Sizeof(t), unsafe.Sizeof(\"a\"), len(t))\n",
      "note": "**Um valor string tem 16 bytes, seja qual for o tamanho do texto**: `unsafe.Sizeof` dá 16 para `t`, de 12 bytes, e para `\"a\"`. Esses 16 bytes são um ponteiro para o primeiro byte e um comprimento, 8 bytes cada nesta máquina."
    },
    {
      "code": "\n\tw := t[7:]\n\tfmt.Println(unsafe.StringData(t), unsafe.StringData(w), w)\n",
      "note": "`unsafe.StringData` dá o endereço do primeiro byte de uma string. A substring `w` começa em `0x49bfcc`, sete bytes depois do `0x49bfc5` de `t`: ela aponta para os mesmos bytes e não copiou nenhum."
    },
    {
      "code": "\n\tu := t[:5] + \"!\"\n\tfmt.Println(unsafe.StringData(u) == unsafe.StringData(t), u)\n}\n",
      "note": "O `+` não reaproveita nada. `u` são bytes novos, então o primeiro byte dela não é o de `t`, e o `false` diz isso."
    }
  ],
  "output": "Hello, world\nhello, world\n16 16 12\n0x49bfc5 0x49bfcc world\nfalse hello!"
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Três valores string à esquerda, cada um um ponteiro e um comprimento. t aponta para o primeiro dos doze bytes de hello, world, com comprimento 12. w, que é t[7:], aponta sete bytes adiante, para o w de world, com comprimento 5, e nenhum byte é copiado. u, que é t[:5] mais um ponto de exclamação, aponta para seis bytes novos, hello!, copiados pelo operador +.\"><defs><marker id=\"sh-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sh-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um valor string: um ponteiro e um comprimento, 16 bytes</text><text x=\"480\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os bytes do literal, que nada escreve</text><rect x=\"300\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">h</text><text x=\"315.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">0</text><rect x=\"330\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">e</text><text x=\"345.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">1</text><rect x=\"360\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">l</text><text x=\"375.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">2</text><rect x=\"390\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">l</text><text x=\"405.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">3</text><rect x=\"420\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">o</text><text x=\"435.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">4</text><rect x=\"450\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">,</text><text x=\"465.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">5</text><rect x=\"480\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"495.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">6</text><rect x=\"510\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">w</text><text x=\"525.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">7</text><rect x=\"540\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">o</text><text x=\"555.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">8</text><rect x=\"570\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">r</text><text x=\"585.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">9</text><rect x=\"600\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">l</text><text x=\"615.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">10</text><rect x=\"630\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">d</text><text x=\"645.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">11</text><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">t</text><rect x=\"20\" y=\"60\" width=\"120\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"140\" y=\"60\" width=\"80\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0x49bfc5</text><text x=\"180\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">len 12</text><path d=\"M222 78 L297 78\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sh-phosphor)\"></path><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">w := t[7:]</text><rect x=\"20\" y=\"130\" width=\"120\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"140\" y=\"130\" width=\"80\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0x49bfcc</text><text x=\"180\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">len 5</text><path d=\"M222 148 L525.0 148 L525.0 99\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sh-phosphor)\"></path><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">u := t[:5] + &quot;!&quot;</text><rect x=\"20\" y=\"210\" width=\"120\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"140\" y=\"210\" width=\"80\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ptr</text><text x=\"180\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">len 6</text><text x=\"390\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">bytes novos, copiados pelo +</text><rect x=\"300\" y=\"210\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">h</text><rect x=\"330\" y=\"210\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">e</text><rect x=\"360\" y=\"210\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">l</text><rect x=\"390\" y=\"210\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"405.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">l</text><rect x=\"420\" y=\"210\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">o</text><rect x=\"450\" y=\"210\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">!</text><path d=\"M222 228 L297 228\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sh-amber)\"></path></svg>", "caption": "O que o programa em ~/strings-share montou. Uma substring é um novo ponteiro e comprimento sobre os mesmos bytes; o + cria bytes novos."}
```

O arranjo é seguro por causa da regra acima. Se os bytes de `t` pudessem mudar, `w` mudaria junto
sem o dono saber; como não podem, uma substring custa um cabeçalho novo e nenhuma cópia. Existe um
custo, e é o caso inverso: uma substring curta mantém viva na memória toda a sequência de bytes para
onde aponta. O `go doc strings.Clone` descreve a saída, uma função que faz uma cópia nova "when
retaining only a small substring of a much larger string", e a lição 24 trata da memória que um
programa mantém.

## O `+` copia, e num laço isso se acumula

O `+` não consegue estender uma string no lugar, então aloca bytes novos e copia os dois lados para
eles. Uma vez, não é nada. Montar uma string longa com `+=` num laço copia tudo o que já foi montado
a cada volta. Os dois programas abaixo montam a mesma string de 200.000 bytes a partir de 100.000
pedaços; `for range 100000` repete o bloco 100.000 vezes, e a lição 17 trata de laços.

```go
package main

import "fmt"

func main() {
	s := ""
	for range 100000 {
		s += "ab"
	}
	fmt.Println(len(s))
}
```

```go
package main

import (
	"fmt"
	"strings"
)

func main() {
	var b strings.Builder
	for range 100000 {
		b.WriteString("ab")
	}
	s := b.String()
	fmt.Println(len(s))
}
```

```
ana@vm:~/strings-plus$ go build && time ./plus
200000

real	0m3.701s
user	0m2.318s
sys	0m3.136s
```

```
ana@vm:~/strings-builder$ go build && time ./builder
200000

real	0m0.003s
user	0m0.003s
sys	0m0.000s
```

Mesma saída, 3,7 segundos contra 3 milissegundos. A versão com `+=` copiou 2 bytes, depois 4,
depois 6, até 200.000, o que soma uns 10 bilhões de bytes movidos para um resultado de 200.000. Um
`strings.Builder` guarda os bytes num buffer que cresce, acrescenta a ele e entrega o resultado no
`String()` sem uma cópia final. A lição 6 mostrou que o valor zero dele já está pronto para uso, e
por isso `var b strings.Builder` é toda a preparação. **Junte poucas strings com `+`; monte uma
string num laço com um `strings.Builder`.**
