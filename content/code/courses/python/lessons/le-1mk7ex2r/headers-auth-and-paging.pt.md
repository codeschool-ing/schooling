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

```text
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

```text
seguiu o next: 3 páginas, 25 linhas
```

**Seis linhas, e as mesmas seis linhas toda vez.** O laço não precisa saber quantas páginas
existem; ele para quando o `next` é nulo.

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
