---
title: Três loggers, medidos
version: 1
---

Cada uma das três bibliotecas diz ser rápida, e é fácil testar a afirmação. Este programa registra a mesma
linha, uma mensagem e três campos, com cada logger e cada API, escrevendo em `io.Discard` para que só o
registro seja medido, e relata tempo e memória por linha com a maquinaria de benchmark do pacote `testing`
usada fora de um teste, como fez a aula 11:

```go
// logothers/bench/main.go
package main

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"testing"

	"github.com/rs/zerolog"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

func report(name string, r testing.BenchmarkResult) {
	fmt.Printf("%-14s %6d ns/line %4d allocs/line %5d B/line\n",
		name, r.NsPerOp(), r.AllocsPerOp(), r.AllocedBytesPerOp())
}

func main() {
	ctx := context.Background()
	s := slog.New(slog.NewJSONHandler(io.Discard, nil))
	report("slog", testing.Benchmark(func(b *testing.B) {
		b.ReportAllocs()
		for b.Loop() {
			s.Info("ticket sold", "event_id", 1, "quantity", 2, "request_id", "5f2c9a1be07d44a3")
		}
	}))
	report("slog LogAttrs", testing.Benchmark(func(b *testing.B) {
		b.ReportAllocs()
		for b.Loop() {
			s.LogAttrs(ctx, slog.LevelInfo, "ticket sold",
				slog.Int("event_id", 1), slog.Int("quantity", 2), slog.String("request_id", "5f2c9a1be07d44a3"))
		}
	}))

	z := zerolog.New(io.Discard).With().Timestamp().Logger()
	report("zerolog", testing.Benchmark(func(b *testing.B) {
		b.ReportAllocs()
		for b.Loop() {
			z.Info().Int("event_id", 1).Int("quantity", 2).Str("request_id", "5f2c9a1be07d44a3").Msg("ticket sold")
		}
	}))

	core := zapcore.NewCore(zapcore.NewJSONEncoder(zap.NewProductionEncoderConfig()), zapcore.AddSync(io.Discard), zap.InfoLevel)
	zl := zap.New(core)
	report("zap", testing.Benchmark(func(b *testing.B) {
		b.ReportAllocs()
		for b.Loop() {
			zl.Info("ticket sold", zap.Int("event_id", 1), zap.Int("quantity", 2), zap.String("request_id", "5f2c9a1be07d44a3"))
		}
	}))
	zs := zl.Sugar()
	report("zap sugared", testing.Benchmark(func(b *testing.B) {
		b.ReportAllocs()
		for b.Loop() {
			zs.Infow("ticket sold", "event_id", 1, "quantity", 2, "request_id", "5f2c9a1be07d44a3")
		}
	}))
}
```

```
ana@vm:~/logothers$ go run ./bench
slog              610 ns/line    0 allocs/line     0 B/line
slog LogAttrs     568 ns/line    0 allocs/line     0 B/line
zerolog           215 ns/line    0 allocs/line     0 B/line
zap               468 ns/line    1 allocs/line   192 B/line
zap sugared       690 ns/line    1 allocs/line   384 B/line
ana@vm:~/logothers$ go run ./bench
slog              667 ns/line    0 allocs/line     0 B/line
slog LogAttrs     598 ns/line    0 allocs/line     0 B/line
zerolog           216 ns/line    0 allocs/line     0 B/line
zap               450 ns/line    1 allocs/line   192 B/line
zap sugared       777 ns/line    1 allocs/line   384 B/line
```

**O zerolog é o mais rápido com folga**, cerca de 215 nanossegundos por linha contra 450 a 470 do zap e 570 a
670 do slog. O `LogAttrs` do slog, que recebe atributos tipados, é um pouco mais rápido que o `Info` de
chave-valor. **O slog e o zerolog não alocaram nada por linha; o zap alocou uma vez**, 192 bytes, e a API
sugared o dobro de bytes.

**Agora ponha os números em proporção.** A aula 6 mediu uma requisição contra o PostgreSQL em milissegundos,
ou seja, milhões de nanossegundos. O boxoffice escreve uma linha de acesso por requisição; a diferença entre o
logger mais rápido e o mais lento aqui é de cerca de meio microssegundo nessa linha, alguns centésimos de um
por cento da requisição. **Para um serviço como o boxoffice, a velocidade do logger não importa**, e as
perguntas decisivas estão em outro lugar:

| | slog | zerolog | zap |
|---|---|---|---|
| de onde vem | a biblioteca padrão, desde o Go 1.21 | um módulo | um módulo |
| API | chave-valor ou atributos tipados | uma cadeia que termina em `Msg` | `Logger` tipado, ou `SugaredLogger` |
| nível padrão | `INFO` | tudo | depende da configuração escolhida |
| trocar o formato ou o destino | escrever ou escolher um `slog.Handler` | os writers dele | os cores e encoders dele |
| bibliotecas de que você depende registram por ele | sim: `slog.Logger` é o tipo compartilhado | só se escolheram o zerolog | só se escolheram o zap |

A última linha é a decisiva. **Como o slog está na biblioteca padrão, uma biblioteca pode aceitar um
`*slog.Logger` e toda aplicação pode lhe dar o seu.** Tanto o zerolog quanto o zap podem ficar atrás do slog,
como handler, para uma equipe que queira a velocidade deles com a API do slog. O boxoffice usa o slog, e um
serviço que registra cem mil linhas por segundo talvez meça de novo.
