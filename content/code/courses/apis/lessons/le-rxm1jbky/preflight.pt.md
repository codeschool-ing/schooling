---
title: O preflight
version: 1
---

**Para uma requisição que nenhum formulário poderia mandar, o navegador pede licença antes.** Ele
manda uma requisição `OPTIONS` ao mesmo endereço, descrevendo a requisição que quer fazer, e só a
manda se a resposta permitir. A pergunta se chama preflight, e o script nunca a vê: o `fetch` volta
uma vez só, com o resultado da requisição de verdade ou com a recusa.

O botão "Set the stock to 11" da página é esse tipo de requisição duas vezes: o método é PATCH, e o
corpo é `application/json`. Esta é a pergunta que o navegador faz para ele, mandada à mão a partir da
origem que está na lista:

```
ana@api:~/shelf$ curl -si -X OPTIONS localhost:8000/v1/books/1 -H 'Origin: http://localhost:8080' -H 'Access-Control-Request-Method: PATCH' -H 'Access-Control-Request-Headers: content-type'
HTTP/1.1 204 No Content
Server: shelf
Date: Sat, 10 Oct 2026 04:23:17 GMT
Content-Length: 0
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer
Cache-Control: no-store
Access-Control-Allow-Origin: http://localhost:8080
Vary: Origin
Allow: GET, PATCH, OPTIONS
Access-Control-Allow-Methods: GET, PATCH
Access-Control-Allow-Headers: Content-Type
Access-Control-Max-Age: 600
```

A requisição leva três cabeçalhos, e a resposta traz quatro que correspondem a eles:

| o navegador pergunta | o servidor responde |
|---|---|
| `Origin`: qual página está perguntando | `Access-Control-Allow-Origin`: a origem que pode seguir em frente |
| `Access-Control-Request-Method`: o método que ela quer usar | `Access-Control-Allow-Methods`: os métodos permitidos |
| `Access-Control-Request-Headers`: os cabeçalhos que o script definiu | `Access-Control-Allow-Headers`: os cabeçalhos permitidos |
| | `Access-Control-Max-Age`: por quantos segundos o navegador pode lembrar esta resposta |

**`Access-Control-Max-Age: 600` economiza uma ida e volta.** Por dez minutos, um PATCH daquela página
para aquele endereço sai sem pergunta na frente. Os navegadores limitam o número a um teto próprio,
então um dia pedido nem sempre é um dia concedido, e sem o cabeçalho a resposta é lembrada por poucos
segundos.

A mesma pergunta vinda da origem que não está na lista também recebe resposta, um 204 com `Allow` para
qualquer cliente que queira saber os métodos, e nada que diga que a página pode seguir:

```
ana@api:~/shelf$ curl -si -X OPTIONS localhost:8000/v1/books/1 -H 'Origin: http://127.0.0.1:8080' -H 'Access-Control-Request-Method: PATCH' -H 'Access-Control-Request-Headers: content-type' | grep -iE '^(HTTP|allow|access-control|vary)'
HTTP/1.1 204 No Content
Vary: Origin
Allow: GET, PATCH, OPTIONS
```

## O que o navegador fez com cada resposta

Carregada de `localhost:8080`, o segundo botão imprimiu:

```
PATCH 200 {"id": 1, "title": "Dom Casmurro", "stock": 11}
```

Carregada de `127.0.0.1:8080`, imprimiu:

```
Access to fetch at 'http://127.0.0.1:8000/v1/books/1' from origin 'http://127.0.0.1:8080' has been blocked by CORS policy: Response to preflight request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource.
Failed to load resource: net::ERR_FAILED
PATCH failed: TypeError: Failed to fetch
```

A segunda mensagem é diferente da do GET. Ela diz que o **preflight** não passou, e o terminal do
servidor diz o que isso significou. Estas são as cinco linhas que as duas páginas causaram, as três
primeiras da página que está na lista e as duas últimas da que não está:

```
127.0.0.1 - - [10/Oct/2026 01:23:15] "GET /v1/books/1 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:23:15] "OPTIONS /v1/books/1 HTTP/1.1" 204 -
127.0.0.1 - - [10/Oct/2026 01:23:15] "PATCH /v1/books/1 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:23:16] "GET /v1/books/1 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:23:17] "OPTIONS /v1/books/1 HTTP/1.1" 204 -
```

