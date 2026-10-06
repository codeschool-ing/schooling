---
title: Lendo um stack trace, quadro a quadro
version: 1
---

A maioria das pessoas lê a primeira linha de um panic e passa direto pelo resto, como se as linhas
de baixo fossem o runtime pigarreando. **O resto é a parte útil.** A primeira linha diz o que deu
errado; o stack trace diz onde, e como o programa chegou lá, com um arquivo e uma linha para cada
função que estava rodando. Várias lições anteriores imprimiram um e deixaram a leitura para esta.

`~/stacks` totaliza um pedido. Cada linha do pedido tem um item e uma quantidade, e uma quantidade
de dois ou três dá desconto:

```go
// Command stacks totals an order, and has a bug three calls deep.
package main

import "fmt"

type line struct {
	item string
	qty  int
}

var prices = map[string]int{"coffee": 450, "cake": 700}

// discount is a percentage, by quantity bought.
var discount = []int{0, 0, 5, 10}

func unitPrice(item string, qty int) int {
	return prices[item] * (100 - discount[qty]) / 100
}

func lineTotal(l line) int {
	return unitPrice(l.item, l.qty) * l.qty
}

func orderTotal(lines []line) int {
	total := 0
	for _, l := range lines {
		total += lineTotal(l)
	}
	return total
}

func main() {
	order := []line{{"coffee", 2}, {"cake", 4}}
	fmt.Println(orderTotal(order))
}
```

Alguém pediu quatro bolos:

```
ana@vm:~/stacks$ go build && ./stacks; echo $?
panic: runtime error: index out of range [4] with length 4

goroutine 1 [running]:
main.unitPrice(...)
	/home/ana/stacks/main.go:17
main.lineTotal(...)
	/home/ana/stacks/main.go:21
main.orderTotal(...)
	/home/ana/stacks/main.go:27
main.main()
	/home/ana/stacks/main.go:34 +0x15b
2
```

## Linha a linha

**`panic: runtime error: index out of range [4] with length 4`** é o que deu errado, e os dois
números ali são evidência. Algo pediu o elemento 4 de uma slice com quatro elementos, de 0 a 3.

**`goroutine 1 [running]:`** diz de quem é a pilha que vem a seguir: a goroutine número 1, a que
roda `main`, que estava rodando quando entrou em panic. Um programa com mais goroutines imprime a
que entrou em panic; a lição 36 mostrou uma iniciada por `main`, cujo trace terminava com uma linha
`created by main.main`.

Depois vêm os **quadros**, duas linhas cada: a função, com o pacote, e na linha seguinte, recuados,
o arquivo e a linha. **Eles são impressos do mais fundo para cima.** O quadro de cima é a função que
estava rodando quando o panic aconteceu, e cada quadro abaixo dele é a função que chamou a de cima:

| quadro | linha | o que está nessa linha |
|---|---|---|
| `main.unitPrice` | `main.go:17` | `discount[qty]`, onde o panic aconteceu |
| `main.lineTotal` | `main.go:21` | a chamada a `unitPrice` |
| `main.orderTotal` | `main.go:27` | a chamada a `lineTotal`, dentro do laço |
| `main.main` | `main.go:34` | a chamada a `orderTotal` |

