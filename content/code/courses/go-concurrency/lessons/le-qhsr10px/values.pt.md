---
title: Valores, e o que cabe neles
version: 1
---

O quarto método, `Value(key)`, deixa um contexto levar dados chamada abaixo junto com o
cancelamento. **Ele serve para dados que pertencem à requisição e precisam atravessar fronteiras de
API**: um id de requisição para os logs, a identidade de quem chama, um id de rastreamento. Não é um
jeito de passar os parâmetros comuns de uma função escondidos.

## Uma chave de tipo próprio

`context.WithValue(parent, key, value)` devolve um filho carregando um par; `Value` procura a chave
nesse contexto e depois em cada pai, um de cada vez. Chaves são comparadas como chaves de map, tipo
incluído, e esse é todo o truque para usá-las com segurança. Salvo como `values.go`:

```go
// Command values carries a request id through a context, under a key of its own type.
package main

import (
	"context"
	"fmt"
)

// ctxKey is unexported, so no other package can make a key equal to ours.
type ctxKey int

const requestIDKey ctxKey = 0

func WithRequestID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, requestIDKey, id)
}

// RequestID returns the id, and false when the context carries none.
func RequestID(ctx context.Context) (string, bool) {
	id, ok := ctx.Value(requestIDKey).(string)
	return id, ok
}

func handle(ctx context.Context) {
	id, ok := RequestID(ctx)
	fmt.Printf("handling request %q (found: %v)\n", id, ok)
}

func main() {
	ctx := WithRequestID(context.Background(), "req-7f3a")
	handle(ctx)
	handle(context.Background())
	fmt.Println("same text, different key:", ctx.Value(0), ctx.Value("requestIDKey"))
	fmt.Println(ctx)
}
```

```
ana@vm:~/ctx$ go run values.go
handling request "req-7f3a" (found: true)
handling request "" (found: false)
same text, different key: <nil> <nil>
context.Background.WithValue(main.ctxKey, req-7f3a)
```

`handle` achou o id no primeiro contexto e informou `found: false` para um vazio, pelo comma-ok da
asserção de tipo. A terceira linha é a razão de existir do `ctxKey`: **nem `0` nem a string
`"requestIDKey"` acham o valor**, porque nenhum dos dois tem o tipo `ctxKey`. Nenhum outro pacote
consegue dar nome a esse tipo, então nenhum outro pacote consegue ler ou sobrescrever esse valor por
acidente, mesmo que também tenha escolhido a chave `0`. Uma chave string, `"id"`, é a colisão
clássica entre duas bibliotecas.

A última linha é o que o `fmt` imprime para um contexto: a corrente a partir da raiz, com o par que
ela carrega. Isso ajuda num depurador e é um motivo para não pôr segredos num valor, já que um
contexto acaba em linhas de log mais vezes do que alguém pretende.

## O que não cabe

A documentação de `context` diz para usar valores só para dados do escopo da requisição que
atravessam processos e APIs, **e não para passar parâmetros opcionais a funções**. Três sinais de que
um valor deveria ser um parâmetro:

1. a função não consegue fazer o seu trabalho sem ele: um handle de banco de dados, uma configuração;
2. a ausência dele é um defeito, e não um caso normal;
3. ele é o mesmo para toda requisição: pertence ao programa, não à requisição.

Um valor também perde o tipo na fronteira, `any` na entrada e uma asserção de tipo na saída, então o
par de funções acima, `WithRequestID` e `RequestID`, é o jeito comum de manter a chave privada e os
tipos certos.
