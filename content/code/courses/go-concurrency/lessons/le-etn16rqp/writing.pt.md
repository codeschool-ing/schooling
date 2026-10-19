---
title: Um benchmark é um teste que mede
version: 1
---

Um teste responde se o código está certo. **Um benchmark responde quanto tempo ele leva e quanta
memória ele pede**, e mora nos mesmos arquivos `_test.go`, rodado pelo mesmo `go test`. A diferença
é o nome e o parâmetro: `BenchmarkXxx(b *testing.B)` em vez de `TestXxx(t *testing.T)`.

## Dois benchmarks para o pacote

A entrada é montada uma vez, no nível do pacote, para todo benchmark medir o mesmo texto. Salvo
como `bench_test.go`:

```go
package wordcount

import (
	"strings"
	"testing"
)

// sample is about 9 KB of text, built once for every benchmark in the file.
var sample = strings.Repeat("The quick brown fox jumps over the lazy dog. Go is fun, and go is fast! ", 128)

func BenchmarkCount(b *testing.B) {
	b.SetBytes(int64(len(sample)))
	for b.Loop() {
		if _, err := Count(strings.NewReader(sample)); err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkTop(b *testing.B) {
	counts, err := Count(strings.NewReader(sample))
	if err != nil {
		b.Fatal(err)
	}
	for b.Loop() {
		Top(counts, 3)
	}
}
```

**`for b.Loop()` é o laço que é cronometrado.** O pacote `testing` roda o corpo de novo e de novo,
aumentando o número de rodadas até o total levar cerca de um segundo, e então divide. Tudo antes do
laço é preparação e não é cronometrado: o `BenchmarkTop` conta a amostra uma vez, do lado de fora,
então o que ele mede é só o `Top`. O `b.SetBytes` declara quantos bytes uma rodada processa, o que
acrescenta uma coluna de vazão ao relatório.

O `b.Loop` chegou no Go 1.24. Código mais antigo escreve a mesma coisa como
`for i := 0; i < b.N; i++`, e a seção 04 mostra a armadilha que essa forma deixa aberta.

## Rodando os benchmarks

O `go test` não roda benchmark nenhum se não pedirem. O `-bench` recebe uma expressão regular de
nomes de benchmark, como o `-run` faz para testes, e `-run '^$'` não casa com teste nenhum, então
os testes não rodam antes. O `-benchmem` acrescenta as colunas de memória:

```
ana@vm:~/wordcount$ go test -run '^$' -bench . -benchmem
goos: linux
goarch: amd64
pkg: example.com/wordcount
cpu: Intel(R) Xeon(R) Processor
BenchmarkCount-4   	   10363	    113733 ns/op	  81.03 MB/s	   16104 B/op	    2311 allocs/op
BenchmarkTop-4     	 2368893	       483.9 ns/op	     320 B/op	       1 allocs/op
PASS
ok  	example.com/wordcount	2.332s
```

O cabeçalho dá o nome da máquina, e isso importa: um número de benchmark é um fato sobre este
código neste processador, e a mesma execução num notebook dá outro. Depois vem uma linha por
benchmark, e o tempo total que a execução inteira levou. A seção 03 lê as colunas.
