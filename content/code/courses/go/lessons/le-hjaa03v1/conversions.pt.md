---
title: O que uma conversão faz com um valor
version: 1
---

Uma conversão se escreve `T(x)`: o nome do tipo, usado como função, em volta do valor. Parece um
cast de C ou Java, e a crença que vem com essa palavra é que ele só troca o rótulo dos mesmos bits.
**Algumas conversões de Go mudam o valor, e o compilador não diz nada quando isso acontece.** Entre
tipos numéricos há três casos que vale conhecer, e estão todos num programa só:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n"
    },
    {
      "code": "\tf := 3.9\n\tfmt.Println(int(f), int(-f))\n",
      "note": "**Um float vira inteiro perdendo tudo o que vem depois da vírgula.** `3.9` vira `3`, não `4`, e `-3.9` vira `-3`: o corte é em direção ao zero, nunca um arredondamento. Se você quer arredondar, `math.Round` faz isso antes da conversão."
    },
    {
      "code": "\n\tbig, mid := 300, 200\n\tfmt.Println(int8(big), int8(mid), uint8(mid))\n",
      "note": "**Um tipo inteiro menor guarda os bits de baixo e mais nada.** `int8` vai de −128 a 127, então 300 não cabe, e a conversão não falha: guarda oito bits e imprime `44`. A figura abaixo mostra de onde vêm `44` e `-56`."
    },
    {
      "code": "\n\ttotal, count := 10, 4\n\tfmt.Println(total / count)\n\tfmt.Println(float64(total / count))\n\tfmt.Println(float64(total) / float64(count))\n}\n",
      "note": "**O lugar da conversão decide a resposta.** `total / count` é divisão inteira e dá `2`. Converter esse resultado continua dando `2`, porque o `.5` sumiu antes de a conversão rodar. Converter os dois operandos antes faz dela uma divisão de float, e só essa imprime `2.5`."
    }
  ],
  "output": "3 -3\n44 -56 200\n2\n2\n2.5"
}
```

## De onde vêm 44 e -56

Um `int` com 300 precisa de nove bits, e `int8` tem oito. A conversão guarda os oito da direita e
joga fora o que vale 256, o que deixa 44. Converter 200 não perde nada, porque 200 cabe em oito
bits, mas os mesmos oito bits significam números diferentes nos dois tipos. Em `uint8` o bit de
cima vale 128; em `int8` vale −128, então os bits que dão 200 sem sinal dão −128 + 72 = −56 com
sinal.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Converter um int para int8 ou uint8 guarda os oito bits de baixo. 300 é 256 mais 44, o bit que vale 256 é descartado, e int8 e uint8 leem 44. 200 cabe em oito bits, mas o bit de cima vale 128 para uint8 e menos 128 para int8, então uint8 lê 200 e int8 lê menos 56.\"><defs><marker id=\"cv-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"138\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">valor da posição</text><text x=\"168.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">256</text><text x=\"204.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">128</text><text x=\"240.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">64</text><text x=\"276.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">32</text><text x=\"312.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><text x=\"348.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"384.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><text x=\"420.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><text x=\"456.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><text x=\"138\" y=\"85.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">300, um int</text><rect x=\"150\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"168.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">1</text><rect x=\"186\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"204.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><rect x=\"222\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><rect x=\"258\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"276.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><rect x=\"294\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"312.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><rect x=\"330\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"348.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><rect x=\"366\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"384.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><rect x=\"402\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><rect x=\"438\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"456.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><path d=\"M482 85.0 L522 85.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cv-phosphor)\"></path><text x=\"532\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">int8(big)  → 44</text><text x=\"532\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">uint8(big) → 44</text><text x=\"138\" y=\"185.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">200, um int</text><rect x=\"150\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"168.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0</text><rect x=\"186\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"204.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1</text><rect x=\"222\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><rect x=\"258\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"276.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><rect x=\"294\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"312.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><rect x=\"330\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"348.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><rect x=\"366\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"384.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><rect x=\"402\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><rect x=\"438\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"456.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><path d=\"M482 185.0 L522 185.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cv-phosphor)\"></path><text x=\"532\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">uint8(mid) → 200</text><text x=\"532\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">int8(mid)  → -56</text><text x=\"168.0\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">descartado</text><path d=\"M186 112 L186 120 L474 120 L474 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"330\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">os oito bits que int8 e uint8 guardam</text><text x=\"204.0\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">vale 128 para uint8, −128 para int8</text><path d=\"M204.0 202 L204.0 212\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path></svg>", "caption": "Uma conversão para um inteiro menor guarda os bits de baixo e os lê no tipo novo. Nada confere se o valor sobreviveu."}
```

