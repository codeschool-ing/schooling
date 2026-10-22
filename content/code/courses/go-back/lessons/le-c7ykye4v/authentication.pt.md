---
title: Autenticação, e quem é a requisição
version: 1
---

Duas perguntas parecem iguais e têm respostas diferentes. **Autenticação pergunta quem está
chamando. Autorização pergunta se quem chama tem permissão para isto.** O HTTP dá a cada uma o seu
status: `401 Unauthorized`, apesar do nome, quer dizer "não sei quem você é", e `403 Forbidden`
quer dizer "sei quem você é, e não". O boxoffice precisa dos dois. Qualquer um lista eventos, a
equipe chama as rotas `/admin/`, e só um gerente lê o relatório de vendas.

## Um token num cabeçalho

O esquema mais simples que não é uma senha digitada a cada requisição é um **bearer token**: uma
string aleatória longa que o servidor conhece, que o cliente manda como `Authorization: Bearer
<token>`. Quem o porta entra, e esse é o significado inteiro do nome e toda a sua fraqueza. Um token
tem de ser longo o bastante para adivinhar ser inútil, mandado só por HTTPS fora de um notebook, e
mantido fora de logs e repositórios.

`openssl rand -hex 16` imprime dezesseis bytes aleatórios em hexadecimal, 128 bits, o que é longo o
bastante. O boxoffice lê dois deles do ambiente, um por papel:

```
ana@vm:~/boxoffice$ export BOXOFFICE_MANAGER_TOKEN=$(openssl rand -hex 16)
ana@vm:~/boxoffice$ export BOXOFFICE_DOOR_TOKEN=$(openssl rand -hex 16)
ana@vm:~/boxoffice$ echo $BOXOFFICE_MANAGER_TOKEN $BOXOFFICE_DOOR_TOKEN
5ca82ad2121fe5f238c90ab37b7106cd 9c101e9b24e371302e323f6964aee17c
```

**Os seus dois valores vão ser outros**; eles são aleatórios. A aula 14 dá à configuração um lugar
próprio, e até lá uma variável de ambiente mantém o segredo fora do código-fonte e fora da linha de
comando, onde o `ps` o mostraria a todo usuário da máquina.

```go
// boxoffice/auth.go
package main

import (
	"context"
	"crypto/subtle"
	"net/http"
	"strings"
)

type roleKey struct{}

// requireStaff lets a request through only if it carries one of the tokens,
// and puts the role that token belongs to into the request's context.
func requireStaff(tokens map[string]string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			role := ""
			if got, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer "); ok {
				for token, owner := range tokens {
					if subtle.ConstantTimeCompare([]byte(got), []byte(token)) == 1 {
						role = owner
					}
				}
			}
			if role == "" {
				w.Header().Set("WWW-Authenticate", `Bearer realm="boxoffice"`)
				http.Error(w, "a staff token is required", http.StatusUnauthorized)
				return
			}
			ctx := context.WithValue(r.Context(), roleKey{}, role)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// staffRole is the role requireStaff found, or "" outside it.
func staffRole(ctx context.Context) string {
	role, _ := ctx.Value(roleKey{}).(string)
	return role
}
```

O middleware recebe o mapa de token para papel e, a cada requisição:

- corta `Bearer ` do começo do cabeçalho, e desiste se não estiver lá;
- compara o que sobra com **todos** os tokens, usando `subtle.ConstantTimeCompare`;
- recusa com 401 e um cabeçalho `WWW-Authenticate` nomeando o esquema quando nada casou;
- senão, põe o papel no contexto da requisição e chama `next` com essa requisição.

**Por que não `==`.** Comparar duas strings com `==` para no primeiro byte diferente, então um token
errado que começa com os caracteres certos leva um pouco mais para ser recusado do que um que não
começa. Medida vezes suficientes pela rede, essa diferença serve para adivinhar um token um
caractere por vez. O `ConstantTimeCompare` leva o mesmo tempo qualquer que seja o casamento, e o
laço também não para num casamento, então o tempo não diz nada sobre qual token era.

**Por que o contexto.** O handler atrás do middleware precisa saber o papel, e a assinatura dele não
tem espaço para isso. A aula 10 do `go-concurrency` apontou valores com escopo de requisição como a
única coisa para a qual o `context.WithValue` serve, e este é um. A chave é `roleKey{}`, um tipo não
exportado do próprio pacote, para nenhum outro pacote ler ou sobrescrever o valor por acidente. O
`staffRole` é o único jeito de chegar a ele, e responde `""` quando o middleware não estava no
caminho.

O handler que o usa:

```go
// boxoffice/admin.go
package main

import (
	"fmt"
	"net/http"
)

func salesReport(store *memStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if staffRole(r.Context()) != "manager" {
			http.Error(w, "only a manager may read the sales report", http.StatusForbidden)
			return
		}
		for _, e := range store.List() {
			fmt.Fprintf(w, "%d\t%s\t%d sold\n", e.ID, e.Name, e.Sold)
		}
	}
}
```

## Todas as respostas que ele dá

```
ana@vm:~/boxoffice$ curl -si localhost:8080/admin/report
HTTP/1.1 401 Unauthorized
Content-Type: text/plain; charset=utf-8
Vary: Origin
Www-Authenticate: Bearer realm="boxoffice"
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:29:24 GMT
Content-Length: 26

a staff token is required
ana@vm:~/boxoffice$ curl -s -H 'Authorization: Bearer 0123456789abcdef' localhost:8080/admin/report
a staff token is required
ana@vm:~/boxoffice$ curl -si -H "Authorization: Bearer $BOXOFFICE_DOOR_TOKEN" localhost:8080/admin/report
HTTP/1.1 403 Forbidden
Content-Type: text/plain; charset=utf-8
Vary: Origin
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:29:24 GMT
Content-Length: 41

only a manager may read the sales report
ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" localhost:8080/admin/report
1	Jazz at the Docks	0 sold
2	Chamber Choir	80 sold
```

Sem cabeçalho: 401, com `WWW-Authenticate` dizendo ao cliente qual esquema usar. Um token
inventado: o mesmo 401, sem pista de que estava quase certo. **O token da portaria é verdadeiro**,
então quem chama é conhecido, e a resposta é 403, do handler. O token do gerente recebe o relatório.

## O que isto não é

Bearer tokens em variáveis de ambiente servem para um serviço chamado por um punhado de ferramentas
da equipe. Eles não expiram, não há como revogar o acesso de uma pessoa sem trocar o de todo mundo,
e não há tela de login. **Contas de usuário de verdade são outro projeto**: senhas guardadas como
hashes lentos, sessões ou tokens assinados de vida curta, e muitas vezes um provedor de identidade
falando OpenID Connect. Qualquer que seja o projeto, a verificação cai exatamente neste lugar, um
middleware que decide quem é a requisição e repassa isso no contexto, e os handlers atrás dele não
mudam.
