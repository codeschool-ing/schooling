---
title: Lendo os números, e o que fazer com eles
version: 1
---

Uma linha do relatório da seção 02, desmontada:

| coluna | valor | o que é |
|---|---|---|
| nome | `BenchmarkCount-4` | o benchmark, e o `GOMAXPROCS` com que rodou |
| rodadas | `10363` | quantas vezes o corpo do laço rodou na execução medida |
| tempo | `113733 ns/op` | nanossegundos por rodada, o número principal |
| vazão | `81.03 MB/s` | do `b.SetBytes`: bytes por rodada sobre o tempo por rodada |
| memória | `16104 B/op` | bytes alocados por rodada |
| alocações | `2311 allocs/op` | alocações separadas por rodada |

**As duas colunas de memória costumam ser mais estáveis e dizer mais que o tempo.** O tempo depende
do processador, da temperatura dele e do que mais a máquina está fazendo. As alocações dependem só
do código, e toda alocação é trabalho para o coletor de lixo depois.

## Uma execução não é uma medição

O mesmo benchmark, cinco vezes seguidas, com `-count 5`:

```
ana@vm:~/wordcount$ go test -run '^$' -bench Count -benchmem -count 5
goos: linux
goarch: amd64
pkg: example.com/wordcount
cpu: Intel(R) Xeon(R) Processor
BenchmarkCount-4   	   12162	     98755 ns/op	  93.32 MB/s	   16104 B/op	    2311 allocs/op
BenchmarkCount-4   	   10000	    101442 ns/op	  90.85 MB/s	   16104 B/op	    2311 allocs/op
BenchmarkCount-4   	   10000	    101035 ns/op	  91.22 MB/s	   16104 B/op	    2311 allocs/op
BenchmarkCount-4   	   10000	    101532 ns/op	  90.77 MB/s	   16104 B/op	    2311 allocs/op
BenchmarkCount-4   	   10000	    101079 ns/op	  91.18 MB/s	   16104 B/op	    2311 allocs/op
PASS
ok  	example.com/wordcount	5.259s
```

As alocações não se mexem. Os cinco tempos ficam entre 98.755 e 101.532 nanossegundos, e a execução
única da seção 02, um minuto antes, disse 113.733: mais de dez por cento mais lenta que qualquer
uma destas, sem nada mudado no meio. Esse espalhamento é o piso de ruído, e **uma mudança menor que o
espalhamento entre execuções idênticas não foi medida**, por mais arrumado que o número novo pareça.

## Um candidato, medido

2311 alocações para cerca de 9 KB de texto é muito. A amostra é de 16 palavras repetidas 128 vezes,
2048 palavras, então cerca de uma alocação por palavra e mais algumas. Algumas são evitáveis no
papel: todo `The` e todo `Go` passa pelo `strings.ToLower`, que monta uma string nova. Uma versão
que põe em minúsculas o ASCII simples no próprio lugar e deixa o resto para o `strings.ToLower`,
salva como `wordcount.go`:

```go
// Package wordcount counts the words in a text.
package wordcount

import (
	"bufio"
	"bytes"
	"io"
	"strings"
	"unicode"
	"unicode/utf8"
)

// Count reads r to the end and returns how many times each word appears.
// Words are compared in lower case, with the punctuation around them removed.
func Count(r io.Reader) (map[string]int, error) {
	counts := make(map[string]int)
	sc := bufio.NewScanner(r)
	sc.Split(bufio.ScanWords)
	for sc.Scan() {
		w := bytes.TrimFunc(sc.Bytes(), notLetter)
		if len(w) == 0 {
			continue
		}
		if lowerASCII(w) {
			counts[string(w)]++
		} else {
			counts[strings.ToLower(string(w))]++
		}
	}
	return counts, sc.Err()
}

func notLetter(r rune) bool { return !unicode.IsLetter(r) && !unicode.IsDigit(r) }

// lowerASCII lowers w in place and reports whether that was enough: at the
// first byte outside ASCII it stops and returns false, and the caller hands
// the word to strings.ToLower instead.
func lowerASCII(w []byte) bool {
	for i, c := range w {
		switch {
		case c >= utf8.RuneSelf:
			return false
		case 'A' <= c && c <= 'Z':
			w[i] = c + 'a' - 'A'
		}
	}
	return true
}
```

**Os testes vêm primeiro**, porque uma resposta errada mais rápida não vale nada, e a tabela da lição
26 já cobre maiúsculas, acentos e pontuação. Depois as mesmas cinco execuções:

```
ana@vm:~/wordcount$ go test . -count=1
ok  	example.com/wordcount	0.068s
ana@vm:~/wordcount$ go test -run '^$' -bench Count -benchmem -count 5
goos: linux
goarch: amd64
pkg: example.com/wordcount
cpu: Intel(R) Xeon(R) Processor
BenchmarkCount-4   	   13570	     88953 ns/op	 103.61 MB/s	   13032 B/op	    2055 allocs/op
BenchmarkCount-4   	   13957	     87509 ns/op	 105.31 MB/s	   13032 B/op	    2055 allocs/op
BenchmarkCount-4   	   12561	     93811 ns/op	  98.24 MB/s	   13032 B/op	    2055 allocs/op
BenchmarkCount-4   	   13279	     89436 ns/op	 103.05 MB/s	   13032 B/op	    2055 allocs/op
BenchmarkCount-4   	   13435	     88568 ns/op	 104.06 MB/s	   13032 B/op	    2055 allocs/op
PASS
ok  	example.com/wordcount	5.992s
```

As alocações caíram de 2311 para 2055, exatamente 256: duas palavras com maiúscula por repetição,
128 repetições, e cada uma não precisa mais da sua cópia em minúsculas. As outras 2048, mais ou
menos, continuam lá, uma por palavra, porque a chave de um map é uma string e toda palavra ainda
vira uma. O tempo também caiu: as execuções novas ficam entre 87.509 e 93.811 nanossegundos, as
antigas entre 98.755 e 101.532. **As duas faixas não se sobrepõem, então essa diferença foi medida**,
em cerca de um décimo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Toda medição do BenchmarkCount desta lição num eixo de nanossegundos por rodada, de 85.000 a 115.000. As cinco execuções do candidato ficam entre 87.509 e 93.811. As cinco do original ficam entre 98.755 e 101.532. A execução única da seção 02 fica à parte, em 113.733. Os dois grupos de cinco não se sobrepõem.\"><text x=\"180\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">candidato, cinco execuções</text><rect x=\"227.8\" y=\"30\" width=\"113.09999999999997\" height=\"20\" rx=\"10\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><circle cx=\"255.9\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"231.8\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"336.9\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"263.9\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"249.5\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"180\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">original, cinco execuções</text><rect x=\"415.2\" y=\"80\" width=\"54.30000000000001\" height=\"20\" rx=\"10\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><circle cx=\"419.2\" cy=\"90\" r=\"4\" fill=\"var(--amber)\"></circle><circle cx=\"464.0\" cy=\"90\" r=\"4\" fill=\"var(--amber)\"></circle><circle cx=\"457.2\" cy=\"90\" r=\"4\" fill=\"var(--amber)\"></circle><circle cx=\"465.5\" cy=\"90\" r=\"4\" fill=\"var(--amber)\"></circle><circle cx=\"458.0\" cy=\"90\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"180\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma execução, seção 02</text><circle cx=\"668.9\" cy=\"140\" r=\"4\" fill=\"var(--paper-dim)\"></circle><path d=\"M190 185 H690\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M190.0 181 V189\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"190.0\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">85.000</text><path d=\"M273.3 181 V189\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"273.3\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">90.000</text><path d=\"M356.7 181 V189\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"356.7\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">95.000</text><path d=\"M440.0 181 V189\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"440.0\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100.000</text><path d=\"M523.3 181 V189\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"523.3\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">105.000</text><path d=\"M606.7 181 V189\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"606.7\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">110.000</text><path d=\"M690.0 181 V189\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"690.0\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">115.000</text><text x=\"690\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ns/op</text></svg>", "caption": "Cada ponto é uma execução. O espalhamento dentro de um grupo é o ruído; uma diferença conta quando os grupos não se sobrepõem."}
```

Medido não é o mesmo que valer a pena. O candidato custa vinte linhas a mais, um segundo caminho
para palavras fora do ASCII e uma escrita no próprio buffer do scanner em que o próximo leitor tem
de confiar. Um décimo a menos numa função que conta 9 KB em um décimo de milissegundo não compra nada
até algo mostrar que contar é onde um programa gasta o seu tempo, e nada aqui mostra. Então este
curso volta atrás: o `wordcount.go` volta à versão com que a lição 25 terminou, na seção 02 dela, e
os testes passam nela como antes. **O trabalho do benchmark era transformar "isto parece mais
rápido" num número**; decidir quanto vale o número é com você, e guardar uma medição jogando fora o
código que ela julgou é um resultado comum.