**Converter para um inteiro menor nunca falha em tempo de execução, e nunca avisa.** Esse é o
preço de a conversão ser explícita: ao escrever `int8(big)`, você afirmou que sabe que o valor
cabe. Se não sabe, confira antes de converter, contra os limites que a lição 7 imprimiu.

O compilador confere um caso, o que ele consegue ver. Uma constante é conhecida durante a
compilação, então uma constante que não sobreviveria à conversão é recusada de cara:

```go
package main

import "fmt"

func main() {
	fmt.Println(int(3.9))
	fmt.Println(int8(300))
}
```

```
ana@vm:~/convert-constconv$ go run .
# example.com/convert-constconv
./main.go:6:18: cannot convert 3.9 (untyped float constant) to type int
./main.go:7:19: constant 300 overflows int8
```

As mesmas duas conversões sobre variáveis compilaram e rodaram no programa lá de cima. A diferença
é só o que o compilador sabe: `3.9` escrito no código é um fato, e `f` é o que ele tiver quando a
linha rodar.

## string(65) não é "65"

Converter um inteiro para `string` é permitido, e quase nunca é o que quem escreveu queria:

```go
package main

import (
	"fmt"
	"strconv"
)

func main() {
	n := 65
	fmt.Println(string(n))
	fmt.Println(string(rune(n)), strconv.Itoa(n))
}
```

```
ana@vm:~/convert-rune$ go run .
A
A 65
ana@vm:~/convert-rune$ go vet; echo $?
main.go:10:14: conversion from int to string yields a string of one rune, not a string of digits
1
```

`string(n)` trata o número como um code point Unicode, e o code point 65 é `A`; a lição 8 imprimiu
`'A'` como 65. O programa compila e roda, então só o `go vet` pega, e a mensagem dele diz
exatamente o que deu errado. Quando o caractere é mesmo o que você quer, `string(rune(n))` diz isso
e o `go vet` fica quieto. Quando você quer os dígitos, a resposta não é uma conversão.

## Texto para número é uma função que pode falhar

**Uma string de dígitos não é um número de outro tipo; é texto que precisa ser interpretado**, e a
interpretação pode falhar de jeitos que uma conversão não pode. É por isso que a biblioteca padrão
faz isso no pacote `strconv`, com funções, e não com `int(s)`, que o compilador recusa. `Atoi`
transforma texto em `int` e `Itoa` transforma um `int` nos seus dígitos:

```go
package main

import (
	"fmt"
	"strconv"
)

func main() {
	n, err := strconv.Atoi("42")
	fmt.Println(n+1, err)

	n, err = strconv.Atoi("4.5")
	fmt.Println(n, err)

	n, err = strconv.Atoi(" 42")
	fmt.Println(n, err)

	n, err = strconv.Atoi("99999999999999999999")
	fmt.Println(n, err)

	s := strconv.Itoa(1500)
	fmt.Println(s+" ms", len(s))
}
```

```
ana@vm:~/convert-atoi$ go run .
43 <nil>
0 strconv.Atoi: parsing "4.5": invalid syntax
0 strconv.Atoi: parsing " 42": invalid syntax
9223372036854775807 strconv.Atoi: parsing "99999999999999999999": value out of range
1500 ms 4
```

`Atoi` devolve dois valores, o número e um erro, e o `<nil>` da primeira linha quer dizer que não
houve erro. Ela é rigorosa: recusa um ponto decimal, e também um espaço no começo, o que importa
quando o texto veio de um arquivo ou de um formulário. A quarta linha é a que vale guardar. O texto
era só dígitos mas grande demais para um `int`, e **`Atoi` devolveu o maior `int` que existe junto
com o erro** — o que o `go doc strconv.ParseInt` documenta. Um programa que usasse `n` sem olhar
`err` seguiria com 9223372036854775807. A lição 32 trata de lidar com erros assim; por enquanto,
olhe `err` antes de confiar em `n`.

`Itoa(1500)` dá os quatro caracteres `"1500"`, e `len` os conta. A parceira dela para floats é
`strconv.ParseFloat`, e `fmt.Sprint` transforma qualquer valor em texto quando o formato exato não
importa.
