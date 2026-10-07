---
title: Uma junção que presta contas
version: 1
---

O papel do catálogo nesta junção é dar a cada item um nome e uma categoria. **O preço cobrado já
está no item**, então os dois preços do catálogo nem precisam ser resolvidos para esta junção, só
mantidos fora dela:

```schooling-example
{
  "language": "python",
  "file": "catalogue.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "products = pd.read_csv(\"raw/products.csv\", dtype=str)\n",
      "note": "O catálogo como texto, 72 linhas."
    },
    {
      "code": "# Three codes are listed twice, at two prices and with no date. What a line was\n# charged is on the line; the catalogue is used for names and categories only.\n",
      "note": "Por que os preços ficam para trás, escrito onde a próxima pessoa vai olhar."
    },
    {
      "code": "names = products.groupby(\"product_code\")[\"name\"].nunique()\nif (names > 1).any():\n    raise ValueError(f\"codes with two names: {list(names[names > 1].index)}\")\n",
      "note": "**A verificação que torna seguro ficar com uma linha**: nenhum código pode ter dois nomes."
    },
    {
      "code": "catalogue = (products.drop_duplicates(\"product_code\")\n             .rename(columns={\"product_code\": \"code\"})[[\"code\", \"name\", \"category\"]])\n",
      "note": "Uma linha por código, renomeada para casar com os itens, só com as colunas que esta junção usa."
    }
  ]
}
```

A verificação antes do `drop_duplicates` é a linha importante. Ficar com a primeira linha de cada
código só é seguro se as linhas concordam no que está sendo mantido, e aqui concordam, fora a
grafia da categoria, que o mapa da aula 8 resolve. Se um código chegar um dia com dois nomes
diferentes, o script para e diz qual.

Depois, a junção em si, escrita uma vez para que toda junção seguinte informe os mesmos três
números:

```schooling-example
{
  "language": "python",
  "file": "joins.py",
  "parts": [
    {
      "code": "def join(left, right, on, how=\"left\", validate=\"many_to_one\"):\n    \"\"\"Join, and say how many rows went in, came out and found nothing.\"\"\"\n",
      "note": "Left join por padrão, e **`many_to_one` por padrão**: o caso comum, verificado a menos que você diga o contrário."
    },
    {
      "code": "    out = left.merge(right, on=on, how=how, validate=validate, indicator=True)\n",
      "note": "`indicator=True` acrescenta uma coluna dizendo se cada linha achou par."
    },
    {
      "code": "    alone = (out[\"_merge\"] == \"left_only\").sum()\n",
      "note": "As linhas que não acharam."
    },
    {
      "code": "    print(f\"join on {on}: {len(left)} rows in, {len(out)} out, {alone} with no match\")\n",
      "note": "**Os três números**, impressos toda vez."
    },
    {
      "code": "    return out.drop(columns=\"_merge\")\n",
      "note": "A coluna do indicador sai, e o resultado fica como o de qualquer outra junção."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from lines import lines; from catalogue import catalogue; from joins import join; j = join(lines, catalogue, 'code'); print(j[j['name'].isna()].groupby('code').agg(lines=('order_id', 'size'), price=('unit_price', 'first')).to_string())"
join on code: 99161 rows in, 99161 out, 1161 with no match
       lines  price
code               
00123    614   18.9
00584    547   26.9
```

**Linhas que entram igual a linhas que saem**, o que o `validate` garante e a contagem mostra. E
1.161 itens não encontraram produto: os dois códigos que a aula 7 achou, `00123` e `00584`,
ausentes do catálogo embora vendidos o ano todo. Os itens ainda sabem quanto foi cobrado, então
ficam, com nome e categoria vazios, e uma pergunta vai para quem cuida do catálogo.

Compare com a junção que quase todo mundo escreve primeiro, um inner join sem verificação:

```
ana@lab:~/clean$ python -c "from lines import lines as l; from catalogue import catalogue as c; i = l.merge(c, on='code'); print(len(l), len(i)); print(l['line_cents'].sum() / 100, i['line_cents'].sum() / 100)"
99161 98000
2516503.95 2476458.4
```

Rodou sem reclamar e devolveu 98.000 linhas. **R$ 40.045,55 de vendas reais saíram da análise**,
e todo número construído em cima dela, receita por categoria, por mês, por cliente, fica baixo
nesse valor, sem nada na tela para avisar. Um inner join é a ferramenta certa quando uma linha sem
par de fato não pertence à análise; é o padrão errado, porque responde à pergunta "quais linhas
não têm par?" apagando-as.
