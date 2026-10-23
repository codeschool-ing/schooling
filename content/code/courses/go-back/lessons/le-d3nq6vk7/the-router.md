---
title: The whole router, over a real connection
version: 1
---

A handler test cannot see middleware, and four of boxoffice's promises live there: the request id, the
access log, CORS and the staff check. The next distance serves the whole router with `httptest.NewServer`,
which listens on a real port on `127.0.0.1` and hands the test a client for it:

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

`newTestServer` builds the configuration as a struct literal: a test knows exactly which tokens exist, so
it does not need section 05's `load` or the environment at all. **`t.Cleanup(srv.Close)`** closes the server
when the test ends, however it ends, and `t.Helper()` makes a failure inside it name the line of the test
that called it.

The tests check what only the whole chain can show:

- **`TestStaffRoutes`** walks the four answers lessons 2 and 3 designed: no token and a wrong one are 401, the
  door's token is 403 on a manager's route, the manager's is 200. Each one must also carry an
  `X-Request-ID`, which lesson 12's middleware sets before anything can refuse the request.
- **`TestPreflight`** sends what a browser sends before a cross-site `POST` and expects lesson 2's 204 with
  the site echoed back.
- **`TestTheLogHoldsNoToken`** is the test lesson 12 promised. It sends the manager's token, captures the
  log into a buffer, and checks that the request was logged and the token was not. Today it passes
  because `logRequests` logs no headers. It is there for the day somebody adds them "to help debugging".

## Quiet by default

The access log writes a line for every request, and the tests make dozens. `TestMain`, which runs once
before any test of the package, sends the default logger to `io.Discard`; `TestTheLogHoldsNoToken` swaps
in its own buffer and puts the previous logger back with `defer`. Without that, every test that touches
the router would print its traffic between the results.

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

Changing the default logger is changing a global, which is why none of these tests calls `t.Parallel()`:
two tests swapping the default at the same time would read each other's lines.
