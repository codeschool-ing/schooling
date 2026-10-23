---
title: A análise de escape no hits
version: 1
---

A lição 13 deixou o `tally` fazendo **uma alocação por linha** do log, em vez de duas, e o profile
apontou a que sobrou sem dizer por que ela estava lá. O relatório do compilador diz por quê. Ana monta
o `~/escape-hits` com o `tools/genlog/main.go` e o `main.go` da lição 1, o `internal/tally/tally.go` e
o `internal/tally/split.go` da lição 13, o módulo `example.com/hits` e o log de 100.000 linhas da
lição 12 em `internal/tally/testdata/access.log`.

## O relatório do `tally`

O `hits` é um programa, e o aviso da seção 02 vale: o pacote nomeado na linha de comando é o `main`, e
o código que importa está num pacote que ele importa.

```
ana@vm:~/escape-hits$ go build -gcflags=-m . 2>&1 | grep -c tally/
0
ana@vm:~/escape-hits$ go build -gcflags='example.com/hits/...=-m' . 2>&1 | grep -c tally/
40
ana@vm:~/escape-hits$ go build -gcflags=all=-m . 2>&1 | wc -l
44067
```

**Nada sobre o `tally` sem padrão, 40 linhas com um, e 44.067 com `all`**, quase todas da biblioteca
padrão. Então fica o padrão do módulo, com as linhas de inlining filtradas:

```
ana@vm:~/escape-hits$ go build -gcflags='example.com/hits/...=-m' . 2>&1 | grep tally/ | grep -v inlin
internal/tally/split.go:7:13: leaking param: line to result f level=0
internal/tally/tally.go:26:12: leaking param: line
internal/tally/tally.go:31:30: ... argument does not escape
internal/tally/tally.go:31:59: len(all) escapes to heap
internal/tally/tally.go:31:30: &errors.errorString{...} escapes to heap
internal/tally/tally.go:41:29: ... argument does not escape
internal/tally/tally.go:41:29: &errors.errorString{...} escapes to heap
internal/tally/tally.go:60:12: leaking param: r
internal/tally/tally.go:61:36: map[int]int{} escapes to heap
internal/tally/tally.go:61:62: map[string]int{} escapes to heap
internal/tally/tally.go:62:24: &bufio.Scanner{...} does not escape
internal/tally/tally.go:64:26: string(bufio.s.token) escapes to heap
internal/tally/tally.go:66:24: ... argument does not escape
internal/tally/tally.go:66:40: n escapes to heap
internal/tally/tally.go:66:24: &errors.errorString{...} escapes to heap
internal/tally/tally.go:89:29: a does not escape
internal/tally/tally.go:89:32: b does not escape
internal/tally/tally.go:90:16: ... argument does not escape
internal/tally/tally.go:84:10: s does not escape
internal/tally/tally.go:85:14: make([]PathCount, 0, len(s.ByPath)) escapes to heap
internal/tally/tally.go:87:16: append escapes to heap
internal/tally/tally.go:89:24: func literal does not escape
```

Agrupadas pelo que custam:

| linhas | veredito | custo |
|---|---|---|
| `split.go:7` | `leaking param: line to result f` | nenhum: o array de cinco strings da lição 13 aponta para `line` e é um valor no quadro do `Parse` |
| `tally.go:31`, `41`, `66` | argumentos e erros escapam | só numa linha que não se deixa ler, uma vez |
| `tally.go:60` | `leaking param: r` | nenhum por linha: o `Scan` lê `r` pela interface `io.Reader`, então o compilador não vê qual `Read` vai rodar |
| `tally.go:61` | os dois maps escapam | dois por contagem: são devolvidos dentro do `Summary` |
| `tally.go:62` | `&bufio.Scanner{...} does not escape` | nenhum: o `NewScanner` foi inlined e o `Scanner` mora no quadro do `Count` |
| `tally.go:64` | `string(bufio.s.token) escapes to heap` | **um por linha** |
| `tally.go:85`, `87` | a fatia do `Top` escapa | uma vez por `Top`: ela é devolvida |

