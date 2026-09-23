---
title: `get`, a query string, `raise_for_status`, `json`, e o timeout
version: 2
---

```python
import requests

r = requests.get("https://pypi.org/pypi/requests/json", timeout=10)
r.raise_for_status()
data = r.json()
```

```sh
>>> r.status_code, r.ok
(200, True)
>>> data["info"]["version"]
'2.34.2'
```

Quatro linhas, e três delas importam. O `timeout` é o que todo mundo deixa de fora.

## O timeout não é opcional

```python
requests.get(url)              # waits forever, by default
requests.get(url, timeout=10)  # raises after ten seconds
```

```sh
>>> requests.get("http://127.0.0.1:8099/slow", timeout=2)
requests.exceptions.ReadTimeout: … Read timed out. (read timeout=2)
```

**O `requests` não tem timeout padrão.** Um servidor que aceita a sua conexão e depois não diz nada
vai segurar a chamada aberta até outra coisa desistir — e num trabalho agendado, isso é um processo
ainda sentado ali de manhã.

```python
requests.get(url, timeout=(3, 10))   # 3s to connect, 10s to read
```

## `raise_for_status`

```sh
>>> r2 = requests.get("https://pypi.org/pypi/no-such-package-xyzzy/json", timeout=10)
>>> r2.status_code, bool(r2)
(404, False)
>>> r2.raise_for_status()
requests.HTTPError: 404 Client Error: Not Found for url: …
```

**Um 404 é uma requisição HTTP bem-sucedida.** O `requests` não levanta por causa dele, então sem o
`raise_for_status` a sua próxima linha chama `.json()` num documento de erro e falha em algum lugar
confuso.

`bool(r)` é `False` para qualquer 4xx ou 5xx, que é por que `if r:` se lê bem e `if r.ok:` se lê
melhor.

## `params`

```python
requests.get(url, params={"a": "1 2", "b": "x&y"})
```

```sh
>>> r.url
'https://pypi.org/simple/?a=1+2&b=x%26y'
```

Os espaços e o e comercial foram codificados por você. Montar a query string na mão é como um valor
com um `&` dentro caladamente vira dois parâmetros.

## `.json()` e `.text`

```python
r.json()      # parsed, raises ValueError if the body is not JSON
r.text        # the body as a string
r.content     # the body as bytes — for a file, an image, a PDF
```

O `r.json()` numa página HTML de erro levanta, que é mais uma razão para o `raise_for_status` vir
antes.

## O resto dos verbos

```python
requests.post(url, json={"cents": 1000}, timeout=10)   # a JSON body
requests.post(url, data={"cents": 1000}, timeout=10)   # a form body
requests.put(url, json=…, timeout=10)
requests.delete(url, timeout=10)
```

O `json=` define o `Content-Type` e codifica por você; o `data=` manda um formulário. Escolher o
errado é um 400 com uma mensagem sobre o corpo que se lê como um defeito nos seus dados.
