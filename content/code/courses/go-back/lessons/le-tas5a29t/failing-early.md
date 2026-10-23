---
title: Refusing to start
version: 1
---

A configuration value that is wrong will be found. The only question is when: at start-up, during the
deploy, while the old version is still serving and somebody is watching; or at the first request that
needs it, at three in the morning. **A service should read and check all of its configuration before it
does anything else, and refuse to start if any of it is wrong.** This is boxoffice's:

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

## One function, its inputs passed in

`load` takes the arguments and a function to read the environment, instead of reaching for `os.Args` and
`os.Getenv` itself. `main` passes the real ones; lesson 15's tests pass a slice and a map, and test every
rule here without touching the process's environment. The flag set is a `flag.NewFlagSet` of its own, for
the reason section 03 gave, with `ContinueOnError` so that `load` returns a problem rather than exiting
from inside a function that a test called.

## Defaults, then variables, then flags

The order of section 02 comes from the order of the code. Declaring each flag sets its default. Then
`VisitAll` walks the declared flags and, for each one, looks for its variable, `-max-conns` becoming
`BOXOFFICE_MAX_CONNS`; a variable that is set goes through `fs.Set`, which parses it with the flag's own
parser. Only then does `Parse` read the command line, so a flag given there overwrites whatever the
variable set. **Every setting is declared once**, with its name, default, parser and help, and both ways
in come from that one declaration. `VisitAll` also adds the variable's name to each flag's help, so `-h`
documents both.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 200\" role=\"img\" aria-label=\"Three layers for each setting, read in order. The default in the code gives max-conns 10 and http localhost:8080. The variable BOXOFFICE_MAX_CONNS=4 replaces 10 with 4; http has no variable and keeps its default. The flag -max-conns 6 replaces 4 with 6. The result is max-conns 6 and http localhost:8080.\"><defs><marker id=\"gb-l14-layers-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"87\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">default</text><text x=\"87\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">fs.IntVar(…, 10, …)</text><rect x=\"15\" y=\"60\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"15\" y=\"125\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M 160 85 L 188 85\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l14-layers-ah)\"></path><path d=\"M 160 150 L 188 150\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l14-layers-ah)\"></path><text x=\"262\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">variable</text><text x=\"262\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">BOXOFFICE_MAX_CONNS=4</text><rect x=\"190\" y=\"60\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"190\" y=\"125\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M 335 85 L 363 85\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l14-layers-ah)\"></path><path d=\"M 335 150 L 363 150\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l14-layers-ah)\"></path><text x=\"437\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">flag</text><text x=\"437\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">-max-conns 6</text><rect x=\"365\" y=\"60\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"365\" y=\"125\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M 510 85 L 538 85\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l14-layers-ah)\"></path><path d=\"M 510 150 L 538 150\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l14-layers-ah)\"></path><text x=\"612\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">result</text><text x=\"612\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">config</text><rect x=\"540\" y=\"60\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"540\" y=\"125\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"87\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">max-conns</text><text x=\"87\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10</text><text x=\"262\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">max-conns</text><text x=\"262\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><text x=\"437\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">max-conns</text><text x=\"437\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"612\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">max-conns</text><text x=\"612\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"87\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">http</text><text x=\"87\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">localhost:8080</text><text x=\"262\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">not set</text><text x=\"437\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">not given</text><text x=\"612\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">http</text><text x=\"612\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">localhost:8080</text></svg>", "caption": "Each layer replaces only what it sets. The run in section 08 started with these values."}
```

## Every problem at once

Problems go into a slice instead of ending the function at the first one, and `errors.Join` returns them
together, one per line, a flag that did not parse included. Somebody fixing a deployment's configuration
sees every mistake in one attempt instead of discovering them one restart at a time.

The checks are about what boxoffice actually needs, not about types alone. A pool of one connection
parses as an integer and cannot work, because lesson 13's `listen` keeps one connection for itself; more
than 100 parses too and fails later, because that is how many connections PostgreSQL accepts by default.
An origin without a scheme parses as a URL and matches no browser's `Origin` header. **Each of these would
have started cleanly and failed somewhere less obvious**, which is the case for checking them here.

## Secrets, and printing the result

`secretFrom` is section 05's convention: the variable, or the file its `_FILE` twin names, with the file's
final newline trimmed, since `echo` and editors add one. A file that cannot be read is an error, never a
quiet fallback to the plain variable.

The type `secret` hides itself twice. `LogValue` covers slog, as lesson 12's `email` did. `String` covers
`fmt`, so a stray `Printf("%v", cfg)` while debugging prints `[hidden]` too. Neither stops code that
converts it back with `string(...)`, which is what `main` does at the one place the real value is needed.

`config` has a `LogValue` as well. **Logging the configuration a process actually started with** is one
of the most useful lines a service writes: when behaviour differs between two environments, the first
question is what each of them was configured with, and the answer is in the first line of each log.
Section 08 shows it.
