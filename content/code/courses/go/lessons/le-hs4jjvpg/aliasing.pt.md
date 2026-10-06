---
title: Quando duas slices dividem um array
version: 1
---

A lição 11 mostrou que fatiar nunca copia: `nums[:2]` é uma segunda visão do array que `nums` já
usa. Ler por duas visões não faz mal. O problema começa quando uma delas faz `append`, porque a
ideia errada que quase todo mundo tem a essa altura é que o `append` só acrescenta à slice que você
entregou. **Ele escreve depois do comprimento dessa slice, e se o array tem espaço ali, esse espaço
pode estar guardando elementos que outra slice usa.**

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"slices\"\n)\n\nfunc main() {\n\tnums := []int{1, 2, 3, 4, 5}\n\thead := nums[:2]\n\thead = append(head, 99)\n\tfmt.Println(nums, head)\n",
      "note": "`head` são os dois primeiros elementos, com capacidade 5, porque o array continua por mais três. **O `append` acha espaço no índice 2 e escreve 99 ali, no array que `nums` lê.** A primeira linha da saída: `nums` perdeu o seu 3 e ninguém atribuiu nada a `nums`."
    },
    {
      "code": "\n\tnums = []int{1, 2, 3, 4, 5}\n\thead = nums[:2:2]\n\tfmt.Println(len(head), cap(head))\n\thead = append(head, 99)\n\tfmt.Println(nums, head)\n",
      "note": "**O terceiro número de uma expressão de fatia completa é onde a capacidade termina.** `nums[:2:2]` tem comprimento 2 e capacidade 2, então o `append` não tem espaço, aloca um array novo e copia antes. `nums` mantém o seu 3."
    },
    {
      "code": "\n\tnums = []int{1, 2, 3, 4, 5}\n\thead = slices.Clone(nums[:2])\n\thead = append(head, 99)\n\tfmt.Println(nums, head)\n}\n",
      "note": "O `slices.Clone` copia os elementos para um array novo na hora, então `head` não divide nada com `nums` desde a primeira linha, faça o que fizer depois."
    }
  ],
  "output": "[1 2 99 4 5] [1 2 99]\n2 2\n[1 2 3 4 5] [1 2 99]\n[1 2 3 4 5] [1 2 99]"
}
```

```
ana@vm:~/slices-alias$ go run .
[1 2 99 4 5] [1 2 99]
2 2
[1 2 3 4 5] [1 2 99]
[1 2 3 4 5] [1 2 99]
```

Os dois primeiros casos lado a lado, como arrays:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Dois casos de append de 99 a head, uma slice dos dois primeiros elementos de nums, que guarda 1 2 3 4 5. Com head := nums[:2], head tem capacidade 5, então o append escreve 99 na terceira célula do mesmo array e nums vira 1 2 99 4 5. Com head := nums[:2:2], head tem capacidade 2, então o append copia 1 e 2 para um array novo, acrescenta 99 lá, e nums continua 1 2 3 4 5.\"><defs><marker id=\"sla-phosphor-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">head := nums[:2]</text><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">head = append(head, 99)</text><path d=\"M132 70 L132 64\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M132 64 L368 64\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M368 64 L368 70\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"250\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">nums   len 5  cap 5</text><rect x=\"130\" y=\"72\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"154.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"178\" y=\"72\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"202.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"226\" y=\"72\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></rect><text x=\"250.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">99</text><rect x=\"274\" y=\"72\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"298.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><rect x=\"322\" y=\"72\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"346.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><text x=\"70\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o array</text><path d=\"M132 104 L132 110\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M132 110 L272 110\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M272 110 L272 104\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"202\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">head   len 3  cap 5</text><text x=\"410\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">head tinha espaço até cap 5, então</text><text x=\"410\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o append escreveu 99 no array</text><text x=\"410\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">que nums continua lendo</text><path d=\"M20 150 L700 150\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">head := nums[:2:2]</text><text x=\"20\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">head = append(head, 99)</text><path d=\"M132 224 L132 218\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M132 218 L368 218\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M368 218 L368 224\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"250\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">nums   len 5  cap 5</text><rect x=\"130\" y=\"226\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"154.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"178\" y=\"226\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"202.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"226\" y=\"226\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><rect x=\"274\" y=\"226\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"298.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><rect x=\"322\" y=\"226\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"346.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><text x=\"70\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o array</text><path d=\"M154 258 L154 278\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sla-phosphor-dim)\"></path><path d=\"M202 258 L202 278\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sla-phosphor-dim)\"></path><text x=\"120\" y=\"268\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">copiado</text><rect x=\"130\" y=\"282\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"154.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"178\" y=\"282\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"202.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"226\" y=\"282\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></rect><text x=\"250.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">99</text><text x=\"70\" y=\"297\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um array novo</text><text x=\"312\" y=\"297\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">head   len 3</text><text x=\"410\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cap 2 não deixou espaço, então o append</text><text x=\"410\" y=\"249\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copiou 1 e 2 para um array novo</text><text x=\"410\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">e nums fica intacto</text></svg>", "caption": "Append numa sub-slice. Com espaço sobrando no array, o append escreve nele; com a capacidade cortada no comprimento, ele copia antes."}
```

A expressão de fatia completa `s[a:b:c]` é `s[a:b]` com a capacidade cortada para `c - a`. O `c`
não pode passar da capacidade que `s` já tem, o que é conferido como os limites da seção 02. Sem o
terceiro número, uma sub-slice herda todo o espaço até o fim do array; com ele, a sub-slice não é
dona de nada além do próprio comprimento, e o próximo `append` precisa copiar.

## Onde isso morde

Ninguém escreve o programa acima de propósito. O que as pessoas escrevem são duas slices montadas a
partir de um prefixo comum:

```go
package main

import "fmt"

func main() {
	path := make([]string, 0, 4)
	path = append(path, "home", "ana")

	docs := append(path, "docs")
	music := append(path, "music")
	fmt.Println(docs, music)
}
```

```
ana@vm:~/slices-path$ go run .
[home ana music] [home ana music]
```

`docs` nunca recebeu `music`, e imprime `music` mesmo assim. `path` tem comprimento 2 e capacidade
4, então os dois appends acharam espaço no índice 2 do mesmo array. O primeiro escreveu `docs` ali e
o segundo escreveu `music` por cima, e `docs` e `music` são duas visões desse único array. **Nada
quebrou e nada avisou; o bug só aparece quando a capacidade por acaso tem espaço**, e é por isso
que ele sobrevive ao teste com uma slice e aparece com outra. Cortar a capacidade do prefixo
resolve:

```go
package main

import "fmt"

func main() {
	path := make([]string, 0, 4)
	path = append(path, "home", "ana")
	path = path[:len(path):len(path)]

	docs := append(path, "docs")
	music := append(path, "music")
	fmt.Println(docs, music)
}
```

```
ana@vm:~/slices-path$ go run .
[home ana docs] [home ana music]
```

Agora todo `append` em `path` precisa copiar, então `docs` e `music` ganham cada um seu próprio
array.

O hábito que vale guardar é uma pergunta a fazer sempre que você der `append` numa slice que não foi
você que criou: **quem mais enxerga este array?** Se a resposta for "talvez alguém", corte a
capacidade com `s[:len(s):len(s)]` antes do `append`, ou tire um `slices.Clone` e acrescente nele.
A função da lição 11 que fazia `append` e perdia o resultado é o mesmo mecanismo visto do lado de
quem chama, e a lição 21 o reencontra quando uma função recebe argumentos `...`.
