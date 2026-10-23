---
title: zerolog
version: 1
---

O zerolog foi escrito para registrar sem alocar memória, e a API dele tem a forma desse objetivo: **uma
cadeia de chamadas tipadas que escreve JSON enquanto avança**, terminando em `Msg`, que escreve a linha. Ele
era um dos dois loggers que a maioria dos serviços Go usava antes de o slog existir. Ele e o zap moram aqui
num módulo pequeno, com o benchmark da seção 07:

```go
// logothers/zerolog/main.go
package main

import (
	"os"

	"github.com/rs/zerolog"
)

func main() {
	logger := zerolog.New(os.Stdout).With().Timestamp().Logger()
	logger.Info().Int("event_id", 1).Int("quantity", 2).Msg("ticket sold")

	req := logger.With().Str("request_id", "5f2c9a1be07d44a3").Logger()
	req.Error().Int("event_id", 2).Str("err", "not enough seats left").Msg("sale failed")

	logger.Debug().Int("event_id", 1).Msg("seats re-read")
	zerolog.SetGlobalLevel(zerolog.InfoLevel)
	logger.Debug().Int("event_id", 1).Msg("seats re-read again")
}
```

```
ana@vm:~/logothers$ go mod init example.com/logothers
go: creating new go.mod: module example.com/logothers
go: to add module requirements and sums:
	go mod tidy
ana@vm:~/logothers$ go mod tidy
go: finding module for package go.uber.org/zap/zapcore
go: finding module for package github.com/rs/zerolog
go: finding module for package go.uber.org/zap
go: found github.com/rs/zerolog in github.com/rs/zerolog v1.35.1
go: found go.uber.org/zap in go.uber.org/zap v1.28.0
go: found go.uber.org/zap/zapcore in go.uber.org/zap v1.28.0
```

```
ana@vm:~/logothers$ go run ./zerolog
{"level":"info","event_id":1,"quantity":2,"time":"2026-10-22T19:20:19-03:00","message":"ticket sold"}
{"level":"error","request_id":"5f2c9a1be07d44a3","event_id":2,"err":"not enough seats left","time":"2026-10-22T19:20:19-03:00","message":"sale failed"}
{"level":"debug","event_id":1,"time":"2026-10-22T19:20:19-03:00","message":"seats re-read"}
```

- **`logger.Info()` começa uma linha, `.Int(...)` e `.Str(...)` acrescentam campos tipados, `.Msg(...)` a
  termina.** Uma linha começada e nunca terminada com `Msg` nunca é escrita, que é o bug clássico do zerolog.
- **`With()...Logger()`** cria um logger que carrega campos, o `With` do slog no formato do zerolog.
- **Os nomes dos campos são do zerolog**: `level` em minúsculas, `message` em vez de `msg`, e um `time` com
  segundos inteiros, a menos que se configure outra coisa. Plataformas de log são configuradas para saber
  quais nomes um serviço usa; misturar loggers num sistema é configurar isso duas vezes.
- **O primeiro `Debug` foi escrito.** O nível padrão do zerolog deixa tudo passar até que `SetGlobalLevel`
  seja chamado; depois dele, a segunda linha de debug foi descartada. O padrão do slog descarta `DEBUG`; uma
  equipe que troca de um para o outro descobre isso na primeira noite em que os logs ficam dez vezes maiores.

O estilo em cadeia é rápido, a seção 07 mede quanto, e tem um custo de leitura: uma linha fica espalhada por
chamadas de método, e esquecer o `Msg` é uma falha silenciosa que o compilador não pega.
