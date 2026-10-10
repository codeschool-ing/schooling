---
title: Escopos, e o que um token pode fazer
version: 1
---

**Um token não precisa carregar tudo o que o dono dele pode fazer.** Quando a Ana deixa um
aplicativo mostrar os pedidos dela no celular, o aplicativo precisa lê-los e nada mais. Se o token
que ela dá a ele também pudesse fazer pedidos, um bug no aplicativo, ou o token vazando dele, gastaria
o dinheiro dela. Então o token carrega **escopos**, uma lista do que ele pode ser usado para fazer,
e a API checa os escopos além da pessoa.

A palavra vem do OAuth, que a aula 9 desenha por inteiro: o aplicativo pede escopos, a Ana aprova,
e o token que o aplicativo recebe lista esses escopos. Esta seção trata do que a API faz com essa
lista quando chega uma requisição.

**A permissão efetiva é a interseção.** Uma requisição pode fazer o que a pessoa pode E o que o
token recebeu, e o `caller` calcula exatamente isso com o operador de conjuntos do Python:
`ROLES.get(role, set()) & scopes`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 280\" role=\"img\" aria-label=\"Dois tokens e as permissões com que cada um termina. O papel da Ana concede orders:read, orders:create e orders:cancel; o token que ela deu a um aplicativo carrega só orders:read, então o aplicativo só pode ler. O papel do Bruno concede os mesmos três; o token dele carrega esses três e orders:refund, e como o papel dele não tem orders:refund, o conjunto efetivo são os três que o papel concede.\"><text x=\"280\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">demo-ana-app: a Ana, por um aplicativo</text><text x=\"550\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">demo-bruno: o Bruno, pedindo mais</text><text x=\"210\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">papel</text><text x=\"280\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">token</text><text x=\"350\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">efetiva</text><text x=\"480\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">papel</text><text x=\"550\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">token</text><text x=\"620\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">efetiva</text><text x=\"20\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders:read</text><line x1=\"20\" y1=\"111\" x2=\"680\" y2=\"111\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"203\" y=\"85\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"273\" y=\"85\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"343\" y=\"85\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"473\" y=\"85\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"543\" y=\"85\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"613\" y=\"85\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders:create</text><line x1=\"20\" y1=\"149\" x2=\"680\" y2=\"149\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"203\" y=\"123\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"273\" y=\"123\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"343\" y=\"123\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"473\" y=\"123\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"543\" y=\"123\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"613\" y=\"123\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders:cancel</text><line x1=\"20\" y1=\"187\" x2=\"680\" y2=\"187\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"203\" y=\"161\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"273\" y=\"161\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"343\" y=\"161\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"473\" y=\"161\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"543\" y=\"161\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"613\" y=\"161\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders:refund</text><line x1=\"20\" y1=\"225\" x2=\"680\" y2=\"225\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"203\" y=\"199\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"273\" y=\"199\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"343\" y=\"199\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"473\" y=\"199\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"543\" y=\"199\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><rect x=\"613\" y=\"199\" width=\"14\" height=\"14\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><line x1=\"415\" y1=\"40\" x2=\"415\" y2=\"240\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"350\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um escopo que o papel não tem não acrescenta nada; um escopo omitido tira alguma coisa</text></svg>", "caption": "O que uma requisição pode fazer é o que a pessoa pode E o que o token recebeu: uma interseção.", "same": ["token"]}
```

O token do aplicativo da Ana lê os pedidos dela como a Ana lê, incluindo o pedido 5, feito na seção
anterior:

```
ana@api:~/shelf$ curl -s -H 'Authorization: Bearer demo-ana-app' localhost:8000/orders | jq -c '.[] | {id, status}'
{"id":1,"status":"cancelled"}
{"id":2,"status":"shipped"}
{"id":5,"status":"placed"}
```

E é recusado quando tenta fazer um:

```
ana@api:~/shelf$ curl -si -X POST -H 'Authorization: Bearer demo-ana-app' -H 'Content-Type: application/json' -d '{"book_id": 1, "quantity": 1}' localhost:8000/orders
HTTP/1.1 403 Forbidden
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:27:57 GMT
Content-Type: application/json
Content-Length: 52
WWW-Authenticate: Bearer error="insufficient_scope", scope="orders:create"

{"error": "this token's scope lacks orders:create"}
```

O 403 diz qual metade recusou. O papel da Ana tem `orders:create`, então é o token que não tem, e a
API responde do jeito que a RFC 6750, o padrão dos bearer tokens, descreve: `WWW-Authenticate` com
`error="insufficient_scope"` e o escopo que era necessário. Um cliente pode ler isso e pedir à Ana
um token com mais, que é uma conversa diferente de dizer a ela que não pode.

A metade direita da figura é o token do Bruno, que alega `orders:refund`. "Funções que só alguns
podem chamar" já mostrou o estorno dele recusado com `the role customer lacks orders:refund`. **Um
token pode estreitar o que o dono dele pode fazer e nunca alargar.** Uma API que lesse só a lista de
escopos, sem o papel, deixaria qualquer um estornar qualquer pedido no dia em que conseguisse um
token emitido com a palavra certa dentro.
