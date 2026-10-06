---
title: From text to fields, and the invoice checking itself
version: 1
---

Text is not yet data. The stock system wants each line of the invoice as a title, a quantity, a unit price and an amount, and the three totals as numbers. **Extraction** is that step, and on a document with a fixed layout it is a few regular expressions over the rows OCR produced.

```schooling-example
{
  "language": "python",
  "file": "extract.py",
  "parts": [
    {
      "code": "\"\"\"The invoice's lines and totals as data, and the arithmetic that checks them.\"\"\"\nimport json\nimport re\nimport subprocess\nimport sys\n\n"
    },
    {
      "code": "lang = sys.argv[2] if len(sys.argv) > 2 else \"eng+por\"\ntext = subprocess.run([\"tesseract\", sys.argv[1], \"-\", \"--psm\", \"6\", \"-l\", lang],\n                      capture_output=True, text=True, check=True).stdout\n",
      "note": "**Tesseract in row mode**, with English and Portuguese, which is the setting that measured best. A second argument changes the language, so the same program can be run on a worse reading."
    },
    {
      "code": "MONEY = r\"(\\d+[.,]\\d\\d)\"\n\n\ndef cents(s):\n    return int(s.replace(\",\", \"\").replace(\".\", \"\"))\n\n\n",
      "note": "**Money is cents, as an integer.** The pattern accepts a comma or a point before the last two digits, because the scan comes back with both, and `cents` throws the separator away."
    },
    {
      "code": "lines, totals = [], {}\nfor row in text.splitlines():\n    m = re.match(rf\"(.+?) (\\d+) {MONEY} {MONEY}$\", row.strip())\n    if m:\n        lines.append({\"title\": m[1], \"qty\": int(m[2]), \"unit\": cents(m[3]), \"amount\": cents(m[4])})\n        continue\n    m = re.match(rf\"(Subtotal|Shipping|Total BRL) {MONEY}$\", row.strip())\n    if m:\n        totals[m[1]] = cents(m[2])\n\n",
      "note": "**A row is a line of the invoice if it ends in a whole number and two amounts.** Anything else is tried as one of the three totals, and the rest of the page is ignored."
    },
    {
      "code": "problems = [f\"{x['title']}: {x['qty']} x {x['unit']} is not {x['amount']}\"\n            for x in lines if x[\"qty\"] * x[\"unit\"] != x[\"amount\"]]\nif sum(x[\"amount\"] for x in lines) != totals.get(\"Subtotal\"):\n    problems.append(f\"the lines add up to {sum(x['amount'] for x in lines)}, not {totals.get('Subtotal')}\")\nif totals.get(\"Subtotal\", 0) + totals.get(\"Shipping\", 0) != totals.get(\"Total BRL\"):\n    problems.append(\"subtotal and shipping do not make the total\")\n",
      "note": "**The invoice checks itself.** Quantity times price must be the amount; the amounts must add up to the subtotal; subtotal and shipping must make the total. None of this needs a model, and each one is a misreading the model cannot see."
    },
    {
      "code": "print(json.dumps({\"lines\": lines, \"totals\": totals}, ensure_ascii=False))\nprint(\"checks:\", \"; \".join(problems) or \"every line and total agrees\")",
      "note": "**The data and the verdict**, separately, so that a program reading this output never takes a total that failed a check."
    }
  ]
}
```

On the clean page and on the scan read with Portuguese, everything agrees:

```
ana@lab:~/mm$ python extract.py media/invoice-0931.png
{"lines": [{"title": "Dom Casmurro", "qty": 12, "unit": 1850, "amount": 22200}, {"title": "The Posthumous Memoirs of Bras Cubas", "qty": 8, "unit": 2100, "amount": 16800}, {"title": "Bleak House", "qty": 5, "unit": 3290, "amount": 16450}, {"title": "The Secret Garden", "qty": 10, "unit": 1590, "amount": 15900}], "totals": {"Subtotal": 71350, "Shipping": 4500, "Total BRL": 75850}}
checks: every line and total agrees
ana@lab:~/mm$ python extract.py media/invoice-0931-scan.jpg
{"lines": [{"title": "Dom Casmurro", "qty": 12, "unit": 1850, "amount": 22200}, {"title": "The Posthumous Memoirs of Brás Cubas", "qty": 8, "unit": 2100, "amount": 16800}, {"title": "Bleak House", "qty": 5, "unit": 3290, "amount": 16450}, {"title": "The Secret Garden", "qty": 10, "unit": 1590, "amount": 15900}], "totals": {"Subtotal": 71350, "Shipping": 4500, "Total BRL": 75850}}
checks: every line and total agrees
ana@lab:~/mm$ python extract.py media/invoice-0931-scan.jpg eng | tail -1
checks: The Secret Garden: 10 x 1596 is not 15900
```

The last command reads the scan with English only, the reading that turned `15.90` into `15.96`, and **the check catches it**: ten copies at 15.96 is not 159.00. The text OCR returned carried no mark on that digit, and its confidence flagged it alongside words that were right. The invoice's own arithmetic singled it out, because a supplier's invoice is a document that has to be internally consistent, and a misread digit almost never keeps it consistent.

That is the most useful habit in this whole course: **wherever the truth has a structure, check the model's output against the structure.** Lines add up to subtotals, an order number exists in the shop's database, a date is not in the future, a quantity is a whole number. These checks are cheap, exact and independent of the model, which is what makes them worth more than a second opinion from a similar model.

## What the arithmetic cannot catch

The checks passed on the clean page even though the title came back as *Bras Cubas*, because no sum depends on a title. A misread title is caught by a different structure: Marginalia's own catalogue. The title on the invoice should match a book in `data/books.jsonl`, and the closest match by edit distance is almost always the right one. A quantity of 2 that should be 12, read in the default mode, would also have failed: 2 × 18.50 is not 222.00.

When no check is possible, a field the system cannot verify is a field a person confirms. That is not a failure of automation. It is the design, and lesson 8 builds the same safety into a vision model's structured output.
