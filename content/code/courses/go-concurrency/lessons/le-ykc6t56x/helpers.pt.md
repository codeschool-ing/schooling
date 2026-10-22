---
title: Helpers, diretórios temporários e limpeza
version: 1
---

Os cinco subtestes da seção 03 repetem as mesmas três linhas cinco vezes: chamar `Count`, parar se
ele devolveu erro, depois conferir. Levar essas linhas para uma função é Go comum. A única coisa a
aprender é o que relata uma falha dentro dessa função, porque por padrão ela relata a linha errada.

## `t.Helper`

Um teste descartável mostra isso. O helper confere uma contagem, e o teste o chama duas vezes, uma
com uma contagem certa e outra com uma errada, salvo como `demo_test.go`:

```go
package wordcount

import "testing"

func wantCount(t *testing.T, counts map[string]int, word string, want int) {
	if counts[word] != want {
		t.Errorf("count of %q = %d, want %d", word, counts[word], want)
	}
}

func TestDemo(t *testing.T) {
	counts := map[string]int{"go": 2}
	wantCount(t, counts, "go", 2)
	wantCount(t, counts, "fun", 1)
}
```

```
ana@vm:~/wordcount$ go test -run TestDemo
--- FAIL: TestDemo (0.00s)
    demo_test.go:7: count of "fun" = 0, want 1
FAIL
exit status 1
FAIL	example.com/wordcount	0.006s
```

A linha 7 é o `t.Errorf` dentro do helper, que todas as chamadas compartilham, então o relatório não
consegue dizer qual chamada falhou. **`t.Helper()`, como primeira linha do helper, diz ao pacote
`testing` para pular esta função quando der nome a uma linha**, e dar o nome de quem a chamou. O
mesmo arquivo com essa linha a mais, salvo como `demo_test.go`:

```go
package wordcount

import "testing"

func wantCount(t *testing.T, counts map[string]int, word string, want int) {
	t.Helper()
	if counts[word] != want {
		t.Errorf("count of %q = %d, want %d", word, counts[word], want)
	}
}

func TestDemo(t *testing.T) {
	counts := map[string]int{"go": 2}
	wantCount(t, counts, "go", 2)
	wantCount(t, counts, "fun", 1)
}
```

```
ana@vm:~/wordcount$ go test -run TestDemo
--- FAIL: TestDemo (0.00s)
    demo_test.go:15: count of "fun" = 0, want 1
FAIL
exit status 1
FAIL	example.com/wordcount	0.002s
ana@vm:~/wordcount$ rm demo_test.go
```

A linha 15 é a segunda chamada, a que perguntou por `fun`. O arquivo de demonstração é apagado logo
depois, porque ele falha de propósito.

## Um arquivo de que o teste precisa, e quem o remove

O pacote ganha uma segunda função, para o caso comum de contar um arquivo em disco, salva como
`file.go`:

```go
package wordcount

import "os"

// CountFile counts the words in the named file.
func CountFile(name string) (map[string]int, error) {
	f, err := os.Open(name)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	return Count(f)
}
```

Testá-la exige um arquivo de verdade. Escrevê-lo no diretório do pacote deixa lixo depois de uma
queda, e escrevê-lo num caminho fixo em `/tmp` colide com uma segunda execução. **`t.TempDir()`
devolve um diretório novo e vazio que pertence só a este teste, e o remove quando o teste termina**,
passando ou falhando. Ele faz isso por meio de `t.Cleanup`, que registra uma função para rodar
depois que o teste e os seus subtestes terminarem; você pode registrar as suas do mesmo jeito, para
um servidor a parar ou uma variável a devolver ao valor antigo.

O arquivo de teste como esta lição o deixa, com os dois helpers, a decisão do `possessive` da
seção 03 e um teste de `CountFile`, salvo como `wordcount_test.go`:

