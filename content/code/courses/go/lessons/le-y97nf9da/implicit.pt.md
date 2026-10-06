---
title: Satisfeita sem dizer
version: 1
---

Em Java ou C#, uma classe que quer ser usada como `Shape` diz isso na própria declaração:
`class Rect implements Shape`. Quem vem de lá procura a grafia Go de `implements`, e não há
nenhuma. Ela não está entre as 25 palavras-chave que a lição 1 contou, e nada mais ocupa o lugar
dela. **Em Go um tipo satisfaz uma interface por ter os métodos da interface, e por nada mais.** O
tipo não nomeia a interface, e não precisa saber que ela existe. Em `~/ifaces`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"math\"\n)\n"
    },
    {
      "code": "\ntype Shape interface {\n\tArea() float64\n}\n",
      "note": "**Um tipo interface é uma lista de assinaturas de métodos**, e nada mais: nem campos, nem código. Um `Shape` é qualquer coisa com um método `Area` que não recebe nada e devolve um `float64`."
    },
    {
      "code": "\ntype Rect struct {\n\tW, H float64\n}\n\nfunc (r Rect) Area() float64 {\n\treturn r.W * r.H\n}\n",
      "note": "Uma struct comum com um método comum, declarado do jeito que a lição 25 declara. Nada aqui menciona `Shape`."
    },
    {
      "code": "\ntype Circle struct {\n\tR float64\n}\n\nfunc (c Circle) Area() float64 {\n\treturn math.Pi * c.R * c.R\n}\n",
      "note": "Um segundo tipo, sem relação com o primeiro, com um método de mesmo nome e mesma assinatura. É só isso que precisa."
    },
    {
      "code": "\nfunc describe(s Shape) {\n\tfmt.Printf(\"%T with area %.2f\\n\", s, s.Area())\n}\n",
      "note": "**`describe` pede um `Shape`, então pode chamar `Area` e mais nada.** O `%T` imprime o tipo do valor que está dentro da interface, e é assim que a saída distingue os dois."
    },
    {
      "code": "\nfunc main() {\n\tdescribe(Rect{W: 3, H: 4})\n\tdescribe(Circle{R: 1})\n",
      "note": "Um `Rect` e um `Circle` são passados onde se pede um `Shape`. O compilador verifica, em cada chamada, que o conjunto de métodos do valor tem `Area`."
    },
    {
      "code": "\n\tshapes := []Shape{Rect{W: 2, H: 2}, Circle{R: 2}}\n\ttotal := 0.0\n\tfor _, s := range shapes {\n\t\ttotal += s.Area()\n\t}\n\tfmt.Printf(\"total %.2f\\n\", total)\n}\n",
      "note": "Um slice de `Shape` guarda valores de tipos diferentes lado a lado, e o laço chama o `Area` certo de cada um: 4 para o `Rect` quadrado, cerca de 12,57 para o círculo de raio 2."
    }
  ],
  "output": "main.Rect with area 12.00\nmain.Circle with area 3.14\ntotal 16.57"
}
```

Nem `Rect` nem `Circle` foram declarados como `Shape`, e os dois foram aceitos como um. Se você
apagasse o tipo `Shape` e `describe` junto, as duas structs compilariam sem mudança, porque nada
nelas se refere a ele. **A relação só existe onde um valor é usado como `Shape`, e é ali que o
compilador a verifica.**

Um valor de tipo interface guarda um valor de algum tipo concreto, e a lição 22 mediu quanto isso
custa: 16 bytes, uma palavra dizendo qual tipo está dentro e outra apontando para uma cópia do
valor. O `%T` imprimiu a primeira palavra. Chamar `s.Area()` executa o `Area` do tipo que essa
palavra nomeia.

## Uma interface, três pacotes

A biblioteca padrão é construída sobre isso, e uma função mostra. `fmt.Fprintf` é o `Printf` com
um lugar para onde escrever, e esse lugar é uma interface do pacote `io`:

```
ana@vm:~/ifaces-writer$ go doc fmt.Fprintf
package fmt // import "fmt"

func Fprintf(w io.Writer, format string, a ...any) (n int, err error)
    Fprintf formats according to a format specifier and writes to w. It returns
    the number of bytes written and any write error encountered.

ana@vm:~/ifaces-writer$ go doc io.Writer | head -5
package io // import "io"

type Writer interface {
	Write(p []byte) (n int, err error)
}
```

Um método. Qualquer coisa com um método `Write` desse formato é um `io.Writer`, então o `Fprintf`
pode escrever num terminal, num buffer na memória e numa string em construção, com a mesma
chamada:

```go
package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"strings"
)

