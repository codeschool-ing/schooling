---
title: Um perfil, coluna por coluna
version: 1
---

**Um perfil é um conjunto pequeno e fixo de medidas tiradas de cada coluna.** O mesmo conjunto
para toda coluna, para que as colunas possam ser comparadas, e pequeno o bastante para caber numa
tela, para que alguém o leia de fato. Dez linhas de `head()` mostram dez linhas; um perfil mostra
todas de uma vez, reduzidas aos números que denunciam defeitos.

O perfil de Ana tira oito medidas por coluna:

```schooling-example
{
  "language": "python",
  "file": "profile.py",
  "parts": [
    {
      "code": "import sys\n\nimport pandas as pd\n\n\n"
    },
    {
      "code": "def profile(df):\n    rows = []\n    for column in df.columns:\n        values = df[column]\n        present = values.dropna()\n",
      "note": "Uma linha do resultado por coluna da tabela. `present` é a coluna sem as células vazias, então toda medida depois das duas primeiras descreve só o que está lá."
    },
    {
      "code": "        rows.append({\n            \"column\": column,\n            \"filled\": present.size,\n            \"empty\": values.isna().sum(),\n",
      "note": "**Preenchidos e vazios** são completude, contada em vez de adivinhada."
    },
    {
      "code": "            \"distinct\": present.nunique(),\n",
      "note": "**Distintos** contra preenchidos é a pergunta da unicidade: numa coluna-chave em que eles diferem, há repetições."
    },
    {
      "code": "            \"shortest\": present.str.len().min(),\n            \"longest\": present.str.len().max(),\n",
      "note": "**Menor e maior**, em caracteres. Todo valor é texto aqui, então `.str.len()` funciona em qualquer coluna, um dos motivos para ler tudo como texto primeiro."
    },
    {
      "code": "            \"most_common\": present.value_counts().index[0],\n            \"times\": present.value_counts().iloc[0],\n        })\n",
      "note": "**O valor mais comum, e quantas vezes.** Um marcador mora aqui: um valor que é comum porque um formulário precisava de alguma coisa, não porque o mundo é assim."
    },
    {
      "code": "    return pd.DataFrame(rows)\n\n\n"
    },
    {
      "code": "path = sys.argv[1]\ndf = pd.read_csv(path, dtype=str, keep_default_na=False, na_values=[\"\"])\nprint(f\"{path}: {len(df)} rows\")\nprint(profile(df).to_string(index=False))\n",
      "note": "**Tudo como texto, e só um campo realmente vazio como faltante.** Por padrão o pandas transforma `NA`, `null`, `n/a` e mais uma dúzia de textos em faltantes na entrada; `keep_default_na=False` impede isso, para o perfil mostrar o que o arquivo diz e não o que o pandas decidiu."
    }
  ]
}
```

Rodado sobre o arquivo de clientes:

```
ana@lab:~/clean$ python profile.py raw/customers.csv
raw/customers.csv: 2413 rows
          column  filled  empty  distinct  shortest  longest                       most_common  times
     customer_id    2413      0      2376         6        6                            C00107      2
            name    2413      0      2198         7       36                     Alice Pereira      5
           email    2131    282      2070        21       50 caio.barbosa.araujo70@example.org      2
             cep    2413      0      2360         7        9                         13015-441      2
            city    2413      0        28         2       15                         São Paulo    458
           state    2413      0        13         2       14                                SP   1053
       signed_up    2413      0      1417        10       10                        04/04/2025      8
      birth_year    2075    338       105         2        4                              1900    348
  signup_channel    2413      0         4         3       11                              site   1020
marketing_opt_in    2352     61        10         1        5                              true    579
```

Leia linha por linha e quase toda a aula 1 reaparece, desta vez sem que alguém tivesse de suspeitar
antes:

- **`customer_id`** tem 2.413 valores e 2.376 distintos. Uma chave com 37 repetições, e o id mais
  comum aparece duas vezes: são as linhas duplicadas exatas que a aula 5 remove.
- **`email`** está vazio 282 vezes, a lacuna de completude da aula 1. O valor mais comum aparece
  duas vezes, e um e-mail compartilhado por duas contas é ou a mesma pessoa duas vezes ou uma
  família; a aula 5 decide qual.
- **`cep`** vai de 7 a 9 caracteres. Um CEP tem oito dígitos, escritos `99999-999` com o hífen,
  então nove está certo, oito é o hífen que caiu e **sete é impossível**, a menos que um dígito
  tenha se perdido. Os padrões, duas seções adiante, dizem qual.
- **`city`** tem 28 valores distintos e **`state`** tem 13, para cinco cidades em quatro estados.
- **`signed_up`** tem sempre 10 caracteres, o que soa arrumado e esconde três formatos em duas
  formas.
- **`birth_year`** tem de 2 a 4 caracteres e é mais vezes `1900`.
- **`marketing_opt_in`**, uma pergunta de sim ou não, tem **10 respostas distintas**.

Essa última linha é o tipo de achado para o qual um perfil existe. Ninguém pensaria em procurar dez
jeitos de dizer sim e não, e ninguém precisa: o número está na tela. A aula 10 os conta.

## O que um perfil não faz

Ele não julga. Um `distinct` de 28 é um fato; se está errado depende de você saber que a empresa
atende cinco cidades. **O perfil diz onde olhar e o domínio diz o que você está vendo.** Essa
divisão de trabalho é o motivo para perfilar toda coluna, e não só as que você já suspeita: a
suspeita vem depois do número, não antes.

Ele também não mostra relações entre colunas — que um ano de dois dígitos sempre vem do aplicativo,
ou que um entregador vazio sempre acompanha uma retirada. Isso pede um segundo passo, separar uma
coluna por outra, que as próximas seções e a aula 3 dão.
