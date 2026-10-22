---
title: O roteador inteiro, numa conexão de verdade
version: 1
---

Um teste de handler não enxerga middleware, e quatro promessas do boxoffice moram ali: o id da requisição,
o log de acesso, o CORS e a verificação da equipe. A distância seguinte serve o roteador inteiro com o
`httptest.NewServer`, que escuta numa porta real em `127.0.0.1` e entrega ao teste um cliente para ela:

```go
// boxoffice/routes_test.go
package main

import (
	"bytes"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// TestMain runs before every test of the package. The access log would fill
// the output of every test that makes a request, so it goes nowhere unless a
// test sets a logger of its own.
func TestMain(m *testing.M) {
	slog.SetDefault(newLogger(io.Discard))
	m.Run()
}

const managerToken = "manager-token-for-tests"
const doorToken = "door-token-for-tests"

// newTestServer serves the whole of boxoffice, middleware included, from
// memory, on a port of its own that the test closes when it ends.
func newTestServer(t *testing.T) *httptest.Server {
	t.Helper()
	cfg := config{
		Origin: "https://tickets.example.com",
		Tokens: map[string]string{managerToken: "manager", doorToken: "door"},
	}
	srv := httptest.NewServer(routes(newMemStore(), cfg, newHub()))
	t.Cleanup(srv.Close)
	return srv
}

func TestStaffRoutes(t *testing.T) {
	srv := newTestServer(t)
	tests := []struct {
		name   string
		token  string
		status int
	}{
		{"no token", "", http.StatusUnauthorized},
		{"a wrong token", "guess", http.StatusUnauthorized},
		{"the door's token", doorToken, http.StatusForbidden},
		{"the manager's token", managerToken, http.StatusOK},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req, _ := http.NewRequest("GET", srv.URL+"/admin/report", nil)
			if tt.token != "" {
				req.Header.Set("Authorization", "Bearer "+tt.token)
			}
			resp, err := srv.Client().Do(req)
			if err != nil {
				t.Fatal(err)
			}
			resp.Body.Close()
			if resp.StatusCode != tt.status {
				t.Errorf("status %d, want %d", resp.StatusCode, tt.status)
			}
			if resp.Header.Get("X-Request-ID") == "" {
				t.Error("no X-Request-ID")
			}
		})
	}
}

func TestPreflight(t *testing.T) {
	srv := newTestServer(t)
	req, _ := http.NewRequest("OPTIONS", srv.URL+"/admin/events", nil)
	req.Header.Set("Origin", "https://tickets.example.com")
	req.Header.Set("Access-Control-Request-Method", "POST")
	resp, err := srv.Client().Do(req)
	if err != nil {
		t.Fatal(err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		t.Errorf("status %d, want 204", resp.StatusCode)
	}
	if got := resp.Header.Get("Access-Control-Allow-Origin"); got != "https://tickets.example.com" {
		t.Errorf("Access-Control-Allow-Origin %q", got)
	}
}

// The log must say who called and what happened, and never with what token.
func TestTheLogHoldsNoToken(t *testing.T) {
	var buf bytes.Buffer
	defer slog.SetDefault(slog.Default())
	slog.SetDefault(newLogger(&buf))

	srv := newTestServer(t)
	req, _ := http.NewRequest("GET", srv.URL+"/admin/report", nil)
	req.Header.Set("Authorization", "Bearer "+managerToken)
	resp, err := srv.Client().Do(req)
	if err != nil {
		t.Fatal(err)
	}
	resp.Body.Close()

	if !strings.Contains(buf.String(), `"path":"/admin/report"`) {
		t.Fatalf("the request was not logged: %s", buf.String())
	}
	if strings.Contains(buf.String(), managerToken) {
		t.Errorf("the log holds the token: %s", buf.String())
	}
}
```

O `newTestServer` monta a configuração como um literal de struct: um teste sabe exatamente quais tokens
existem, então não precisa do `load` da seção 05 nem do ambiente. **O `t.Cleanup(srv.Close)`** fecha o
servidor quando o teste termina, seja como for que termine, e o `t.Helper()` faz uma falha dentro dele
apontar a linha do teste que o chamou.

Os testes verificam o que só a cadeia inteira mostra:

- **O `TestStaffRoutes`** percorre as quatro respostas que as aulas 2 e 3 desenharam: sem token e com um
  token errado é 401, o token da portaria é 403 numa rota de gerente, o do gerente é 200. Cada uma também
  precisa trazer um `X-Request-ID`, que o middleware da aula 12 define antes que qualquer coisa possa
  recusar a requisição.
- **O `TestPreflight`** envia o que um navegador envia antes de um `POST` entre sites e espera o 204 da
  aula 2 com o site ecoado de volta.
- **O `TestTheLogHoldsNoToken`** é o teste que a aula 12 prometeu. Ele envia o token do gerente, captura o
  log num buffer e verifica que a requisição foi registrada e o token não. Hoje ele passa porque o
  `logRequests` não registra cabeçalhos. Ele está ali para o dia em que alguém os acrescentar "para ajudar
  a depurar".

## Quieto por padrão

O log de acesso escreve uma linha por requisição, e os testes fazem dezenas. O `TestMain`, que roda uma vez
antes de qualquer teste do pacote, manda o logger padrão para o `io.Discard`; o `TestTheLogHoldsNoToken`
põe no lugar o seu próprio buffer e devolve o logger anterior com `defer`. Sem isso, todo teste que toca o
roteador imprimiria o seu tráfego no meio dos resultados.

```
ana@vm:~/boxoffice$ go test -run "TestStaffRoutes|TestPreflight|TestTheLogHoldsNoToken" -v .
=== RUN   TestStaffRoutes
=== RUN   TestStaffRoutes/no_token
=== RUN   TestStaffRoutes/a_wrong_token
=== RUN   TestStaffRoutes/the_door's_token
=== RUN   TestStaffRoutes/the_manager's_token
--- PASS: TestStaffRoutes (0.00s)
    --- PASS: TestStaffRoutes/no_token (0.00s)
    --- PASS: TestStaffRoutes/a_wrong_token (0.00s)
    --- PASS: TestStaffRoutes/the_door's_token (0.00s)
    --- PASS: TestStaffRoutes/the_manager's_token (0.00s)
=== RUN   TestPreflight
--- PASS: TestPreflight (0.00s)
=== RUN   TestTheLogHoldsNoToken
--- PASS: TestTheLogHoldsNoToken (0.00s)
PASS
ok  	example.com/boxoffice	(cached)
```

Mudar o logger padrão é mudar uma global, e é por isso que nenhum destes testes chama `t.Parallel()`: dois
testes trocando o padrão ao mesmo tempo leriam as linhas um do outro.
