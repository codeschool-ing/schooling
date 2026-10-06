---
title: Rótulos, para o laço que você quer
version: 1
---

A imagem comum do `break` é que ele tira você de lá. Ele tira você de **um** comando: o `for`, o
`switch` ou o `select` mais interno em volta dele. Com dois laços, um dentro do outro, esse é o
laço interno, e o externo segue como se nada tivesse acontecido. Este programa, em `~/flow-grid`,
pretende achar o primeiro valor acima de 20, lendo linha por linha:

```go
// Command grid finds the first value above 20, reading row by row.
package main

import "fmt"

func main() {
	grid := [][]int{
		{1, 4, 9},
		{16, 25, 36},
		{49, 64, 81},
	}
	for r, row := range grid {
		for c, v := range row {
			if v > 20 {
				fmt.Println("found", v, "at row", r, "column", c)
				break
			}
		}
	}
}
```

```
ana@vm:~/flow-grid$ go run .
found 25 at row 1 column 1
found 49 at row 2 column 0
```

Duas respostas para uma pergunta que tem uma. O `break` saiu do laço interno no 25, e o laço
externo seguiu para a linha 2 e achou 49 lá. **Um `break` dentro de dois laços sai só do
interno.**

## Dando nome ao laço

Um **rótulo** é um nome seguido de dois-pontos, escrito na linha antes de um comando, e o `break` e
o `continue` podem então nomear o laço a que se referem. A correção é rotular o laço externo.
Acrescentar o rótulo e esquecer de usá-lo é recusado, e é a primeira coisa que a maioria das pessoas
encontra:

```
ana@vm:~/flow-grid$ go run .
# example.com/grid
./main.go:12:1: label search defined and not used
```

Linha 12, coluna 1: o `gofmt` escreve um rótulo um nível à esquerda do comando que ele nomeia, para
que se destaque, e dentro de `main` isso é a própria margem. Um rótulo sem uso é recusado como o
import sem uso da lição 4: Go trata um nome que nada usa como engano, não como bagunça. Nomeá-lo no
`break` completa a correção:

```go
search:
	for r, row := range grid {
		for c, v := range row {
			if v > 20 {
				fmt.Println("found", v, "at row", r, "column", c)
				break search
			}
		}
	}
```

```
ana@vm:~/flow-grid$ go run .
found 25 at row 1 column 1
```

O `continue` aceita um rótulo do mesmo jeito, e `continue rows` quer dizer "a próxima volta do laço
chamado `rows`", abandonando o laço interno onde quer que ele estivesse. Este programa, em
`~/flow-rows`, soma cada linha e desiste de uma linha assim que encontra nela um valor negativo:

```go
rows:
	for r, row := range grid {
		sum := 0
		for _, v := range row {
			if v < 0 {
				fmt.Println("row", r, "skipped: it has", v)
				continue rows
			}
			sum += v
		}
		fmt.Println("row", r, "sum", sum)
	}
```

```
ana@vm:~/flow-rows$ go run .
row 0 sum 14
row 1 skipped: it has -25
row 2 sum 194
```

A linha 1 não imprimiu soma. O `-25` dela mandou o programa para a próxima volta de `rows`,
passando por cima do `Println` no fim do corpo externo, que um `continue` simples não teria pulado.
Quatro comandos, quatro destinos:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" aria-label=\"Para onde quatro comandos dentro de um laço interno mandam o programa. O laço externo tem o rótulo outer e contém o laço interno. continue vai para a próxima volta do laço interno. break sai do laço interno e segue com o resto do corpo do laço externo. continue outer vai para a próxima volta do laço externo. break outer sai dos dois laços.\"><defs><marker id=\"flw-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"flw-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M30 55 L24 55 L24 313 L30 313\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M54 85 L48 85 L48 253 L54 253\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"56\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fim do laço externo</text><text x=\"80\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fim do laço interno</text><text x=\"36\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">outer:</text><text x=\"36\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">for r := range grid {</text><text x=\"60\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">for c := range row {</text><text x=\"84\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">continue</text><text x=\"84\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">break</text><text x=\"84\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">continue outer</text><text x=\"84\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">break outer</text><text x=\"60\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">}</text><text x=\"60\" y=\"274\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">fmt.Println(r)</text><text x=\"36\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">}</text><text x=\"36\" y=\"334\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">fmt.Println(&quot;done&quot;)</text><path d=\"M145 124 L340 124 L340 94 L212 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#flw-phosphor)\"></path><text x=\"458\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">continue</text><text x=\"516\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">próxima volta do laço interno</text><path d=\"M125 154 L372 154 L372 274 L212 274\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#flw-phosphor)\"></path><text x=\"458\" y=\"274\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">break</text><text x=\"498\" y=\"274\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o resto do corpo do laço externo</text><path d=\"M184 184 L404 184 L404 64 L212 64\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#flw-amber)\"></path><text x=\"458\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">continue outer</text><text x=\"554\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">próxima volta do laço externo</text><path d=\"M165 214 L436 214 L436 334 L212 334\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#flw-amber)\"></path><text x=\"458\" y=\"334\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">break outer</text><text x=\"535\" y=\"334\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">depois dos dois laços</text></svg>", "caption": "Para onde cada comando vai. Sem rótulo, break e continue agem sobre o laço mais interno; com rótulo, sobre o laço que o rótulo nomeia."}
```

Um rótulo nomeia um comando **que envolve o `break`**, e nada mais. Um rótulo no laço interno não
pode ser usado depois que esse laço terminou, nem mesmo de dentro do externo:

```go
package main

import "fmt"

func main() {
	for r := 0; r < 3; r++ {
	inner:
		for c := 0; c < 3; c++ {
			fmt.Println(r, c)
		}
		if r == 1 {
			break inner
		}
	}
}
```

```
ana@vm:~/flow-wrong$ go build
# example.com/wrong
./main.go:12:10: invalid break label inner
```

## Um break dentro de um switch

O `switch` da lição 19 é o outro comando a que o `break` pertence, e é aí que isto dá errado em
código de verdade. Cada `case` termina sozinho em Go, então um `break` dentro de um nunca é
necessário para impedir que o próximo caso rode; quem escreve um ali quase sempre quer dizer o laço
em volta. Este programa, em `~/flow-switch`, deveria parar em `"stop"`:

```go
// Command commands runs a list of commands and should stop at "stop".
package main

import "fmt"

func main() {
	commands := []string{"add", "list", "stop", "delete"}
	for _, c := range commands {
		switch c {
		case "stop":
			fmt.Println("stopping")
			break
		default:
			fmt.Println("running", c)
		}
	}
	fmt.Println("done")
}
```

```
ana@vm:~/flow-switch$ go run .
running add
running list
stopping
running delete
done
ana@vm:~/flow-switch$ go vet; echo $?
0
```

Ele disse `stopping` e depois executou `delete`. **O `break` saiu do `switch`, que ia terminar de
qualquer jeito, e o laço seguiu para o próximo comando.** Compila, roda e o `go vet` sai com 0,
então a única coisa que denuncia esse bug é o comando que não deveria ter rodado. A correção é o
mesmo rótulo de antes, no laço:

```go
loop:
	for _, c := range commands {
		switch c {
		case "stop":
			fmt.Println("stopping")
			break loop
		default:
			fmt.Println("running", c)
		}
	}
```

```
ana@vm:~/flow-switch$ go run .
running add
running list
stopping
done
```

Quando o laço é a última coisa que uma função faz, um `return` dentro do `case` é a outra correção,
e muitas vezes a mais clara. O rótulo serve para quando a função tem mais a fazer depois do laço,
como `main` tem aqui com o `done`.
