---
title: Um laço, três formatos
version: 1
---

A maioria das linguagens chega com uma família de laços: `for`, `while`, `do … while`, `foreach`.
**Go tem uma palavra-chave para repetir código, `for`, e todo laço da linguagem é escrito com ela.**
O que muda é quanto você escreve entre o `for` e a chave de abertura, e este programa mostra as três
quantidades:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tfor i := 0; i < 3; i++ {\n\t\tfmt.Println(\"pass\", i)\n\t}\n",
      "note": "**Três cláusulas, separadas por ponto e vírgula**: uma instrução que roda uma vez no começo, uma condição e uma instrução que roda depois de cada volta. Não há parênteses em volta delas, e as chaves são obrigatórias mesmo para um corpo de uma linha."
    },
    {
      "code": "\n\tn := 100\n\tfor n > 1 {\n\t\tn /= 3\n\t}\n\tfmt.Println(\"n is\", n)\n",
      "note": "**Uma condição sozinha é o `while` de Go.** O corpo roda enquanto `n > 1` for verdade: 100, 33, 11, 3 e então 1, onde a divisão inteira o faz parar."
    },
    {
      "code": "\n\ttries := 0\n\tfor {\n\t\ttries++\n\t\tif tries == 4 {\n\t\t\tbreak\n\t\t}\n\t}\n\tfmt.Println(\"tries:\", tries)\n}\n",
      "note": "**Nada é um laço que roda até alguma coisa dentro dele o parar.** Aqui é o `break`, assunto da lição 18; o `if` é da lição 19. Um `return` também o encerra, e o fim do programa também."
    }
  ],
  "output": "pass 0\npass 1\npass 2\nn is 1\ntries: 4"
}
```

O primeiro formato é o que tem peças móveis, e a ordem em que elas rodam é tudo o que há para
aprender sobre ele:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"O laço for i := 0; i &lt; 3; i++ desenhado como quatro passos. i := 0 roda uma vez, antes de tudo. Depois a condição i &lt; 3 é testada. Se for verdadeira, o corpo, fmt.Println(&quot;pass&quot;, i), roda, depois i++ roda, e a seta volta para o teste. Se o teste for falso, o laço termina. O teste é feito antes de cada volta, então uma condição falsa logo de início roda o corpo zero vezes.\"><defs><marker id=\"fl-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"fl-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"86\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">i := 0</text><text x=\"75\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">roda uma vez</text><path d=\"M130 108.0 L178 108.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-phosphor)\"></path><rect x=\"180\" y=\"86\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"235\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">i &lt; 3</text><text x=\"235\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">testada antes de cada volta</text><path d=\"M290 108.0 L348 108.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-phosphor)\"></path><text x=\"319\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">true</text><rect x=\"350\" y=\"86\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fmt.Println(&quot;pass&quot;, i)</text><text x=\"435\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o corpo</text><path d=\"M520 108.0 L568 108.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-phosphor)\"></path><rect x=\"570\" y=\"86\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">i++</text><text x=\"625\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">roda depois de cada volta</text><path d=\"M625 160 L625 200 L235 200 L235 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-phosphor)\"></path><path d=\"M235 86 L235 30 L330 30\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-amber)\"></path><text x=\"244\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">false</text><text x=\"338\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o laço termina</text></svg>", "caption": "O for de três cláusulas. A primeira cláusula roda uma vez, a condição é testada antes de cada volta e a última cláusula roda depois de cada volta."}
```

**A condição é testada antes de cada volta, inclusive a primeira**, então um laço cuja condição é
falsa desde o início roda o corpo zero vezes. A última cláusula roda depois do corpo e antes do
próximo teste, e é por isso que o último valor de `i` que a condição vê é 3, enquanto o último que
o corpo imprimiu foi 2. Qualquer uma das três cláusulas pode ficar vazia; quando só sobra a
condição, os pontos e vírgulas vão embora também, e esse é o segundo formato.

## A variável do laço pertence ao laço

`i` foi declarada na primeira cláusula, e o escopo dela é o comando `for` e nada depois dele:

```go
func main() {
	for i := 0; i < 3; i++ {
		fmt.Println("pass", i)
	}
	fmt.Println("done after", i)
}
```

```
ana@vm:~/loops-scope$ go run .
# example.com/loops-scope
./main.go:9:28: undefined: i
```

É o escopo de bloco da lição 6, aplicado a um laço. Se você precisa do contador depois, declare-o
antes do `for` com `i := 0` e deixe a primeira cláusula vazia: `for ; i < 3; i++`.

## Não existe `while`

A lição 1 contou as 25 palavras-chave de Go, e `while` não é uma delas. Digitá-la por hábito dá um
erro que nem menciona laços:

```go
package main

import "fmt"

func main() {
	n := 100
	while n > 1 {
		n /= 3
	}
	fmt.Println("n is", n)
}
```

```
ana@vm:~/loops-while$ go run .
# example.com/loops-while
./main.go:7:8: syntax error: unexpected name n at end of statement
./main.go:10:2: syntax error: non-declaration statement outside function body
```

Para o compilador, `while` é um nome comum, como `n`, e dois nomes seguidos não formam uma
instrução, então ele reclama do segundo, na coluna 8. O erro da linha 10 é consequência do
primeiro: o parser perdeu a conta de quais chaves pertencem a quê e conclui que `fmt.Println` está
fora da função. **Quando o primeiro erro de uma lista não faz sentido, corrija esse e rode de
novo**, porque os seguintes muitas vezes são o parser tropeçando no mesmo engano.

## Contando com `range`

Escrever `i := 0; i < n; i++` para fazer algo `n` vezes é comum o bastante para o Go 1.22 ter dado
a isso uma forma mais curta. As lições 7 e 9 já a usaram como `for range 10`:

```go
package main

import "fmt"

func main() {
	for i := range 3 {
		fmt.Println("pass", i)
	}
	for range 2 {
		fmt.Println("again")
	}
}
```

```
ana@vm:~/loops-int$ go run .
pass 0
pass 1
pass 2
again
again
ana@vm:~/loops-int$ go mod edit -go=1.21 && go run .
# example.com/loops-int
./main.go:6:17: cannot range over 3 (untyped int constant): requires go1.22 or later (-lang was set to go1.21; check go.mod)
./main.go:9:12: cannot range over 2 (untyped int constant): requires go1.22 or later (-lang was set to go1.21; check go.mod)
```

`for i := range 3` dá a `i` os valores 0, 1 e 2, exatamente como o laço de três cláusulas do começo
desta seção, e `for range 2` repete o corpo sem nem nomear um contador. A segunda execução mostra a
versão decidindo de novo o que compila: um módulo cuja linha `go` diz 1.21 está escrito num Go que
não tinha essa forma, como a lição 2 explicou. `range` faz muito mais do que contar, e a próxima
seção trata do resto.