func main() {
	var buf bytes.Buffer
	var sb strings.Builder

	writers := []io.Writer{os.Stdout, &buf, &sb}
	for i, w := range writers {
		fmt.Fprintf(w, "line %d, written to a %T\n", i, w)
	}

	fmt.Print(buf.String())
	fmt.Print(sb.String())
}
```

```
ana@vm:~/ifaces-writer$ go run .
line 0, written to a *os.File
line 1, written to a *bytes.Buffer
line 2, written to a *strings.Builder
```

A primeira linha foi direto para o terminal, porque `os.Stdout` é o arquivo aberto por trás dele.
As outras duas foram para a memória, e as duas últimas chamadas de `fmt.Print` as trouxeram para
fora. O buffer e o builder são passados como `&buf` e `&sb` porque os métodos `Write` deles têm
receptor ponteiro, que é a regra da lição 26; a seção 04 mostra o que passar o próprio `sb` faz.

Agora leia os três métodos `Write` como os pacotes os declaram:

```
ana@vm:~/ifaces-writer$ go doc os.File.Write | sed -n 3p
func (f *File) Write(b []byte) (n int, err error)
ana@vm:~/ifaces-writer$ go doc bytes.Buffer.Write | sed -n 3p
func (b *Buffer) Write(p []byte) (n int, err error)
ana@vm:~/ifaces-writer$ go doc strings.Builder.Write | sed -n 3p
func (b *Builder) Write(p []byte) (int, error)
```

O parâmetro é `b` num e `p` noutro, e os resultados do builder não têm nome nenhum. Nada disso
importa. **O que precisa casar é o nome do método e os tipos dos seus parâmetros e resultados**,
em ordem: um `[]byte` entra, um `int` e um `error` saem. Os nomes são documentação.

E o arquivo que declara `strings.Builder` nem importa `io`:

```
ana@vm:~/ifaces-writer$ sed -n "/^import/,/^)/p" /usr/local/go/src/strings/builder.go
import (
	"internal/abi"
	"internal/bytealg"
	"unicode/utf8"
	"unsafe"
)
```

Então `strings.Builder` se encaixa em `io.Writer` sem que o código-fonte dele jamais nomeie o
pacote que declara a interface. O `Write` dele tem o formato certo, e essa é a ligação inteira.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Três tipos de três pacotes, *os.File, *bytes.Buffer e *strings.Builder, cada um com um método Write que recebe um []byte e devolve um int e um error, seja qual for o nome dos parâmetros. Setas tracejadas saem de cada um para a interface io.Writer, que lista esse único método, e io.Writer é o tipo do primeiro parâmetro de fmt.Fprintf. Nenhum dos três tipos declara que satisfaz io.Writer; o compilador compara conjuntos de métodos onde um valor é passado.\"><defs><marker id=\"iw-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"135\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">três tipos, três pacotes</text><rect x=\"20\" y=\"40\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">*os.File</text><text x=\"32\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Write(b []byte) (n int, err error)</text><path d=\"M250 65 L295 65 L295 120 L336 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#iw-phosphor)\"></path><rect x=\"20\" y=\"105\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">*bytes.Buffer</text><text x=\"32\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Write(p []byte) (n int, err error)</text><path d=\"M250 130 L295 130 L295 140 L336 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#iw-phosphor)\"></path><rect x=\"20\" y=\"170\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">*strings.Builder</text><text x=\"32\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Write(p []byte) (int, error)</text><path d=\"M250 195 L295 195 L295 160 L336 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#iw-phosphor)\"></path><text x=\"298\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tem o método</text><text x=\"450\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a interface</text><rect x=\"340\" y=\"100\" width=\"220\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"354\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">type io.Writer interface {</text><text x=\"366\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Write(p []byte) (n int, err error)</text><text x=\"354\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">}</text><text x=\"647\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a função que pede</text><rect x=\"586\" y=\"115\" width=\"124\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"648\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">fmt.Fprintf(</text><text x=\"648\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">w io.Writer, ...)</text><path d=\"M582 140 L564 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#iw-phosphor)\"></path><path d=\"M20 248 L700 248\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Nenhum dos três declara que satisfaz io.Writer. O compilador compara o conjunto de métodos</text><text x=\"20\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">de cada valor com a interface na chamada, e essa comparação é o contrato inteiro.</text></svg>", "caption": "Uma interface é satisfeita por quem tem os seus métodos. Os três tipos foram escritos sem pensar em io.Writer, e os três se encaixam nela."}
```

Esta é a metade da herança que a lição 16 deixou para as interfaces: deixar tipos diferentes
ocuparem o lugar uns dos outros. Uma hierarquia de classes decide isso de antemão, na declaração
de cada classe. **Uma interface decide no ponto de uso, e um tipo escrito anos antes pode
satisfazer uma interface escrita hoje**, o que a seção 03 mostra com três tipos de `time`.
