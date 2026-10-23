---
title: O vet que o `go test` roda por você
version: 1
---

Você provavelmente já rodou o vet sem digitá-lo. **Antes de o `go test` rodar um único teste, ele passa
o vet no pacote e nos arquivos de teste, e se o vet relatar qualquer coisa os testes não rodam.** Ele
não roda os 35 analisadores: só aqueles cujas descobertas são reais com tanta regularidade que reprovar
uma execução de testes por elas nunca é um incômodo. A ajuda os cita, e o próprio código-fonte do
comando go também:

```
ana@vm:~/vetted$ go help test | grep -A2 "That subset"
used. That subset is: atomic, bools, buildtag, directive, errorsas,
ifaceassert, nilfunc, printf, stdversion, stringintconv, and tests.
You can see the documentation for these and other vet tests via
ana@vm:~/vetted$ grep -A40 "defaultVetFlags = " "$(go env GOROOT)/src/cmd/go/internal/test/test.go" | grep -E "^\s+\"-" | tr -d "\t\"," | tr "\n" " "; echo
-atomic -bools -buildtag -directive -errorsas -ifaceassert -nilfunc -printf -slog -stdversion -stringintconv -tests 
```

As duas linhas não concordam, e **a segunda é a que roda**. É a lista compilada no comando go, lida do
código-fonte do próprio toolchain na sua máquina: doze analisadores, onde o `go help test` cita onze e
deixa o `slog` de fora. Um pacote de teste com uma chamada `slog.Info` malformada reprova o `go test`
no Go 1.27.1, diga a ajuda o que disser. Todo o resto da lista está nas duas.

Dos analisadores que a seção 03 usou, só o `printf` está na lista. `copylocks`, `lostcancel`,
`structtag`, `unusedresult`, `shift`, `assign` e `unreachable` ficam todos desligados. O
`go help test` chama o subconjunto de "high-confidence", de alta confiança, e a régua é mais alta que a
do próprio vet: uma checagem que trava os testes de alguém por um alarme falso ensina essa pessoa a
desligar a etapa, que é a próxima parte desta seção.

## Uma execução de testes que falha antes de qualquer teste

Um pacote que lê um código de status, com um erro tipado e uma função auxiliar que pergunta a um erro
de qual campo ele veio, salvo como `status/status.go`:

```go
// Package status reads the status field of a log line.
package status

import (
	"errors"
	"fmt"
	"strconv"
)

// Error says which field could not be read, and why.
type Error struct {
	Field string
	Err   error
}

func (e *Error) Error() string { return e.Field + ": " + e.Err.Error() }
func (e *Error) Unwrap() error { return e.Err }

// Parse reads an HTTP status code, which runs from 100 to 599.
func Parse(s string) (int, error) {
	n, err := strconv.Atoi(s)
	if err != nil {
		return 0, &Error{"status", err}
	}
	if n < 100 || n > 999 {
		return 0, fmt.Errorf("status %d out of range", n)
	}
	return n, nil
}

// Field names the field a parse error came from, or "" for any other error.
func Field(err error) string {
	var e *Error
	if errors.As(err, e) {
		return e.Field
	}
	return ""
}
```

E os testes dele, `status/status_test.go`:

```go
package status

import "testing"

func TestParse(t *testing.T) {
	if n, err := Parse("404"); n != 404 || err != nil {
		t.Errorf("Parse(%q) = %d, %v", "404", n, err)
	}
}

func TestparseRejects(t *testing.T) {
	for _, s := range []string{"abc", "99", "600"} {
		if _, err := Parse(s); err == nil {
			t.Errorf("Parse(%q) accepted it", s)
		}
	}
}
```

Há três bugs aqui, e o `go test` relata dois deles sem rodar nada:

```
ana@vm:~/vetted$ go test ./status
# example.com/vetted/status
# [example.com/vetted/status]
status/status.go:34:5: second argument to errors.As must be a non-nil pointer to either a type that implements error, or to any interface type
status/status_test.go:11:6: TestparseRejects has malformed name: first letter after 'Test' must not be lowercase
FAIL	example.com/vetted/status [build failed]
FAIL
```

