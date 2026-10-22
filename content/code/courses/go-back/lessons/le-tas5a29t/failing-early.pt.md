---
title: Recusando-se a iniciar
version: 1
---

Um valor de configuração errado vai ser descoberto. A única pergunta é quando: na inicialização, durante o
deploy, enquanto a versão antiga ainda atende e alguém está olhando; ou na primeira requisição que precisa
dele, às três da manhã. **Um serviço deve ler e verificar toda a configuração antes de fazer qualquer outra
coisa, e se recusar a iniciar se alguma parte estiver errada.** Esta é a do boxoffice:

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

	for name, role := range map[string]string{
		"BOXOFFICE_MANAGER_TOKEN": "manager",
		"BOXOFFICE_DOOR_TOKEN":    "door",
	} {
		t, err := secretFrom(getenv, name)
		if err != nil {
			errs = append(errs, err)
		} else if t != "" {
			c.Tokens[string(t)] = role
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

## Uma função, com as entradas passadas a ela

O `load` recebe os argumentos e uma função para ler o ambiente, em vez de ir buscar `os.Args` e
`os.Getenv` por conta própria. O `main` passa os de verdade; os testes da aula 15 passam uma fatia e um
mapa, e testam cada regra daqui sem tocar no ambiente do processo. O conjunto de flags é um
`flag.NewFlagSet` só dele, pelo motivo que a seção 03 deu, com `ContinueOnError` para o `load` devolver um
problema em vez de encerrar o programa de dentro de uma função que um teste chamou.

## Padrões, depois variáveis, depois flags

A ordem da seção 02 vem da ordem do código. Declarar cada flag define o padrão dela. Depois o `VisitAll`
percorre as flags declaradas e, para cada uma, procura a variável correspondente, `-max-conns` virando
`BOXOFFICE_MAX_CONNS`; uma variável definida passa pelo `fs.Set`, que a analisa com o próprio analisador da
flag. Só então o `Parse` lê a linha de comando, e assim uma flag passada ali sobrescreve o que a variável
definiu. **Cada configuração é declarada uma vez**, com nome, padrão, analisador e ajuda, e os dois caminhos
de entrada saem dessa única declaração. O `VisitAll` também acrescenta o nome da variável à ajuda de cada
flag, então o `-h` documenta os dois.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 200\" role=\"img\" aria-label=\"Três camadas para cada configuração, lidas em ordem. O padrão no código dá max-conns 10 e http localhost:8080. A variável BOXOFFICE_MAX_CONNS=4 troca 10 por 4; http não tem variável e mantém o padrão. A flag -max-conns 6 troca 4 por 6. O resultado é max-conns 6 e http localhost:8080.\"><defs><marker id=\"gb-l14-layers-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"87\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">padrão</text><text x=\"87\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">fs.IntVar(…, 10, …)</text><rect x=\"15\" y=\"60\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"15\" y=\"125\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M 160 85 L 188 85\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l14-layers-ah)\"></path><path d=\"M 160 150 L 188 150\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l14-layers-ah)\"></path><text x=\"262\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">variável</text><text x=\"262\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">BOXOFFICE_MAX_CONNS=4</text><rect x=\"190\" y=\"60\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"190\" y=\"125\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M 335 85 L 363 85\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l14-layers-ah)\"></path><path d=\"M 335 150 L 363 150\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l14-layers-ah)\"></path><text x=\"437\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">flag</text><text x=\"437\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">-max-conns 6</text><rect x=\"365\" y=\"60\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"365\" y=\"125\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M 510 85 L 538 85\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l14-layers-ah)\"></path><path d=\"M 510 150 L 538 150\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l14-layers-ah)\"></path><text x=\"612\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">resultado</text><text x=\"612\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">config</text><rect x=\"540\" y=\"60\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"540\" y=\"125\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"87\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">max-conns</text><text x=\"87\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10</text><text x=\"262\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">max-conns</text><text x=\"262\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><text x=\"437\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">max-conns</text><text x=\"437\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"612\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">max-conns</text><text x=\"612\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"87\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">http</text><text x=\"87\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">localhost:8080</text><text x=\"262\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não definida</text><text x=\"437\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não passada</text><text x=\"612\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">http</text><text x=\"612\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">localhost:8080</text></svg>", "caption": "Cada camada substitui só o que define. A execução da seção 08 começou com estes valores.", "same": ["flag"]}
```

## Todos os problemas de uma vez

Os problemas vão para uma fatia em vez de encerrar a função no primeiro, e o `errors.Join` os devolve
juntos, um por linha, inclusive uma flag que não foi lida. Quem está consertando a configuração de um
deploy vê todos os erros numa tentativa só, em vez de descobri-los um reinício de cada vez.

As verificações tratam do que o boxoffice realmente precisa, não só de tipos. Um pool de uma conexão é um
inteiro válido e não funciona, porque o `listen` da aula 13 guarda uma conexão para si; mais de 100 também
é um inteiro válido e falha depois, porque é esse o número de conexões que o PostgreSQL aceita por padrão.
Uma origem sem esquema é uma URL válida e não bate com o cabeçalho `Origin` de nenhum navegador. **Cada uma
dessas teria iniciado sem erro e falhado num lugar menos óbvio**, e é esse o motivo de verificá-las aqui.

## Segredos, e imprimir o resultado

O `secretFrom` é a convenção da seção 05: a variável, ou o arquivo que a gêmea `_FILE` indica, com a
quebra de linha final do arquivo removida, já que o `echo` e os editores acrescentam uma. Um arquivo que
não se consegue ler é um erro, nunca um recuo silencioso para a variável simples.

O tipo `secret` se esconde duas vezes. O `LogValue` cobre o slog, como o `email` da aula 12 fez. O `String`
cobre o `fmt`, então um `Printf("%v", cfg)` perdido durante uma depuração também imprime `[hidden]`. Nenhum
dos dois impede código que o converta de volta com `string(...)`, que é o que o `main` faz no único lugar
em que o valor real é necessário.

O `config` também tem um `LogValue`. **Registrar a configuração com que um processo realmente começou** é
uma das linhas mais úteis que um serviço escreve: quando o comportamento difere entre dois ambientes, a
primeira pergunta é com o que cada um foi configurado, e a resposta está na primeira linha de cada log. A
seção 08 a mostra.
