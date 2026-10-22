---
title: Testando a configuração
version: 1
---

A aula 14 escreveu o `load` para receber o ambiente como uma função, e era para isto. Um teste monta um
ambiente a partir de um mapa, sem nada definido que ele não tenha definido, e nada que ele define chega ao
processo:

```go
// boxoffice/config_test.go
package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// env is an environment for load, built from a map instead of the process's own.
func env(vars map[string]string) func(string) string {
	return func(name string) string { return vars[name] }
}

func TestLoadPrecedence(t *testing.T) {
	vars := map[string]string{
		"DATABASE_URL":            "postgres:///boxoffice",
		"BOXOFFICE_MANAGER_TOKEN": "m",
		"BOXOFFICE_MAX_CONNS":     "4",
		"BOXOFFICE_GRPC":          "localhost:9999",
	}
	c, err := load([]string{"-max-conns", "6"}, env(vars))
	if err != nil {
		t.Fatal(err)
	}
	if c.MaxConns != 6 {
		t.Errorf("max-conns %d: the flag must beat the variable", c.MaxConns)
	}
	if c.GRPCAddr != "localhost:9999" {
		t.Errorf("grpc %q: the variable must beat the default", c.GRPCAddr)
	}
	if c.HTTPAddr != "localhost:8080" {
		t.Errorf("http %q: the default must stand when nothing is set", c.HTTPAddr)
	}
}

func TestLoadRefuses(t *testing.T) {
	good := map[string]string{"DATABASE_URL": "postgres:///boxoffice", "BOXOFFICE_MANAGER_TOKEN": "m"}
	tests := []struct {
		name string
		set  map[string]string
		want string // a piece of the error
	}{
		{"no database", map[string]string{"DATABASE_URL": ""}, "DATABASE_URL: not set"},
		{"no staff", map[string]string{"BOXOFFICE_MANAGER_TOKEN": ""}, "no staff could sign in"},
		{"a pool too small", map[string]string{"BOXOFFICE_MAX_CONNS": "1"}, "at least 2"},
		{"a pool too large", map[string]string{"BOXOFFICE_MAX_CONNS": "500"}, "accepts 100"},
		{"a timeout in words", map[string]string{"BOXOFFICE_WRITE_TIMEOUT": "ten"}, `BOXOFFICE_WRITE_TIMEOUT="ten"`},
		{"an origin with no scheme", map[string]string{"BOXOFFICE_ORIGIN": "tickets.example.com"}, "want a site"},
		{"one token for two roles", map[string]string{"BOXOFFICE_DOOR_TOKEN": "m"}, "BOXOFFICE_DOOR_TOKEN"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			vars := map[string]string{}
			for k, v := range good {
				vars[k] = v
			}
			for k, v := range tt.set {
				vars[k] = v
			}
			_, err := load(nil, env(vars))
			if err == nil || !strings.Contains(err.Error(), tt.want) {
				t.Errorf("error %v, want one containing %q", err, tt.want)
			}
		})
	}
}

func TestLoadSecretFromFile(t *testing.T) {
	path := filepath.Join(t.TempDir(), "token")
	if err := os.WriteFile(path, []byte("from-a-file\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	c, err := load(nil, env(map[string]string{
		"DATABASE_URL":                 "postgres:///boxoffice",
		"BOXOFFICE_MANAGER_TOKEN_FILE": path,
	}))
	if err != nil {
		t.Fatal(err)
	}
	if c.Tokens["from-a-file"] != "manager" {
		t.Errorf("tokens %v: want the file's content, without its newline", c.Tokens)
	}
}
```

O `TestLoadPrecedence` fixa a ordem da aula 14: uma flag vence uma variável, uma variável vence um padrão,
e um padrão fica valendo quando nada é definido. O `TestLoadRefuses` parte de uma configuração que funciona
e quebra uma coisa por caso, e cada caso nomeia um pedaço da mensagem que espera, então uma recusa pelo
motivo errado também falha. O `TestLoadSecretFromFile` escreve um arquivo de token em `t.TempDir()`, um
diretório que o framework de testes apaga depois, com a quebra de linha que um editor deixaria, e verifica
que a quebra de linha não foi parar no token.

O último caso do `TestLoadRefuses` dá à portaria o token do gerente. Rodando contra o `load` da aula 14:

```
ana@vm:~/boxoffice$ go test -run TestLoad .
--- FAIL: TestLoadRefuses (0.00s)
    --- FAIL: TestLoadRefuses/one_token_for_two_roles (0.00s)
        config_test.go:64: error <nil>, want one containing "BOXOFFICE_DOOR_TOKEN"
FAIL
FAIL	example.com/boxoffice	0.007s
FAIL
```

**O `load` aceitou.** E o que ele fazia com isso é pior que um erro. Os tokens são um mapa de token para
papel, então o segundo papel escrito para o mesmo token substitui o primeiro, e o laço da aula 14
percorria os dois papéis num mapa próprio. O Go visita um mapa numa ordem diferente a cada vez, de
propósito, então quem tinha o token da portaria era o gerente em algumas inicializações e a portaria em
outras, e o gerente também, decidido por cara ou coroa na inicialização. Nada nas aulas 2 a 14 poderia ter
mostrado isso, porque ninguém tinha tentado dois tokens iguais.

