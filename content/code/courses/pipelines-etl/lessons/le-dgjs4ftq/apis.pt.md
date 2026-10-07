---
title: Uma API, uma página por vez
version: 1
---

Uma API é um banco de dados com um balcão na frente. **Você recebe o que os seus criadores decidiram
expor, no formato que escolheram, na velocidade que permitem**, e a API de preços do laboratório se
comporta como as que um pipeline encontra por aí. O laboratório a inicia com `sudo bash
~/lab/lab.sh api`, e ela responde na porta 8081.

Sem a chave, ela recusa:

```
ana@vm:~/etl$ curl -s "http://127.0.0.1:8081/v1/prices?page_size=2"; echo
{"error": "missing or wrong X-Api-Key"}
```

Com ela, responde uma página e um cursor para a próxima:

```
ana@vm:~/etl$ curl -s -H "X-Api-Key: $PRICES_API_KEY" "http://127.0.0.1:8081/v1/prices?page_size=2" | python -m json.tool
{
    "data": [
        {
            "isbn": "9786574218454",
            "publisher": "Borda",
            "list_price_cents": 10490,
            "currency": "BRL",
            "updated_at": "2026-01-01T05:01:00-03:00"
        },
        {
            "isbn": "9786501618715",
            "publisher": "Litoral",
            "list_price_cents": 5990,
            "currency": "BRL",
            "updated_at": "2026-01-01T05:22:00-03:00"
        }
    ],
    "next_cursor": "bzoy"
}
```

A API nunca diz quantas linhas existem. O único jeito de pegar todas é seguir o cursor até ele
voltar `null`, uma requisição por página. **O cursor é opaco de propósito**: o servidor pode mudar o
que ele significa, e um cliente que o decodificasse e montasse o seu próprio quebraria no dia em que
isso acontecesse.

## O limite de taxa

Pergunte rápido demais e ela para de responder:

```
ana@vm:~/etl$ for i in 1 2 3 4 5 6 7; do curl -s -o /dev/null -w "%{http_code} " -H "X-Api-Key: $PRICES_API_KEY" "http://127.0.0.1:8081/v1/prices?page_size=1"; done; echo
200 200 200 429 429 429 429
```

Três respostas, depois quatro recusas. O limite é de cinco requisições em qualquer segundo, e as
requisições antes deste laço já tinham gastado parte dele. Um `429 Too Many Requests` diz *vá mais
devagar*, e o cabeçalho `Retry-After` nele diz por quanto tempo.

## Um cliente que pagina e espera

```schooling-example
{
  "language": "python",
  "file": "prices.py",
  "parts": [
    {
      "code": "\"\"\"Every list price the publishers changed since a moment, page by page.\"\"\"\nimport json\nimport os\nimport sys\nimport time\n\nimport requests\n\n"
    },
    {
      "code": "URL = \"http://127.0.0.1:8081/v1/prices\"\nHEADERS = {\"X-Api-Key\": os.environ[\"PRICES_API_KEY\"]}\nparams = {\"updated_since\": sys.argv[1], \"page_size\": 200}\nrows, pages, waits = [], 0, 0\n",
      "note": "A chave vem do ambiente, nunca do arquivo. **Um segredo escrito num script é um segredo em toda cópia dele**, inclusive a que está no controle de versão; a lição 18 diz onde os segredos moram."
    },
    {
      "code": "while True:\n"
    },
    {
      "code": "    r = requests.get(URL, headers=HEADERS, params=params, timeout=10)\n",
      "note": "Toda requisição tem `timeout`. Sem ele, um servidor que aceita a conexão e nunca responde segura o pipeline para sempre, e nada falha para avisar."
    },
    {
      "code": "    if r.status_code == 429:\n        waits += 1\n        time.sleep(float(r.headers.get(\"Retry-After\", \"1\")))\n        continue\n",
      "note": "**Um 429 não é um erro, é uma instrução**: vá mais devagar. O servidor diz por quanto tempo em `Retry-After`, e o laço espera esse tempo e pede a mesma página de novo."
    },
    {
      "code": "    r.raise_for_status()\n    body = r.json()\n    rows += body[\"data\"]\n    pages += 1\n",
      "note": "Qualquer outra falha para a execução com o código de status. Seguir em frente depois de um 500 escreveria um arquivo com um buraco que parece completo."
    },
    {
      "code": "    if body[\"next_cursor\"] is None:\n        break\n    params[\"cursor\"] = body[\"next_cursor\"]\n",
      "note": "O servidor decide onde a próxima página começa e entrega um cursor. O cliente o devolve sem ler, e para quando não vier nenhum."
    },
    {
      "code": "with open(sys.argv[2], \"w\") as out:\n    for row in rows:\n        out.write(json.dumps(row) + \"\\n\")\nprint(f\"{len(rows)} prices in {pages} pages, {waits} waits for the rate limit\")",
      "note": "A resposta cai como linhas JSON em `landing/`, do jeito que a API mandou. Cair primeiro e carregar depois é o hábito do ELT, aplicado a uma API."
    }
  ]
}
```

```
ana@vm:~/etl$ python prices.py 2026-01-01T00:00:00-03:00 landing/prices.jsonl
871 prices in 5 pages, 1 waits for the rate limit
ana@vm:~/etl$ python prices.py 2026-03-01T00:00:00-03:00 landing/prices_march.jsonl
62 prices in 1 pages, 1 waits for the rate limit
ana@vm:~/etl$ head -2 landing/prices_march.jsonl
{"isbn": "9786569764065", "publisher": "Duna", "list_price_cents": 3990, "currency": "BRL", "updated_at": "2026-03-01T01:07:00-03:00"}
{"isbn": "9786554474122", "publisher": "Horizonte", "list_price_cents": 7990, "currency": "BRL", "updated_at": "2026-03-01T01:22:00-03:00"}
```

O `updated_since` é o que mantém a segunda execução pequena: 62 preços mudaram desde 1º de março,
contra 871 desde o começo de janeiro. A API conhece o relógio do laboratório, então não serve nada de
dias que a loja ainda não viveu. Pedir só o que mudou desde a última vez é o assunto da lição 4, e
uma API que aceita um parâmetro `since` está oferecendo isso a você.

**O que este cliente ainda não faz** é sobreviver à API fora do ar. Um `503` às três da manhã o para
com um erro, que é a coisa certa a fazer e o começo da lição 10.
