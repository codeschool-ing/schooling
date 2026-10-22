---
title: Recuperando-se de um pânico
version: 1
---

Um pânico num handler é um bug: um mapa nil escrito, um índice além do fim de um slice, um ponteiro
nil seguido. A aula 36 do `go` pôs os pânicos do lado de "isto nunca deveria acontecer" e os erros
do lado de "isto vai acontecer", e nada nesta aula muda isso. **O que um servidor tem de decidir é
o que um bug numa requisição faz com todo o resto.**

## O que o `net/http` faz sozinho

```go
// fragile/main.go
package main

import (
	"log"
	"net/http"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /boom", func(w http.ResponseWriter, r *http.Request) {
		var seats map[string]int
		seats["A1"]++
	})
	log.Fatal(http.ListenAndServe("localhost:8080", mux))
}
```

Escrever num mapa nil causa pânico. Peça:

```
ana@vm:~/fragile$ curl -si localhost:8080/boom; echo "exit $?"
exit 52
```

O `curl` não imprimiu nada, e o `-s` escondeu a reclamação dele, então o status de saída é a única
testemunha: **52 é o "resposta vazia do servidor" do curl**. A conexão foi fechada sem linha de
status, sem cabeçalhos e sem corpo. O terminal do servidor mostra por quê:

```
ana@vm:~/fragile$ go run .
2026/10/16 19:29:16 http: panic serving 127.0.0.1:53290: assignment to entry in nil map
goroutine 23 [running]:
net/http.(*conn).serve.func1()
	/usr/local/go/src/net/http/server.go:1939 +0xbb
panic({0x91a830?, 0x98fc00?})
	/usr/local/go/src/runtime/panic.go:859 +0x125
main.main.func1({0x1c5c5dd462d4?, 0x48a352?}, 0x0?)
	/home/ana/fragile/main.go:13 +0x28
net/http.HandlerFunc.ServeHTTP(0x1c5c5dd340c0?, {0x94fc58?, 0x1c5c5dd2a1e0?}, 0x61635a?)
	/usr/local/go/src/net/http/server.go:2338 +0x29
net/http.(*ServeMux).ServeHTTP(0x482839?, {0x94fc58, 0x1c5c5dd2a1e0}, 0x1c5c5dd62280)
	/usr/local/go/src/net/http/server.go:2903 +0x1cf
net/http.serverHandler.ServeHTTP({0x1c5c5dd30380?}, {0x94fc58?, 0x1c5c5dd2a1e0?}, 0x1?)
	/usr/local/go/src/net/http/server.go:3413 +0x8e
net/http.(*conn).serve(0x1c5c5dd5a2d0, {0x950008, 0x1c5c5dd27500})
	/usr/local/go/src/net/http/server.go:2137 +0x6dc
created by net/http.(*Server).Serve in goroutine 1
	/usr/local/go/src/net/http/server.go:3581 +0x4fd
```

**O `net/http` recuperou o pânico ele mesmo.** Ele o registrou com o endereço do cliente e a pilha
inteira, fechou aquela conexão e continuou servindo: o programa não morreu, e uma requisição que
chegasse um instante depois teria sido respondida. Leia a pilha de cima para baixo até a primeira
linha que é código seu, `main.main.func1` em `main.go:13`, que é a linha que escreveu no mapa. Tudo
acima dela é o runtime relatando o pânico, e tudo abaixo é o `net/http` chamando o seu handler.

Esse padrão protege o processo e é cruel com o cliente, que fica com uma conexão fechada na cara e
nada para mostrar ao usuário.

## Um 500 em vez de silêncio

O middleware abaixo pega o pânico antes, com `recover` numa função adiada, e o transforma numa
resposta:

```go
// sturdy/main.go
package main

import (
	"log"
	"net/http"
	"runtime/debug"
)

func recoverPanics(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			v := recover()
			if v == nil {
				return
			}
			if v == http.ErrAbortHandler {
				panic(v)
			}
			log.Printf("panic serving %s %s: %v\n%s", r.Method, r.URL.Path, v, debug.Stack())
			http.Error(w, "internal server error", http.StatusInternalServerError)
		}()
		next.ServeHTTP(w, r)
	})
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /boom", func(w http.ResponseWriter, r *http.Request) {
		var seats map[string]int
		seats["A1"]++
	})
	log.Fatal(http.ListenAndServe("localhost:8080", recoverPanics(mux)))
}
```

```
ana@vm:~/sturdy$ curl -si localhost:8080/boom
HTTP/1.1 500 Internal Server Error
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:29:20 GMT
Content-Length: 22

internal server error
```

```
ana@vm:~/sturdy$ go run .
2026/10/16 19:29:20 panic serving GET /boom: assignment to entry in nil map
goroutine 19 [running]:
runtime/debug.Stack()
	/usr/local/go/src/runtime/debug/stack.go:26 +0x5e
main.recoverPanics.func1.1()
	/home/ana/sturdy/main.go:20 +0x8d
```

O cliente agora tem um status com que agir, e **o corpo não diz nada da causa**: a mensagem de um
pânico guarda qualquer coisa, e um estranho não precisa saber que um mapa era nil. O detalhe foi
para o log, com o `debug.Stack()` imprimindo a pilha da goroutine que entrou em pânico; as seis
linhas acima são o topo dela, e a pilha completa segue até o handler em `main.go`.

Três detalhes desse middleware são de propósito:

- **`recover` só funciona numa função adiada**, e só na goroutine que entrou em pânico. Um handler
  que inicia goroutines próprias tem de protegê-las ele mesmo, porque um pânico numa delas encerra o
  programa inteiro e nenhum middleware consegue impedir.
- **`http.ErrAbortHandler` é relançado.** É o valor com que um handler entra em pânico de propósito
  para abandonar uma resposta no meio, e o `net/http` o trata como um pedido para fechar a conexão
  sem registrar nada. Transformá-lo num 500 desfaria isso.
- **Se o handler já tinha escrito, o 500 não tem como ser mandado.** O status saiu com a primeira
  escrita, então o `http.Error` acrescenta uma linha de `WriteHeader` supérfluo ao log e o cliente
  recebe o que estava escrito pela metade. A recuperação torna um pânico sobrevivível; não o torna
  invisível.

## O mesmo no boxoffice

O boxoffice ganha o mesmo middleware num arquivo próprio:

```go
// boxoffice/recover.go
package main

import (
	"log"
	"net/http"
	"runtime/debug"
)

func recoverPanics(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			v := recover()
			if v == nil {
				return
			}
			if v == http.ErrAbortHandler {
				panic(v)
			}
			log.Printf("panic serving %s %s: %v\n%s", r.Method, r.URL.Path, v, debug.Stack())
			http.Error(w, "internal server error", http.StatusInternalServerError)
		}()
		next.ServeHTTP(w, r)
	})
}
```
