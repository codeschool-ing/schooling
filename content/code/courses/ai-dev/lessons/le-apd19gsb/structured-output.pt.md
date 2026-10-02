---
title: Respostas que o seu código consegue ler
version: 1
---

A chamada de funções tira JSON de um modelo para uma função. A mesma necessidade aparece sem função
nenhuma: **uma resposta que um programa, e não uma pessoa, lê em seguida**. Esta seção transforma o
e-mail de um cliente num chamado que a fila do suporte consegue ordenar, com um esquema dizendo o
que é um chamado.

## O e-mail e o chamado

```
Hello, I got order 1042 last week. I'd like to return one of the two mugs:
it's unused and still in its box. How do I do that? Thanks, Marta
```

A fila precisa de quatro campos, e o esquema diz que valores cada um pode ter:

```python
TICKET = {
    "type": "object",
    "properties": {
        "order_id": {"type": ["string", "null"], "pattern": "^[0-9]{4}$"},
        "category": {"enum": ["return", "delivery", "payment", "warranty", "other"]},
        "summary": {"type": "string", "maxLength": 120},
        "urgent": {"type": "boolean"},
    },
    "required": ["order_id", "category", "summary", "urgent"],
    "additionalProperties": False,
}
```

**O `order_id` pode ser `null`**, e isso é uma decisão. Um e-mail sem número de pedido é normal, e
um esquema que exigisse um empurraria o modelo a inventar um.

## Pedindo, depois conferindo

```schooling-example
{
  "language": "python",
  "file": "extract.py",
  "parts": [
    {
      "code": "\"\"\"Turn a customer's email into a ticket the support queue can sort, or say it could not.\"\"\"\nimport json\nimport sys\nfrom pathlib import Path\n\nimport anthropic\nfrom jsonschema import Draft202012Validator\n\n"
    },
    {
      "code": "TICKET = {\n    \"type\": \"object\",\n    \"properties\": {\n        \"order_id\": {\"type\": [\"string\", \"null\"], \"pattern\": \"^[0-9]{4}$\"},\n        \"category\": {\"enum\": [\"return\", \"delivery\", \"payment\", \"warranty\", \"other\"]},\n        \"summary\": {\"type\": \"string\", \"maxLength\": 120},\n        \"urgent\": {\"type\": \"boolean\"},\n    },\n    \"required\": [\"order_id\", \"category\", \"summary\", \"urgent\"],\n    \"additionalProperties\": False,\n}\nSYSTEM = (\"Extract the ticket from the customer's email. Reply with one JSON object and \"\n          \"nothing else, matching this JSON Schema:\\n\" + json.dumps(TICKET))\nmodel = anthropic.Anthropic()\n\n\n",
      "note": "**O esquema é dado, e o prompt o cita**, para o modelo ler as mesmas regras que o validador aplica."
    },
    {
      "code": "def problems(text):\n    try:\n        ticket = json.loads(text)\n    except json.JSONDecodeError as e:\n        return None, [f\"not JSON: {e.msg}\"]\n    found = [f\"{'.'.join(map(str, e.path)) or '(top)'}: {e.message}\"\n             for e in Draft202012Validator(TICKET).iter_errors(ticket)]\n    return ticket, found\n\n\n",
      "note": "**Dois tipos de falha, uma lista.** Texto que não é JSON e JSON que quebra o esquema voltam como motivos que uma pessoa, ou um modelo, consegue ler."
    },
    {
      "code": "def extract(email, attempts=2):\n    messages = [{\"role\": \"user\", \"content\": email}]\n    for attempt in range(1, attempts + 1):\n        r = model.messages.create(model=\"scripted-1\", max_tokens=300, system=SYSTEM, messages=messages)\n        text = r.content[0].text\n        ticket, found = problems(text)\n        if not found:\n            return ticket\n        print(f\"attempt {attempt}: {'; '.join(found)}\", file=sys.stderr)\n        messages += [\n            {\"role\": \"assistant\", \"content\": text},\n            {\"role\": \"user\", \"content\": \"That reply is not valid: \" + \"; \".join(found)\n                                        + \". Reply again with the corrected JSON only.\"},\n        ]\n    return None\n\n\n",
      "note": "**Numa falha os motivos voltam ao modelo**, depois da própria resposta dele, e ele ganha mais uma tentativa."
    },
    {
      "code": "ticket = extract(Path(sys.argv[1]).read_text())\nprint(json.dumps(ticket) if ticket else \"no valid ticket; this email goes to a person\")",
      "note": "**Acabar as tentativas também é uma resposta**: `None`, e o e-mail vai para uma pessoa."
    }
  ]
}
```

```
ana@dev:~/shop$ python extract.py data/emails/1.txt
{"order_id": "1042", "category": "return", "summary": "Wants to return one of two mugs, unused.", "urgent": false}
```

**A resposta foi lida e passou**, então o programa imprimiu um chamado. O JSON foi escrito pelo
curso como resposta do `scripted-1`; a leitura e a validação são o que o seu código rodaria contra
qualquer modelo.

## Pedindo ao provedor que mantenha o formato

Os provedores oferecem uma versão mais forte: a **decodificação restrita**, em que o modelo só
consegue produzir tokens que mantêm a saída dentro de um esquema. No SDK da Anthropic que este
curso instala ela é o `output_config` com um `format`, e uma ferramenta pode dizer `strict`; a da
OpenAI é o `response_format` com um JSON schema. O SDK confirma que os campos existem:

```
ana@dev:~/shop$ python -c 'import anthropic.types as t; print(sorted(t.OutputConfigParam.__annotations__)); print(sorted(t.JSONOutputFormatParam.__annotations__)); print("strict" in t.ToolParam.__annotations__)'
['effort', 'format']
['schema', 'type']
True
ana@dev:~/shop$ python -c 'import anthropic; anthropic.Anthropic().messages.create(model="scripted-1", max_tokens=50, messages=[{"role": "user", "content": "hi"}], output_config={"format": {"type": "json_schema", "schema": {"type": "object"}}})' 2>&1 | tail -n 1
anthropic.BadRequestError: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'output_config: labllm does not constrain its output; validate the reply yourself'}, 'request_id': 'req_lab_0011'}
```

**O laboratório recusa, de propósito.** O labllm não tem decodificador para restringir, então diz
isso em vez de aceitar o campo e ignorá-lo, o que deixaria a aula fingir.

Onde um provedor de verdade oferece isso, use, e **mantenha a verificação mesmo assim**. A
decodificação restrita garante o formato: os nomes dos campos, os tipos, o enum. Ela não faz do
`order_id` o pedido certo, e os provedores documentam quais palavras-chave de esquema respeitam, que
nem sempre são todas. O validador é a linha que segura seja lá o que o provedor fez.
