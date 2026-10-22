---
title: Um formato para todo erro
version: 1
---

Na seção 04, o boxoffice já tinha quatro jeitos de dizer não: um id ruim, um corpo ilegível, valores
inválidos, e as recusas do store ainda por vir. Se cada handler inventasse o próprio formato de
erro, um cliente precisaria de um parser por rota. **Os erros de uma API devem ter um formato só, e
existe um padrão: a RFC 9457, "Problem Details for HTTP APIs"**, publicada em 2023 para substituir a
RFC 7807, de 2016, com o mesmo formato. É um objeto JSON com alguns membros combinados, mandado como
`application/problem+json`:

| membro | guarda |
|---|---|
| `type` | uma URI que nomeia o tipo de problema; `about:blank` quando o status diz tudo |
| `title` | um resumo curto desse tipo, o mesmo em toda ocorrência; com `about:blank`, a frase do status |
| `status` | o status HTTP de novo, para quem registra o corpo sem os cabeçalhos |
| `detail` | esta ocorrência, em palavras com que um desenvolvedor do cliente sabe agir |
| qualquer outro | extensões; o boxoffice acrescenta `errors`, o mapa campo a campo da seção 04 |

A versão do boxoffice é um tipo e uma função, no arquivo que também guarda o `fail` da seção 06:

```go
// boxoffice/problem.go
package main

import (
	"errors"
	"log"
	"net/http"
)

// problem is an error response in the shape RFC 9457 describes.
type problem struct {
	Type   string            `json:"type"`
	Title  string            `json:"title"`
	Status int               `json:"status"`
	Detail string            `json:"detail,omitempty"`
	Errors map[string]string `json:"errors,omitempty"`
}

// writeProblem sends an error as application/problem+json.
func writeProblem(w http.ResponseWriter, status int, detail string, fields map[string]string) {
	w.Header().Set("Content-Type", "application/problem+json")
	writeJSON(w, status, problem{
		Type:   "about:blank",
		Title:  http.StatusText(status),
		Status: status,
		Detail: detail,
		Errors: fields,
	})
}

// fail turns an error from the store into the response it deserves.
func fail(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrNotFound):
		writeProblem(w, http.StatusNotFound, err.Error(), nil)
	case errors.Is(err, ErrSoldOut):
		writeProblem(w, http.StatusConflict, err.Error(), nil)
	default:
		log.Printf("unexpected error: %v", err)
		writeProblem(w, http.StatusInternalServerError, "", nil)
	}
}
```

O `writeProblem` define o tipo de mídia preciso e depois entrega o valor ao `writeJSON`, que mantém
um `Content-Type` já definido; essa é a linha para a qual a seção 02 deixou espaço. Todo erro que o
boxoffice escreve daqui em diante passa por ele, inclusive os dois middlewares da aula 2 que
escreviam texto: a seção 07 mostra o `requireStaff` e o `recoverPanics` alterados para usá-lo. Eis o
401 que eles dão agora:

```
ana@vm:~/boxoffice$ curl -si --json '{"name": "Organ Recital", "seats": 60}' localhost:8080/admin/events
HTTP/1.1 401 Unauthorized
Content-Type: application/problem+json
Vary: Origin
Www-Authenticate: Bearer realm="boxoffice"
Date: Fri, 16 Oct 2026 22:36:33 GMT
Content-Length: 96

{"type":"about:blank","title":"Unauthorized","status":401,"detail":"a staff token is required"}
```

**O `detail` é seguro de mostrar, e o `detail` de um 500 fica vazio de propósito.** A mensagem de um
erro inesperado pode citar um arquivo, uma consulta ou um nome de host, então o `fail` a manda para
o log e dá ao cliente só o status. O `type` fica `about:blank` em todo o boxoffice porque nenhum dos
erros dele precisa de mais que o status para ser entendido; uma API com quarenta tipos de recusa
daria a cada um uma URI com uma página que o explica.

## As duas respostas que o boxoffice não escreve

Uma requisição ainda recebe texto puro:

```
ana@vm:~/boxoffice$ curl -si -X DELETE localhost:8080/events
HTTP/1.1 405 Method Not Allowed
Allow: GET, HEAD
Content-Type: text/plain; charset=utf-8
Vary: Origin
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:36:33 GMT
Content-Length: 19

Method Not Allowed
```

**O 404 e o 405 que o mux escreve para caminhos e métodos sem padrão são dele**, e o `ServeMux` não
tem configuração para mudar o formato deles. O conserto óbvio é um padrão curinga, `/`, cujo handler
escreve um 404 em JSON. Ele tem um custo fácil de não ver:

```go
// catchall/main.go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /events", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "every event")
	})
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/problem+json")
		w.WriteHeader(http.StatusNotFound)
		fmt.Fprintln(w, `{"type":"about:blank","title":"Not Found","status":404}`)
	})
	log.Fatal(http.ListenAndServe("localhost:8080", mux))
}
```

```
ana@vm:~/catchall$ curl -s localhost:8080/events
every event
ana@vm:~/catchall$ curl -si localhost:8080/nothing
HTTP/1.1 404 Not Found
Content-Type: application/problem+json
Date: Fri, 16 Oct 2026 22:36:38 GMT
Content-Length: 56

{"type":"about:blank","title":"Not Found","status":404}
ana@vm:~/catchall$ curl -si -X DELETE localhost:8080/events
HTTP/1.1 404 Not Found
Content-Type: application/problem+json
Date: Fri, 16 Oct 2026 22:36:38 GMT
Content-Length: 56

{"type":"about:blank","title":"Not Found","status":404}
```

O caminho desconhecido recebeu o 404 em JSON, e o `DELETE /events` também, **que antes era um
405**. Com `/` registrado para todo método, o mux sempre encontra um padrão para `/events`, então
nunca chega ao ponto de dizer "o caminho existe, o método não", e o cabeçalho `Allow` vai junto. Um
cliente que mandou o método errado agora ouve que o recurso não existe, o que é falso.

O boxoffice mantém as respostas em texto do próprio mux para esses dois casos. **Um status correto
no formato errado é melhor que um status errado bem formatado**, e um cliente sempre consegue cair
no código de status quando o corpo não é JSON. A aula 5 conta este entre os lugares em que a
biblioteca padrão é mais magra que um framework.
