---
title: Um registro, e o handler que o escreve
version: 1
---

Uma linha de log escrita com `fmt.Printf` é uma frase: fácil para uma pessoa, e um enigma para o
programa que precisa achar toda consulta lenta num dia delas. **O `log/slog` escreve registros: um
nível, uma mensagem e uma lista de valores com nome**, e um handler decide como o registro vira
bytes. A mesma chamada pode então produzir texto que uma pessoa lê ou JSON que uma máquina busca.

Todo programa desta lição mora num diretório próprio dentro de `~/logs`, um módulo só para todos.
O primeiro usa o logger padrão, sem nada configurado, salvo como `first/main.go`:

```go
// Command first logs through the default logger, as it comes.
package main

import (
	"log"
	"log/slog"
)

func main() {
	log.Print("an old-style line")
	slog.Info("order placed", "order", 1042, "total_cents", 15990)
	slog.Debug("not shown")
}
```

```
ana@vm:~/logs$ go run ./first
2026/10/16 19:38:40 an old-style line
2026/10/16 19:38:40 INFO order placed order=1042 total_cents=15990
```

O velho pacote `log` e o `slog` compartilham um padrão, então as duas linhas saíram no mesmo
formato, com a data e a hora da execução na frente. A linha do `slog` tem um nível, `INFO`, e os
seus valores como `chave=valor`. **A linha de `Debug` não imprimiu nada: o logger padrão registra
`INFO` para cima.** Os argumentos depois da mensagem são lidos em pares, uma chave e depois o seu
valor.

## Texto para pessoas, JSON para máquinas

O handler é escolhido quando o logger é criado. O próximo programa cria dois, cada um com opções que
baixam o nível para `DEBUG` e tiram a hora de todo registro, para a saída desta lição ser a mesma em
toda execução. Salvo como `handlers/main.go`:

```go
// Command handlers writes the same records through two handlers.
package main

import (
	"log/slog"
	"os"
)

// noTime drops the time from every record, so that this lesson's
// output is the same on every run.
func noTime(groups []string, a slog.Attr) slog.Attr {
	if a.Key == slog.TimeKey && len(groups) == 0 {
		return slog.Attr{}
	}
	return a
}

func main() {
	opts := &slog.HandlerOptions{Level: slog.LevelDebug, ReplaceAttr: noTime}

	text := slog.New(slog.NewTextHandler(os.Stdout, opts))
	text.Debug("cache miss", "key", "user:7")
	text.Info("order placed", "order", 1042, "note", "gift wrap")
	text.Warn("slow query", "took_ms", 812)

	json := slog.New(slog.NewJSONHandler(os.Stdout, opts))
	json.Info("order placed", "order", 1042, "note", "gift wrap")
	json.Error("payment refused", "order", 1042, "reason", "card expired")
}
```

```
ana@vm:~/logs$ go run ./handlers
level=DEBUG msg="cache miss" key=user:7
level=INFO msg="order placed" order=1042 note="gift wrap"
level=WARN msg="slow query" took_ms=812
{"level":"INFO","msg":"order placed","order":1042,"note":"gift wrap"}
{"level":"ERROR","msg":"payment refused","order":1042,"reason":"card expired"}
```

**O `TextHandler` escreve pares `chave=valor`, pondo aspas num valor só quando ele tem espaço**,
então a linha continua legível e o `grep` ainda acha `level=WARN`. O `JSONHandler` escreve um
objeto JSON por linha, e um número continua número, `"order":1042`, que uma busca de logs consegue
comparar e somar. O registro `DEBUG` apareceu desta vez porque as opções baixaram o nível.

Cada linha de JSON é um objeto inteiro, então qualquer ferramenta que lê JSON lê uma:

```
ana@vm:~/logs$ go run ./handlers | grep ERROR
{"level":"ERROR","msg":"payment refused","order":1042,"reason":"card expired"}
ana@vm:~/logs$ go run ./handlers | tail -1 | python3 -m json.tool
{
    "level": "ERROR",
    "msg": "payment refused",
    "order": 1042,
    "reason": "card expired"
}
```

O `python3 -m json.tool` aqui só formata; os serviços que coletam logs em produção leem as mesmas
linhas. **Escolha JSON para um programa cujos logs uma máquina vai ler, e texto para um programa que
uma pessoa acompanha num terminal.** As chamadas que escrevem os registros não mudam, só o handler.
