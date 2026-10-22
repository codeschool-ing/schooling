---
title: O que uma linha coberta não diz
version: 1
---

Uma linha marcada como coberta rodou pelo menos uma vez durante os testes. É só isso que ela diz.
Ela não diz que o resultado foi conferido, que a linha está certa para toda entrada, nem que duas
goroutines rodando-a ao mesmo tempo concordam. **Cobertura alta é sinal de que os testes vão a toda
parte; nunca é evidência de que o código está certo lá.**

## Coberto, e ainda errado

O `Top` está em 100%. Cada uma das instruções dele rodou na tabela do `TestTop`. Uma pergunta sobre
ele, feita num arquivo descartável, salvo como `negative_test.go`:

```go
package wordcount

import "testing"

func TestTopNegative(t *testing.T) {
	got := Top(map[string]int{"go": 1}, -1)
	t.Logf("Top(..., -1) = %v", got)
}
```

```
ana@vm:~/wordcount$ go test -run TestTopNegative
--- FAIL: TestTopNegative (0.00s)
panic: runtime error: slice bounds out of range [:-1] [recovered, repanicked]

goroutine 8 [running]:
testing.tRunner.func1.2({0xbd3a68, 0x16648526e168})
	/usr/local/go/src/testing/testing.go:2123 +0x232
testing.tRunner.func1()
	/usr/local/go/src/testing/testing.go:2126 +0x329
panic({0xbd3a68?, 0x16648526e168?})
	/usr/local/go/src/runtime/panic.go:859 +0x125
example.com/wordcount.Top(0x16648529d720, 0xffffffffffffffff)
	/home/ana/wordcount/top.go:28 +0x1df
example.com/wordcount.TestTopNegative(0x166485386488)
	/home/ana/wordcount/negative_test.go:6 +0xcd
testing.tRunner(0x166485386488, 0xbf1220)
	/usr/local/go/src/testing/testing.go:2193 +0xea
created by testing.(*T).Run in goroutine 1
	/usr/local/go/src/testing/testing.go:2258 +0x4d4
exit status 2
FAIL	example.com/wordcount	0.005s
```

**Um pânico, numa função com cobertura total.** `entries[:min(n, len(entries))]` é uma instrução que
os testes rodaram muitas vezes, com `n` de 0, 1, 4 e 9; com `-1` a mesma instrução fatia fora dos
limites. A cobertura conta instruções alcançadas, não os valores com que foram alcançadas, e a
tabela nunca teve uma linha negativa. O `Handler` recusa `n` abaixo de 1 antes de chamar o `Top`,
então o caminho web está seguro; qualquer outro chamador desta função exportada não está.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Os valores de n que chegaram à última instrução de Top. A tabela do TestTop tentou 0, 1, 4 e 9, e a instrução foi marcada como coberta depois do primeiro deles. O valor -1 nunca foi tentado, e com ele a mesma instrução entra em pânico. A cobertura registra que a instrução rodou, não com que valores.\"><rect x=\"200\" y=\"16\" width=\"320\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">entries[:min(n, len(entries))]</text><text x=\"360\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma instrução, marcada como coberta</text><path d=\"M80 140 H660\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80.0 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80.0\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">-2</text><path d=\"M128.3 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"128.3\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">-1</text><path d=\"M176.7 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"176.7\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M225.0 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"225.0\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M273.3 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"273.3\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M321.7 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"321.7\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><path d=\"M370.0 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"370.0\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M418.3 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"418.3\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M466.7 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"466.7\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M515.0 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"515.0\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><path d=\"M563.3 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"563.3\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><path d=\"M611.7 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"611.7\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9</text><path d=\"M660.0 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"660.0\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><text x=\"680\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">n</text><circle cx=\"176.7\" cy=\"140\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M176.7 132 L360 76\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><circle cx=\"225.0\" cy=\"140\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M225.0 132 L360 76\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><circle cx=\"370.0\" cy=\"140\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M370.0 132 L360 76\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><circle cx=\"611.7\" cy=\"140\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M611.7 132 L360 76\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><circle cx=\"128.3\" cy=\"140\" r=\"6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><text x=\"128.3\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">nunca tentado: pânico</text><text x=\"490.8\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">tentados pelo TestTop: coberto</text></svg>", "caption": "A cobertura marca uma instrução quando ela roda uma vez; os valores que ela nunca encontrou ficam invisíveis."}
```

O conserto é uma decisão sobre o que o `Top` promete. Um `n` negativo não pede nada, então não
devolve nada, como o 0. O `top.go` com essa linha, salvo como `top.go`:

```go
package wordcount

