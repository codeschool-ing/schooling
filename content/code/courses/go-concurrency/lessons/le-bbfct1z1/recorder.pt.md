---
title: Um handler, testado sem servidor
version: 1
---

Um handler HTTP é um valor com um método, `ServeHTTP(w, r)`. **Um teste pode chamar esse método
diretamente, com uma requisição que ele montou e um writer que registra tudo o que é escrito nele**,
e nenhuma porta, nenhuma rede e nenhuma goroutine entram nisso. O `net/http/httptest` traz as duas
metades: `NewRequest` monta a requisição e `NewRecorder` é o writer.

## Um handler para o pacote

O `wordcount` ganha um handler que responde a `GET /top?doc=NOME&n=N` com as palavras mais
frequentes do documento em JSON, pegando os documentos de qualquer `Source`, salvo como
`handler.go`:

```go
package wordcount

import (
	"encoding/json"
	"errors"
	"io/fs"
	"net/http"
	"strconv"
)

// Handler serves GET /top?doc=NAME&n=N: the n most frequent words of the
// named document in src, as JSON.
func Handler(src Source) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		name := r.URL.Query().Get("doc")
		n, err := strconv.Atoi(r.URL.Query().Get("n"))
		if name == "" || err != nil || n < 1 {
			http.Error(w, "want ?doc=NAME&n=N with N at least 1", http.StatusBadRequest)
			return
		}
		top, err := TopOf(r.Context(), src, name, n)
		if errors.Is(err, fs.ErrNotExist) {
			http.Error(w, "no such document", http.StatusNotFound)
			return
		}
		if err != nil {
			http.Error(w, "could not count the document", http.StatusInternalServerError)
			return
		}
		json.NewEncoder(w).Encode(top)
		w.Header().Set("Content-Type", "application/json")
	})
}
```

O contexto da própria requisição vai para `TopOf`, como a lição 12 pediu, então um cliente que vai
embora para o trabalho. Um documento que falta vira 404 porque `TopOf` embrulha o erro da fonte com
`%w`, e `errors.Is` ainda acha `fs.ErrNotExist` dentro dele.

## O teste

Uma tabela de novo, uma linha por tipo de resposta, usando o fake `mapSource` da lição 27, que mora
nos testes do mesmo pacote. Salvo como `handler_test.go`:

```go
package wordcount

import (
	"net/http/httptest"
	"testing"
)

func TestHandler(t *testing.T) {
	h := Handler(mapSource{"note": "to be or not to be"})
	tests := []struct {
		name     string
		target   string
		wantCode int
		wantType string
		wantBody string
	}{
		{"top two", "/top?doc=note&n=2", 200, "application/json",
			`[{"Word":"be","Count":2},{"Word":"to","Count":2}]` + "\n"},
		{"missing doc", "/top?doc=other&n=2", 404, "text/plain; charset=utf-8",
			"no such document\n"},
		{"bad n", "/top?doc=note&n=zero", 400, "text/plain; charset=utf-8",
			"want ?doc=NAME&n=N with N at least 1\n"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest("GET", tc.target, nil)
			rec := httptest.NewRecorder()
			h.ServeHTTP(rec, req)
			res := rec.Result()
			if got := res.Header.Get("Content-Type"); res.StatusCode != tc.wantCode || got != tc.wantType {
				t.Errorf("GET %s: %d %q, want %d %q", tc.target, res.StatusCode, got, tc.wantCode, tc.wantType)
			}
			if rec.Body.String() != tc.wantBody {
				t.Errorf("GET %s: body %q, want %q", tc.target, rec.Body.String(), tc.wantBody)
			}
		})
	}
}
```

`httptest.NewRequest` recebe um caminho sem host, que é o que um handler vê, e entra em pânico com
um absurdo em vez de devolver erro, porque num teste uma requisição ruim é engano do próprio teste.
Depois que `ServeHTTP` retorna, o recorder guarda o corpo em `Body`, e `Result()` devolve a resposta
como um cliente a teria recebido, com status e cabeçalhos. **Confira os cabeçalhos em `Result()`, e
não em `rec.Header()`**: o segundo é o map vivo em que o handler escreve, e ele mostra um cabeçalho
definido tarde demais como se tivesse sido enviado.

```
ana@vm:~/wordcount$ go test -v -run TestHandler
=== RUN   TestHandler
=== RUN   TestHandler/top_two
    handler_test.go:31: GET /top?doc=note&n=2: 200 "text/plain; charset=utf-8", want 200 "application/json"
=== RUN   TestHandler/missing_doc
=== RUN   TestHandler/bad_n
--- FAIL: TestHandler (0.00s)
    --- FAIL: TestHandler/top_two (0.00s)
    --- PASS: TestHandler/missing_doc (0.00s)
    --- PASS: TestHandler/bad_n (0.00s)
FAIL
exit status 1
FAIL	example.com/wordcount	0.003s
```

**O corpo estava certo e o tipo de conteúdo estava errado.** O handler chama `Header().Set` depois
do `Encode`, e a primeira escrita num `ResponseWriter` envia o status e os cabeçalhos como estão
naquele momento. O que for definido depois vai para um map que ninguém lê de novo, então a resposta
saiu rotulada com o tipo que o `net/http` farejou do corpo. As duas linhas de erro passaram porque o
`http.Error` define o seu próprio cabeçalho antes de escrever.

O conserto é definir o cabeçalho antes do corpo. As duas últimas linhas do handler trocam de lugar,
e o arquivo inteiro é salvo como `handler.go`:

```go
package wordcount

import (
	"encoding/json"
	"errors"
	"io/fs"
	"net/http"
	"strconv"
)

// Handler serves GET /top?doc=NAME&n=N: the n most frequent words of the
// named document in src, as JSON.
func Handler(src Source) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		name := r.URL.Query().Get("doc")
		n, err := strconv.Atoi(r.URL.Query().Get("n"))
		if name == "" || err != nil || n < 1 {
			http.Error(w, "want ?doc=NAME&n=N with N at least 1", http.StatusBadRequest)
			return
		}
		top, err := TopOf(r.Context(), src, name, n)
		if errors.Is(err, fs.ErrNotExist) {
			http.Error(w, "no such document", http.StatusNotFound)
			return
		}
		if err != nil {
			http.Error(w, "could not count the document", http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(top)
	})
}
```

```
ana@vm:~/wordcount$ go test -run TestHandler
PASS
ok  	example.com/wordcount	0.003s
```

Um recorder é a ferramenta certa para a lógica de um handler: o que ele responde a qual requisição.
Ele não é um servidor, então não exercita roteamento, timeouts nem o que acontece no fio. A seção 03
inicia um de verdade.
