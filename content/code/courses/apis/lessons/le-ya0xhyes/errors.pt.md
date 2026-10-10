---
title: Erros que um programa consegue ler
version: 1
---

**Um corpo de erro é lido primeiro por um programa e só depois por uma pessoa.** O código de status
diz que classe de coisa deu errado; o corpo precisa dizer exatamente o quê, numa forma em que o
cliente consiga decidir sem interpretar uma frase. A RFC 9457, *Problem Details for HTTP APIs*, é o
formato padrão para esse corpo, e todo erro que o `catalogue.py` escreve segue esse formato.

O corpo de erro comum é uma mensagem para um humano. O `rest.py` da lição 1, ao receber um livro com
título vazio, ano como texto, preço como float e sem ISBN nem autor:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"title": "", "year": "1891", "price_cents": 39.90}'
{"error": "wrong type for: price_cents, year"}
422
```

Não há nada ali que um programa possa usar a não ser comparando texto em inglês, e o texto é livre
para mudar na próxima versão. Também está incompleto: aponta dois tipos errados e não diz nada sobre
os dois campos ausentes nem sobre o título vazio, que o cliente descobre uma requisição por vez.

## O objeto de problem details

O mesmo corpo, enviado ao `catalogue.py`:

```
ana@api:~/shelf$ curl -s -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"title": "", "year": "1891", "price_cents": 39.90}' | jq .
{
  "type": "https://shelf.example/problems/invalid-book",
  "title": "The book breaks the contract",
  "status": 422,
  "detail": "every problem with the book is listed in errors",
  "instance": "/v1/books",
  "errors": [
    {
      "pointer": "#",
      "detail": "Additional properties are not allowed ('price_cents' was unexpected)"
    },
    {
      "pointer": "#",
      "detail": "'isbn' is a required property"
    },
    {
      "pointer": "#",
      "detail": "'author_id' is a required property"
    },
    {
      "pointer": "#",
      "detail": "'price' is a required property"
    },
    {
      "pointer": "#/title",
      "detail": "'' is too short"
    },
    {
      "pointer": "#/year",
      "detail": "'1891' is not of type 'integer'"
    }
  ]
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O corpo de problem details que o catalogue.py enviou para um livro inválido, um membro por linha, cada um com uma nota. type, status e os ponteiros de errors são para o programa cliente; title e detail são para uma pessoa; instance diz qual ocorrência foi.\"><defs><marker id=\"l02-pd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"400\" height=\"266\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"22.0\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{</text><text x=\"33.5\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;type&quot;: &quot;https://shelf.example/problems/invalid-book&quot;,</text><line x1=\"470\" y1=\"54\" x2=\"418\" y2=\"54\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l02-pd-ah)\"></line><text x=\"478\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">que tipo de problema: o cliente decide por isto</text><text x=\"33.5\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;title&quot;: &quot;The book breaks the contract&quot;,</text><line x1=\"470\" y1=\"76\" x2=\"418\" y2=\"76\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l02-pd-ah)\"></line><text x=\"478\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o tipo, em palavras, sempre o mesmo</text><text x=\"33.5\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;status&quot;: 422,</text><line x1=\"470\" y1=\"98\" x2=\"418\" y2=\"98\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l02-pd-ah)\"></line><text x=\"478\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o código de status de novo, para logs</text><text x=\"33.5\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;detail&quot;: &quot;every problem with the book is ...&quot;,</text><line x1=\"470\" y1=\"120\" x2=\"418\" y2=\"120\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l02-pd-ah)\"></line><text x=\"478\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">esta ocorrência, para uma pessoa</text><text x=\"33.5\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;instance&quot;: &quot;/v1/books&quot;,</text><line x1=\"470\" y1=\"142\" x2=\"418\" y2=\"142\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l02-pd-ah)\"></line><text x=\"478\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">qual ocorrência</text><text x=\"33.5\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;errors&quot;: [</text><line x1=\"470\" y1=\"164\" x2=\"418\" y2=\"164\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l02-pd-ah)\"></line><text x=\"478\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um membro de extensão</text><text x=\"45.0\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{&quot;pointer&quot;: &quot;#/year&quot;,</text><line x1=\"470\" y1=\"186\" x2=\"418\" y2=\"186\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l02-pd-ah)\"></line><text x=\"478\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">qual campo, como JSON Pointer</text><text x=\"50.75\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;detail&quot;: &quot;&#x27;1891&#x27; is not of type &#x27;integer&#x27;&quot;}</text><line x1=\"470\" y1=\"208\" x2=\"418\" y2=\"208\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l02-pd-ah)\"></line><text x=\"478\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o que está errado nele</text><text x=\"33.5\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">]</text><text x=\"22.0\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">}</text><rect x=\"430\" y=\"262\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"448\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lido pelo programa</text><rect x=\"580\" y=\"262\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"598\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lido por uma pessoa</text></svg>", "caption": "Um corpo de problem details tem uma parte para o programa e uma para a pessoa, e um cliente que decide pelo texto escolheu a parte errada."}
```

| membro | para que serve |
|---|---|
| `type` | uma URI que nomeia o tipo de problema. **É nele que o cliente se baseia para decidir.** Nunca muda para um dado tipo, e pode levar a uma página que o documenta |
| `title` | um resumo curto desse tipo, igual em toda ocorrência; para pessoas, não para código |
| `status` | o código de status HTTP de novo, para quando o corpo é registrado ou repassado sem os cabeçalhos |
| `detail` | esta ocorrência, explicada para uma pessoa |
| `instance` | qual ocorrência: aqui, o caminho que foi pedido. Um id que também aparece no log do servidor serve ao mesmo propósito |
| qualquer outro | membros de extensão. `errors`, uma entrada por falha com um JSON Pointer para o campo, é o que a própria RFC 9457 usa como exemplo |

O tipo de mídia é `application/problem+json`, então o cliente conhece o formato antes de ler um
byte. Um problema que não tem nada a dizer além do código de status usa o tipo `about:blank`, e o
título passa a ser o próprio nome do código de status:

```
ana@api:~/shelf$ curl -si localhost:8000/v1/books/99
HTTP/1.1 404 Not Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:29:42 GMT
Content-Type: application/problem+json
Content-Length: 122

