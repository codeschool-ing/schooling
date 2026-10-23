---
title: zap
version: 1
---

O zap veio da Uber, e **oferece duas APIs sobre um mesmo núcleo**: um `Logger` estrito que recebe campos
tipados, pela velocidade, e um `SugaredLogger` que recebe pares chave-valor soltos e formatos de `Printf`,
pela conveniência.

```go
// logothers/zap/main.go
package main

import (
	"go.uber.org/zap"
)

func main() {
	logger, err := zap.NewProduction()
	if err != nil {
		panic(err)
	}
	defer logger.Sync()

	logger.Info("ticket sold", zap.Int("event_id", 1), zap.Int("quantity", 2))

	req := logger.With(zap.String("request_id", "5f2c9a1be07d44a3"))
	req.Error("sale failed", zap.Int("event_id", 2), zap.String("err", "not enough seats left"))

	sugar := logger.Sugar()
	sugar.Infow("ticket sold", "event_id", 1, "quantity", 2)
	sugar.Infof("%d tickets sold for event %d", 2, 1)
}
```

```
ana@vm:~/logothers$ go run ./zap
{"level":"info","ts":1792707620.004298,"caller":"zap/main.go:15","msg":"ticket sold","event_id":1,"quantity":2}
{"level":"error","ts":1792707620.0043795,"caller":"zap/main.go:18","msg":"sale failed","request_id":"5f2c9a1be07d44a3","event_id":2,"err":"not enough seats left","stacktrace":"main.main\n\t/home/ana/logothers/zap/main.go:18\nruntime.main\n\t/usr/local/go/src/runtime/proc.go:302"}
{"level":"info","ts":1792707620.0043929,"caller":"zap/main.go:21","msg":"ticket sold","event_id":1,"quantity":2}
{"level":"info","ts":1792707620.004404,"caller":"zap/main.go:22","msg":"2 tickets sold for event 1"}
```

- **`zap.NewProduction()`** é uma configuração pronta: JSON, `INFO` para cima, um carimbo de tempo em
  segundos desde 1970 em `ts`, e **o arquivo e a linha da chamada em `caller`**.
- **`zap.Int`, `zap.String`** são campos tipados, como o `slog.Int` do slog.
- **A linha `ERROR` traz um `stacktrace`**: a configuração de produção acrescenta a pilha a todo erro. Isso
  ajuda na primeira vez e custa caro num serviço que registra muitos erros.
- **`Sugar()`** dá a API conveniente. `Infow` recebe pares chave-valor como o `Info` do slog; `Infof` monta a
  mensagem com `Printf`, contra o que a seção 02 argumentou, e continua lá para código em migração.
- **`defer logger.Sync()`** descarrega as linhas em buffer antes de o programa sair. Esquecê-lo faz perder as
  últimas linhas que um programa em queda escreveu, que são justamente as que explicam a queda.
