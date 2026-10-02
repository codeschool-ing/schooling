---
title: Removendo na origem
version: 1
---

A primeira defesa fica no código, onde a linha nasce, e não confia que cada ponto de chamada vá
lembrar. **Um filtro de logging fica entre toda chamada e o formatador**, então ele vê todo registro
que todo serviço escreve. O da loja, em `common/redact.py`:

```schooling-example
{
  "language": "python",
  "file": "common/redact.py",
  "parts": [
    {
      "code": "\"\"\"A logging filter that keeps secrets and card numbers out of every line.\"\"\"\nimport logging\nimport re\n\n"
    },
    {
      "code": "CARD = re.compile(r\"\\b(?:\\d[ -]?){12,15}(\\d{4})\\b\")\nSECRET_KEYS = {\"authorization\", \"cookie\", \"password\", \"token\", \"card\"}\n\n\n",
      "note": "**Duas listas, escritas uma vez.** Um número de cartão tem de treze a dezenove dígitos com espaços ou hífens opcionais, e os quatro últimos ficam, para alguém do suporte ainda poder dizer *o cartão final 1111*. Um campo cujo nome é um segredo é removido seja o que for que guarde."
    },
    {
      "code": "def clean(value):\n    if isinstance(value, dict):\n        return {k: \"[removed]\" if k.lower() in SECRET_KEYS else clean(v) for k, v in value.items()}\n    if isinstance(value, str):\n        return CARD.sub(r\"**** \\1\", value)\n    return value\n\n\n",
      "note": "Percorre dicionários, para que um segredo aninhado num cabeçalho ou num corpo seja achado, e mascara números de cartão dentro de qualquer string, incluindo texto livre."
    },
    {
      "code": "class Redact(logging.Filter):\n    def filter(self, record):\n        record.fields = clean(getattr(record, \"fields\", {}))\n        record.msg = clean(str(record.msg))\n        return True\n",
      "note": "Um **filtro** de logging roda em todo registro antes de o formatador vê-lo, então toda linha de todo serviço que o configura passa por ele, seja quem for que escreveu a chamada."
    }
  ]
}
```

Duas linhas no `logs.py` compartilhado o instalam no handler, então todo serviço que chama
`logs.setup()` o ganha sem mudança própria. A vitrine é reiniciada, com a linha de depuração
vazadora ainda no lugar e o `DEBUG` ainda ligado, e um checkout leva um segundo número de cartão
escondido numa observação de texto livre:

```
ana@obs:~/shop$ sed -i 's/^    handler.setFormatter(JsonFormatter())$/&\n    handler.addFilter(redact.Redact())/; s/^from opentelemetry import trace$/&\n\nfrom common import redact/' services/common/logs.py && grep -n 'redact' services/common/logs.py
13:from common import redact
42:    handler.addFilter(redact.Redact())
ana@obs:~/shop$ docker compose restart storefront 2>&1 | tail -1
 Container shop-storefront-1 Started 
ana@obs:~/shop$ curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -H 'Authorization: Bearer sk_live_9f8e7d6c5b4a' -d '{"sku": "kettle", "qty": 1, "card": "4111 1111 1111 1111", "note": "paid with 5500 0000 0000 0004"}'
{"id":2702,"qty":1,"sku":"kettle","status":"paid"}
```

```
ana@obs:~/shop$ curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service_name="storefront"} | json | message="request"' --data-urlencode since=5m --data-urlencode limit=1 | jq -r '.data.result[].values[][1]' | jq -c '{auth: .headers.Authorization, body}'
{"auth":"[removed]","body":{"sku":"kettle","qty":1,"card":"[removed]","note":"paid with **** 0004"}}
```

O cabeçalho `Authorization` e o campo `card` estão **`[removed]`**, porque os nomes deles são segredos
sejam quais forem os valores. O número de cartão digitado na observação foi pego pelo formato e
mascarado até os quatro últimos dígitos. E a linha de depuração, a causa do vazamento, continua lá:
**o filtro protege contra a próxima linha descuidada, não só contra esta**.

Dois limites valem ser ditos. Um filtro por nome de campo só conhece os nomes da sua lista, e um token
num campo chamado `x_api_credential` passa. Um filtro por padrão pega o que tem forma, números de
cartão, e perde o que não tem, uma senha. Nenhum dos dois substitui não registrar o objeto; os dois
são o que segura o dia em que alguém registra.
