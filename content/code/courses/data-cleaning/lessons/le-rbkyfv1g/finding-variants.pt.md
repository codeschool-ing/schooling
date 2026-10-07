---
title: Achar as variantes
version: 1
---

**Uma coluna de categoria é a promessa de que poucos rótulos se repetem em muitas linhas**, e essa
promessa é quebrada por toda mão que digitou um rótulo de um jeito um pouco diferente. O catálogo é
o caso mais claro nos arquivos da Quitanda Verde: setenta e duas linhas, uma categoria cada, mantidas
pelos compradores numa planilha.

Listar os valores ordenados pela forma em minúsculas põe as variantes lado a lado:

```
ana@lab:~/clean$ psql -c 'SELECT category, count(*) FROM raw.products GROUP BY category ORDER BY lower(category), count(*) DESC'
     category      | count 
-------------------+-------
 Cesta             |     2
 Cestas            |     2
 Empório           |     3
 Folhas            |     1
 Fruta             |     2
 Frutas            |     9
 frutas            |     3
 FRUTAS            |     1
 Frutas            |     1
 Graos e cereais   |     3
 Grãos             |     5
 Laticínios        |     1
 Legume            |     1
 Legumes           |     9
 legumes           |     5
 Mercearia         |     6
 ovos e laticinios |     1
 Ovos e laticínios |     5
 Verduras          |    10
 VERDURAS          |     2
(20 rows)
```

Vinte rótulos. Alguns grupos são obviamente uma categoria escrita de vários jeitos — `Frutas`,
`frutas`, `FRUTAS`, e um `Frutas` que ordena separado por causa de um espaço no fim. Outros são menos
óbvios: `Fruta` no singular, `Grãos` ao lado de `Graos e cereais`, `Folhas` ao lado de `Verduras`,
`Empório` ao lado de `Mercearia`.

**O primeiro passo é o que a aula 6 construiu**: uma chave simples sem maiúsculas, espaços e acentos.

```schooling-example
{
  "language": "python",
  "file": "keyed.py",
  "parts": [
    {
      "code": "import unicodedata\n\nimport pandas as pd\n\n\n"
    },
    {
      "code": "def plain(text):\n    text = unicodedata.normalize(\"NFKD\", text)\n    text = \"\".join(ch for ch in text if not unicodedata.combining(ch))\n    return \" \".join(text.lower().split())\n\n\n",
      "note": "**A forma simples da aula 6**: sem acentos, maiúsculas e espaços a mais."
    },
    {
      "code": "products = pd.read_csv(\"raw/products.csv\", dtype=str)\nproducts[\"category_key\"] = products[\"category\"].map(plain)\n",
      "note": "O catálogo, com uma chave simples ao lado do rótulo como os compradores digitaram."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from keyed import products as p; print(p['category'].nunique(), p['category_key'].nunique()); print(sorted(p['category_key'].unique()))"
20 14
['cesta', 'cestas', 'emporio', 'folhas', 'fruta', 'frutas', 'graos', 'graos e cereais', 'laticinios', 'legume', 'legumes', 'mercearia', 'ovos e laticinios', 'verduras']
```

Vinte rótulos viram catorze chaves. Toda diferença de maiúscula, espaço e acento sumiu, e o que sobra
é uma lista que uma pessoa lê em dez segundos — e precisa ler, porque as diferenças restantes não são
tipografia. `fruta` e `frutas` diferem por um plural, `graos` e `graos e cereais` por uma palavra,
`folhas` e `verduras` por tudo. Nenhuma regra junta isso com segurança. **Daqui em diante o trabalho
é decidir, não limpar.**

Dois hábitos tornam as variantes mais fáceis de ver em qualquer coluna: ordenar pela chave simples e
não pelo valor bruto, para que os vizinhos sejam candidatos; e imprimir a contagem ao lado de cada
um, porque um rótulo usado uma vez tem muito mais chance de ser variante do que um usado nove.
