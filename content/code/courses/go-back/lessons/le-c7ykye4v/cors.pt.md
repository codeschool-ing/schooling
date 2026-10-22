---
title: CORS, do lado do servidor
version: 1
---

Primeiro a imagem errada, porque quase todo mundo começa com ela: **CORS não é uma tranca no
servidor.** Ele não decide quem pode chamar o boxoffice. O `curl`, um script, outro servidor: todos
eles conseguem chamar qualquer rota de qualquer servidor, e nenhum cabeçalho que o boxoffice mande
vai impedi-los.

O que o CORS governa é um cliente em particular, o **navegador**, e uma situação em particular: uma
página carregada de uma origem rodando JavaScript que chama um servidor de outra. Uma origem é o
esquema, o host e a porta juntos, então `https://tickets.example.com` e `http://localhost:8080` são
duas. **Por padrão o navegador manda essa requisição e depois se recusa a deixar a página ler a
resposta.** Essa regra, a política de mesma origem, é o que impede uma página que você por acaso
visita de ler o seu webmail com os seus cookies. O CORS é como um servidor diz ao navegador para
abrir uma exceção para páginas das origens que ele nomeia.

Então a pergunta que o middleware responde é estreita: **quais páginas web podem ler as respostas
do boxoffice?** A bilheteria vende pelo próprio site, `https://tickets.example.com`, e por nenhum
outro.

```go
// boxoffice/cors.go
package main

import (
	"net/http"
	"slices"
)

// cors lets pages served from the allowed origins read boxoffice's answers.
func cors(allowed ...string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Add("Vary", "Origin")
			origin := r.Header.Get("Origin")
			if origin == "" || !slices.Contains(allowed, origin) {
				next.ServeHTTP(w, r)
				return
			}
			w.Header().Set("Access-Control-Allow-Origin", origin)
			if r.Method == http.MethodOptions && r.Header.Get("Access-Control-Request-Method") != "" {
				w.Header().Set("Access-Control-Allow-Methods", "GET, POST, DELETE")
				w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")
				w.Header().Set("Access-Control-Max-Age", "600")
				w.WriteHeader(http.StatusNoContent)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}
```

## Uma origem que ele conhece, e uma que não

```
ana@vm:~/boxoffice$ curl -si -H 'Origin: https://tickets.example.com' localhost:8080/events/1
HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://tickets.example.com
Vary: Origin
Date: Fri, 16 Oct 2026 22:29:24 GMT
Content-Length: 41
Content-Type: text/plain; charset=utf-8

Jazz at the Docks: 120 of 120 seats left
ana@vm:~/boxoffice$ curl -si -H 'Origin: https://elsewhere.example.net' localhost:8080/events/1
HTTP/1.1 200 OK
Vary: Origin
Date: Fri, 16 Oct 2026 22:29:24 GMT
Content-Length: 41
Content-Type: text/plain; charset=utf-8

Jazz at the Docks: 120 of 120 seats left
```

O navegador acrescenta `Origin` sozinho a uma requisição de outra origem; aqui o `-H` faz o papel
do navegador. Para o site de ingressos, o boxoffice respondeu com `Access-Control-Allow-Origin`
devolvendo o nome, e o navegador entregaria o corpo à página. Para a outra origem não há esse
cabeçalho, e o navegador esconderia o corpo da página.

**Olhe de novo a segunda resposta: 200, e o corpo inteiro.** O servidor fez todo o trabalho e
mandou os dados; só a recusa do navegador os mantém longe daquela página. É exatamente por isso que
o CORS não protege nada privado. O que um estranho não pode ler precisa de autenticação, que é a
seção 06, e não de um cabeçalho ausente.

`Vary: Origin` vai em toda resposta, permitida ou não. **A resposta agora depende de um cabeçalho
da requisição**, e um cache entre os dois, uma CDN ou o do próprio navegador, tem de saber disso,
senão ele entrega a cópia que guardou para uma origem a uma página de outra.

## O preflight

Uma requisição que o navegador considera arriscada é consultada antes. Qualquer método além de
`GET`, `HEAD` ou `POST`, qualquer cabeçalho fora de uma lista curta, ou um corpo do tipo JSON fazem
o navegador mandar uma requisição `OPTIONS` antes da verdadeira, nomeando o método e os cabeçalhos
que pretende usar. Uma requisição levando um token da equipe em `Authorization` é uma delas:

```
ana@vm:~/boxoffice$ curl -si -X OPTIONS -H 'Origin: https://tickets.example.com' -H 'Access-Control-Request-Method: GET' -H 'Access-Control-Request-Headers: authorization' localhost:8080/admin/report
HTTP/1.1 204 No Content
Access-Control-Allow-Headers: Authorization, Content-Type
Access-Control-Allow-Methods: GET, POST, DELETE
Access-Control-Allow-Origin: https://tickets.example.com
Access-Control-Max-Age: 600
Vary: Origin
Date: Fri, 16 Oct 2026 22:29:24 GMT
```

**204 com as permissões, e sem corpo.** O navegador compara o método e os cabeçalhos que quer com
as listas e, se couberem, manda a requisição verdadeira. `Access-Control-Max-Age: 600` deixa ele
lembrar a resposta por dez minutos em vez de perguntar antes de toda chamada.

Duas coisas sobre onde isso fica. **O preflight não leva token**, pelas regras que os navegadores
seguem, então ele tem de ser respondido antes da autenticação, e é por isso que o `cors` fica fora
do `requireStaff` na seção 07. E o middleware responde ao preflight ele mesmo e não chama `next`,
porque nenhum handler do boxoffice tem o que dizer a uma requisição `OPTIONS`.

## O erro a evitar

O atalho tentador é copiar qualquer `Origin` que chegue para o `Access-Control-Allow-Origin`, ou
mandar `*`. Para uma API pública sem nada privado, `*` é honesto. **Para qualquer coisa que use
cookies, combinar uma origem refletida com `Access-Control-Allow-Credentials: true` deixa toda
página da internet ler a resposta com os cookies do visitante anexados.** O boxoffice não usa
cookies e nomeia uma origem, e uma lista de nomes é o padrão seguro para todo o resto.
