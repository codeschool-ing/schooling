---
title: Uma mensagem de falha sobre a qual dá para agir
version: 1
---

Um teste que falha é lido por alguém que não o escreveu, muitas vezes meses depois, muitas vezes
num log de CI sem editor aberto. **A mensagem tem de dizer o que foi chamado, com o quê, o que
voltou e o que se esperava**, nessa ordem. A convenção de Go é a forma que as tabelas acima já usam:

```go
t.Errorf("Count(%q) = %v, want %v", tc.text, got, tc.want)
```

A chamada como foi feita, depois `=`, depois o que ela devolveu, depois `want` e a expectativa. Ela
foi feita para ser lida a frio: nenhuma linha do teste é necessária para entendê-la.

## Uma segunda função, e um teste que falha às vezes

O pacote ganha a função que o nome dele promete, as palavras mais frequentes, salva como `top.go`:

```go
package wordcount

import (
	"cmp"
	"slices"
)

// Entry is one word and how many times it appeared.
type Entry struct {
	Word  string
	Count int
}

// Top returns the n most frequent words in counts, most frequent first.
// Words with the same count come in alphabetical order.
func Top(counts map[string]int, n int) []Entry {
	entries := make([]Entry, 0, len(counts))
	for w, c := range counts {
		entries = append(entries, Entry{w, c})
	}
	slices.SortFunc(entries, func(a, b Entry) int { return cmp.Compare(b.Count, a.Count) })
	return entries[:min(n, len(entries))]
}
```

`cmp.Compare(b.Count, a.Count)` põe as contagens maiores primeiro, e o slice é cortado em `n`, ou
no que houver se houver menos. O teste é uma tabela sobre um conjunto de contagens, salvo como
`top_test.go`:

```go
package wordcount

import (
	"slices"
	"testing"
)

func TestTop(t *testing.T) {
	counts := map[string]int{"go": 3, "is": 3, "fun": 1, "fast": 1, "and": 1}
	tests := []struct {
		name string
		n    int
		want []Entry
	}{
		{"first", 1, []Entry{{"go", 3}}},
		{"ties", 4, []Entry{{"go", 3}, {"is", 3}, {"and", 1}, {"fast", 1}}},
		{"more than there are", 9, []Entry{{"go", 3}, {"is", 3}, {"and", 1}, {"fast", 1}, {"fun", 1}}},
		{"none", 0, []Entry{}},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := Top(counts, tc.n)
			if !slices.Equal(got, tc.want) {
				t.Errorf("Top(counts, %d) = %v, want %v", tc.n, got, tc.want)
			}
		})
	}
}
```

```
ana@vm:~/wordcount$ go test -run TestTop
--- FAIL: TestTop (0.00s)
    --- FAIL: TestTop/ties (0.00s)
        top_test.go:24: Top(counts, 4) = [{is 3} {go 3} {fun 1} {fast 1}], want [{go 3} {is 3} {and 1} {fast 1}]
    --- FAIL: TestTop/more_than_there_are (0.00s)
        top_test.go:24: Top(counts, 9) = [{go 3} {is 3} {fun 1} {fast 1} {and 1}], want [{go 3} {is 3} {and 1} {fast 1} {fun 1}]
FAIL
exit status 1
FAIL	example.com/wordcount	0.002s
```

Duas das quatro linhas falharam, e cada mensagem é a convenção trabalhando. Sem abrir o teste, ela
diz que pediram a `Top` 4 entradas e 9, que entradas voltaram e quais eram esperadas, e o olho acha
o problema na hora: `is` antes de `go`, `fun` antes de `and`, palavras com a mesma contagem numa
ordem que ninguém escolheu.

Rodadas vinte vezes, com `-count=20`, e as falhas contadas por nome, as linhas se comportam de
jeitos diferentes entre si:

```
ana@vm:~/wordcount$ go test -run TestTop -count=20 | grep -- '--- FAIL' | sort | uniq -c
      4     --- FAIL: TestTop/first (0.00s)
     20     --- FAIL: TestTop/more_than_there_are (0.00s)
     20     --- FAIL: TestTop/ties (0.00s)
     20 --- FAIL: TestTop (0.00s)
```

