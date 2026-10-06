---
title: Indexar uma string dá bytes
version: 1
---

A leitura natural de `s[3]` é "o quarto caractere de `s`". **Em Go é o quarto byte**, e a lição 8
mostrou que um caractere fora do ASCII ocupa mais de um. Com `café`, essa diferença aparece na
quarta posição, que é exatamente onde está o `é`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"strings\"\n\t\"unicode/utf8\"\n)\n\nfunc main() {\n\ts := \"café\"\n\tfmt.Println(len(s), utf8.RuneCountInString(s))\n",
      "note": "**`len` conta bytes e `utf8.RuneCountInString` conta runes**: 5 e 4 para `café`, cujo `é` tem dois bytes."
    },
    {
      "code": "\tfmt.Println(utf8.RuneCountInString(\"cafe\\u0301\"))\n",
      "note": "A grafia decomposta da lição 8, `cafe\\u0301`, tem 5 runes, embora o leitor veja quatro caracteres."
    },
    {
      "code": "\tfmt.Println(s[0], s[3], s[4])\n",
      "note": "Indexar dá bytes. `s[0]` é 99, o `c`; `s[3]` e `s[4]` são 195 e 169, as duas metades do `é`, que a lição 8 imprimiu em hexadecimal como `c3 a9`."
    },
    {
      "code": "\tfmt.Printf(\"%T %c\\n\", s[3], s[3])\n",
      "note": "O `%T` confirma que `s[3]` é um `uint8`. Impresso com `%c`, 195 vira `Ã`, o caractere cujo code point é 195: **um byte lido como caractere dá o caractere errado**, e nenhum erro."
    },
    {
      "code": "\tfmt.Printf(\"%q %q\\n\", s[:3], s[:4])\n",
      "note": "Recortar com `s[a:b]` também conta bytes. `s[:3]` para antes do `é`; `s[:4]` corta o `é` ao meio e deixa um `\\xc3` sozinho, que o `%q` mostra como escape."
    },
    {
      "code": "\tfmt.Println(utf8.ValidString(s[:4]), utf8.ValidString(s))\n",
      "note": "O `utf8.ValidString` pega o corte: `false` para a metade, `true` para a palavra inteira."
    },
    {
      "code": "\tfmt.Println(strings.Index(\"café au lait\", \"au\"))\n",
      "note": "As funções de `strings` também respondem em posições de byte. Em `café au lait`, `au` começa no byte 6, embora só cinco caracteres venham antes dele."
    },
    {
      "code": "\tr, size := utf8.DecodeRuneInString(s[3:])\n\tfmt.Printf(\"%c %d\\n\", r, size)\n}\n",
      "note": "Para ler a rune que começa numa posição de byte, `utf8.DecodeRuneInString` devolve a rune e quantos bytes ela ocupou: `é` e 2. Uma chamada que devolve dois resultados é Go comum, e a lição 20 trata delas."
    }
  ],
  "output": "5 4\n5\n99 195 169\nuint8 Ã\n\"caf\" \"caf\\xc3\"\nfalse true\n6\né 2"
}
```

A regra que decorre disso: **recorte uma string só numa posição que uma função encontrou para você**,
como `strings.Index`, e nunca numa que você contou em caracteres. Quando as duas strings são UTF-8
válido, a posição que o `strings.Index` devolve é onde uma rune começa, então recortar ali mantém os
dois pedaços válidos. Percorrer uma string uma rune por vez, sem fazer a conta você mesmo, é o que
um laço `for range` sobre uma string faz, e a lição 17 mostra isso.

## Uma string pode guardar quaisquer bytes

Nada impede uma string de guardar bytes que não são UTF-8. Um arquivo-fonte Go é UTF-8, então o
texto que você digita entre aspas é válido; os escapes `\x` e octais, um arquivo lido do disco e o
corpo de uma requisição de rede podem pôr qualquer coisa ali:

```go
package main

import (
	"fmt"
	"unicode/utf8"
)

func main() {
	b := "\xff\xfe"
	fmt.Println(len(b), utf8.ValidString(b), utf8.RuneCountInString(b))
	fmt.Printf("%q % x\n", b, b)
}
```

```
ana@vm:~/strings-invalid$ go run .
2 false 2
"\xff\xfe" ff fe
```

`ff fe` é a marca de ordem de bytes do começo de um arquivo codificado em UTF-16 little-endian, e
como UTF-8 são dois bytes que não começam caractere nenhum. O `utf8.ValidString` diz isso. O
`RuneCountInString` ainda responde 2, porque conta cada byte que não consegue decodificar como uma
rune, então uma contagem sozinha não diz que o texto era válido. **Quando uma string vem de fora do
seu programa, confira com `utf8.ValidString` antes de tratá-la como texto.**

Então cada pergunta que esta lição e a anterior levantaram tem agora uma função que a responde:

| você quer | escreva | para `café` |
|---|---|---|
| o tamanho em bytes | `len(s)` | 5 |
| o número de runes | `utf8.RuneCountInString(s)` | 4 |
| se é UTF-8 válido | `utf8.ValidString(s)` | `true` |

A terceira contagem da lição 8, caracteres como o leitor os vê, continua fora da biblioteca padrão,
e o `café` decomposto acima é o lembrete: 5 runes, 4 caracteres.
