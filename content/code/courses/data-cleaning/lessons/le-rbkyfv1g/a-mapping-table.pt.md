---
title: Uma tabela de mapeamento, guardada como arquivo
version: 1
---

**A decisão sobre o que cada rótulo quer dizer pertence a uma tabela, não ao código.** Uma cadeia de
linhas `if category in ('fruta', 'fruits')` funciona, e enterra cada decisão dentro de um programa
que ninguém que conheça os produtos vai ler. Uma tabela é uma lista que os compradores conseguem
revisar:

```
category_key,category,department
frutas,Frutas,Hortifruti
fruta,Frutas,Hortifruti
fruits,Frutas,Hortifruti
verduras,Verduras,Hortifruti
folhas,Verduras,Hortifruti
legumes,Legumes,Hortifruti
legume,Legumes,Hortifruti
ovos e laticinios,Ovos e laticínios,Frios
laticinios,Ovos e laticínios,Frios
graos e cereais,Grãos e cereais,Mercearia
graos,Grãos e cereais,Mercearia
mercearia,Mercearia,Mercearia
emporio,Mercearia,Mercearia
cestas,Cestas,Cestas
cesta,Cestas,Cestas
```

Toda chave que a coluna limpa pode conter tem uma linha, com a categoria que ela quer dizer e o
departamento acima dela. O código de limpeza faz então uma coisa só com ela — juntar — e confere duas
coisas no caminho:

```schooling-example
{
  "language": "python",
  "file": "categorise.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom keyed import products\n\n"
    },
    {
      "code": "mapping = pd.read_csv(\"category_map.csv\", dtype=str)\n",
      "note": "A tabela de mapeamento, lida como texto."
    },
    {
      "code": "if mapping[\"category_key\"].duplicated().any():\n    raise SystemExit(\"category_map.csv lists a spelling twice\")\n",
      "note": "**Uma grafia listada duas vezes é recusada**: duas linhas para uma chave duplicariam todo produto que a usa."
    },
    {
      "code": "products = products.merge(mapping, on=\"category_key\", how=\"left\",\n                          suffixes=(\"_raw\", \"\"), validate=\"many_to_one\")\n",
      "note": "Uma junção **à esquerda**, para um produto com rótulo desconhecido ficar na tabela e ser contado; `validate` recusa um mapa que não tenha uma linha por chave."
    },
    {
      "code": "unmapped = products[products[\"category\"].isna()]\nif len(unmapped):\n    raise SystemExit(f\"{len(unmapped)} products have a category the map does not know: \"\n                     f\"{sorted(unmapped['category_raw'].unique())}\")\n",
      "note": "**Rótulos desconhecidos param a execução**, com a contagem e os nomes."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from categorise import products as p; print(p.groupby(['department', 'category']).size().to_string())"
department  category         
Cestas      Cestas                4
Frios       Ovos e laticínios     7
Hortifruti  Frutas               16
            Legumes              15
            Verduras             13
Mercearia   Grãos e cereais       8
            Mercearia             9
```

Sete categorias em quatro departamentos, com todo produto no lugar. Como o laboratório sabe a
categoria real de cada produto, o mapeamento também recebe nota:

```
ana@lab:~/clean$ python -c "import pandas as pd; from categorise import products as p; t = pd.read_csv('~/clean-data/truth/categories.csv', dtype=str); m = p.merge(t, on='product_code', suffixes=('', '_true')); print(len(m), (m['category'] == m['category_true']).sum())"
72 72
```

**72 de 72 produtos caem na categoria a que realmente pertencem.** O trabalho real não tem arquivo de
verdade, e ali a checagem é alguém do time de compras lendo os sete grupos e os produtos de cada um.
A tabela torna essa revisão possível; uma cadeia de `if` não tornaria.

A tabela tem três propriedades que vale manter em qualquer mapeamento:

- **uma linha por valor de entrada**, o que `validate="many_to_one"` garante pelo lado do dado e a
  checagem de duplicados garante pelo lado da tabela. Uma grafia listada duas vezes com dois
  significados duplicaria produtos em silêncio;
- **a saída canônica escrita por inteiro**, `Ovos e laticínios` com acento e maiúscula, porque a
  tabela é também de onde vem a forma de exibição;
- **todo valor que o dado contém**, e nada além. O mapa tem `fruits`, que o arquivo deste ano não
  usa: uma grafia que os compradores sabem que já usaram, mantida para o arquivo do ano que vem não
  parar nela.