A linha 64 é `e, err := Parse(sc.Text())`. O `Scanner.Text` foi inlined, então a única instrução dele,
a conversão dos bytes do scanner em string, é julgada no `Count`, e a string escapa. **Essa é a
alocação por linha.** A pergunta seguinte é por quê.

## Seguindo o motivo

```
ana@vm:~/escape-hits$ go build -gcflags='example.com/hits/...=-m=2' . 2>&1 | grep -A6 'tally.go:64:26: string.* in Count'
internal/tally/tally.go:64:26: string(bufio.s.token) escapes to heap in Count:
internal/tally/tally.go:64:26:   flow: ~r0 ← &{storage for string(bufio.s.token)}:
internal/tally/tally.go:64:26:     from string(bufio.s.token) (spill) at internal/tally/tally.go:64:26
internal/tally/tally.go:64:26:     from ~r0 = string(bufio.s.token) (assign-pair) at internal/tally/tally.go:64:26
internal/tally/tally.go:64:26:   flow: {heap} ← ~r0:
internal/tally/tally.go:64:26:     from Parse(~r0) (call parameter) at internal/tally/tally.go:64:18
internal/tally/tally.go:66:40: n escapes to heap in Count:
```

A string escapa porque é passada ao `Parse`, e o resumo do `Parse` para `line` diz heap, que é a linha
26 do relatório acima: `leaking param: line` puro. Então a pergunta muda para dentro do `Parse`:

```
ana@vm:~/escape-hits$ go build -gcflags='example.com/hits/...=-m=2' . 2>&1 | grep -A2 'line leaks to {heap}'
internal/tally/tally.go:26:12: parameter line leaks to {heap} for Parse with derefs=0:
internal/tally/tally.go:26:12:   flow: {heap} ← line:
internal/tally/tally.go:26:12:     from strings.Fields(line) (call parameter) at internal/tally/tally.go:29:24
```

**O `strings.Fields(line)`, na linha 29, é o fallback que a lição 13 manteve para as linhas que o
`split5` recusa.** O `genlog` não escreve nenhuma dessas, e o fallback não rodou em nenhuma das 100.000
linhas. Não importa: **a análise de escape trata de todos os caminhos que o código pode seguir**,
decididos antes de qualquer linha ser lida, e um caminho que vaza basta para entregar ao heap a string
de todo chamador.

## Tirar um motivo mostra o próximo

O experimento óbvio é fazer o fallback não vazar nada: entregar ao `strings.Fields` uma cópia da linha,
`strings.Clone(line)`, que só custa uma alocação no caminho que nunca roda. Ana tenta numa cópia do
arquivo:

```
ana@vm:~/escape-hits$ cp internal/tally/tally.go tally.go.bak
ana@vm:~/escape-hits$ sed -i "s/strings.Fields(line)/strings.Fields(strings.Clone(line))/" internal/tally/tally.go
ana@vm:~/escape-hits$ go build -gcflags='example.com/hits/...=-m=2' . 2>&1 | grep -A8 'line leaks to {heap}' | grep from
internal/tally/tally.go:26:12:     from split5(line) (call parameter) at internal/tally/tally.go:27:17
internal/tally/tally.go:26:12:     from f, ok := ([5]string)(.autotmp_5), .autotmp_6 (assign-pair) at internal/tally/tally.go:27:8
internal/tally/tally.go:26:12:     from f[4] (fixed-array-index-of) at internal/tally/tally.go:43:32
internal/tally/tally.go:26:12:     from time.ParseDuration(f[4]) (call parameter) at internal/tally/tally.go:43:30
```

O `line` continua vazando para o heap, por outra rota: pelo `split5` até o array `f`, e de `f[4]` para
o `time.ParseDuration`, cujo resumo vaza o argumento. **O `-m=2` imprime uma rota para cada veredito, a
primeira que acha**, então uma segunda rota fica escondida até a primeira sumir. Clonando esse
argumento também:

```
ana@vm:~/escape-hits$ sed -i "s/ParseDuration(f\[4\])/ParseDuration(strings.Clone(f[4]))/" internal/tally/tally.go
ana@vm:~/escape-hits$ go build -gcflags='example.com/hits/...=-m=2' . 2>&1 | grep 'leaking param: line'
internal/tally/split.go:7:13: leaking param: line to result f level=0
internal/tally/tally.go:26:12: leaking param: line to result ~r0 level=0
ana@vm:~/escape-hits$ go build -gcflags='example.com/hits/...=-m=2' . 2>&1 | grep -A12 'tally.go:64:26: string.* in Count' | grep from
internal/tally/tally.go:64:26:     from string(bufio.s.token) (spill) at internal/tally/tally.go:64:26
internal/tally/tally.go:64:26:     from ~r0 = string(bufio.s.token) (assign-pair) at internal/tally/tally.go:64:26
internal/tally/tally.go:64:26:     from Parse(~r0) (call parameter) at internal/tally/tally.go:64:18
internal/tally/tally.go:64:26:     from e, err := Entry(.autotmp_8), .autotmp_9 (assign-pair) at internal/tally/tally.go:64:10
internal/tally/tally.go:64:26:     from e.Path (dot) at internal/tally/tally.go:70:13
internal/tally/tally.go:64:26:     from s.ByPath[e.Path] (key of map put) at internal/tally/tally.go:70:11
```

**O próprio `Parse` agora está limpo**: `line` vaza só para o resultado, a `Entry`. E a string no
`Count` escapa assim mesmo, pela terceira rota, a que o `words.go` da seção 03 mostrou em duas linhas:
o `Parse` devolve `Path` como um pedaço de `line`, e a linha 70 o guarda como chave em `s.ByPath`. **Um
map guarda as chaves, então a string precisa sobreviver à volta do laço.** O backup volta para o lugar:

```
ana@vm:~/escape-hits$ mv tally.go.bak internal/tally/tally.go
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 314\" role=\"img\" aria-label=\"Três rotas levam a string de cada linha do Count até o heap. O Count converte o token do scanner em string na linha 64 e a passa ao Parse. Dentro do Parse, o fallback strings.Fields na linha 29 a vaza, e o compilador relata essa rota primeiro. Quando o fallback clona a linha, ele relata time.ParseDuration na linha 43. Quando essa também é clonada, relata a terceira: o Parse devolve o caminho dentro da Entry, e o Count o guarda como chave de map na linha 70. Mesmo sem rota nenhuma, cada linha tem de 34 a 51 bytes e uma string guardada na pilha ganha 32.\"><defs><marker id=\"er-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"er-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"er-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"122\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">string(token)</text><text x=\"95\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Count, linha 64</text><rect x=\"205\" y=\"122\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Parse(line)</text><text x=\"265\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">linha 26</text><rect x=\"370\" y=\"24\" width=\"230\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"384\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"485\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">strings.Fields(line)</text><text x=\"485\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o fallback, linha 29</text><text x=\"485\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">relatada primeiro</text><path d=\"M325 150 H345 V52 H366\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#er-phosphor)\"></path><path d=\"M600 52 H615 V150 H626\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#er-amber)\"></path><rect x=\"370\" y=\"122\" width=\"230\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"384\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"485\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">time.ParseDuration(f[4])</text><text x=\"485\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a duração, linha 43</text><text x=\"485\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">relatada com a 1 clonada</text><path d=\"M325 150 H345 V150 H366\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#er-phosphor)\"></path><path d=\"M600 150 H615 V150 H626\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#er-amber)\"></path><rect x=\"370\" y=\"220\" width=\"230\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"384\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"485\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">s.ByPath[e.Path]++</text><text x=\"485\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">key of map put, linha 70</text><text x=\"485\" y=\"267\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">relatada com a 1 e a 2 clonadas</text><path d=\"M325 150 H345 V248 H366\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#er-phosphor)\"></path><path d=\"M600 248 H615 V150 H626\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#er-amber)\"></path><rect x=\"630\" y=\"122\" width=\"70\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"665\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">{heap}</text><path d=\"M170 150 H201\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#er-phosphor)\"></path><text x=\"20\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">E sem rota nenhuma: toda linha tem de 34 a 51 bytes, e uma string guardada na pilha ganha 32.</text></svg>", "caption": "Tirar uma rota só revela a próxima. O -m=2 imprime a primeira rota que acha, não todas."}
```