**`[build failed]` é a cara de uma falha do vet dentro do `go test`**: o comando go trata a etapa do
vet como parte do build do binário de teste, e o binário nunca rodou. O `errorsas` pegou o `Field`
passando `e`, um `*Error` nulo, onde o `errors.As` precisa de um ponteiro para ele. Essa chamada
entraria em pânico na primeira vez que alguém perguntasse a um erro de verdade de qual campo ele veio,
e nenhum teste chama `Field`, então nenhum teste o teria achado. O `tests` pegou um nome: o `testing`
roda funções chamadas `Test` seguido de algo que não começa com letra minúscula, e `TestparseRejects`
não é uma delas.

## Por que não `-vet=off`

O `-vet=off` desliga a etapa, e é a primeira coisa que se procura quando o `go test` falha de um jeito
inesperado. Veja o que ele compra:

```
ana@vm:~/vetted$ go test -vet=off -v ./status
=== RUN   TestParse
--- PASS: TestParse (0.00s)
PASS
ok  	example.com/vetted/status	0.003s
```

**`ok`, e um teste.** O teste com nome errado não rodou e nada avisou: nenhum alerta, nenhuma contagem
de pulados, uma linha verde. Corrigir as duas descobertas são dois comandos `sed`, e o teste que volta
à vida acha o terceiro bug, aquele que o vet nunca poderia ver, porque `999` é um número perfeitamente
válido:

```
ana@vm:~/vetted$ sed -i "s/Testparse/TestParse/" status/status_test.go
ana@vm:~/vetted$ sed -i "s/errors.As(err, e)/errors.As(err, \&e)/" status/status.go
ana@vm:~/vetted$ go test ./status
--- FAIL: TestParseRejects (0.00s)
    status_test.go:14: Parse("600") accepted it
FAIL
FAIL	example.com/vetted/status	0.002s
FAIL
ana@vm:~/vetted$ sed -i "s/n > 999/n > 599/" status/status.go && go test ./status
ok  	example.com/vetted/status	0.011s
```

O `Parse` aceitou `600` porque a checagem de faixa dizia `999`. **Com `-vet=off` esse bug vai para
produção, atrás de uma execução de testes verde, protegido por um teste que existe e nunca roda.** Esse
é o argumento contra a flag: as checagens que o `go test` roda foram escolhidas para que uma falha
sempre valha a leitura, então desligá-las troca uma mensagem que você pode resolver por um bug que você
não vê.

## As checagens que o `go test` deixa com você

O outro lado de uma lista curada é que um `go test` verde não diz nada sobre o resto. O `counter`, da
seção 03, ganha um teste, `counter/main_test.go`, que chama `Add` de uma goroutine só:

```go
package main

import "testing"

func TestAdd(t *testing.T) {
	c := Counter{n: map[string]int{}}
	c.Add("/login")
	c.Add("/login")
	if got := c.n["/login"]; got != 2 {
		t.Errorf("got %d, want 2", got)
	}
}
```

```
ana@vm:~/vetted$ go test ./counter
ok  	example.com/vetted/counter	0.002s
ana@vm:~/vetted$ go test -vet=all ./counter
# example.com/vetted/counter
# [example.com/vetted/counter]
counter/main.go:15:9: Add passes lock by value: example.com/vetted/counter.Counter contains sync.Mutex
FAIL	example.com/vetted/counter [build failed]
FAIL
```

O teste passa, porque uma goroutine nunca disputa consigo mesma, e o `copylocks` não está na lista
padrão, então o `go test` fica verde num tipo que quebra sob carga. **`-vet=all` faz o `go test` rodar
todos os analisadores**, e aí a mesma execução falha. **É por isso que um projeto roda `go vet ./...`
como etapa própria, ao lado do `go test ./...`.** O subconjunto é o que é seguro impor a toda execução
de testes, e a suíte completa é o que um pipeline de CI pode se dar ao luxo de exigir.
