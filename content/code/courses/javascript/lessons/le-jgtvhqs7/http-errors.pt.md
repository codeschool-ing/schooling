---
title: Um 404 não é falha, para o fetch
version: 1
---

O fato mais importante sobre o `fetch` é o que ele **não** trata como erro:

```html
<!doctype html>
<script type="module">
  for (const path of ["/api/books/2", "/api/books/9", "/api/broken"]) {
    try {
      const response = await fetch(path);
      const body = await response.json();
      console.log(path, "resolved:", response.status, response.ok, JSON.stringify(body));
    } catch (err) {
      console.log(path, "rejected:", err.name);
    }
  }
</script>
```

```
ana@dev:~/js$ page status.html
/api/books/2 resolved: 200 true {"id":2,"title":"Grande Sertão: Veredas","author":"João Guimarães Rosa","year":1956}
[error] Failed to load resource: the server responded with a status of 404 (Not Found)
/api/books/9 resolved: 404 false {"error":"no book 9"}
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
/api/broken resolved: 500 false {"error":"the database is not answering"}
```

Três requisições: um livro que existe, um livro que não existe, e um endpoint cujo banco de dados
caiu. **As três promessas se cumpriram.** O 404 e o 500 voltaram como respostas comuns com
`ok: false`, e o `catch` nunca rodou. As linhas `[error]` são o próprio console do navegador anotando
os status de falha; não são exceções que o seu código consiga pegar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Em que uma chamada de fetch pode terminar. Se nenhuma resposta chega, porque a conexão foi recusada, a rede caiu ou a requisição foi abortada, a promessa rejeita. Se qualquer resposta chega, seja qual for o status, a promessa se cumpre. O código então confere o tipo de conteúdo antes de ler JSON, e response.ok antes de confiar no corpo.\"><defs><marker id=\"fetch-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"fetch-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"fetch-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fetch(url)</text><rect x=\"200\" y=\"20\" width=\"230\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">nenhuma resposta</text><text x=\"315.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">recusada, sem rede, abortada</text><rect x=\"200\" y=\"168\" width=\"230\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">uma resposta, qualquer status</text><text x=\"315.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200, 404, 500, 502</text><path d=\"M140 112 L196 52\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#fetch-ah-amber)\"></path><path d=\"M140 132 L196 192\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#fetch-ah-phosphor)\"></path><rect x=\"490\" y=\"20\" width=\"210\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">a promessa rejeita</text><text x=\"595.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">TypeError / AbortError</text><path d=\"M430 48 L486 48\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#fetch-ah-amber)\"></path><rect x=\"490\" y=\"120\" width=\"210\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1. tipo de conteúdo JSON?</text><rect x=\"490\" y=\"180\" width=\"210\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2. response.ok?</text><path d=\"M430 186 L486 146\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#fetch-ah-phosphor)\"></path><path d=\"M595 160 L595 176\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fetch-ah-paper-dim)\"></path></svg>", "caption": "O fetch só rejeita quando nenhuma resposta chega; todo status, 404 e 500 inclusive, é uma promessa cumprida para o seu código conferir.", "same": ["2. response.ok?"]}
```

**O `fetch` só rejeita quando nenhuma resposta chega.** Uma resposta com qualquer status é uma ida e
volta bem-sucedida para o `fetch`, porque o servidor respondeu. Se a resposta é uma boa notícia é a
pergunta do programa, e se o programa nunca pergunta, uma página mostra "undefined" onde deveria haver
um título, ou uma mensagem de erro como se fosse um livro.

## Uma função que confere

```javascript
export async function getJSON(url, options) {
  const response = await fetch(url, options);
  const type = response.headers.get("content-type") ?? "";
  if (!type.includes("application/json")) {
    throw new Error(`${url}: expected JSON, got ${response.status} ${type || "no type"}`);
  }
  const body = await response.json();
  if (!response.ok) {
    throw new Error(`${url}: ${response.status} ${body.error ?? ""}`.trim());
  }
  return body;
}
```

O resto desta aula usa esta função auxiliar. Ela transforma tudo o que não é uma resposta JSON
utilizável num erro, para quem chama ter um `try`/`catch` e nenhuma falha silenciosa:

1. **o tipo de conteúdo precisa ser JSON**, ou `response.json()` lançaria um `SyntaxError` confuso
   sobre o que viesse no lugar;
2. o corpo é lido, porque uma boa API explica os erros nele, como esta fez com `"no book 9"`;
3. **`response.ok` precisa ser verdadeiro**, ou ela lança erro com o status e a explicação do
   servidor.
