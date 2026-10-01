---
title: As mesmas requisições, a partir do Python
version: 1
---

`curl` é a ferramenta certa para olhar uma API. Um programa que faz alguma coisa com a resposta é
escrito em Python, com `requests`:

```schooling-example
{
  "language": "python",
  "file": "login.py",
  "parts": [
    {
      "code": "from pathlib import Path\n\nimport requests\n\nBASE = \"https://edge1.example.net/api/v1\"\nCA = \"lab-ca.pem\"\npassword = Path(\"~/.netops-password\").expanduser().read_text().strip()\n",
      "note": "**O endereço da API e o arquivo que prova quem é o servidor.** `lab-ca.pem` é a autoridade certificadora do laboratório; a seção 08 explica por que ela é nomeada aqui."
    },
    {
      "code": "r = requests.post(f\"{BASE}/auth/login\", json={\"username\": \"netops\", \"password\": password},\n                  verify=CA, timeout=10)\nr.raise_for_status()\ntoken = r.json()[\"token\"]\n",
      "note": "**Entrar uma vez.** A senha viaja em uma requisição, e o que volta é um token que expira."
    },
    {
      "code": "r = requests.get(f\"{BASE}/system\", headers={\"Authorization\": f\"Bearer {token}\"},\n                 verify=CA, timeout=10)\nr.raise_for_status()\nprint(r.json())",
      "note": "**Toda outra requisição leva o token**, no cabeçalho `Authorization`, e nunca a senha."
    }
  ]
}
```

```
ana@ctl:~$ python login.py
{'hostname': 'edge1', 'software': 'FRRouting 8.4.4', 'uptime_seconds': 18, 'management_address': '192.0.2.12'}
```

O que voltou é um dicionário Python, `r.json()`, montado a partir do corpo. **Nenhum parsing foi
escrito**: os campos já têm nome, e `data["hostname"]` é uma string seja lá o que o CLI do
roteador teria impresso em volta dela. Essa é a primeira coisa que uma API compra em relação ao
screen-scraping da aula 1.

Três detalhes no script importam mais do que parecem:

- **`raise_for_status()`** transforma qualquer 4xx ou 5xx numa exceção. Sem ele, `requests`
  devolve um `401` tão feliz quanto um `200`, e a linha seguinte falha com um `KeyError` confuso.
- **`timeout=10`**. `requests` não tem timeout a não ser que você dê um, e um equipamento que
  aceita a conexão e nunca responde vai prender o script para sempre.
- **`verify=CA`** diz qual autoridade certificadora usar para verificar o certificado do
  roteador. A seção 08 mostra o que acontece sem isso.

Todo script daqui em diante precisa do mesmo endereço, da mesma autoridade certificadora e do
mesmo token, então eles vão para um pequeno cliente que o resto da aula importa. O construtor
faz o login, `request` envia e `all` segue as páginas, e as próximas três seções usam cada um
deles.

```schooling-example
{
  "language": "python",
  "file": "devapi.py",
  "parts": [
    {
      "code": "import time\nfrom pathlib import Path\n\nimport requests\n\n\nclass Device:\n    def __init__(self, host, username=\"netops\", password_file=\"~/.netops-password\"):\n        self.base = f\"https://{host}.example.net/api/v1\"\n        self.http = requests.Session()\n        self.http.verify = \"lab-ca.pem\"\n        password = Path(password_file).expanduser().read_text().strip()\n        r = self.http.post(f\"{self.base}/auth/login\", timeout=10,\n                           json={\"username\": username, \"password\": password})\n        r.raise_for_status()\n        self.http.headers[\"Authorization\"] = \"Bearer \" + r.json()[\"token\"]\n",
      "note": "**Um pequeno cliente para a API dos roteadores**, o arquivo que todo script seguinte desta aula importa. Ele guarda o que toda requisição compartilha: o endereço, a autoridade certificadora e o token."
    },
    {
      "code": "    def request(self, method, path, **kwargs):\n        url = path if path.startswith(\"https://\") else self.base + path\n        for attempt in range(4):\n            r = self.http.request(method, url, timeout=10, **kwargs)\n            if r.status_code != 429 or attempt == 3:\n                break\n            wait = int(r.headers.get(\"Retry-After\", \"1\"))\n            print(f\"  429 on {path}: waiting {wait} s\")\n            time.sleep(wait)\n        r.raise_for_status()\n        return r.json() if r.content else None\n",
      "note": "**Um só lugar envia toda requisição.** Um 429 quer dizer \"rápido demais\": o cliente espera os segundos que o servidor deu em `Retry-After` e tenta de novo, no máximo três vezes. Qualquer outro status de erro vira uma exceção, então nada falha em silêncio."
    },
    {
      "code": "    def all(self, path, **params):\n        page = self.request(\"GET\", path, params=params)\n        while True:\n            yield from page[\"results\"]\n            if not page[\"next\"]:\n                return\n            page = self.request(\"GET\", page[\"next\"])",
      "note": "**Paginação, seguida até o fim.** O servidor responde uma página e um link `next`; este gerador segue os links e entrega os itens um de cada vez, então quem chama nunca vê uma página."
    }
  ]
}
```
