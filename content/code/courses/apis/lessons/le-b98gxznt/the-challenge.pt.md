---
title: O 401 e o desafio dele
version: 1
---

**O HTTP já traz uma conversa para credenciais, e ela começa com o servidor recusando.** Uma requisição
sem credencial recebe **401 Unauthorized**, e o 401 leva um cabeçalho `WWW-Authenticate` para cada
esquema que o servidor aceitaria. O cliente escolhe um e pergunta de novo, com um cabeçalho
`Authorization`. Peça os livros ao `keys.py` sem nada junto:

```
ana@api:~/shelf$ curl -si localhost:8000/v1/books
HTTP/1.1 401 Unauthorized
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:26:05 GMT
Content-Type: application/json
Content-Length: 37
WWW-Authenticate: Basic realm="shelf"
WWW-Authenticate: Bearer realm="shelf"

{"error": "authentication required"}
```

As duas linhas `WWW-Authenticate` são o **desafio** (*challenge*). Cada uma começa com um esquema,
`Basic` ou `Bearer`, e leva parâmetros depois dele; `realm="shelf"` dá nome à área protegida, para que
um cliente com credenciais de várias áreas no mesmo host saiba qual enviar. Um 401 sem esse cabeçalho
quebra o contrato: o status diz "autentique-se" e nada diz como.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Duas linhas de vida, o curl à esquerda e o keys.py à direita. Primeiro o curl envia GET /v1/books sem credencial. O keys.py responde 401 Unauthorized com dois cabeçalhos WWW-Authenticate, Basic realm=&quot;shelf&quot; e Bearer realm=&quot;shelf&quot;. O curl envia a mesma requisição de novo com Authorization: Basic e o nome e a senha codificados. O keys.py responde 200 OK com os livros.\"><defs><marker id=\"l07-ch-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"15\" width=\"120\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">curl</text><rect x=\"540\" y=\"15\" width=\"120\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">keys.py</text><line x1=\"100\" y1=\"49\" x2=\"100\" y2=\"290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"600\" y1=\"49\" x2=\"600\" y2=\"290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"100\" y1=\"80\" x2=\"598\" y2=\"80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l07-ch-ah)\"></line><text x=\"350\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /v1/books</text><text x=\"115\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1  sem credencial</text><line x1=\"600\" y1=\"130\" x2=\"102\" y2=\"130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l07-ch-ah)\"></line><text x=\"350\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">401 Unauthorized</text><text x=\"350\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">WWW-Authenticate: Basic realm=&quot;shelf&quot;</text><text x=\"350\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">WWW-Authenticate: Bearer realm=&quot;shelf&quot;</text><text x=\"585\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2  o desafio: quais esquemas</text><line x1=\"100\" y1=\"210\" x2=\"598\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l07-ch-ah)\"></line><text x=\"350\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /v1/books</text><text x=\"350\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Authorization: Basic YW5hOnJpdmVyLWxhbXAtNDI=</text><text x=\"115\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3  a resposta ao desafio</text><line x1=\"600\" y1=\"260\" x2=\"102\" y2=\"260\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l07-ch-ah)\"></line><text x=\"350\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">200 OK</text><text x=\"350\" y=\"275\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">os livros</text></svg>", "caption": "Um 401 não é só uma recusa: os cabeçalhos WWW-Authenticate dizem quais esquemas seriam aceitos, e a próxima requisição responde com um deles."}
```

A resposta ao desafio tem a mesma forma, no sentido contrário. **O `Authorization` leva um esquema, um
espaço e as credenciais**, e o `curl -u` monta o do Basic para você:

```
ana@api:~/shelf$ curl -si -u ana:river-lamp-42 localhost:8000/v1/whoami
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:26:05 GMT
Content-Type: application/json
Content-Length: 34

{"kind": "person", "name": "ana"}
```

O `/v1/whoami` existe para você perguntar ao servidor o que ele concluiu. Ele conhece uma pessoa chamada
`ana`, e a seção sobre o Basic mostra o cabeçalho que disse isso a ele.

## 401 ou 403

O nome é um acidente histórico. **401 quer dizer não autenticado**: não veio credencial, ou a que veio
não provou nada. Mandar uma válida pode mudar a resposta. **403 Forbidden quer dizer não autorizado**:
o servidor sabe quem você é e a resposta continua sendo não, então mandar a mesma credencial de novo
não adianta. Um cliente que recebe 401 deve entrar de novo ou perguntar ao usuário; um cliente que
recebe 403 deve parar e mostrar a recusa.

Trocar os dois custa caro nos dois sentidos. Um 403 para um token ausente manda o cliente desistir de
uma requisição que funcionaria depois de um login. Um 401 para uma ação proibida põe o cliente num laço
de login do qual ele não sai: entra, pede, recebe 401, entra de novo.

Um tipo de credencial não tem esquema próprio. O `keys.py` recebe chaves de API num cabeçalho
`X-API-Key`, e não em `Authorization`, como muitas APIs fazem, e não existe desafio padrão para esse
cabeçalho, e é por isso que o 401 acima não fala dele. O cliente descobre que a API aceita chaves pela
documentação, e o arquivo OpenAPI da lição 6 tem lugar para dizer isso: `securitySchemes` com `type:
apiKey`, `in: header` e o nome do cabeçalho.
