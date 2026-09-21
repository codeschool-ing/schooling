---
title: Um token, um limite de taxa, e o laço que segue o `next`
version: 1
---

```python
import os, requests

s = requests.Session()
s.headers.update({
    "Authorization": f"Bearer {os.environ['API_TOKEN']}",
    "User-Agent": "rates/0.1 (ops@example.tld)",
})
r = s.get(url, timeout=10)
```

**Uma `Session` manda esses cabeçalhos em toda requisição que passa por ela**, então o token é
escrito uma vez. Ela também reaproveita a conexão TCP, o que vale ter ao longo de algumas centenas
de chamadas.

## O token vai num cabeçalho

Não na query string. Uma URL é registrada por todo proxy, todo servidor e pelo seu próprio
histórico de terminal, e um token numa é um token em todos eles.

```python
os.environ["API_TOKEN"]       # do ambiente
```

Nem no arquivo. Isso é o `.env` da aula 18 e o `.gitignore` da aula 17, e o modo de falhar é um
repositório que alguém torna público dois anos depois.

## O limite de taxa é um cabeçalho

```sh
>>> {k: v for k, v in r.headers.items() if k.lower().startswith("x-rate")}
{'X-RateLimit-Limit': '60', 'X-RateLimit-Remaining': '59'}
```

A maioria das APIs diz onde você está em toda resposta — em geral `X-RateLimit-Remaining` e um
`X-RateLimit-Reset` com um instante. **Ler isso é como você descobre antes de ser cortado.**

```python
if int(r.headers.get("X-RateLimit-Remaining", 1)) < 5:
    time.sleep(...)
```

Quando você é cortado é um **429**, muitas vezes com um cabeçalho `Retry-After` dizendo quanto
tempo. Esse cabeçalho é uma instrução, e ignorá-lo é como um bloqueio temporário vira permanente.

## Paginação

```json
{"results": [ … dez linhas … ], "next": "https://api.example.tld/orders?page=2"}
```

```python
url, linhas = "https://api.example.tld/orders", []
while url:
    r = s.get(url, timeout=10)
    r.raise_for_status()
    pagina = r.json()
    linhas += pagina["results"]
    url = pagina["next"]
```

```sh
seguiu o next: 3 páginas, 25 linhas
```

**Seis linhas, e as mesmas seis linhas toda vez.** O laço não precisa saber quantas páginas
existem; ele para quando o `next` é nulo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Cada resposta traz as suas linhas e o endereço da página seguinte. O laço segue esse endereço até uma resposta voltar sem nenhum, e ele nunca precisa saber quantas páginas havia.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"20\" y=\"24\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">while url:</text> <rect x=\"20\" y=\"36\" width=\"180\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"110\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/orders</text> <path d=\"M206 55 L244 55\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"250\" y=\"36\" width=\"150\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"325\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10 linhas</text> <rect x=\"420\" y=\"36\" width=\"160\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"500\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">?page=2</text> <path d=\"M500 78 L500 84 L110 84 L110 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"20\" y=\"88\" width=\"180\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"110\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">?page=2</text> <path d=\"M206 107 L244 107\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"250\" y=\"88\" width=\"150\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"325\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10 linhas</text> <rect x=\"420\" y=\"88\" width=\"160\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"500\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">?page=3</text> <path d=\"M500 130 L500 136 L110 136 L110 142\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"20\" y=\"140\" width=\"180\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"110\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">?page=3</text> <path d=\"M206 159 L244 159\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"250\" y=\"140\" width=\"150\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"325\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5 linhas</text> <rect x=\"420\" y=\"140\" width=\"160\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"500\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">null</text> <text x=\"500\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">sem próxima, então o laço acaba</text> <text x=\"360\" y=\"208\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">3 páginas, 25 linhas</text> <text x=\"360\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Um número de página que você incrementa até a lista voltar vazia é a outra convenção,</text> <text x=\"360\" y=\"247\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e um cabeçalho Link com rel=&quot;next&quot; é a terceira: r.links[&quot;next&quot;][&quot;url&quot;] lê essa.</text> </svg>", "caption": "Seis linhas, e as mesmas seis linhas toda vez. O laço para quando o servidor diz não há próxima."}
```

A outra convenção é um número de página que você incrementa até receber uma lista vazia, e a
terceira é um cabeçalho `Link` com `rel="next"` dentro — o `r.links.get("next", {}).get("url")` lê
essa.

## Repetir

```python
from requests.adapters import HTTPAdapter
from urllib3.util import Retry

s.mount("https://", HTTPAdapter(max_retries=Retry(
    total=3, backoff_factor=1,
    status_forcelist=[429, 500, 502, 503, 504],
)))
```

Repita os status que vale repetir, com um intervalo que cresce. **Não** repita um 400 ou um 404 —
esses vão dizer a mesma coisa da próxima vez — e não repita um POST que não seja idempotente, ou
você vai criar dois de alguma coisa.

## E seja um bom convidado

Um `User-Agent` nomeando o seu programa e um jeito de entrar em contato com você. Quando o seu
script começar a fazer algo pouco útil, essa linha é a diferença entre alguém mandar um e-mail e
alguém bloquear a sua faixa de endereços.
