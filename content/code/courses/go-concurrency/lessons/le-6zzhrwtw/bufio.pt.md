---
title: bufio, e por que um byte de cada vez é lento
version: 1
---

Todo `Write` num `*os.File` é um pedido ao sistema operacional, uma **chamada de sistema**, e uma
chamada de sistema custa muito mais que os poucos bytes que a maioria das escritas carrega. Todo
`Read` também é uma. **O `bufio` põe um buffer entre o seu código e o arquivo**, para que muitas
escritas pequenas virem uma grande e uma leitura grande sirva muitas pequenas. Ele tem duas metades,
um Writer e um Scanner, e cada uma tem um jeito de dar errado que vale ver uma vez.

## Escrevendo por um buffer

O programa escreve as mesmas 100.000 linhas curtas três vezes: direto num arquivo, por um
`bufio.Writer`, e por um `bufio.Writer` que nunca recebe flush. Salvo como `buffered.go`:

```go
// Command buffered writes the same 100,000 lines with and without a bufio.Writer.
package main

import (
	"bufio"
	"fmt"
	"os"
	"time"
)

func main() {
	start := time.Now()
	f, _ := os.Create("plain.txt")
	for i := range 100_000 {
		fmt.Fprintf(f, "line %d\n", i)
	}
	f.Close()
	fmt.Println("unbuffered:", time.Since(start).Round(time.Millisecond))

	start = time.Now()
	g, _ := os.Create("buffered.txt")
	w := bufio.NewWriter(g)
	for i := range 100_000 {
		fmt.Fprintf(w, "line %d\n", i)
	}
	w.Flush()
	g.Close()
	fmt.Println("buffered:  ", time.Since(start).Round(time.Millisecond))

	h, _ := os.Create("forgot.txt")
	v := bufio.NewWriter(h)
	for i := range 100_000 {
		fmt.Fprintf(v, "line %d\n", i)
	}
	h.Close()
}
```

```
ana@vm:~/files$ go run buffered.go
unbuffered: 39ms
buffered:   6ms
ana@vm:~/files$ wc -c plain.txt buffered.txt forgot.txt
1088890 plain.txt
1088890 buffered.txt
1085440 forgot.txt
3263220 total
ana@vm:~/files$ tail -c 15 forgot.txt; echo '<- end of file'
line 99685
line<- end of file
```

**A execução com buffer levou 6 milissegundos contra 39**, porque 100.000 chamadas a `Fprintf`
viraram cerca de 266 escritas de 4.096 bytes cada, em vez de 100.000 escritas de nove ou dez. Os
dois primeiros arquivos são idênticos, 1.088.890 bytes cada.

O terceiro arquivo é o aviso. Ele tem 1.085.440 bytes, que são 265 vezes 4.096: **todo buffer cheio
chegou ao arquivo, e o último, pela metade, não chegou**, porque nada chamou o `Flush`. O arquivo
para no meio de uma linha, em `line`, e nenhum erro foi informado em lugar nenhum. Fechar o
`*os.File` embaixo não faz o flush do `bufio.Writer` em cima; só o `Flush` faz, e vale conferir o
erro dele pelo mesmo motivo que o do `Close` na seção 02.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O que o bufio.Writer faz com 100.000 escritas pequenas. O programa chama Fprintf 100.000 vezes com nove ou dez bytes cada. O bufio.Writer as junta num buffer de 4.096 bytes e passa ao arquivo um buffer cheio por vez: cerca de 266 chamadas de sistema em vez de 100.000. Sem Flush, os últimos 3.450 bytes ficam no buffer e nunca chegam ao arquivo.\"><defs><marker id=\"l18buf-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18buf-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o seu programa</text><text x=\"105\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Fprintf(w, ...)</text><path d=\"M192 85 H268\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18buf-amber)\"></path><text x=\"230\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">100.000 escritas de 9 ou 10 bytes</text><rect x=\"270\" y=\"50\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">bufio.Writer</text><text x=\"360\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um buffer de 4.096 bytes</text><path d=\"M452 85 H528\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18buf-phosphor)\"></path><text x=\"490\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">cerca de 266 chamadas de sistema</text><rect x=\"530\" y=\"50\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o arquivo</text><text x=\"615\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">*os.File</text><rect x=\"200\" y=\"178\" width=\"320\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><path d=\"M360 122 V176\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"360\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">sem Flush: os últimos 3.450 bytes ficam aqui</text></svg>", "caption": "Um buffer transforma muitas escritas pequenas em poucas grandes, e segura a última, incompleta, até o Flush."}
```

## Lendo linha a linha

O `bufio.Scanner` é o jeito comum de ler texto uma linha por vez. Ele lê pedaços grandes por baixo e
entrega uma linha por `Scan`, sem a quebra de linha. Salvo como `lines.go`:

```go
// Command lines counts the lines of a file with a bufio.Scanner.
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	f, err := os.Open(os.Args[1])
	if err != nil {
		fmt.Println(err)
		return
	}
	defer f.Close()

	s := bufio.NewScanner(f)
	if len(os.Args) > 2 {
		limit, _ := strconv.Atoi(os.Args[2])
		s.Buffer(make([]byte, 64*1024), limit)
	}
	n, longest := 0, 0
	for s.Scan() {
		n++
		longest = max(longest, len(s.Text()))
	}
	if err := s.Err(); err != nil {
		fmt.Println("stopped after", n, "lines:", err)
		return
	}
	fmt.Println(n, "lines, the longest", longest, "bytes")
}
```

Ele conta o `plain.txt`, depois um arquivo com uma linha de 100.000 caracteres acrescentada no fim,
feito no shell, e depois o mesmo arquivo de novo com um segundo argumento que aumenta o limite:

```
ana@vm:~/files$ go run lines.go plain.txt
100000 lines, the longest 10 bytes
ana@vm:~/files$ head -c 100000 /dev/zero | tr '\0' x > long.txt; echo >> long.txt
ana@vm:~/files$ cat plain.txt long.txt > mixed.txt
ana@vm:~/files$ go run lines.go mixed.txt
stopped after 100000 lines: bufio.Scanner: token too long
ana@vm:~/files$ go run lines.go mixed.txt 1048576
100001 lines, the longest 100000 bytes
```

**Um Scanner recusa uma linha maior que 64 KiB por padrão**, e não cai nem pula: o `Scan` devolve
`false`, o laço termina como se o arquivo tivesse terminado, e só o `s.Err()` diz
`bufio.Scanner: token too long`. Um programa que nunca chamasse `s.Err()` teria informado 100.000
linhas e dado o dia por encerrado. O `s.Buffer` sobe o teto, aqui para os 1.048.576 bytes passados na
linha de comando, e a linha longa foi lida.

Então a regra de um Scanner tem duas partes: **confira sempre o `s.Err()` depois do laço, e defina o
`s.Buffer` quando as linhas puderem ser longas**, como arquivos de log e JSON minificado costumam
ter. Para dados que não são divididos em linhas, o `bufio.Reader` oferece `ReadString`, `ReadByte` e
o resto, com o mesmo buffer por baixo.