`ties` e `more than there are` falharam nas vinte execuções. **`first` falhou em só 4 das 20**: um
conjunto só com essa linha teria passado na maioria dos dias e falhado nos outros, sem ninguém ter
mudado nada. Um teste cujo resultado muda entre execuções idênticas está dizendo que o resultado
depende de algo que o teste não controla. Aqui é a ordem em que o `range` percorre um map, que Go
embaralha de propósito para que ninguém passe a depender dela. A documentação promete ordem
alfabética nos empates e a comparação nunca olha a palavra, então duas palavras com a mesma
contagem saem na ordem em que o map as produziu. Cinco execuções só da linha `ties` mostram a
ordem mudando de uma execução para outra:

```
ana@vm:~/wordcount$ go test -run 'TestTop/ties' -count=5
--- FAIL: TestTop (0.00s)
    --- FAIL: TestTop/ties (0.00s)
        top_test.go:24: Top(counts, 4) = [{go 3} {is 3} {fast 1} {and 1}], want [{go 3} {is 3} {and 1} {fast 1}]
--- FAIL: TestTop (0.00s)
    --- FAIL: TestTop/ties (0.00s)
        top_test.go:24: Top(counts, 4) = [{go 3} {is 3} {fast 1} {and 1}], want [{go 3} {is 3} {and 1} {fast 1}]
--- FAIL: TestTop (0.00s)
    --- FAIL: TestTop/ties (0.00s)
        top_test.go:24: Top(counts, 4) = [{go 3} {is 3} {fun 1} {fast 1}], want [{go 3} {is 3} {and 1} {fast 1}]
--- FAIL: TestTop (0.00s)
    --- FAIL: TestTop/ties (0.00s)
        top_test.go:24: Top(counts, 4) = [{go 3} {is 3} {fun 1} {fast 1}], want [{go 3} {is 3} {and 1} {fast 1}]
--- FAIL: TestTop (0.00s)
    --- FAIL: TestTop/ties (0.00s)
        top_test.go:24: Top(counts, 4) = [{go 3} {is 3} {and 1} {fun 1}], want [{go 3} {is 3} {and 1} {fast 1}]
FAIL
exit status 1
FAIL	example.com/wordcount	0.002s
```

## O conserto, e uma conferência de que ele se sustenta

A comparação desempata pela palavra, como o comentário dizia desde o começo. O arquivo inteiro de
novo, salvo como `top.go`:

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
// Words with the same count come in alphabetical order.
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
	return entries[:min(n, len(entries))]
}
```

```
ana@vm:~/wordcount$ go test -run TestTop -count=100
PASS
ok  	example.com/wordcount	0.008s
ana@vm:~/wordcount$ go test .
ok  	example.com/wordcount	0.003s
ana@vm:~/wordcount$ go test .
ok  	example.com/wordcount	(cached)
```

Cem execuções, nenhuma falha. Os dois últimos comandos também valem a pena. Quando recebe um pacote
para testar, `.` aqui, e não nada, **o `go test` guarda em cache um resultado que passou e o repete
enquanto nem o código nem o teste mudarem**, e é por isso que a segunda execução imprimiu `(cached)`
e não rodou nada. Sem pacote nomeado ele testa o diretório atual e nunca usa o cache. Passar
`-count` desliga o cache, e é por isso que `-count=1` é o jeito usual de forçar uma execução de
verdade, e o hábito para quando um teste depende de qualquer coisa fora do pacote: um arquivo, um
relógio, um servidor.

Mais duas comparações ficam ao lado de `maps.Equal` e `slices.Equal`. `reflect.DeepEqual` compara
quaisquer dois valores, inclusive aninhados, ao preço de o compilador não conferir mais se os dois
têm o mesmo tipo. Para uma struct, `==` funciona quando todo campo é comparável, e é por isso que o
`slices.Equal` pôde comparar os valores `Entry` diretamente.