A correção são duas ideias. Ler os papéis de uma fatia, para a ordem ser a mesma toda vez, e recusar um
token que já tem um papel:

```go
// boxoffice/config.go
package main

import (
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net/url"
	"os"
	"strings"
	"time"
)

// config is everything boxoffice reads from outside. Each setting has a
// default, a BOXOFFICE_* variable that overrides it, and a flag that
// overrides both. Secrets have no flag.
type config struct {
	HTTPAddr     string
	GRPCAddr     string
	MaxConns     int
	WriteTimeout time.Duration
	Origin       string
	DatabaseURL  secret
	Tokens       map[string]string // token → role
}

// secret is a string that does not show itself in a log or a Printf.
type secret string

func (secret) LogValue() slog.Value { return slog.StringValue("[hidden]") }
func (secret) String() string       { return "[hidden]" }

func load(args []string, getenv func(string) string) (config, error) {
	c := config{Tokens: map[string]string{}}
	fs := flag.NewFlagSet("boxoffice", flag.ContinueOnError)
	fs.StringVar(&c.HTTPAddr, "http", "localhost:8080", "`address` the HTTP API listens on")
	fs.StringVar(&c.GRPCAddr, "grpc", "localhost:9090", "`address` the gRPC service listens on")
	fs.IntVar(&c.MaxConns, "max-conns", 10, "most database connections open at once")
	fs.DurationVar(&c.WriteTimeout, "write-timeout", 10*time.Second, "longest an ordinary response may take to write")
	fs.StringVar(&c.Origin, "origin", "https://tickets.example.com", "the `site` whose pages may call the API")

	var errs []error
	fs.VisitAll(func(f *flag.Flag) {
		name := "BOXOFFICE_" + strings.ToUpper(strings.ReplaceAll(f.Name, "-", "_"))
		f.Usage += " ($" + name + ")"
		if v := getenv(name); v != "" {
			if err := fs.Set(f.Name, v); err != nil {
				errs = append(errs, fmt.Errorf("%s=%q: %w", name, v, err))
			}
		}
	})
	if err := fs.Parse(args); err != nil {
		return c, errors.Join(append(errs, err)...)
	}

	// A slice, not a map, so the roles are read in the same order every time.
	for _, s := range []struct{ name, role string }{
		{"BOXOFFICE_MANAGER_TOKEN", "manager"},
		{"BOXOFFICE_DOOR_TOKEN", "door"},
	} {
		t, err := secretFrom(getenv, s.name)
		switch {
		case err != nil:
			errs = append(errs, err)
		case t == "":
		case c.Tokens[string(t)] != "":
			errs = append(errs, fmt.Errorf("%s: the same token as the %s's", s.name, c.Tokens[string(t)]))
		default:
			c.Tokens[string(t)] = s.role
		}
	}
	dbURL, err := secretFrom(getenv, "DATABASE_URL")
	if err != nil {
		errs = append(errs, err)
	}
	c.DatabaseURL = dbURL

	if c.DatabaseURL == "" && err == nil {
		errs = append(errs, errors.New("DATABASE_URL: not set"))
	}
	if len(c.Tokens) == 0 {
		errs = append(errs, errors.New("BOXOFFICE_MANAGER_TOKEN: not set, so no staff could sign in"))
	}
	if c.MaxConns < 2 {
		errs = append(errs, fmt.Errorf("max-conns %d: at least 2 are needed, one for LISTEN and one for queries", c.MaxConns))
	} else if c.MaxConns > 100 {
		errs = append(errs, fmt.Errorf("max-conns %d: PostgreSQL accepts 100 connections unless it is told otherwise", c.MaxConns))
	}
	if u, err := url.Parse(c.Origin); err != nil || (u.Scheme != "https" && u.Scheme != "http") || u.Host == "" {
		errs = append(errs, fmt.Errorf("origin %q: want a site such as https://tickets.example.com", c.Origin))
	}
	return c, errors.Join(errs...)
}

// secretFrom reads a secret from the variable name, or from the file that
// name_FILE points to, which is how container platforms hand secrets over.
func secretFrom(getenv func(string) string, name string) (secret, error) {
	if path := getenv(name + "_FILE"); path != "" {
		b, err := os.ReadFile(path)
		if err != nil {
			return "", fmt.Errorf("%s_FILE: %w", name, err)
		}
		return secret(strings.TrimSpace(string(b))), nil
	}
	return secret(getenv(name)), nil
}

// LogValue is the configuration as a log shows it, secrets hidden.
func (c config) LogValue() slog.Value {
	return slog.GroupValue(
		slog.String("http", c.HTTPAddr),
		slog.String("grpc", c.GRPCAddr),
		slog.Int("max_conns", c.MaxConns),
		slog.String("write_timeout", c.WriteTimeout.String()),
		slog.String("origin", c.Origin),
		slog.Any("database_url", c.DatabaseURL),
		slog.Int("staff_tokens", len(c.Tokens)),
	)
}
```

```
ana@vm:~/boxoffice$ go test -run TestLoad .
ok  	example.com/boxoffice	(cached)
```

**O teste foi escrito antes da correção e falhou pelo motivo certo**, que é a parte que faz valer a pena
mantê-lo: agora ele é a razão de este defeito não poder voltar sem ninguém perceber.
