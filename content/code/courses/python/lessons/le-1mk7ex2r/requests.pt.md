---
title: `get`, a query string, `raise_for_status`, `json`, e o timeout
version: 1
---

```python
import requests

r = requests.get("https://pypi.org/pypi/requests/json", timeout=10)
r.raise_for_status()
dados = r.json()
```

```text
>>> r.status_code, r.ok
(200, True)
>>> dados["info"]["version"]
'2.34.2'
```

Quatro linhas, e três delas importam. O `timeout` é o que todo mundo deixa de fora.

## O timeout não é opcional

```python
requests.get(url)              # espera para sempre, por padrão
requests.get(url, timeout=10)  # levanta depois de dez segundos
```

```text
>>> requests.get("http://127.0.0.1:8099/slow", timeout=2)
requests.exceptions.ReadTimeout: … Read timed out. (read timeout=2)
```

**O `requests` não tem timeout padrão.** Um servidor que aceita a sua conexão e depois não diz nada
vai segurar a chamada aberta até outra coisa desistir — e num trabalho agendado, isso é um processo
ainda sentado ali de manhã.

```python
requests.get(url, timeout=(3, 10))   # 3s para conectar, 10s para ler
```

## `raise_for_status`

```text
>>> r2 = requests.get("https://pypi.org/pypi/pacote-que-nao-existe-xyzzy/json", timeout=10)
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

```text
>>> r.url
'https://pypi.org/simple/?a=1+2&b=x%26y'
```

Os espaços e o e comercial foram codificados por você. Montar a query string na mão é como um valor
com um `&` dentro caladamente vira dois parâmetros.

## `.json()` e `.text`

```python
r.json()      # analisado, levanta ValueError se o corpo não for JSON
r.text        # o corpo como string
r.content     # o corpo como bytes — para um arquivo, uma imagem, um PDF
```

O `r.json()` numa página HTML de erro levanta, que é mais uma razão para o `raise_for_status` vir
antes.

## O resto dos verbos

```python
requests.post(url, json={"centavos": 1000}, timeout=10)   # um corpo JSON
requests.post(url, data={"centavos": 1000}, timeout=10)   # um corpo de formulário
requests.put(url, json=…, timeout=10)
requests.delete(url, timeout=10)
```

O `json=` define o `Content-Type` e codifica por você; o `data=` manda um formulário. Escolher o
errado é um 400 com uma mensagem sobre o corpo que se lê como um defeito nos seus dados.
