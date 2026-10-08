---
title: Validar na borda
version: 1
---

O `staging/prices.sql` da lição 6 já limpa os preços: tira hífens, apara nomes, põe a moeda em
maiúsculas, converte texto em número e descarta os que faltam. Faz tudo isso **em silêncio**. Ninguém
fica sabendo quantos preços vieram como texto ontem à noite, ou que uma editora nova começou a mandá-los
em reais com vírgula, o que o `::integer` transformaria num erro ou num número errado. A Ana leva as
decisões para onde os registros chegam, e faz cada uma dizer o que fez:

```schooling-example
{
  "language": "python",
  "file": "validate_prices.py",
  "parts": [
    {
      "code": "\"\"\"Check every price the publishers sent before it is loaded.\n\nEach record is fixed where the fix is certain, rejected where it is not, and\ncounted either way. The good records go on to be loaded; the rejected ones go\nto quarantine with the reason; and if too many are rejected, nothing is loaded.\"\"\"\n",
      "note": "A política, dita uma vez no topo: corrigir o que é certo, rejeitar o que não é, contar os dois, e parar o lote inteiro quando há coisa errada demais."
    },
    {
      "code": "import json\nimport sys\nfrom collections import Counter\n\n",
      "note": "Só a biblioteca padrão. O `Counter` mantém uma contagem por motivo."
    },
    {
      "code": "MAX_REJECTED = 0.05          # more than 5% rejected: the batch is wrong, not the records\n\n\n",
      "note": "**O limite entre um registro ruim e um lote ruim.** Quatro preços faltando em mil são as editoras sendo editoras; metade dos preços faltando é uma exportação quebrada, e carregar a outra metade seria pior que não carregar nada."
    },
    {
      "code": "def isbn13_ok(isbn):\n    \"\"\"The last digit of an ISBN-13 is a check digit over the other twelve.\"\"\"\n    if len(isbn) != 13 or not isbn.isdigit():\n        return False\n    total = sum(int(d) * (3 if i % 2 else 1) for i, d in enumerate(isbn[:12]))\n    return (10 - total % 10) % 10 == int(isbn[12])\n\n\n",
      "note": "**Uma regra que uma conferência de formato não faz.** Treze dígitos é a forma de um ISBN; o último ser o dígito verificador certo é o que o torna um ISBN de verdade. Um erro de digitação em qualquer dígito o reprova."
    },
    {
      "code": "def check(rec, fixed):\n    \"\"\"Return the reason to reject rec, or None; fix what can be fixed, in place.\"\"\"\n",
      "note": "Uma função por registro. Ela devolve o motivo para rejeitar, ou `None`, e corrige no lugar o que pode ser corrigido, contando cada correção."
    },
    {
      "code": "    if \"-\" in rec[\"isbn\"]:\n        rec[\"isbn\"] = rec[\"isbn\"].replace(\"-\", \"\")\n        fixed[\"isbn written with hyphens\"] += 1\n",
      "note": "**Uma correção certa**: os hífens nos ISBNs da Maré não carregam informação, então tirá-los não perde nada."
    },
    {
      "code": "    if not isbn13_ok(rec[\"isbn\"]):\n        return \"isbn fails its check digit\"\n",
      "note": "E depois a conferência de verdade, sobre o valor corrigido."
    },
    {
      "code": "    if rec[\"publisher\"] != rec[\"publisher\"].strip():\n        rec[\"publisher\"] = rec[\"publisher\"].strip()\n        fixed[\"publisher with stray spaces\"] += 1\n",
      "note": "O espaço no fim do nome da Granito, o mesmo tipo de correção certa."
    },
    {
      "code": "    if rec[\"currency\"] != \"BRL\":\n        if rec[\"currency\"].upper() != \"BRL\":\n            return f\"currency {rec['currency']!r}\"\n        rec[\"currency\"] = \"BRL\"\n        fixed[\"currency in lower case\"] += 1\n",
      "note": "`brl` é corrigido; qualquer outra moeda é rejeitada em vez de convertida. Converter seria escolher uma cotação, e essa não é uma decisão que um validador deve tomar sozinho."
    },
    {
      "code": "    price = rec[\"list_price_cents\"]\n    if price is None:\n        return \"price missing\"\n    if isinstance(price, str):\n        if not price.isdigit():\n            return f\"price {price!r} is not a number\"\n        rec[\"list_price_cents\"] = int(price)\n        fixed[\"price sent as text\"] += 1\n",
      "note": "**Um preço faltando é rejeitado, nunca preenchido.** Nada no registro diz qual deveria ser o preço, e um palpite seria carregado como fato. Um preço mandado como dígitos numa string é certo e é corrigido; qualquer outra coisa numa string é rejeitada."
    },
    {
      "code": "    if not 100 <= rec[\"list_price_cents\"] <= 100_000:\n        return f\"price {rec['list_price_cents']} out of range\"\n    return None\n\n\n",
      "note": "Um intervalo plausível para o preço de capa de um livro, em centavos: de um real a mil. Um preço fora dele é muito mais provavelmente um erro do que um livro."
    },
    {
      "code": "src, good_path, bad_path = sys.argv[1:4]\nfixed, rejected, good, bad = Counter(), Counter(), [], []\nfor line in open(src, encoding=\"utf-8\"):\n    rec = json.loads(line)\n    reason = check(rec, fixed)\n    if reason:\n        rejected[reason] += 1\n        bad.append({\"reason\": reason, \"record\": json.loads(line)})\n    else:\n        good.append(rec)\n\n",
      "note": "Cada registro vai para um lado ou para o outro. O rejeitado é guardado **como chegou**, não meio corrigido, ao lado do motivo."
    },
    {
      "code": "total = len(good) + len(bad)\nprint(f\"{total} records: {len(good)} accepted, {len(bad)} rejected\")\nfor what, n in sorted(fixed.items()):\n    print(f\"  fixed     {n:4}  {what}\")\nfor why, n in sorted(rejected.items()):\n    print(f\"  rejected  {n:4}  {why}\")\n",
      "note": "**A contagem é o relatório.** Toda correção e toda rejeição são contadas, então uma correção que acontecia oitenta vezes e passa a acontecer oitocentas fica visível na primeira noite em que isso ocorre."
    },
    {
      "code": "with open(bad_path, \"w\", encoding=\"utf-8\") as out:\n    out.writelines(json.dumps(b, ensure_ascii=False) + \"\\n\" for b in bad)\n",
      "note": "O arquivo de quarentena é gravado aconteça o que acontecer depois, para que os registros rejeitados possam sempre ser lidos."
    },
    {
      "code": "if len(bad) > MAX_REJECTED * total:\n    print(f\"STOP: {len(bad) / total:.0%} rejected is more than {MAX_REJECTED:.0%}; nothing loaded\")\n    sys.exit(1)\n",
      "note": "**Parar, com saída diferente de zero**, para que o que estiver rodando isto — Airflow, `make`, um script de shell com `set -e` — pare também."
    },
    {
      "code": "with open(good_path, \"w\", encoding=\"utf-8\") as out:\n    out.writelines(json.dumps(g, ensure_ascii=False) + \"\\n\" for g in good)",
      "note": "Só agora os registros bons são gravados para o carregador."
    }
  ]
}
```

