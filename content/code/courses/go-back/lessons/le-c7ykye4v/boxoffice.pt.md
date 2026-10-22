---
title: A corrente no boxoffice
version: 1
---

Quatro middlewares, e dois lugares onde podem ficar: em volta de tudo, ou em volta de algumas
rotas. O boxoffice usa os dois. **O arquivo de rotas diz qual é qual**, então a API inteira e tudo o
que fica na frente dela ainda cabem numa tela:

```go
// boxoffice/routes.go
package main

import "net/http"

func routes(store *memStore, tokens map[string]string) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /events", listEvents(store))
	mux.HandleFunc("GET /events/{id}", getEvent(store))

	admin := http.NewServeMux()
	admin.HandleFunc("GET /admin/report", salesReport(store))
	mux.Handle("/admin/", requireStaff(tokens)(admin))

	return chain(mux, logRequests, recoverPanics, cors("https://tickets.example.com"))
}
```

## Em volta de algumas rotas: um mux dentro do mux

`admin` é um segundo mux com as rotas da equipe, com os caminhos completos, `/admin/report`. O mux
principal o registra, envolvido em `requireStaff`, sob o padrão de subárvore `/admin/`, então **todo
caminho debaixo de `/admin/` passa pela conferência do token antes de o mux de dentro sequer olhar
para ele**, e todo caminho fora dele nunca encontra a conferência. Uma rota acrescentada ao `admin`
no mês que vem fica protegida sem ninguém lembrar de protegê-la, que é o motivo de pôr a conferência
na subárvore e não em cada handler.

## Em volta de tudo: a ordem

O `chain` põe o primeiro middleware mais por fora, e a ordem não é questão de gosto:

| posição | middleware | por que ali |
|---|---|---|
| mais por fora | `logRequests` | ele precisa ver a resposta final de toda requisição, inclusive o 500 que o `recoverPanics` faz de um pânico e o 204 que o `cors` dá a um preflight |
| segundo | `recoverPanics` | tudo dentro dele fica protegido, os outros middlewares incluídos; se ficasse fora do logger, um pânico pularia a linha de log |
| terceiro | `cors` | preflights não levam token, então ele tem de respondê-los antes de chegar ao `requireStaff` |
| só em `/admin/` | `requireStaff` | as rotas públicas têm de continuar públicas |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 230\" role=\"img\" aria-label=\"Uma requisição entra em logRequests, depois recoverPanics, depois cors, depois o mux. O mux manda os caminhos /events direto para os handlers, e os caminhos /admin/ por requireStaff até um segundo mux que guarda salesReport.\"><defs><marker id=\"gb-l2-chain-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"60\" width=\"105\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"67\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">logRequests</text><path d=\"M 120 82 L 135 82\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-chain-ah)\"></path><rect x=\"135\" y=\"60\" width=\"105\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"187\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">recoverPanics</text><path d=\"M 240 82 L 255 82\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-chain-ah)\"></path><rect x=\"255\" y=\"60\" width=\"105\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"307\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cors</text><path d=\"M 360 82 L 375 82\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-chain-ah)\"></path><rect x=\"375\" y=\"60\" width=\"70\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"410\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mux</text><path d=\"M 445 75 L 475 75 L 475 35 L 493 35\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-chain-ah)\"></path><rect x=\"495\" y=\"12\" width=\"180\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/events, /events/{id}</text><text x=\"585\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">listEvents, getEvent</text><path d=\"M 445 92 L 475 92 L 475 150 L 493 150\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-chain-ah)\"></path><rect x=\"495\" y=\"126\" width=\"105\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"547\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/admin/</text><text x=\"547\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">requireStaff</text><path d=\"M 547 172 L 547 188\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-chain-ah)\"></path><rect x=\"475\" y=\"190\" width=\"145\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"547\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">admin: salesReport</text><text x=\"15\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">toda requisição passa por estes três</text></svg>", "caption": "Três middlewares em volta de tudo, um só em volta das rotas da equipe."}
```

## O `main` lê os tokens

```go
// boxoffice/main.go
package main

import (
	"log"
	"net/http"
	"os"
	"time"
)

func main() {
	tokens := map[string]string{}
	for role, name := range map[string]string{
		"manager": "BOXOFFICE_MANAGER_TOKEN",
		"door":    "BOXOFFICE_DOOR_TOKEN",
	} {
		if t := os.Getenv(name); t != "" {
			tokens[t] = role
		}
	}
	if len(tokens) == 0 {
		log.Fatal("no staff tokens: set BOXOFFICE_MANAGER_TOKEN")
	}
	srv := &http.Server{
		Addr:              "localhost:8080",
		Handler:           routes(newMemStore(), tokens),
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Printf("boxoffice listening on %s", srv.Addr)
	log.Fatal(srv.ListenAndServe())
}
```

O laço lê as duas variáveis e fica com as que estiverem definidas, então uma instalação sem equipe
de portaria simplesmente deixa uma de fora. **Sem nenhuma das duas, o programa se recusa a
iniciar**: um servidor cujas rotas da equipe ninguém consegue abrir é um erro a pegar agora, não um
401 para decifrar depois.

## Rodando a aula inteira

```
ana@vm:~/boxoffice$ ls
admin.go
auth.go
cors.go
events.go
go.mod
main.go
middleware.go
recover.go
routes.go
store.go
ana@vm:~/boxoffice$ go vet ./...
ana@vm:~/boxoffice$ go run .
2026/10/16 19:29:24 no staff tokens: set BOXOFFICE_MANAGER_TOKEN
exit status 1
```

Dez arquivos agora, todos `package main`. Depois de exportar os dois tokens como a seção 06 mostrou,
`go run .` inicia o servidor, e toda requisição das seções 03 a 06 passou por esta corrente. **Aqui
está o log do servidor para todas elas, na ordem em que foram feitas:**

```
2026/10/16 19:29:24 boxoffice listening on localhost:8080
2026/10/16 19:29:24 GET /events 200 77B 25µs
2026/10/16 19:29:24 GET /events/9 404 14B 19µs
2026/10/16 19:29:24 POST /events 405 19B 29µs
2026/10/16 19:29:24 GET /events/1 200 41B 18µs
2026/10/16 19:29:24 GET /events/1 200 41B 15µs
2026/10/16 19:29:24 OPTIONS /admin/report 204 0B 4µs
2026/10/16 19:29:24 GET /admin/report 401 26B 18µs
2026/10/16 19:29:24 GET /admin/report 401 26B 21µs
2026/10/16 19:29:24 GET /admin/report 403 41B 19µs
2026/10/16 19:29:24 GET /admin/report 200 51B 19µs
```

Todas estão lá: o 404 e o 405 que o mux escreveu, o preflight que o `cors` respondeu sem chegar ao
mux, os dois 401 e o 403 que o `requireStaff` e o handler devolveram. **Nenhum token aparece
nele**, embora três daquelas requisições levassem um. O 200 do relatório é a única linha que diz
que um gerente passou por aqui, o que a aula 12 vai querer dizer com todas as letras.
