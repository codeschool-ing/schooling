---
title: A cara de um faltante
version: 1
---

**Um valor faltante é o que um sistema escreve quando não tem nada a escrever, e os sistemas
discordam sobre o que é isso.** Um campo vazio é a versão honesta. As outras são valores que fazem
as vezes de ausência — um zero, um ano marcador, um traço, a palavra `null` — e são mais difíceis de
achar justamente porque parecem dado.

Comece pelos honestos. Todo campo vazio de todo arquivo, lido como a aula 2 ensinou, com só o vazio
de verdade contado como faltante:

```schooling-example
{
  "language": "python",
  "file": "blanks.py",
  "parts": [
    {
      "code": "import glob\n\nimport pandas as pd\n\n"
    },
    {
      "code": "for path in sorted(glob.glob(\"raw/*.csv\")):\n",
      "note": "Todo arquivo de `raw/`, numa ordem fixa para a saída poder ser comparada entre execuções."
    },
    {
      "code": "    latin = \"store_sales\" in path\n    df = pd.read_csv(path, dtype=str, keep_default_na=False, na_values=[\"\"],\n                     encoding=\"latin-1\" if latin else \"utf-8\", sep=\";\" if latin else \",\")\n",
      "note": "O arquivo das lojas é lido como a aula 2 descobriu que ele foi escrito. Tudo é texto, e só um campo realmente vazio é faltante."
    },
    {
      "code": "    empty = df.isna().sum()\n",
      "note": "`isna().sum()` conta os vazios de todas as colunas de uma vez."
    },
    {
      "code": "    for column, n in empty[empty > 0].items():\n        print(f\"{path:22} {column:18} {n:6} of {len(df)}\")\n",
      "note": "Só as colunas com pelo menos um vazio são impressas, cada uma ao lado do tamanho do seu arquivo."
    }
  ]
}
```

```
ana@lab:~/clean$ python blanks.py
raw/customers.csv      email                 282 of 2413
raw/customers.csv      birth_year            338 of 2413
raw/customers.csv      marketing_opt_in       61 of 2413
raw/orders.csv         discount            13883 of 28551
raw/orders.csv         courier              5717 of 28551
raw/orders.csv         delivery_minutes    13679 of 28551
raw/store_sales.csv    cliente             15406 of 23594
raw/survey.csv         answered_on         16838 of 26494
raw/survey.csv         nps                 16838 of 26494
```

Nove colunas em quatro arquivos têm vazios. Essa lista é onde esta aula começa, e de propósito não é
onde ela termina, porque **uma contagem de vazios não diz nada sobre por que eles estão ali**: 13.679
tempos de entrega vazios e 16.838 notas de pesquisa vazias são ambos "faltantes" e não têm mais nada
em comum.

## Um fato, duas grafias

Algumas colunas registram o mesmo fato como vazio num sistema e como valor em outro. O desconto do
aplicativo:

```
ana@lab:~/clean$ psql -c "SELECT discount, count(*) FROM raw.orders WHERE channel = 'app' GROUP BY discount ORDER BY count(*) DESC"
 discount | count 
----------+-------
 0        | 11233
 5.00     |   411
 10.00    |   392
 15.00    |   382
 20.00    |   378
(5 rows)
```

Nenhum vazio, e 11.233 zeros. A aula 2 mostrou que o site escreve o mesmo fato, sem cupom, como campo
vazio. **Aqui um vazio quer dizer zero**, e uma regra que contasse vazios chamaria o aplicativo de
completo e o site de 88% vazio, por uma diferença que só existe no jeito como dois programas foram
escritos.

O consentimento de marketing das lojas mistura os dois tipos numa coluna:

```
ana@lab:~/clean$ psql -c "SELECT marketing_opt_in, count(*) FROM raw.customers WHERE signup_channel = 'store' GROUP BY marketing_opt_in ORDER BY count(*) DESC"
 marketing_opt_in | count 
------------------+-------
 sim              |   115
 S                |   108
 Sim              |   107
 não              |    88
 nao              |    79
 N                |    61
                  |    60
(7 rows)
```

Seis grafias de sim e não, e 60 vazios. O vazio aqui é um cliente no balcão a quem nunca se
perguntou, ou que não respondeu, e o arquivo não sabe dizer qual. Essa distinção é o assunto do
resto desta aula.

Os casos que o curso encontrou até aqui, pela cara que têm no arquivo:

| parece | exemplo aqui | quer dizer |
|---|---|---|
| um campo vazio | `delivery_minutes` numa retirada | nenhum valor poderia existir |
| um campo vazio | `nps` na pesquisa | o cliente não respondeu |
| um campo vazio | `discount` no site | zero: sem cupom |
| um ano marcador | `birth_year` de 1900 | ninguém perguntou, ou ninguém sabia |
| um valor que ninguém digitou | o `NA` da aula 2 numa leitura padrão do pandas | o que o leitor decidiu |

**Antes que qualquer um desses possa ser tratado, cada um precisa ser reconhecido como faltante**, o
que quer dizer que o primeiro passo para lidar com faltantes é tirá-los dos seus disfarces. A aula 4
transforma os 1900 em vazios honestos, e os descontos vazios do site nos zeros que eles querem dizer,
antes de decidir qualquer outra coisa.
