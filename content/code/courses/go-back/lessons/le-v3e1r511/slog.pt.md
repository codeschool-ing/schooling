---
title: slog, o logger estruturado da biblioteca padrão
version: 1
---

A aula 22 do `go-concurrency` apresentou o `log/slog`. Esta seção usa as partes de que um servidor precisa,
num programa pequeno:

```go
// logdemo/main.go
package main

import (
	"log/slog"
	"os"
	"strings"
)

// email is an address that logs itself with most of the local part hidden.
type email string

func (e email) LogValue() slog.Value {
	local, domain, ok := strings.Cut(string(e), "@")
	if !ok || local == "" {
		return slog.StringValue("(invalid)")
	}
	return slog.StringValue(local[:1] + "***@" + domain)
}

func main() {
	text := slog.New(slog.NewTextHandler(os.Stdout, nil))
	text.Info("ticket sold", "event_id", 1, "quantity", 2)

	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))
	logger.Info("ticket sold", "event_id", 1, "quantity", 2, "email", email("ana@example.com"))
	logger.Debug("seats re-read", "event_id", 1)
	logger.Warn("event nearly sold out", slog.Group("event", "id", 3, "available", 2))

	reqLogger := logger.With("request_id", "5f2c9a1be07d44a3")
	reqLogger.Error("sale failed", "event_id", 2, "err", "not enough seats left")
}
```

```
ana@vm:~/logdemo$ go run .
time=2026-10-22T19:20:19.523-03:00 level=INFO msg="ticket sold" event_id=1 quantity=2
{"time":"2026-10-22T19:20:19.523268918-03:00","level":"INFO","msg":"ticket sold","event_id":1,"quantity":2,"email":"a***@example.com"}
{"time":"2026-10-22T19:20:19.523289023-03:00","level":"WARN","msg":"event nearly sold out","event":{"id":3,"available":2}}
{"time":"2026-10-22T19:20:19.523298473-03:00","level":"ERROR","msg":"sale failed","request_id":"5f2c9a1be07d44a3","event_id":2,"err":"not enough seats left"}
```

Linha por linha:

- **Um logger é um handler embrulhado num `*slog.Logger`.** O handler decide o formato: o `TextHandler`
  escreve pares `key=value`, legíveis num terminal; o `JSONHandler` escreve JSON, legível por todo o resto.
  As chamadas são as mesmas para os dois.
- **Os campos são passados como chave, valor, chave, valor** depois da mensagem, e cada um mantém o tipo:
  `1` é um número no JSON, não uma string.
- **A linha de debug sumiu.** O handler recebeu `Level: slog.LevelInfo`, que também é o padrão, então o
  `Debug` foi descartado antes de qualquer formatação.
- **O `slog.Group` aninha campos** sob uma chave, `"event":{"id":3,"available":2}`.
- **O `With` devolve um logger que carrega campos** para toda linha que escreve. O id de requisição foi dado
  uma vez e aparece na linha de erro; a seção 04 usa exatamente isso em toda requisição.

## Um valor que se registra sozinho

O endereço saiu como `a***@example.com`. **O tipo `email` tem um método `LogValue`**, o que faz dele um
`slog.LogValuer`, e o slog chama esse método em vez de imprimir o valor. O tipo decide como é registrado,
então toda chamada de log que um dia receber um `email` o esconde, sem ninguém precisar lembrar. A seção 08
explica por que isso importa.
