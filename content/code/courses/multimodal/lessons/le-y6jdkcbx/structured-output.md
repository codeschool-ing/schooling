---
title: The invoice as data, in a shape you declare
version: 1
---

A description is for a person. The stock system wants fields, and a vision model can be asked for them in a **declared shape**: a JSON Schema the reply must fit, which the API enforces when the model supports **structured outputs**. The openai SDK builds the schema from Pydantic models and parses the reply back into them:

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
      "note": "**The shape of the answer, declared as Pydantic models.** Amounts are integer cents, so the arithmetic below is exact."
    },
    {
      "code": "path = sys.argv[1]\nkind = \"png\" if path.endswith(\".png\") else \"jpeg\"\nurl = f\"data:image/{kind};base64,\" + base64.b64encode(open(path, \"rb\").read()).decode()\n",
      "note": "**The picture, as a data URL.** Base64 makes the file a third larger in the request, a price paid for not needing a public URL."
    },
    {
      "code": "client = OpenAI()\nreply = client.chat.completions.parse(\n    model=\"lab-vision-1\",\n    messages=[\n        {\"role\": \"system\", \"content\": \"Read supplier invoices. Copy every number exactly as printed; amounts in cents.\"},\n        {\"role\": \"user\", \"content\": [{\"type\": \"text\", \"text\": \"Read this invoice.\"},\n                                     {\"type\": \"image_url\", \"image_url\": {\"url\": url, \"detail\": \"high\"}}]},\n    ],\n    response_format=Invoice,\n)\ninv = reply.choices[0].message.parsed\n\n",
      "note": "**`parse` sends the models as a JSON Schema** in `response_format`, and turns the reply back into an `Invoice`. If the reply did not fit the schema, this line would raise rather than hand over half an invoice."
    },
    {
      "code": "problems = [f\"{x.title}: {x.qty} x {x.unit_cents} is not {x.amount_cents}\"\n            for x in inv.lines if x.qty * x.unit_cents != x.amount_cents]\nif sum(x.amount_cents for x in inv.lines) != inv.subtotal_cents:\n    problems.append(\"the lines do not add up to the subtotal\")\nif inv.subtotal_cents + inv.shipping_cents != inv.total_cents:\n    problems.append(\"subtotal and shipping do not make the total\")\n",
      "note": "**A schema says the answer has the right shape, not that it is true.** The invoice's own arithmetic, the same checks as lesson 2, is what says whether the numbers agree with each other."
    },
    {
      "code": "print(f\"{inv.number} from {inv.supplier}: {len(inv.lines)} lines, total {inv.total_cents / 100:.2f}\")\nprint(\"checks:\", \"; \".join(problems) or \"every line and total agrees\")",
      "note": "**The verdict printed beside the data.**"
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

**Both readings were written by the course**, and the second one carries a mistake on purpose: it says 6 copies of *Bleak House* where the page says 5, the kind of digit a blurred scan invites. The schema accepted it, because 6 is a perfectly good integer. **The arithmetic caught it**: 6 × 32.90 is not 164.50.

That is the whole lesson of this section. **A schema guarantees the shape of an answer, never its truth.** It turns "the model returned a paragraph and I have to dig the total out of it" into "the model returned an `Invoice` or the call failed", which is a great improvement for the program, and it says nothing at all about whether the numbers are the ones on the page.

## Two readers are better than one

Lesson 2 read the same invoice with Tesseract and checked it the same way. With both a vision model's reading and an OCR reading, a program can compare them field by field and send only the disagreements to a person:

| the field | vision model | Tesseract (lesson 2) | verdict |
|---|---|---|---|
| Bleak House, quantity | 6 | 5 | disagree: check it |
| Bleak House, amount | 164.50 | 164.50 | agree |
| total | 758.50 | 758.50 | agree |

Two readers with different weaknesses rarely make the same mistake on the same field, so an agreement is strong evidence and a disagreement is a precise question for a person. It costs an OCR run, which is free and takes a second. On this invoice the arithmetic already caught the mistake; the comparison says *which* reader made it.
