---
title: Strings e slices de bytes sem cópia
version: 1
---

`string(b)` copia. **Uma string em Go é imutável e um slice de bytes não é**, então a conversão
precisa dar à string bytes próprios, senão uma escrita posterior em `b` mudaria um valor que a
linguagem promete que nunca muda. Essa cópia é uma alocação e um `memmove`, e num laço que passa por
cada linha de um log ela é paga uma vez por linha. A reação de costume é recorrer ao `unsafe`; a
certa é conferir antes se o compilador já eliminou a cópia, o que ele faz em mais lugares do que se
imagina. Esta seção mede as duas coisas e depois quebra a promessa de propósito.

## Quatro funções, desde o Go 1.20

Uma string são duas palavras, um ponteiro para os bytes e um tamanho. Um slice são três, um
ponteiro, um tamanho e uma capacidade. Converter um no outro sem copiar significa montar um
cabeçalho que aponta para os bytes do outro, e o Go 1.20 acrescentou ao `unsafe` quatro funções
exatamente para isso, para ninguém precisar forjar um cabeçalho com o padrão 6:

| função | devolve | a partir de |
|---|---|---|
| `unsafe.StringData(s)` | `*byte`, o primeiro byte de uma string | uma string |
| `unsafe.SliceData(b)` | um ponteiro para o primeiro elemento de um slice | um slice |
| `unsafe.String(p, n)` | uma string de `n` bytes começando em `p` | um `*byte` e um tamanho |
| `unsafe.Slice(p, n)` | um slice de tamanho e capacidade `n` começando em `p` | um ponteiro e um tamanho |

A regra de uso está em dois comentários de documentação. `unsafe.String`: "the bytes passed to
String must not be modified as long as the returned string value exists", os bytes passados não
podem ser modificados enquanto a string devolvida existir. `unsafe.StringData`: "the bytes returned
by StringData must not be modified", os bytes devolvidos não podem ser modificados. **Todo o resto
desta seção é o que acontece quando alguém esquece uma dessas duas frases.**

Seguindo a regra da seção 05, as conversões ficam num pacote pequeno e em mais lugar nenhum.
Salve-o como `internal/zc/zc.go`:

```go
// Package zc converts between strings and byte slices without copying.
//
// Both functions hand out memory that two values now share. Whoever calls
// them promises that the bytes never change while the result exists.
package zc

import "unsafe"

// String returns a string that uses b's bytes as they are. b must not be
// modified afterwards, ever, or the string changes with it.
func String(b []byte) string {
	return unsafe.String(unsafe.SliceData(b), len(b))
}

// Bytes returns the bytes of s as a slice. The slice must never be written
// to: the bytes may be in read-only memory, and other strings may share them.
func Bytes(s string) []byte {
	return unsafe.Slice(unsafe.StringData(s), len(s))
}
```

## Medido contra a conversão comum

O arquivo de teste confere a única propriedade para a qual o pacote existe, que nada seja copiado,
e depois compara as duas formas de converter uma linha de log de 46 bytes e uma página de 4 KiB. Os
cinco últimos benchmarks fazem outra pergunta: se o código comum precisa do `zc`. Salve-o como
`internal/zc/zc_test.go`:

