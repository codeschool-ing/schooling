---
title: Um servidor que nunca responde
version: 1
---

A falha que mais importa para um cliente não é um 404 nem um 500. É um servidor que aceita a conexão
e depois não diz nada, por um minuto ou para sempre. **Um `http.Client` sem timeout e uma requisição
sem prazo esperam exatamente esse tanto**, e o `http.DefaultClient` não tem timeout. Um servidor de
teste faz esse papel quando se pede, o que nenhum servidor real faz na hora que você quer.

## O teste

O handler espera até o contexto da requisição acabar, o que acontece quando o cliente desiste e
fecha a conexão. O lado do cliente desiste depois de 50 milissegundos, pelo contexto que a lição 10
ensinou. Salvo como `timeout_test.go`:

```go
package wordcount

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestHTTPSourceTimeout(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		<-r.Context().Done() // never answer; return when the client goes away
	}))
	defer srv.Close()
	src := HTTPSource{BaseURL: srv.URL, Client: srv.Client()}

	ctx, cancel := context.WithTimeout(t.Context(), 50*time.Millisecond)
	defer cancel()
	start := time.Now()
	_, err := TopOf(ctx, src, "slow.txt", 1)
	if !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("err = %v, want context.DeadlineExceeded", err)
	}
	t.Logf("gave up after %v: %v", time.Since(start).Round(time.Millisecond), err)
}
```

```
ana@vm:~/wordcount$ go test -v -run Timeout
=== RUN   TestHTTPSourceTimeout
    timeout_test.go:26: gave up after 51ms: open slow.txt: Get "http://127.0.0.1:43865/slow.txt": context deadline exceeded
--- PASS: TestHTTPSourceTimeout (0.06s)
PASS
ok  	example.com/wordcount	0.062s
```

A requisição foi cancelada quando o prazo passou, o erro embrulha `context.DeadlineExceeded` por três
camadas, `http.Client`, `HTTPSource` e `TopOf`, e o `errors.Is` ainda o acha. É o teste provando que
o `HTTPSource` respeita o contexto que recebe, que é o motivo inteiro de o `Open` receber um.

## O handler também tem de parar

O `<-r.Context().Done()` do handler não é enfeite. O `srv.Close` espera toda requisição ainda em
atendimento terminar, então um handler de teste que ignora o contexto segura o teste aberto pelo
tempo que resolver esperar. Um arquivo descartável mostra isso, com um handler que dorme seis
segundos aconteça o que acontecer, salvo como `stuck_test.go`:

```go
package wordcount

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestStuckServer(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(6 * time.Second) // ignores the client entirely
	}))
	defer srv.Close()
	ctx, cancel := context.WithTimeout(t.Context(), 50*time.Millisecond)
	defer cancel()
	_, err := TopOf(ctx, HTTPSource{BaseURL: srv.URL, Client: srv.Client()}, "slow.txt", 1)
	t.Logf("client gave up: %v", err)
}
```

```
ana@vm:~/wordcount$ go test -v -run Stuck
=== RUN   TestStuckServer
    stuck_test.go:19: client gave up: open slow.txt: Get "http://127.0.0.1:35767/slow.txt": context deadline exceeded
2026/10/16 19:47:20 httptest.Server blocked in Close after 5 seconds, waiting for connections:
  *net.TCPConn 0x2dd721902010 127.0.0.1:37320 in state active
--- PASS: TestStuckServer (6.02s)
PASS
ok  	example.com/wordcount	6.019s
ana@vm:~/wordcount$ rm stuck_test.go
```

**O cliente desistiu depois de 50 milissegundos e o teste ainda levou seis segundos**, porque o
`srv.Close` esperou o handler adormecido, e avisou no caminho. Num conjunto de algumas centenas de
testes é assim que uma execução passa de segundos para minutos com todo teste passando. Um handler
escrito para um teste observa o `r.Context()`, exatamente como um handler de produção deve fazer.

## Um prazo por requisição ou por cliente

O teste acima pôs o prazo no contexto, que é o lugar certo quando quem chama sabe quanto a operação
inteira pode levar. O `http.Client` também tem um campo `Timeout`, um limite para cada requisição
feita por aquele cliente, incluindo a leitura do corpo. Os dois se combinam, e vence o que acabar
primeiro. O que um cliente em produção não deve ter é nenhum dos dois: dê ao `HTTPSource` um cliente
com `Timeout`, ou chamadores que sempre passem um prazo, e teste isso do jeito que esta seção fez.