E mesmo sem rota nenhuma, a alocação continuaria:

```
ana@vm:~/escape-hits$ awk '{ print length }' internal/tally/testdata/access.log | sort -n | sed -n '1p;$p'
34
51
```

**Toda linha do log tem entre 34 e 51 bytes.** Uma conversão para string que não escapa ganha um
buffer de 32 bytes no quadro, `tmpStringBufSize` em `runtime/string.go`, e qualquer coisa maior é
alocada no heap de qualquer jeito: a mesma regra do `Sized`, para strings.

## A contagem, e o veredito

Um teste mede o `Parse` numa linha que recebe como string, e o `Count` nas primeiras 1.000 linhas e em
todas as 100.000. `internal/tally/allocs_test.go`:

```go
package tally

import (
	"os"
	"strings"
	"testing"
)

func TestAllocs(t *testing.T) {
	data, err := os.ReadFile("testdata/access.log")
	if err != nil {
		t.Fatal(err)
	}
	text := string(data)
	line, _, _ := strings.Cut(text, "\n")
	short := strings.Join(strings.SplitAfter(text, "\n")[:1000], "")

	t.Logf("Parse, one line:      %v allocs", testing.AllocsPerRun(1000, func() {
		Parse(line)
	}))
	t.Logf("Count, 1,000 lines:   %v allocs", testing.AllocsPerRun(10, func() {
		Count(strings.NewReader(short))
	}))
	t.Logf("Count, 100,000 lines: %v allocs", testing.AllocsPerRun(10, func() {
		Count(strings.NewReader(text))
	}))
}
```

```
ana@vm:~/escape-hits$ go test -run Allocs -v ./internal/tally
=== RUN   TestAllocs
    allocs_test.go:18: Parse, one line:      0 allocs
    allocs_test.go:21: Count, 1,000 lines:   1009 allocs
    allocs_test.go:24: Count, 100,000 lines: 100009 allocs
--- PASS: TestAllocs (0.20s)
PASS
ok  	example.com/hits/internal/tally	0.204s
```

**O `Parse` não aloca nada**: o `split5` da lição 13, o horário, o status e a duração são todos lidos
sem tocar no heap. O `Count` faz 1.009 alocações para 1.000 linhas e 100.009 para 100.000, ou seja,
uma por linha mais nove que não crescem com a entrada, os dois maps da linha 61 entre elas. A uma por
linha é a string que o `Text` cria.

**Esta é a conclusão honesta: essa alocação é necessária para o `tally` do jeito que ele foi
projetado.** O `Parse` recebe uma string e devolve strings que apontam para ela, e o `Count` guarda uma
delas como chave de map, então a linha precisa ser uma string no heap. As saídas mudam o projeto. O
`Count` poderia ler `sc.Bytes()`, que é o buffer do próprio scanner e não custa nada, analisar os
bytes, e copiar um caminho para uma string nova só na primeira vez que o vê, oito vezes no log do
`genlog`. Isso é um `Parse` novo, um conjunto novo de testes e um alvo de fuzz novo, para economizar
uma alocação pequena por linha. Se vale a pena é uma pergunta para o profile da lição 13, que mede
tempo, e não para o `-m`, que só explica de onde vem a memória.
