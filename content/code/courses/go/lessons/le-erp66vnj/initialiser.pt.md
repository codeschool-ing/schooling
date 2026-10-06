---
title: Um if com inicialização, e o retorno antecipado
version: 1
---

Um `if` pode começar com um comando curto próprio, separado da condição por um ponto e vírgula:
`if n, err := strconv.Atoi(s); err != nil`. O comando roda primeiro, depois a condição é testada.
**Os nomes que ele declara pertencem ao `if`**, que é a linha de bloco da tabela de escopos da
lição 6: eles existem na condição e nos blocos da cadeia, e não depois dela. Este programa, em
`~/cond-init`, lê três strings como números:

```go
// Command size says how large each number in a list is.
package main

import (
	"fmt"
	"strconv"
)

func main() {
	for _, s := range []string{"42", "7", "forty-two"} {
		if n, err := strconv.Atoi(s); err != nil {
			fmt.Println("not a number:", err)
		} else if n > 10 {
			fmt.Println(n, "is more than ten")
		} else {
			fmt.Println(n, "is ten or less")
		}
	}
}
```

```
ana@vm:~/cond-init$ go run .
42 is more than ten
7 is ten or less
not a number: strconv.Atoi: parsing "forty-two": invalid syntax
```

A imagem que as pessoas trazem é que `n` pertence ao primeiro bloco, aquele onde a inicialização
está, e isso é metade da história. **O `else if` e o `else` também enxergam `n` e `err`**: o
`else if` testa `n > 10` e o `else` imprime `n`, e os dois ficam depois do bloco onde a
inicialização foi escrita. De onde eles não podem ser vistos é de qualquer lugar depois da última
chave de fechamento. Acrescentar uma linha depois da cadeia, ainda dentro do laço, é recusado:

```go
		fmt.Println("done with", n)
```

```
ana@vm:~/cond-init$ go build
# example.com/size
./main.go:18:28: undefined: n
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O escopo das variáveis que um if declara na sua inicialização. No laço de ~/cond-init, if n, err := strconv.Atoi(s) declara n e err. Elas são visíveis na condição e em todos os ramos da cadeia: o if, o else if e o else. A linha depois da cadeia, fmt.Println(&quot;done with&quot;, n), está fora dela, e o compilador diz undefined: n.\"><defs><marker id=\"cis-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"38\" y=\"41\" width=\"326\" height=\"194\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">for _, s := range []string{&quot;42&quot;, &quot;7&quot;, &quot;forty-two&quot;} {</text><text x=\"48\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">if n, err := strconv.Atoi(s); err != nil {</text><text x=\"72\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fmt.Println(&quot;not a number:&quot;, err)</text><text x=\"48\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">} else if n &gt; 10 {</text><text x=\"72\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fmt.Println(n, &quot;is more than ten&quot;)</text><text x=\"48\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">} else {</text><text x=\"72\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fmt.Println(n, &quot;is ten or less&quot;)</text><text x=\"48\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">}</text><text x=\"48\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">fmt.Println(&quot;done with&quot;, n)</text><text x=\"24\" y=\"278\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">}</text><path d=\"M370 44 L378 44 L378 232 L370 232\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M378 138 L392 138\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"400\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o escopo de n e err:</text><text x=\"400\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a condição, e todos os ramos</text><text x=\"400\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">da cadeia, inclusive o else</text><path d=\"M392 250 L252 250\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cis-amber)\"></path><text x=\"400\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">undefined: n</text><text x=\"400\" y=\"274\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fora da cadeia, n não existe mais</text></svg>", "caption": "Onde existem os nomes da inicialização de um if: da inicialização até a chave que fecha o último else, e em nenhum lugar depois."}
```