Da página da lista: OPTIONS, depois o PATCH. Da outra: o GET que foi respondido e jogado fora, como a
seção anterior mostrou, depois o OPTIONS, e **nenhum PATCH**. O estoque nunca mudou, porque a
requisição que o mudaria nunca saiu do navegador.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Duas sequências lado a lado. À esquerda, uma página da lista de permissões: o navegador envia OPTIONS, a API responde 204 nomeando a origem, o navegador envia o PATCH, a API responde 200 e o script lê a resposta. À direita, uma página fora da lista: o mesmo OPTIONS recebe um 204 sem Allow-Origin, o PATCH nunca é enviado e o script recebe um TypeError.\"><defs><marker id=\"l13-cors-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"5\" y=\"8\" width=\"340\" height=\"314\" rx=\"8\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"175\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">página em localhost:8080, na lista</text><rect x=\"25\" y=\"42\" width=\"90\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"70.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">navegador</text><rect x=\"245\" y=\"42\" width=\"90\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API</text><line x1=\"70\" y1=\"70\" x2=\"70\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"290\" y1=\"70\" x2=\"290\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"72\" y1=\"104\" x2=\"288\" y2=\"104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-cors-ah)\"></line><text x=\"180.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">OPTIONS /v1/books/1</text><text x=\"180\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Request-Method: PATCH</text><line x1=\"288\" y1=\"152\" x2=\"72\" y2=\"152\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-cors-ah)\"></line><text x=\"180.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">204</text><text x=\"180\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">Allow-Origin: localhost:8080</text><line x1=\"72\" y1=\"200\" x2=\"288\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-cors-ah)\"></line><text x=\"180.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">PATCH {&quot;stock&quot;: 11}</text><line x1=\"288\" y1=\"238\" x2=\"72\" y2=\"238\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-cors-ah)\"></line><text x=\"180.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">200 {&quot;stock&quot;: 11}</text><text x=\"175\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o script lê a resposta</text><rect x=\"375\" y=\"8\" width=\"340\" height=\"314\" rx=\"8\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">página em 127.0.0.1:8080, fora da lista</text><rect x=\"395\" y=\"42\" width=\"90\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">navegador</text><rect x=\"615\" y=\"42\" width=\"90\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"660.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API</text><line x1=\"440\" y1=\"70\" x2=\"440\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"660\" y1=\"70\" x2=\"660\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"442\" y1=\"104\" x2=\"658\" y2=\"104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-cors-ah)\"></line><text x=\"550.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">OPTIONS /v1/books/1</text><text x=\"550\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Request-Method: PATCH</text><line x1=\"658\" y1=\"152\" x2=\"442\" y2=\"152\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-cors-ah)\"></line><text x=\"550.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">204</text><text x=\"550\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">sem Allow-Origin</text><line x1=\"442\" y1=\"200\" x2=\"510\" y2=\"200\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"504\" y1=\"194\" x2=\"516\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><line x1=\"504\" y1=\"206\" x2=\"516\" y2=\"194\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"528\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">PATCH nunca enviado</text><text x=\"550\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o servidor nunca fica sabendo</text><text x=\"545\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o script recebe TypeError</text></svg>", "caption": "O mesmo PATCH vindo de duas páginas. O preflight é respondido nas duas vezes; só a página cuja origem a resposta nomeia tem o PATCH enviado.", "same": ["API"]}
```

Essa é a diferença entre os dois tipos de requisição. Uma requisição simples é enviada e a
resposta dela é retida; uma com preflight não é enviada a não ser que o servidor concorde. Quando o
servidor concorda, a requisição de verdade leva `Origin` de novo, e a resposta dela precisa nomear a
origem de novo:

```
ana@api:~/shelf$ curl -si -X PATCH localhost:8000/v1/books/1 -H 'Origin: http://localhost:8080' -H 'Content-Type: application/json' -d '{"stock": 12}' | grep -iE '^(HTTP|access-control|vary)|stock'
HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://localhost:8080
Vary: Origin
{"id": 1, "title": "Dom Casmurro", "stock": 12}
```

## Duas coisas que a lição 1 deixou para trás

O `rest.py` da lição 1 respondia `OPTIONS` com **501** e uma página HTML, porque não define esse
método. O navegador trata um preflight respondido com qualquer coisa que não seja 2xx como recusa,
então nenhuma página jamais conseguiria mandar um PATCH ao `rest.py`, por mais cabeçalhos que ele
ganhasse depois. O `secure.py` responde **204**, com `Allow` para qualquer cliente e os cabeçalhos de
CORS para uma página da lista.

A segunda é o cabeçalho que a lição 7 acrescenta a toda requisição: `Authorization`. Ele não está na
lista segura do navegador, então uma página que manda um token dispara um preflight, e o servidor
precisa nomeá-lo em `Access-Control-Allow-Headers` ao lado de `Content-Type`. Esqueça-o e toda chamada
autenticada da página falha na pergunta, enquanto o curl funciona perfeitamente.
