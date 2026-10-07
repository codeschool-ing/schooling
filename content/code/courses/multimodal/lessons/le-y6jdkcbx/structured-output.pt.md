---
title: A nota como dado, num formato que você declara
version: 1
---

Uma descrição é para uma pessoa. O sistema de estoque quer campos, e um modelo de visão pode ser pedido a devolvê-los num **formato declarado**: um JSON Schema em que a resposta precisa caber, e que a API garante quando o modelo suporta **saídas estruturadas** (structured outputs). O SDK da OpenAI monta o schema a partir de modelos Pydantic e transforma a resposta de volta neles:

```schooling-example
{
  "language": "python",
  "file": "invoice.py",
  "parts": [
    {
      "code": "\"\"\"The invoice as data, in a shape the program declares, and the arithmetic that checks it.\"\"\"\nimport base64\nimport sys\n\nfrom openai import OpenAI\nfrom pydantic import BaseModel\n\n\n"
    },
    {
      "code": "class Line(BaseModel):\n    title: str\n    qty: int\n    unit_cents: int\n    amount_cents: int\n\n\nclass Invoice(BaseModel):\n    number: str\n    date: str\n    supplier: str\n    lines: list[Line]\n    subtotal_cents: int\n    shipping_cents: int\n    total_cents: int\n\n\n",
      "note": "**O formato da resposta, declarado como modelos Pydantic.** Os valores são centavos inteiros, para a conta abaixo ser exata."
    },
    {
      "code": "path = sys.argv[1]\nkind = \"png\" if path.endswith(\".png\") else \"jpeg\"\nurl = f\"data:image/{kind};base64,\" + base64.b64encode(open(path, \"rb\").read()).decode()\n",
      "note": "**A imagem, como data URL.** O base64 deixa o arquivo um terço maior no pedido, o preço de não precisar de uma URL pública."
    },
    {
      "code": "client = OpenAI()\nreply = client.chat.completions.parse(\n    model=\"qwen2.5vl:3b\", temperature=0, seed=1,\n    messages=[\n        {\"role\": \"system\", \"content\": \"Read supplier invoices. Copy every number exactly as printed; amounts in cents.\"},\n        {\"role\": \"user\", \"content\": [{\"type\": \"text\", \"text\": \"Read this invoice.\"},\n                                     {\"type\": \"image_url\", \"image_url\": {\"url\": url, \"detail\": \"high\"}}]},\n    ],\n    response_format=Invoice,\n)\ninv = reply.choices[0].message.parsed\n\n",
      "note": "**O `parse` manda os modelos como JSON Schema** em `response_format`, e transforma a resposta de volta num `Invoice`. Se a resposta não coubesse no schema, esta linha levantaria um erro em vez de entregar meia nota."
    },
    {
      "code": "problems = [f\"{x.title}: {x.qty} x {x.unit_cents} is not {x.amount_cents}\"\n            for x in inv.lines if x.qty * x.unit_cents != x.amount_cents]\nif sum(x.amount_cents for x in inv.lines) != inv.subtotal_cents:\n    problems.append(\"the lines do not add up to the subtotal\")\nif inv.subtotal_cents + inv.shipping_cents != inv.total_cents:\n    problems.append(\"subtotal and shipping do not make the total\")\n",
      "note": "**Um schema diz que a resposta tem o formato certo, não que ela é verdadeira.** A aritmética da própria nota, as mesmas conferências da aula 2, é o que diz se os números concordam entre si."
    },
    {
      "code": "print(f\"{inv.number} from {inv.supplier}: {len(inv.lines)} lines, total {inv.total_cents / 100:.2f}\")\nprint(\"checks:\", \"; \".join(problems) or \"every line and total agrees\")",
      "note": "**O veredito impresso ao lado dos dados.**"
    }
  ]
}
```

```
ana@lab:~/mm$ python invoice.py media/invoice-0931.png
INV-0931 from Lantern & Quill Distributors: 4 lines, total 758.50
checks: every line and total agrees
ana@lab:~/mm$ python invoice.py media/invoice-0931-scan.jpg
INV-0931 from Lantern & Quill Distributors: 4 lines, total 758.50
checks: Bleak House: 6 x 3290 is not 16450
```

**As duas leituras foram escritas pelo curso**, e a segunda carrega um erro de propósito: diz 6 exemplares de *Bleak House* onde a página diz 5, o tipo de dígito que um escaneado borrado convida. O schema aceitou, porque 6 é um inteiro perfeitamente válido. **A aritmética pegou**: 6 × 32,90 não dá 164,50.

Essa é a lição inteira desta seção. **Um schema garante o formato de uma resposta, nunca a verdade dela.** Ele transforma "o modelo devolveu um parágrafo e eu preciso garimpar o total" em "o modelo devolveu um `Invoice` ou a chamada falhou". É uma grande melhora para o programa, e não diz absolutamente nada sobre os números serem os da página.

## Dois leitores são melhores que um

A aula 2 leu a mesma nota com o Tesseract e a conferiu do mesmo jeito. Com uma leitura de modelo de visão e uma de OCR, um programa pode compará-las campo a campo e mandar só as discordâncias a uma pessoa:

| o campo | modelo de visão | Tesseract (aula 2) | veredito |
|---|---|---|---|
| Bleak House, quantidade | 6 | 5 | discordam: conferir |
| Bleak House, valor | 164,50 | 164,50 | concordam |
| total | 758,50 | 758,50 | concordam |

Dois leitores com fraquezas diferentes raramente erram o mesmo campo do mesmo jeito, então uma concordância é um indício forte e uma discordância é uma pergunta precisa para uma pessoa. Custa uma passada de OCR, que é de graça e leva um segundo. Nesta nota a aritmética já pegou o erro; a comparação diz *qual* leitor o cometeu.