{"type": "about:blank", "title": "Not Found", "status": 404, "detail": "there is no book 99", "instance": "/v1/books/99"}
```

## Um formato para todos os erros

**O cliente deveria precisar de um único leitor de erros**, então toda falha toma este formato,
inclusive as que não têm nada a ver com os campos do livro. Um livro cujo ISBN já existe, e um corpo
que nem JSON é:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000016", "title": "Dom Casmurro", "author_id": 1, "year": 1899, "price": {"amount_cents": 3990, "currency": "BRL"}}'
{"type": "https://shelf.example/problems/duplicate-isbn", "title": "ISBN already in the catalogue", "status": 409, "detail": "another book has ISBN 9786500000016", "instance": "/v1/books"}
409
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"title": '
{"type": "https://shelf.example/problems/malformed-json", "title": "The body is not JSON", "status": 400, "detail": "Expecting value: line 1 column 11 (char 10)", "instance": "/v1/books"}
400
```

O 409 diz qual ISBN já existe e nada sobre como o banco descobriu. O 409 da lição 1 repassava ao
cliente a própria mensagem do SQLite, com o nome da tabela e da coluna; isso é um detalhe interno, e
a próxima mudança no banco muda a mensagem. O 400 repassa, sim, a mensagem do parser, porque a linha
e a coluna de um erro de sintaxe são exatamente o que o cliente precisa.

A última reclamação da lição 1 foi a página HTML que a biblioteca do Python mandou para um método que
ninguém tinha escrito. O `catalogue.py` responde a esses métodos ele mesmo, com um 405, um cabeçalho
`Allow` e um problema:

```
ana@api:~/shelf$ curl -si -X DELETE localhost:8000/v1/books/1
HTTP/1.1 405 Method Not Allowed
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:29:42 GMT
Content-Type: application/problem+json
Content-Length: 145
Allow: GET, POST

{"type": "about:blank", "title": "Method Not Allowed", "status": 405, "detail": "the catalogue does not take DELETE", "instance": "/v1/books/1"}
```