```go
package zc

import (
	"strings"
	"testing"
	"unsafe"
)

// TestShares checks the one thing the package is for: nothing is copied.
func TestShares(t *testing.T) {
	b := []byte("GET /login")
	s := String(b)
	if s != "GET /login" {
		t.Fatalf("String = %q", s)
	}
	if unsafe.StringData(s) != &b[0] {
		t.Error("String copied the bytes")
	}
	if &Bytes(s)[0] != &b[0] {
		t.Error("Bytes copied the bytes")
	}
	if String(nil) != "" || Bytes("") != nil {
		t.Error("empty input should give an empty result")
	}
}

var (
	line = []byte("2026-10-01T09:00:01Z POST /api/users 404 115ms")
	page = []byte(strings.Repeat("x", 4096))
	sink string
)

func BenchmarkLineCopy(b *testing.B) {
	for b.Loop() {
		sink = string(line)
	}
}

func BenchmarkLineUnsafe(b *testing.B) {
	for b.Loop() {
		sink = String(line)
	}
}

func BenchmarkPageCopy(b *testing.B) {
	for b.Loop() {
		sink = string(page)
	}
}

func BenchmarkPageUnsafe(b *testing.B) {
	for b.Loop() {
		sink = String(page)
	}
}

var (
	hits = map[string]int{"/api/users": 1}
	path = []byte("/api/users")
	long = []byte("/static/vendor/charts/2026-10/app.min.js")
)

// m[string(b)], written in the index expression, is looked up without
// building a string at all.
func BenchmarkLookup(b *testing.B) {
	n := 0
	for b.Loop() {
		n += hits[string(path)]
	}
}

func BenchmarkLookupLong(b *testing.B) {
	n := 0
	for b.Loop() {
		n += hits[string(long)]
	}
}

// The same conversion one line earlier is an ordinary one. A short string
// that does not escape is still built without the heap.
func BenchmarkLookupVar(b *testing.B) {
	n := 0
	for b.Loop() {
		k := string(path)
		n += hits[k]
	}
}

func BenchmarkLookupVarLong(b *testing.B) {
	n := 0
	for b.Loop() {
		k := string(long)
		n += hits[k]
	}
}

// Counting may insert the key, and a key in a map has to be a real string.
func BenchmarkIncrement(b *testing.B) {
	for b.Loop() {
		hits[string(path)]++
	}
}
```

```
ana@vm:~/unsafe$ go test -race -count=1 ./internal/zc
ok  	example.com/hits/internal/zc	1.009s
```

```
ana@vm:~/unsafe$ go test -run "^$" -bench . -benchmem ./internal/zc
goos: linux
goarch: amd64
pkg: example.com/hits/internal/zc
cpu: Intel(R) Xeon(R) Processor
BenchmarkLineCopy-4        	32549576	        39.35 ns/op	      48 B/op	       1 allocs/op
BenchmarkLineUnsafe-4      	1000000000	         0.8246 ns/op	       0 B/op	       0 allocs/op
BenchmarkPageCopy-4        	  630120	      1605 ns/op	    4096 B/op	       1 allocs/op
BenchmarkPageUnsafe-4      	1000000000	         0.8174 ns/op	       0 B/op	       0 allocs/op
BenchmarkLookup-4          	141466650	         8.477 ns/op	       0 B/op	       0 allocs/op
BenchmarkLookupLong-4      	123594883	         9.704 ns/op	       0 B/op	       0 allocs/op
BenchmarkLookupVar-4       	95115313	        12.82 ns/op	       0 B/op	       0 allocs/op
BenchmarkLookupVarLong-4   	24622020	        51.34 ns/op	      48 B/op	       1 allocs/op
BenchmarkIncrement-4       	28707585	        50.54 ns/op	      16 B/op	       1 allocs/op
PASS
ok  	example.com/hits/internal/zc	10.311s
```

As quatro primeiras linhas são a defesa do `unsafe`. **A cópia custa uma alocação do tamanho da
entrada**, 48 bytes para a linha e 4096 para a página, e o tempo cresce com o tamanho: dezenas de
nanossegundos para a linha, mais de um microssegundo para a página. A conversão unsafe monta um
cabeçalho e não copia nada, então leva menos de um nanossegundo, seja qual for o tamanho.

As cinco últimas são a acusação contra recorrer a ela. `hits[string(path)]`, escrito dentro da
expressão de índice, **não alocou nada, nem para uma chave de 10 bytes nem para uma de 40**. O
compilador reconhece uma conversão usada só para consultar uma chave e passa os bytes ao mapa sem
montar string nenhuma. Suba a mesma conversão uma linha, para uma variável, e a chave de 10 bytes
continua sem custar nada, por outro motivo: **uma string convertida que não escapa e cabe em 32
bytes é montada num buffer na pilha** (`tmpStringBufSize`, em `runtime/string.go`). A chave de 40
bytes não cabe, e volta a custar sua alocação.