**A linha do quadro de cima é onde o programa quebrou; a linha de cada um dos outros é onde aquela
função fez a chamada de cima.** Então o trace se lê como uma frase, de cima para baixo: a linha 17
falhou, dentro de uma chamada feita na linha 21, dentro de uma chamada feita na linha 27, dentro de
`main` na linha 34. As chamadas aconteceram na ordem oposta, e a figura põe as duas ordens lado a
lado:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"As quatro chamadas de ~/stacks e o trace que as relata, lado a lado. À esquerda, as chamadas na ordem em que o programa as fez: main.main, na linha 34, chamou orderTotal, que na linha 27 chamou lineTotal, que na linha 21 chamou unitPrice, que entrou em panic na linha 17. À direita, o trace na ordem em que o runtime o imprime: unitPrice e a linha 17 primeiro, depois lineTotal, orderTotal, e main.main por último. Cada chamada está ligada ao seu lugar no trace, e as linhas se cruzam, porque o trace é impresso do mais fundo para cima.\"><defs><marker id=\"tr-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">as chamadas, na ordem em que o programa as fez</text><text x=\"550\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o trace, na ordem em que o runtime o imprime</text><rect x=\"40\" y=\"44\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main.main()</text><text x=\"56\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">main.go:34</text><path d=\"M70 84 L70 102\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tr-wire)\"></path><text x=\"80\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">chama</text><rect x=\"420\" y=\"224\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"436\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main.main()</text><text x=\"436\" y=\"253\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">main.go:34</text><path d=\"M300 64 L420 244\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"40\" y=\"104\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main.orderTotal(...)</text><text x=\"56\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">main.go:27</text><path d=\"M70 144 L70 162\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tr-wire)\"></path><text x=\"80\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">chama</text><rect x=\"420\" y=\"164\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"436\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main.orderTotal(...)</text><text x=\"436\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">main.go:27</text><path d=\"M300 124 L420 184\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"40\" y=\"164\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main.lineTotal(...)</text><text x=\"56\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">main.go:21</text><path d=\"M70 204 L70 222\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tr-wire)\"></path><text x=\"80\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">chama</text><rect x=\"420\" y=\"104\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"436\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main.lineTotal(...)</text><text x=\"436\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">main.go:21</text><path d=\"M300 184 L420 124\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"40\" y=\"224\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main.unitPrice(...)</text><text x=\"56\" y=\"253\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">main.go:17</text><rect x=\"420\" y=\"44\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"436\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main.unitPrice(...)</text><text x=\"436\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">main.go:17</text><path d=\"M300 244 L420 64\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"170\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o panic acontece aqui</text><text x=\"550\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">leia de cima: onde quebrou, depois quem pediu</text></svg>", "caption": "As mesmas quatro chamadas, feitas de cima para baixo à esquerda e impressas a partir da mais funda à direita. Um trace começa onde o programa quebrou e volta até main."}
```

Juntando com a mensagem, o trace achou o bug sem depurador. A linha 17 indexou `discount` com
`qty`, a quantidade era 4, e `discount` só cobre as quantidades de 0 a 3. Uma quantidade de quatro
ou mais precisa de uma regra própria, e o programa nunca teve uma. O código de saída, 2, é o do
panic, como a lição 36 mostrou.

## `(...)` e `+0x15b`

Três dos quatro quadros terminam em `(...)` e não têm `+0x` depois da linha, e isso é o compilador
trabalhando. **Um quadro `(...)` foi expandido inline**: o compilador copiou o corpo da função para
dentro de quem a chama em vez de chamá-la, então, na execução, não houve chamada separada, e o
runtime reconstrói o quadro a partir de uma tabela que registra de onde veio o código copiado. A
flag `-m` que a lição 24 usou para a análise de escape também relata essas decisões:

```
ana@vm:~/stacks$ go build -gcflags=-m 2>&1 | grep 'inlining call'
./main.go:21:18: inlining call to unitPrice
./main.go:27:21: inlining call to lineTotal
./main.go:27:21: inlining call to unitPrice
./main.go:34:24: inlining call to orderTotal
./main.go:34:13: inlining call to fmt.Println
./main.go:34:24: inlining call to lineTotal
./main.go:34:24: inlining call to unitPrice
```

As três funções pequenas foram parar dentro de `main`, e é por isso que só `main.main` é um quadro
de verdade. O código que imprime um quadro diz o mesmo, no próprio código-fonte do runtime:

```
ana@vm:~/stacks$ grep -n -A12 'printFuncName(name)' $(go env GOROOT)/src/runtime/traceback.go | head -13
1050:			printFuncName(name)
1051-			print("(")
1052-			if iu.isInlined(uf) {
1053-				print("...")
1054-			} else {
1055-				argp := unsafe.Pointer(u.frame.argp)
1056-				printArgs(f, argp, u.symPC())
1057-			}
1058-			print(")\n")
1059-			print("\t", file, ":", line)
1060-			if !iu.isInlined(uf) {
1061-				if u.frame.pc > f.entry() {
1062-					print(" +", hex(u.frame.pc-f.entry()))
```

Um quadro inline recebe `...` no lugar dos argumentos e nenhum deslocamento. Um quadro de verdade
recebe os argumentos e **`+0x15b`, a distância em bytes do começo do código de máquina da função até
a instrução que estava rodando**: `pc` menos a entrada da função. Ele identifica a instrução exata,
mas só neste binário exato. Recompile depois de qualquer mudança e o número muda, enquanto o número
da linha continua querendo dizer a mesma coisa. Leia a linha.

### Os argumentos, e os pontos de interrogação

Com o inline desligado, o `-l` da lição 24, `unitPrice` ganha um quadro próprio, e o runtime
imprime o que consegue encontrar dos argumentos:

```
ana@vm:~/stacks$ go build -gcflags=-l -o noinline . && ./noinline 2>&1 | grep -A1 '^main.unitPrice'
main.unitPrice({0x49b0c7?, 0x41b4f9?}, 0x4)
	/home/ana/stacks/main.go:17 +0x8f
```

Os argumentos são impressos como palavras de máquina, em hexadecimal. `item` é uma string, que a
lição 9 mostrou ser um ponteiro e um comprimento, então ocupa duas palavras entre chaves. `qty` é
uma palavra, `0x4`, o mesmo 4 da mensagem. **Um `?` depois de uma palavra quer dizer que o runtime
não garante o valor**: o código-fonte acima imprime um quando a posição que guardava o valor já não
estava em uso naquela instrução, então o número pode ser sobra de outra coisa. `0x41b4f9` não pode
ser o comprimento de `"cake"`, e o `?` avisou. Trate os argumentos como pistas, e confie nos que não
têm ponto de interrogação.