É esse o sentido da forma. `n` e `err` são necessários exatamente enquanto a decisão dura, e a
inicialização os mantém ali: o resto da função não consegue usar um `err` velho por engano, e o
próximo `if` pode declarar o seu próprio `err` sem colidir com este. O `:=` de uma inicialização
declara nomes novos como qualquer outro `:=` num bloco, então o `err` sombreado da lição 6 vale
aqui também: se um `err` já existe do lado de fora, o da inicialização é outra variável.

Quando o valor é necessário depois da decisão, a inicialização é a forma errada. Escreva o comando
numa linha própria e teste-o na seguinte, como esta função em `~/cond-after` faz:

```go
func double(s string) (int, error) {
	n, err := strconv.Atoi(s)
	if err != nil {
		return 0, err
	}
	return n * 2, nil
}
```

```
ana@vm:~/cond-after$ go run .
42 <nil>
0 strconv.Atoi: parsing "twenty-one": invalid syntax
```

`n` sobrevive ao `if`, porque foi declarado antes dele, e a última linha o usa. Essa forma, uma
chamada e depois `if err != nil` com um `return` dentro, é a coisa mais comum de se ver em código
Go. A lição 20 trata de funções que devolvem dois valores, e a lição 32 da metade `err`.

## Retorne cedo, e mantenha o resto plano

Um `else` depois de um bloco que termina em `return` não tem o que fazer: o programa só chega à
linha depois do `if` quando o `if` não retornou. Escrita com todos os `else` mesmo assim, uma função
se aninha um nível a mais a cada decisão. Aqui está a mesma regra de preço duas vezes, em
`~/cond-early`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command price works out a ticket's price twice, in two shapes.\npackage main\n\nimport \"fmt\"\n\nfunc priceNested(age int, member bool) int {\n\tif age >= 0 {\n\t\tif age < 12 {\n\t\t\treturn 0\n\t\t} else {\n\t\t\tif member {\n\t\t\t\treturn 15\n\t\t\t} else {\n\t\t\t\treturn 20\n\t\t\t}\n\t\t}\n\t} else {\n\t\treturn -1\n\t}\n}\n",
      "note": "**Toda decisão abre um bloco, e as respostas acabam no pé de uma escada.** O caso de uma idade inválida, que é a primeira coisa testada, é respondido por último, onze linhas abaixo do seu teste."
    },
    {
      "code": "\nfunc priceFlat(age int, member bool) int {\n\tif age < 0 {\n\t\treturn -1\n\t}\n\tif age < 12 {\n\t\treturn 0\n\t}\n\tif member {\n\t\treturn 15\n\t}\n\treturn 20\n}\n",
      "note": "**Cada caso especial é tratado e deixado na hora, e o que sobra é o caso comum.** A idade inválida é respondida na linha seguinte ao seu teste, e a última linha, na margem esquerda, é o preço que a maioria paga. Cada `if` se lê sozinho, sem lembrar dentro de quais blocos ele está."
    },
    {
      "code": "\nfunc main() {\n\tfmt.Println(priceNested(8, false), priceNested(30, true), priceNested(30, false), priceNested(-1, false))\n\tfmt.Println(priceFlat(8, false), priceFlat(30, true), priceFlat(30, false), priceFlat(-1, false))\n}\n",
      "note": "Os mesmos quatro ingressos pelas duas: uma criança, um sócio, um adulto que não é sócio e uma idade que não pode estar certa."
    }
  ],
  "output": "0 15 20 -1\n0 15 20 -1\n"
}
```

```
ana@vm:~/cond-early$ go run .
0 15 20 -1
0 15 20 -1
```

As duas funções concordam em todos os ingressos; diferem no que quem lê precisa guardar na cabeça.
**Trate a falha ou o caso especial primeiro, retorne, e deixe o caminho principal descer pela
margem esquerda.** Código Go é escrito assim quase em todo lugar, e é por isso que um `if` cujo
bloco termina em `return` raramente é seguido de `else`. O `-1` para uma idade inválida é um
quebra-galho aqui; a lição 32 troca números assim por um erro.
