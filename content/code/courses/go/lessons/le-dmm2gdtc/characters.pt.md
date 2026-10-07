---
title: Um caractere também não é uma rune
version: 1
---

Depois da seção anterior dá vontade de concluir que "uma rune é um caractere". É mais perto do que
"um byte é um caractere", e continua errado. **O que um leitor vê como um caractere pode ser várias
runes**, e duas strings que parecem idênticas podem guardar runes diferentes.

A letra `é` tem duas grafias no Unicode. Uma é o code point único U+00E9. A outra é um `e` simples,
U+0065, seguido de U+0301, o acento agudo combinante, um code point feito para se apoiar na letra
anterior. O Unicode define as duas como **canonicamente equivalentes**: o mesmo
caractere, escrito de dois jeitos. Go não sabe disso, e este programa em `~/runes-cafe` mostra o
que ele sabe:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"unicode\"\n)\n\nfunc main() {\n\tcomposed := \"caf\\u00e9\"\n\tdecomposed := \"cafe\\u0301\"\n",
      "note": "**Duas grafias da mesma palavra.** `\\u00e9` é o `é` como um único code point; `e\\u0301` é um `e` simples seguido do acento agudo combinante. Estão escritos como escapes para o código mostrar qual é qual."
    },
    {
      "code": "\tfmt.Println(composed == decomposed)\n",
      "note": "O `==` entre strings compara bytes, e os bytes diferem, então ele imprime `false` para duas palavras que um leitor não distingue."
    },
    {
      "code": "\tfmt.Println(len(composed), len(decomposed))\n",
      "note": "O `len` conta bytes: 5 e 6. O `é` pré-composto ocupa dois bytes, e o `e` com seu acento ocupa três."
    },
    {
      "code": "\tfmt.Printf(\"%+q\\n%+q\\n\", composed, decomposed)\n",
      "note": "O `%+q` põe a string entre aspas e escapa tudo o que está fora do ASCII, e isso deixa as runes visíveis: quatro na primeira palavra, cinco na segunda."
    },
    {
      "code": "\tfmt.Printf(\"% x\\n% x\\n\", composed, decomposed)\n",
      "note": "O `% x` mostra os próprios bytes. O acento sozinho, U+0301, é `cc 81`."
    },
    {
      "code": "\tfmt.Println(unicode.IsLetter('\\u0301'), unicode.IsMark('\\u0301'))\n}\n",
      "note": "**O pacote `unicode` sabe o que é U+0301**: não uma letra, mas uma marca, que se combina com a letra anterior. É daí que partiria quem quisesse dividir um texto em caracteres."
    }
  ],
  "output": "false\n5 6\n\"caf\\u00e9\"\n\"cafe\\u0301\"\n63 61 66 c3 a9\n63 61 66 65 cc 81\nfalse true"
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A palavra café escrita com o acento como marca combinante, em três linhas. Quatro caracteres: c, a, f, é. Cinco runes: U+0063, U+0061, U+0066, U+0065 e U+0301, porque o é é um e seguido do acento. Seis bytes: 63, 61, 66, 65, cc e 81, porque o acento ocupa dois bytes em UTF-8.\"><text x=\"20\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4 caracteres</text><text x=\"20\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que o leitor vê</text><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">5 runes</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os code points</text><text x=\"20\" y=\"197\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">6 bytes</text><text x=\"20\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que o len conta</text><rect x=\"203\" y=\"33\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">c</text><rect x=\"283\" y=\"33\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">a</text><rect x=\"363\" y=\"33\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">f</text><rect x=\"443\" y=\"33\" width=\"234\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">é</text><rect x=\"203\" y=\"108\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">U+0063</text><rect x=\"283\" y=\"108\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">U+0061</text><rect x=\"363\" y=\"108\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">U+0066</text><rect x=\"443\" y=\"108\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">U+0065</text><rect x=\"523\" y=\"108\" width=\"154\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">U+0301</text><rect x=\"203\" y=\"183\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">63</text><rect x=\"283\" y=\"183\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">61</text><rect x=\"363\" y=\"183\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">66</text><rect x=\"443\" y=\"183\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">65</text><rect x=\"523\" y=\"183\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">cc</text><rect x=\"603\" y=\"183\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">81</text></svg>", "caption": "Uma palavra, três comprimentos: café com o acento escrito como marca combinante. A parte destacada é a letra é, uma só.", "same": ["5 runes", "6 bytes"]}
```

## Uma bandeira são duas runes desenhadas como uma

O `é` decomposto não é um caso raro guardado para prova. Um texto vindo de outro programa pode
chegar em qualquer das duas formas, nada nos bytes diz qual, e os emojis tornam rotina várias runes
por caractere. Uma bandeira nacional não tem code point próprio: são dois símbolos **indicadores
regionais**, as letras do código do país, e uma fonte que conhece o par desenha uma bandeira. Brasil
é B e R:

```go
package main

import "fmt"

func main() {
	brazil := "\U0001F1E7\U0001F1F7"
	fmt.Printf("%+q\n", brazil)
	fmt.Println(len(brazil))
	fmt.Printf("%U %U\n", '\U0001F1E7', '\U0001F1F7')
}
```

```
ana@vm:~/runes-flag$ go run .
"\U0001f1e7\U0001f1f7"
8
U+1F1E7 U+1F1F7
```

Uma figura na tela, duas runes, oito bytes. Cada indicador ocupa quatro bytes de UTF-8, e nenhum
dos dois significa nada para um leitor sozinho. O que um leitor chama de caractere, o Unicode chama
de **grapheme cluster**: um ou mais code points desenhados e editados como uma unidade, aquilo que
o cursor de um editor de texto atravessa num só movimento.

## O que a biblioteca padrão não faz

A biblioteca padrão de Go tem três pacotes para texto Unicode, e nenhum deles divide uma string em
grapheme clusters:

```
ana@vm:~/runes-flag$ go list std | grep '^unicode'
unicode
unicode/utf16
unicode/utf8
ana@vm:~/runes-flag$ go doc unicode.Version
package unicode // import "unicode"

const Version = "17.0.0"
    Version is the Unicode edition from which the tables are derived.
```

O `unicode` responde perguntas sobre uma rune de cada vez, a partir das tabelas do Unicode 17.0.0:
é letra, é dígito, é marca. O `unicode/utf8` converte entre runes e bytes, e a lição 9 o usa.
Nenhum dos dois sabe que U+0301 pertence ao `e` antes dele. Transformar `cafe\u0301` em `caf\u00e9`
se chama normalização, e o pacote que faz isso, `golang.org/x/text/unicode/norm`, mora num módulo
mantido pelo projeto Go fora da biblioteca padrão; a lição 38 acrescenta esse módulo a um programa.
Dividir texto em grapheme clusters fica para módulos de terceiros, e a lição 40 trata de como
escolher um.

Então uma palavra tem três comprimentos, e cada um responde a uma pergunta diferente:

| contagem | o que mede | em Go |
|---|---|---|
| bytes | o espaço que ocupa na memória, num arquivo, na rede | `len(s)` |
| runes | os code points de que é feita | `utf8.RuneCountInString(s)`, lição 9 |
| caracteres | o que o leitor vê, e o que o cursor atravessa | fora da biblioteca padrão |

**Antes de medir um texto, decida qual dos três pediram a você.** Uma coluna de banco de dados
limitada a 20 bytes, um formulário que aceita 20 caracteres e um protocolo que conta code points
são três limites diferentes, e o mesmo nome pode caber num e estourar outro.
