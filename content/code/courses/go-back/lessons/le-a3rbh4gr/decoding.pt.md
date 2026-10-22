---
title: Lendo JSON, e recusando o que não é
version: 1
---

Escrever JSON é a direção fácil, porque o servidor controla o valor. Ler é a outra: **o corpo vem de
um estranho, e pode estar vazio, quebrado, enorme, no formato errado ou tudo isso ao mesmo tempo.**
A linha única óbvia não lida bem com nada disso:

```go
json.NewDecoder(r.Body).Decode(&p)
```

Ela lê tudo o que o cliente mandar, sem limite. Ignora em silêncio os campos que não conhece, então
um cliente que escreve `quantiy` em vez de `quantity` recebe uma compra de zero ingressos e nenhuma
reclamação. Ela para depois do primeiro valor, então o que vier depois nunca é olhado. E os erros
que devolve são escritos para programadores Go, não para quem mandou a requisição. O boxoffice lê
todo corpo por uma função que fecha cada uma dessas portas:

```go
// boxoffice/decode.go
package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
)

// maxBody is the most a request body may hold: 1 MiB.
const maxBody = 1 << 20

// decodeJSON reads exactly one JSON object from the body into dst, and
// refuses everything else with an error a client can act on.
func decodeJSON(w http.ResponseWriter, r *http.Request, dst any) error {
	r.Body = http.MaxBytesReader(w, r.Body, maxBody)
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	if err := dec.Decode(dst); err != nil {
		var syntaxErr *json.SyntaxError
		var typeErr *json.UnmarshalTypeError
		var tooBig *http.MaxBytesError
		switch {
		case errors.Is(err, io.EOF):
			return errors.New("the body is empty")
		case errors.Is(err, io.ErrUnexpectedEOF):
			return errors.New("the body ends in the middle of a JSON value")
		case errors.As(err, &syntaxErr):
			return fmt.Errorf("the body is not valid JSON (at byte %d)", syntaxErr.Offset)
		case errors.As(err, &typeErr):
			return fmt.Errorf("the field %q has the wrong type: want %s", typeErr.Field, typeErr.Type)
		case errors.As(err, &tooBig):
			return fmt.Errorf("the body is larger than %d bytes", tooBig.Limit)
		case strings.HasPrefix(err.Error(), "json: unknown field "):
			return fmt.Errorf("the body has an unknown field %s",
				strings.TrimPrefix(err.Error(), "json: unknown field "))
		default:
			return err
		}
	}
	if err := dec.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return errors.New("the body must hold one JSON object and nothing after it")
	}
	return nil
}
```

Quatro linhas fazem a guarda antes de qualquer decodificação ou depois dela:

- **`http.MaxBytesReader`** envolve o corpo para que ler além de 1 MiB falhe, e manda o servidor
  fechar a conexão em vez de ler o resto. Uma compra tem menos de cem bytes; um megabyte é generoso
  e ainda assim tem limite.
- **`DisallowUnknownFields`** transforma um campo que a struct não tem num erro, em vez de algo
  descartado em silêncio.
- **O segundo `Decode`** tem de encontrar o fim da entrada. Qualquer outra coisa depois do objeto,
  até outro objeto válido, é recusada.
- O **`switch`** transforma cada tipo de falha numa frase que nomeia o problema nos termos do
  cliente. O caso de campo desconhecido lê o texto do erro porque o `encoding/json` informa esse
  como uma mensagem simples, sem tipo próprio para casar.

## Sete corpos, sete respostas

A seção 06 desta aula acrescenta a rota para a qual estes foram mandados, `POST /events/{id}/tickets`,
e a seção 05 o formato JSON dos erros; leia o `detail` de cada um. O `curl --json` manda o argumento
como corpo com `Content-Type: application/json`, e `-X POST` sem corpo não manda nada:

```
ana@vm:~/boxoffice$ curl -s -X POST localhost:8080/events/1/tickets
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the body is empty"}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2,}' localhost:8080/events/1/tickets
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the body is not valid JSON (at byte 16)"}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2' localhost:8080/events/1/tickets
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the body ends in the middle of a JSON value"}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": "two"}' localhost:8080/events/1/tickets
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the field \"quantity\" has the wrong type: want int"}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "seat": "A1"}' localhost:8080/events/1/tickets
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the body has an unknown field \"seat\""}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2}{"quantity": 9}' localhost:8080/events/1/tickets
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the body must hold one JSON object and nothing after it"}
ana@vm:~/boxoffice$ python3 -c 'print("{\"email\": \"" + "a" * 2000000 + "\"}")' | curl -s --json @- localhost:8080/events/1/tickets
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the body is larger than 1048576 bytes"}
```

Na ordem: **nada, uma vírgula sobrando, uma chave faltando, uma string onde vai um número, um campo
que não existe, dois objetos, e dois milhões de caracteres.** Cada resposta é um 400, porque cada
uma é uma requisição que o servidor nem consegue ler, e cada uma diz qual delas foi. O deslocamento
em bytes da segunda aponta o `}` depois da vírgula. A última foi recusada no megabyte sem ler o
resto, e o log do servidor, mostrado na seção 07, a registra levando 4.845 ms contra dezenas de
microssegundos das outras: o custo é ler um megabyte.

**Nenhuma delas chegou ao store.** Todas falharam antes de rodar uma única linha da lógica do
próprio boxoffice, que é exatamente onde uma requisição malformada deve parar.

## Uma palavra sobre o `Content-Type`

O boxoffice não recusa um corpo porque o `Content-Type` dele não é `application/json`. Algumas APIs
recusam, respondendo `415 Unsupported Media Type`, e é uma regra defensável: ela impede que um
formulário HTML postado de outro site seja lido como JSON. A proteção do boxoffice contra isso é a
da aula 2: as rotas que mudam algo para a equipe exigem um bearer token, que um formulário não
consegue mandar.