```
ana@vm:~/etl$ mkdir -p quarantine; python validate_prices.py landing/prices.jsonl landing/prices.valid.jsonl quarantine/prices.jsonl
1071 records: 1067 accepted, 4 rejected
  fixed       81  currency in lower case
  fixed       84  isbn written with hyphens
  fixed       81  price sent as text
  fixed       85  publisher with stray spaces
  rejected     4  price missing
ana@vm:~/etl$ cat quarantine/prices.jsonl
{"reason": "price missing", "record": {"isbn": "9786542137312", "publisher": "Litoral", "list_price_cents": null, "currency": "BRL", "updated_at": "2026-01-07T18:51:00-03:00"}}
{"reason": "price missing", "record": {"isbn": "9786528944132", "publisher": "Oásis", "list_price_cents": null, "currency": "BRL", "updated_at": "2026-02-11T04:18:00-03:00"}}
{"reason": "price missing", "record": {"isbn": "978-65-64226-84-1", "publisher": "Maré", "list_price_cents": null, "currency": "BRL", "updated_at": "2026-02-25T03:14:00-03:00"}}
{"reason": "price missing", "record": {"isbn": "978-65-67767-15-0", "publisher": "Maré", "list_price_cents": null, "currency": "BRL", "updated_at": "2026-03-16T10:45:00-03:00"}}
```

Todo registro contabilizado: 1.067 aceitos, quatro rejeitados, e uma linha para cada tipo de correção
com quantas vezes ela foi necessária. As contagens são os hábitos das editoras, medidos: a Maré põe
hífens nos ISBNs, o nome da Granito tem um espaço no fim, a Farol manda preços como texto e a moeda
em minúsculas. Se um desses números saltar amanhã, algo mudou numa editora, e a Ana vai saber em qual.

Os quatro registros rejeitados estão em quarentena, **como chegaram**, cada um com o motivo. Ninguém
precisa reconstruir o que estava errado com eles a partir de uma linha de log. São preços que a loja
não vai ter até uma editora mandá-los de novo, e o arquivo de quarentena é o que a Ana manda à editora
para perguntar.

O validador grava `landing/prices.valid.jsonl` para o carregador. Apontar o `load_raw.py` para ele em
vez do arquivo cru é uma mudança de uma linha, e esta lição a deixa para o exercício. Daqui em
diante, o staging pode confiar que todo preço que lê foi conferido, e que todo preço que não foi
carregado está escrito em algum lugar com um motivo.