import (
	"cmp"
	"slices"
	"strings"
)

// Entry is one word and how many times it appeared.
type Entry struct {
	Word  string
	Count int
}

// Top returns the n most frequent words in counts, most frequent first.
// Words with the same count come in alphabetical order. An n below 1
// returns no words.
func Top(counts map[string]int, n int) []Entry {
	entries := make([]Entry, 0, len(counts))
	for w, c := range counts {
		entries = append(entries, Entry{w, c})
	}
	slices.SortFunc(entries, func(a, b Entry) int {
		if c := cmp.Compare(b.Count, a.Count); c != 0 {
			return c
		}
		return strings.Compare(a.Word, b.Word)
	})
	return entries[:max(0, min(n, len(entries)))]
}
```

O teste descartável sai, e a pergunta dele vira uma linha da tabela do `TestTop` no arquivo da lição
26: `{"negative", -1, []Entry{}}`, acrescentada depois da linha `none`.

```
ana@vm:~/wordcount$ rm negative_test.go
ana@vm:~/wordcount$ go test -run TestTop -v
=== RUN   TestTopOf
--- PASS: TestTopOf (0.00s)
=== RUN   TestTopOfOpenFails
--- PASS: TestTopOfOpenFails (0.00s)
=== RUN   TestTopOfClosesTheDocument
--- PASS: TestTopOfClosesTheDocument (0.00s)
=== RUN   TestTop
=== RUN   TestTop/first
=== RUN   TestTop/ties
=== RUN   TestTop/more_than_there_are
=== RUN   TestTop/none
=== RUN   TestTop/negative
--- PASS: TestTop (0.00s)
    --- PASS: TestTop/first (0.00s)
    --- PASS: TestTop/ties (0.00s)
    --- PASS: TestTop/more_than_there_are (0.00s)
    --- PASS: TestTop/none (0.00s)
    --- PASS: TestTop/negative (0.00s)
PASS
ok  	example.com/wordcount	0.003s
```

O `-run TestTop` também rodou os três testes `TestTopOf`, o padrão sem âncora sobre o qual a lição
26 avisou, e todos passaram, a linha nova inclusive. E a cobertura do `Top`:

```
ana@vm:~/wordcount$ go test -coverprofile=c.out >/dev/null && go tool cover -func=c.out | grep Top
example.com/wordcount/source.go:16:	TopOf		100.0%
example.com/wordcount/top.go:18:	Top		100.0%
```

Antes do conserto, o `Top` estava em 100%; depois dele, o `Top` continua em 100%. **O número nunca
se mexeu, e o defeito veio e foi embora por baixo dele.**

## Mais três coisas que uma porcentagem não vê

- **Uma conferência que falta.** Um teste que chama uma função e não afirma nada cobre toda linha
  que alcança. Um conjunto de testes pode ter a cobertura de um cuidadoso e não testar quase nada.
- **Uma corrida.** O `count.go` da lição 1 não tem desvio nenhum, então uma execução alcança toda
  instrução, e ele imprimiu o total errado em quatro execuções de cinco. Só o `-race` vê isso, e
  `go test -race -cover` mede os dois de uma vez.
- **Um caso que nem está no código.** A cobertura mede o código que existe. Quando o defeito é um
  `if` que falta, não há linha vermelha para achar, porque a linha nunca foi escrita. A tabela da
  lição 26 e a pergunta "que entrada eu ainda não tentei" acham esses; a cobertura não.
