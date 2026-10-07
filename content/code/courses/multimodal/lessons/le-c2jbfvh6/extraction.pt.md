---
title: Do texto aos campos, e a nota conferindo a si mesma
version: 1
---

Texto ainda não é dado. O sistema de estoque quer cada linha da nota como título, quantidade, preço unitário e valor, e os três totais como números. A **extração** é esse passo, e num documento de layout fixo são algumas expressões regulares sobre as linhas que o OCR produziu.

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
      "note": "**O Tesseract no modo de linhas**, com inglês e português, que foi a configuração que mediu melhor. Um segundo argumento troca o idioma, para o mesmo programa rodar sobre uma leitura pior."
    },
    {
      "code": "MONEY = r\"(\\d+[.,]\\d\\d)\"\n\n\ndef cents(s):\n    return int(s.replace(\",\", \"\").replace(\".\", \"\"))\n\n\n",
      "note": "**Dinheiro são centavos, inteiros.** O padrão aceita vírgula ou ponto antes dos dois últimos dígitos, porque a leitura do escaneado volta com os dois, e `cents` descarta o separador."
    },
    {
      "code": "lines, totals = [], {}\nfor row in text.splitlines():\n    m = re.match(rf\"(.+?) (\\d+) {MONEY} {MONEY}$\", row.strip())\n    if m:\n        lines.append({\"title\": m[1], \"qty\": int(m[2]), \"unit\": cents(m[3]), \"amount\": cents(m[4])})\n        continue\n    m = re.match(rf\"(Subtotal|Shipping|Total BRL) {MONEY}$\", row.strip())\n    if m:\n        totals[m[1]] = cents(m[2])\n\n",
      "note": "**Uma linha é item da nota se termina num número inteiro e dois valores.** O resto é testado como um dos três totais, e o restante da página é ignorado."
    },
    {
      "code": "problems = [f\"{x['title']}: {x['qty']} x {x['unit']} is not {x['amount']}\"\n            for x in lines if x[\"qty\"] * x[\"unit\"] != x[\"amount\"]]\nif sum(x[\"amount\"] for x in lines) != totals.get(\"Subtotal\"):\n    problems.append(f\"the lines add up to {sum(x['amount'] for x in lines)}, not {totals.get('Subtotal')}\")\nif totals.get(\"Subtotal\", 0) + totals.get(\"Shipping\", 0) != totals.get(\"Total BRL\"):\n    problems.append(\"subtotal and shipping do not make the total\")\n",
      "note": "**A nota confere a si mesma.** Quantidade vezes preço tem de dar o valor; os valores têm de somar o subtotal; subtotal e frete têm de dar o total. Nada disso precisa de modelo, e cada um é uma leitura errada que o modelo não vê."
    },
    {
      "code": "print(json.dumps({\"lines\": lines, \"totals\": totals}, ensure_ascii=False))\nprint(\"checks:\", \"; \".join(problems) or \"every line and total agrees\")",
      "note": "**Os dados e o veredito**, separados, para que um programa que lê esta saída nunca use um total que falhou numa conferência."
    }
  ]
}
```

Na página limpa e no escaneado lido com português, tudo confere:

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

O último comando lê o escaneado só com inglês, a leitura que transformou `15.90` em `15.96`, e **a conferência pega**: dez exemplares a 15,96 não dão 159,00. O texto que o OCR devolveu não trazia marca nenhuma nesse dígito, e a confiança o marcou junto com palavras certas. A própria aritmética da nota o isolou, porque a nota de um fornecedor é um documento que precisa ser coerente por dentro, e um dígito mal lido quase nunca a mantém coerente.

Esse é o hábito mais útil de todo este curso: **onde a verdade tem uma estrutura, confira a saída do modelo contra a estrutura.** Linhas somam subtotais, um número de pedido existe no banco da loja, uma data não está no futuro, uma quantidade é um número inteiro. Essas conferências são baratas, exatas e independentes do modelo, e é isso que as faz valer mais do que uma segunda opinião de um modelo parecido.

## O que a aritmética não pega

As conferências passaram na página limpa mesmo com o título voltando como *Bras Cubas*, porque nenhuma soma depende de um título. Um título mal lido se pega com outra estrutura: o próprio catálogo da Marginalia. O título da nota deve corresponder a um livro que a loja vende, e o mais parecido na grafia quase sempre é o certo; a aula 7 monta exatamente essa conferência contra um catálogo pequeno. Uma quantidade 2 que deveria ser 12, lida no modo padrão, também teria falhado: 2 × 18,50 não dá 222,00.

Quando nenhuma conferência é possível, um campo que o sistema não consegue verificar é um campo que uma pessoa confirma. Isso não é uma falha da automação. É o desenho, e a aula 8 constrói a mesma segurança na saída estruturada de um modelo de visão.
