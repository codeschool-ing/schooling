---
title: Respostas que o seu código consegue ler
version: 2
---

A chamada de funções tira JSON de um modelo para uma função. A mesma necessidade aparece sem função
nenhuma: **uma resposta que um programa, e não uma pessoa, lê em seguida**. Esta seção transforma o
e-mail de um cliente num chamado que a fila do suporte consegue ordenar, com um esquema dizendo o
que é um chamado.

## O e-mail e o chamado

Dois e-mails, salvos como `data/emails/1.txt` e `data/emails/2.txt`:

```
Hello, I got order 1042 last week. I'd like to return one of the two mugs:
it's unused and still in its box. How do I do that? Thanks, Marta
```

```
Hi. My lamp from order 1043 shipped on 30 September and the tracking has had
no update since. I need it for Saturday. Can you check? João
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
      "code": "def extract(email, attempts=2):\n    messages = [{\"role\": \"user\", \"content\": email}]\n    for attempt in range(1, attempts + 1):\n        r = model.messages.create(model=\"llama3.2:3b\", max_tokens=300, system=SYSTEM, messages=messages, extra_body={\"temperature\": 0})\n        text = r.content[0].text\n        ticket, found = problems(text)\n        if not found:\n            return ticket\n        print(f\"attempt {attempt}: {'; '.join(found)}\", file=sys.stderr)\n        messages += [\n            {\"role\": \"assistant\", \"content\": text},\n            {\"role\": \"user\", \"content\": \"That reply is not valid: \" + \"; \".join(found)\n                                        + \". Reply again with the corrected JSON only.\"},\n        ]\n    return None\n\n\n",
      "note": "**Numa falha os motivos voltam ao modelo**, depois da própria resposta dele, e ele ganha mais uma tentativa."
    },
    {
      "code": "if __name__ == \"__main__\":\n    ticket = extract(Path(sys.argv[1]).read_text())\n    print(json.dumps(ticket) if ticket else \"no valid ticket; this email goes to a person\")\n",
      "note": "**Acabar as tentativas também é uma resposta**: `None`, e o e-mail vai para uma pessoa."
    }
  ]
}
```

```
ana@dev:~/shop$ python extract.py data/emails/1.txt
attempt 1: not JSON: Expecting ',' delimiter
{"order_id": "1042", "category": "return", "summary": "Return one of two mugs", "urgent": false}
```

**A primeira resposta não era JSON**, e a linha no `stderr` diz onde o parser desistiu. O motivo
voltou ao modelo, a segunda resposta foi lida e passou, e o programa imprimiu um chamado. A aula 8
seção 07 olha esse laço no segundo e-mail.

## Pedindo ao provedor que mantenha o formato

Os provedores oferecem uma versão mais forte: a **decodificação restrita**, em que o modelo só consegue
produzir tokens que mantêm a saída dentro de um esquema. No SDK da Anthropic ela é o `output_config`
com um `format`; a da OpenAI é o `response_format` com um JSON schema. Pelo endpoint Anthropic do
Ollama, a primeira não está lá:

```
ana@dev:~/shop$ python -c 'import anthropic; r = anthropic.Anthropic().messages.create(model="llama3.2:3b", max_tokens=60, messages=[{"role": "user", "content": "Name a colour."}], output_config={"format": {"type": "json_schema", "schema": {"type": "object", "properties": {"colour": {"type": "string"}}, "required": ["colour"]}}}); print(repr(r.content[0].text))'
'Blue.'
```

**`Blue.`**, que não é um objeto com um `colour`. O endpoint Anthropic do Ollama aceitou o campo e não
fez nada com ele, sem erro, que é o pior jeito de uma restrição faltar: um código que contasse com ela
leria a resposta e falharia em outro lugar. O endpoint OpenAI dele respeita o `response_format`, então
o `strict.py` pede por esse, com o mesmo esquema e a mesma checagem:

```schooling-example
{
  "language": "python",
  "file": "strict.py",
  "parts": [
    {
      "code": "\"\"\"The same ticket, with the schema enforced by Ollama while the model writes it.\"\"\"\nimport json\nimport sys\nfrom pathlib import Path\n\n"
    },
    {
      "code": "import openai\n\nfrom extract import TICKET, problems\n\n",
      "note": "**O esquema e a checagem são os do `extract.py`**, importados e não copiados."
    },
    {
      "code": "client = openai.OpenAI()\nemail = Path(sys.argv[1]).read_text()\nr = client.chat.completions.create(\n    model=\"llama3.2:3b\", temperature=0,\n    messages=[{\"role\": \"user\", \"content\": \"Extract the ticket from the customer's email.\\n\\n\" + email}],\n    response_format={\"type\": \"json_schema\", \"json_schema\": {\"name\": \"ticket\", \"schema\": TICKET, \"strict\": True}},\n)\n",
      "note": "**`response_format` com um JSON schema**, pelo SDK da OpenAI, que o endpoint compatível do Ollama lê: o modelo só consegue escrever tokens que mantêm a resposta dentro do esquema."
    },
    {
      "code": "text = r.choices[0].message.content\nticket, found = problems(text)\nprint(text)\nprint(\"schema:\", \"; \".join(found) if found else \"every field valid\")\n",
      "note": "**E a mesma checagem roda mesmo assim**, numa resposta que não tem como falhar nela, que é o ponto das próximas linhas."
    }
  ]
}
```

```
ana@dev:~/shop$ python strict.py data/emails/1.txt
{
  "order_id": "1042",
  "category": "return",
  "summary": "Return one of the two mugs",
  "urgent": false
}
schema: every field valid
ana@dev:~/shop$ python strict.py data/emails/2.txt
{"order_id": "1043", "category": "delivery", "summary": "Missing update on tracking", "urgent": true}
schema: every field valid
```

**As duas válidas, de primeira**, e a primeira espalhada em várias linhas, o que o JSON permite e a
checagem não se importa. É isso que a restrição compra: os nomes dos campos, os tipos, o `enum` e o
padrão do `order_id` se mantêm porque o modelo não tinha como escrever outra coisa.

O que ela não compra são os valores certos. `"summary": "Missing update on tracking"` é uma leitura
justa do e-mail do João; enquanto esta aula era preparada, o mesmo modelo, pedido do mesmo jeito com
uma instrução um pouco diferente, arquivou o mesmo e-mail como `"return"`, uma categoria válida e a
errada. **Mantenha a checagem mesmo assim**, e honesta sobre o que ela confere: o validador segura o
formato seja lá o que o provedor fez, e só uma pessoa ou uma regra no código seguram o significado.
