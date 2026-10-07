---
title: Juntando uma tabela de referência
version: 1
---

Os dois arquivos do IBGE são pequenos e simples:

```
ana@lab:~/clean$ head -4 ref/ibge_states.csv; wc -l ref/ibge_states.csv
code,uf,name,region
11,RO,Rondônia,Norte
12,AC,Acre,Norte
13,AM,Amazonas,Norte
28 ref/ibge_states.csv
ana@lab:~/clean$ cat ref/ibge_cities.csv
code,name,uf
3550308,São Paulo,SP
3509502,Campinas,SP
3304557,Rio de Janeiro,RJ
3106200,Belo Horizonte,MG
4106902,Curitiba,PR
```

27 linhas de estados, cada uma com o código numérico, as duas letras, o nome e a região; cinco
cidades com os seus códigos municipais de sete dígitos. Os dois primeiros dígitos do código de uma
cidade são os do estado: a cidade de São Paulo é 3550308 e o estado de São Paulo é 35. É o tipo de
estrutura que um código oficial carrega e um nome nunca carrega.

A coluna `state` do arquivo de clientes é o que a referência precisa encontrar:

```
ana@lab:~/clean$ python -c "from cities import customers; print(customers['state'].value_counts(dropna=False).to_string())"
state
SP                1036
RJ                 422
MG                 305
PR                 282
sp                  98
São Paulo           54
S.P.                46
rj                  40
Rio de Janeiro      25
mg                  22
pr                  21
Paraná              15
Minas Gerais        10
```

Treze grafias: as duas letras em maiúsculas e minúsculas, as letras com pontos, e os nomes
completos. **A tabela de referência define quais são as respostas certas**, então o casamento só
precisa cobrir os jeitos de escrevê-las, não inventar os alvos:

```schooling-example
{
  "language": "python",
  "file": "places.py",
  "parts": [
    {
      "code": "import unicodedata\n\nimport pandas as pd\n\n"
    },
    {
      "code": "from cascade import values  # lesson 6: each city trimmed, repaired, lower case, unaccented\nfrom cities import customers\n\n\n",
      "note": "O trabalho da aula 6 na coluna de cidade, e os clientes de onde ela veio."
    },
    {
      "code": "def plain(text):\n    text = unicodedata.normalize(\"NFKD\", text)\n    return \"\".join(ch for ch in text if not unicodedata.combining(ch)).lower().strip()\n\n\n",
      "note": "Minúsculas sem acento, para comparar nomes."
    },
    {
      "code": "states = pd.read_csv(\"ref/ibge_states.csv\", dtype=str)\ncities = pd.read_csv(\"ref/ibge_cities.csv\", dtype=str)\nspellings = pd.read_csv(\"abbreviations.csv\", dtype=str)\n\n",
      "note": "**As três referências**: estados e cidades do IBGE, e a lista de grafias de cidade da aula 6."
    },
    {
      "code": "# A state is written as its two letters, with or without dots, or as its name.\nby_name = dict(zip(states[\"name\"].map(plain), states[\"uf\"]))\n",
      "note": "Nomes de estado em forma comparável, cada um apontando para as suas duas letras."
    },
    {
      "code": "letters = customers[\"state\"].str.replace(\".\", \"\", regex=False).str.strip().str.upper()\ncustomers[\"uf\"] = letters.where(letters.isin(states[\"uf\"]), customers[\"state\"].map(plain).map(by_name))\n",
      "note": "**As duas letras onde as letras são válidas**, senão o nome procurado; pontos e maiúsculas saem antes."
    },
    {
      "code": "customers[\"city_name\"] = values.map(dict(zip(spellings[\"spelling\"], spellings[\"city\"])))\n\n",
      "note": "A grafia de cada cidade para o nome como o IBGE escreve."
    },
    {
      "code": "for found, written in [(\"uf\", \"state\"), (\"city_name\", \"city\")]:\n    lost = customers[found].isna() & customers[written].notna()\n    if lost.any():\n        raise ValueError(f\"{written}: {sorted(customers.loc[lost, written].unique())} match no reference\")\n\n",
      "note": "**Todo valor escrito precisa ter casado**, senão o script diz quais não casaram."
    },
    {
      "code": "customers = customers.merge(cities.rename(columns={\"code\": \"city_code\", \"name\": \"city_name\",\n                                                   \"uf\": \"city_uf\"}),\n                            on=\"city_name\", how=\"left\", validate=\"many_to_one\")\n",
      "note": "**O código da cidade e o estado dela**, juntados muitos para um para a referência não multiplicar clientes."
    },
    {
      "code": "customers = customers.merge(states[[\"uf\", \"region\"]], on=\"uf\", how=\"left\", validate=\"many_to_one\")\n",
      "note": "**A região**, a partir do estado."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from places import customers as c; print(c[['customer_id', 'state', 'uf', 'city', 'city_name', 'city_code', 'region']].head(4).to_string(index=False))"
customer_id state uf           city      city_name city_code  region
     C00001    sp SP      Sao Paulo      São Paulo   3550308 Sudeste
     C00002    RJ RJ Rio de Janeiro Rio de Janeiro   3304557 Sudeste
     C00004    MG MG Belo Horizonte Belo Horizonte   3106200 Sudeste
     C00005    PR PR       Curitiba       Curitiba   4106902     Sul
ana@lab:~/clean$ python -c "from places import customers as c; print(c['region'].value_counts(dropna=False).to_string()); print((c['uf'] != c['city_uf']).sum())"
region
Sudeste    2058
Sul         318
0
```

Todo cliente agora tem um `uf` de duas letras, o nome da cidade como o IBGE escreve, o código da
cidade e a região. Três verificações foram junto, duas no código, onde parariam o script, e uma
no comando seguinte:

- **Todo estado e toda cidade escritos precisam casar.** Uma grafia que não casa com nada é nomeada
  no erro. Um enriquecimento que deixa um vazio em silêncio é a mesma falha de uma conversão que
  faz isso.
- **As duas junções são `many_to_one`**, então uma tabela de referência com chave repetida não
  consegue multiplicar os clientes.
- **O estado e a cidade precisam concordar.** O `uf` da própria cidade, vindo do IBGE, fica como
  `city_uf`, e o último número acima, 0, conta os clientes cujo estado escrito discorda do estado
  da cidade. Duas colunas que deveriam dizer a mesma coisa, conferidas contra uma autoridade de
  fora, são a verificação de coerência da aula 9 com um juiz melhor.

Os 2.376 clientes caem em duas regiões, 2.058 no Sudeste e 318 no Sul, o que bate com onde ficam as
cinco cidades.