O incremento é o caso interessante. `hits[string(path)]++` alocou 16 bytes em toda chamada, mesmo
com a chave já no mapa, porque o `++` num mapa pode inserir, e **uma chave guardada num mapa precisa
ser uma string de verdade, que nada mais consegue mudar**. Essa é a alocação que um programa que
conta caminhos paga por linha, e o próximo programa é o que acontece quando alguém a elimina com o
`zc`.

## Quebrando a promessa

Primeiro a promessa na forma mais curta. Salve isto como `mutate/main.go`:

```go
// Command mutate breaks the promise zc asks for, in both directions.
package main

import (
	"fmt"

	"example.com/hits/internal/zc"
)

func main() {
	b := []byte("GET /login")
	s := zc.String(b)
	fmt.Println("before:", s)
	copy(b, "PUT")
	fmt.Println("after: ", s) // nobody assigned to s

	method := "GET"
	zc.Bytes(method)[0] = 'P' // a literal lives in read-only memory
	fmt.Println(method)
}
```

```
ana@vm:~/unsafe$ go build -o bin/mutate ./mutate && bin/mutate 2>&1 | head -5; echo ${PIPESTATUS[0]}
before: GET /login
after:  PUT /login
unexpected fault address 0x49a058
fatal error: fault
[signal SIGSEGV: segmentation violation code=0x2 addr=0x49a058 pc=0x499f2f]
2
```

**`s` mudou sem que nada fosse atribuído a ela**, porque `s` e `b` dividem os mesmos bytes. Na
direção contrária, escrever num literal de string por meio de `zc.Bytes` matou o programa com uma
falha de segmentação: literais ficam numa memória que o sistema operacional marcou como somente
leitura, e o status de saída 2 é o erro fatal do runtime. Não é um pânico, e nenhum `recover` o
captura.

Agora o mesmo erro onde ele acontece de verdade. `bufio.Scanner.Bytes` devolve a linha atual como
um slice do buffer do próprio scanner, e a documentação dele diz "the underlying array may point to
data that will be overwritten by a subsequent call to Scan": o array por baixo pode ser sobrescrito
pela próxima chamada de `Scan`. Este programa conta os caminhos de um log duas vezes, uma com
`string(b)` como chave e outra com `zc.String(b)`. Salve-o como `paths/main.go`:

```go
// Command paths counts the requests per path in an access log, once with
// ordinary strings and once with strings that share the scanner's buffer.
package main

import (
	"bufio"
	"bytes"
	"fmt"
	"os"
	"strings"

	"example.com/hits/internal/zc"
)

func count(name string, key func([]byte) string) (map[string]int, error) {
	f, err := os.Open(name)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	byPath := map[string]int{}
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		fields := bytes.Fields(sc.Bytes())
		byPath[key(fields[2])]++
	}
	return byPath, sc.Err()
}

func main() {
	safe, err := count(os.Args[1], func(b []byte) string { return string(b) })
	if err != nil {
		fmt.Fprintln(os.Stderr, "paths:", err)
		os.Exit(1)
	}
	fast, _ := count(os.Args[1], zc.String)
	fmt.Println("copied:   ", len(safe), "keys,", safe["/login"], "requests for /login")
	fmt.Println("zero-copy:", len(fast), "keys,", fast["/login"], "requests for /login")
	total, spaced := 0, 0
	for k, v := range fast {
		total += v
		if strings.ContainsAny(k, " \n") {
			spaced++
		}
	}
	fmt.Println("requests the zero-copy map counted:", total)
	fmt.Println("keys with a space or a newline in them:", spaced)
}
```

Rodado sobre as 20.000 linhas que o `genlog` da lição 1 escreve:

```
ana@vm:~/unsafe$ go run ./tools/genlog -n 20000 > access.log && go run ./paths access.log
copied:    8 keys, 2576 requests for /login
zero-copy: 1535 keys, 19 requests for /login
requests the zero-copy map counted: 20000
keys with a space or a newline in them: 1065
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Dois cabeçalhos apontam para os mesmos dez bytes. O slice b é um ponteiro, um tamanho 10 e uma capacidade 10; a string s, vinda de zc.String, é um ponteiro e um tamanho 10. Os dois ponteiros levam a uma única fileira de bytes que diz PUT /login, cujos três primeiros bytes foram escritos por meio de b.\"><defs><marker id=\"zc-arrow\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20.0\" y=\"32.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">b []byte</text><rect x=\"20.0\" y=\"46.0\" width=\"52.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ptr</text><rect x=\"76.0\" y=\"46.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">len 10</text><rect x=\"148.0\" y=\"46.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"182.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cap 10</text><text x=\"20.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cabeçalho do slice: ponteiro, tamanho, capacidade</text><text x=\"20.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">s string</text><rect x=\"20.0\" y=\"138.0\" width=\"52.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ptr</text><rect x=\"76.0\" y=\"138.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">len 10</text><text x=\"20.0\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cabeçalho da string: ponteiro, tamanho</text><text x=\"515.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dez bytes, guardados uma vez</text><rect x=\"341.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"357.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">P</text><rect x=\"376.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"392.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">U</text><rect x=\"411.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"427.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">T</text><rect x=\"446.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"462.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&#x2423;</text><rect x=\"481.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"497.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/</text><rect x=\"516.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"532.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">l</text><rect x=\"551.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"567.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">o</text><rect x=\"586.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"602.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">g</text><rect x=\"621.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"637.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">i</text><rect x=\"656.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"672.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n</text><path d=\"M392.5 136 V148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"392.5\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">escritos por meio de b</text><path d=\"M46 76 V81 H240 C 290 81, 300 106, 336 106\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#zc-arrow)\"></path><path d=\"M46 168 V173 H240 C 290 173, 300 114, 336 114\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#zc-arrow)\"></path></svg>", "caption": "O que zc.String constrói: um segundo cabeçalho, e não uma segunda cópia. Depois de copy(b, \"PUT\"), os três bytes mudaram no único lugar para onde os dois cabeçalhos apontam, e s passa a dizer PUT /login sem que ninguém atribua nada a ela."}
```

**O mapa com cópia tem os oito caminhos do log, e `/login` com suas 2.576 requisições.** O mapa sem
cópia contou cada uma das 20.000 requisições e as arquivou sob umas mil e quinhentas chaves, a
maioria delas pedaços de outras linhas: cada chave era uma janela para o buffer do scanner, e o
scanner reabasteceu o buffer por baixo delas. Mais de mil chaves contêm um espaço ou uma quebra de
linha, coisa que nenhum caminho do log tem. Os números exatos mudam um pouco de uma execução para
outra; que o mapa sem cópia é um disparate, não muda.

E nenhuma ferramenta percebe:

```
ana@vm:~/unsafe$ go vet ./paths ./internal/zc && go run -race ./paths access.log
copied:    8 keys, 2576 requests for /login
zero-copy: 1536 keys, 19 requests for /login
requests the zero-copy map counted: 20000
keys with a space or a newline in them: 1063
```

**O `vet`, o detector de corrida e o checkptr passaram.** Nenhuma conversão era inválida no momento
em que foi feita, nenhuma dupla de goroutines mexeu na memória e nenhum ponteiro saiu da sua
alocação. O bug é uma promessa quebrada sobre o futuro, e só uma pessoa lendo o código consegue
vê-lo: o comentário de documentação do `zc.String` diz que os bytes nunca podem mudar, e a chamada
entregou a ele bytes cujo dono avisa que vão mudar.