```go
package wordcount

import (
	"errors"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// count runs Count on text and stops the test if Count fails.
func count(t *testing.T, text string) map[string]int {
	t.Helper()
	got, err := Count(strings.NewReader(text))
	if err != nil {
		t.Fatalf("Count(%q) returned an error: %v", text, err)
	}
	return got
}

// wantCount reports a failure if word does not appear want times.
func wantCount(t *testing.T, counts map[string]int, word string, want int) {
	t.Helper()
	if counts[word] != want {
		t.Errorf("count of %q = %d, want %d", word, counts[word], want)
	}
}

func TestCount(t *testing.T) {
	t.Run("punctuation", func(t *testing.T) {
		got := count(t, "Go is fun. Go is fast, and go is simple.")
		wantCount(t, got, "fun", 1)
		wantCount(t, got, "fast", 1)
	})
	t.Run("case", func(t *testing.T) {
		wantCount(t, count(t, "Go GO go gO"), "go", 4)
	})
	t.Run("accents", func(t *testing.T) {
		wantCount(t, count(t, "Ação, ação e AÇÃO."), "ação", 3)
	})
	t.Run("possessive", func(t *testing.T) {
		got := count(t, "Go and Go's tools")
		wantCount(t, got, "go", 1)
		wantCount(t, got, "go's", 1)
	})
	t.Run("empty", func(t *testing.T) {
		if got := count(t, ""); len(got) != 0 {
			t.Errorf(`Count("") = %v, want an empty map`, got)
		}
	})
}

func TestCountFile(t *testing.T) {
	dir := t.TempDir()
	t.Logf("working in %s", dir)
	name := filepath.Join(dir, "note.txt")
	if err := os.WriteFile(name, []byte("one two two"), 0o644); err != nil {
		t.Fatal(err)
	}
	got, err := CountFile(name)
	if err != nil {
		t.Fatalf("CountFile: %v", err)
	}
	wantCount(t, got, "two", 2)

	_, err = CountFile(filepath.Join(dir, "missing.txt"))
	if !errors.Is(err, fs.ErrNotExist) {
		t.Errorf("CountFile of a missing file: err = %v, want fs.ErrNotExist", err)
	}
}
```

A conferência do arquivo que falta importa tanto quanto o caminho feliz. `CountFile` devolve o erro
de `os.Open` intacto, e o teste fixa isso: quem chama pode usar `errors.Is` com `fs.ErrNotExist`,
como a lição 34 de `go` ensinou, e uma mudança futura que embrulhasse o erro sem cuidado falharia
aqui. `t.Logf` escreve uma linha que o `go test` só mostra com `-v` ou quando o teste falha:

```
ana@vm:~/wordcount$ go test -v
=== RUN   TestCount
=== RUN   TestCount/punctuation
=== RUN   TestCount/case
=== RUN   TestCount/accents
=== RUN   TestCount/possessive
=== RUN   TestCount/empty
--- PASS: TestCount (0.00s)
    --- PASS: TestCount/punctuation (0.00s)
    --- PASS: TestCount/case (0.00s)
    --- PASS: TestCount/accents (0.00s)
    --- PASS: TestCount/possessive (0.00s)
    --- PASS: TestCount/empty (0.00s)
=== RUN   TestCountFile
    wordcount_test.go:56: working in /tmp/TestCountFile3474527985/001
--- PASS: TestCountFile (0.01s)
PASS
ok  	example.com/wordcount	0.010s
ana@vm:~/wordcount$ ls /tmp/TestCountFile3474527985
ls: cannot access '/tmp/TestCountFile3474527985': No such file or directory
```

O diretório existia enquanto o teste rodava e tinha sumido quando o `go test` voltou. Mais dois
métodos de `*testing.T` pertencem ao lado destes. `t.Setenv` define uma variável de ambiente para
um teste e a devolve depois. `t.Context` entrega ao teste um contexto cancelado logo antes das
limpezas rodarem, o que passar ao código que recebe um `ctx`, como as lições 10 e 11 pediram.
