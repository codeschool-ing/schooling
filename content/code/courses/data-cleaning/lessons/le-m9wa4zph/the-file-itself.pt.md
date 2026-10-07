---
title: O arquivo em si: codificação, separador e linhas
version: 1
---

**Um arquivo CSV não diz como foi escrito.** Não há cabeçalho que diga a sua codificação de
caracteres, o separador, a marca decimal ou como ele põe um campo entre aspas, e toda ferramenta
que abre um adivinha as quatro coisas. Perfilar começa conferindo os palpites antes que qualquer
um deles chegue a uma coluna.

`file` lê os primeiros bytes de cada arquivo e diz com o que eles se parecem:

```
ana@lab:~/clean$ file raw/*.csv
raw/customers.csv:     CSV Unicode text, UTF-8 text
raw/fx_rates_2025.csv: CSV ASCII text
raw/invoices.csv:      CSV Unicode text, UTF-8 text
raw/order_items.csv:   CSV ASCII text
raw/orders.csv:        CSV ASCII text
raw/products.csv:      CSV Unicode text, UTF-8 text
raw/store_sales.csv:   ISO-8859 text
raw/survey.csv:        CSV ASCII text
raw/targets_2025.csv:  CSV Unicode text, UTF-8 text
```

Oito arquivos parecem UTF-8 ou ASCII puro, que é um subconjunto dele. **O `store_sales.csv` é
diferente**: ISO-8859, a família a que o Latin-1 pertence, e o `file` nem o reconhece como CSV,
porque os campos são separados por ponto e vírgula. As duas coisas vêm do caixa das lojas, um
programa antigo configurado para o português, em que a vírgula é a marca decimal e por isso não
pode também separar campos.

O pandas supõe UTF-8 e vírgulas, e avisa do único jeito que pode:

```
ana@lab:~/clean$ python -c "import pandas as pd; pd.read_csv('raw/store_sales.csv')" 2>&1 | tail -1
UnicodeDecodeError: 'utf-8' codec can't decode byte 0xe3 in position 106: invalid continuation byte
```

O byte `0xe3` na posição 106 está na primeira linha de dados. Olhar os bytes dessa linha mostra
que caractere é:

```
ana@lab:~/clean$ sed -n 2p raw/store_sales.csv | od -An -c
   V   0   0   0   0   0   1   ;   P   i   n   h   e   i   r   o
   s   ;   0   2   /   0   1   /   2   0   2   5   ;   0   8   :
   3   3   ;   C   0   0   5   9   6   ;   R   $       9   4   ,
   5   0   ;   C   a   r   t 343   o   ;   5  \n
```

O `od` imprime `343`, que é `0xe3` em octal, onde a palavra `Cartão` precisa do seu `ã`. Em Latin-1,
esse único byte é `ã`. Em UTF-8, a mesma letra ocupa dois bytes, e um `0xe3` sozinho é o começo de
um caractere que nunca termina — daí *invalid continuation byte*. **O erro é o desfecho bom.** Uma
ferramenta que decodificasse este arquivo como Latin-1 sendo ele UTF-8, ou o contrário, não falharia:
produziria `CartÃ£o`, exatamente o texto estragado que a migração de 2023 deixou no arquivo de
clientes.

Dizer ao pandas o que o arquivo é resolve os dois problemas de uma vez:

```
ana@lab:~/clean$ python -c "import pandas as pd; print(pd.read_csv('raw/store_sales.csv', sep=';', encoding='latin-1').head(3))"
     venda       loja        data   hora cliente     total pagamento  itens
0  V000001  Pinheiros  02/01/2025  08:33  C00596  R$ 94,50    Cartão      5
1  V000002  Pinheiros  02/01/2025  15:07  C00121  R$ 44,00    Cartão      3
2  V000003  Pinheiros  02/01/2025  12:50  C00089  R$ 10,60    Cartão      2
```

## Linhas e registros

A aula 1 contou linhas com `wc -l` e prometeu conferir se linhas e registros batem. Um campo CSV pode
conter uma quebra de linha se estiver entre aspas, e aí um registro ocupa duas linhas. Contar dos
dois jeitos resolve:

```schooling-example
{
  "language": "python",
  "file": "lines_and_rows.py",
  "parts": [
    {
      "code": "import csv\nimport glob\n\n",
      "note": "Só a biblioteca padrão: esta checagem não deve depender da ferramenta cuja leitura ela está checando."
    },
    {
      "code": "for path in sorted(glob.glob(\"raw/*.csv\")):\n    encoding = \"latin-1\" if \"store_sales\" in path else \"utf-8\"\n    delimiter = \";\" if \"store_sales\" in path else \",\"\n",
      "note": "Cada arquivo é aberto do jeito que a seção anterior descobriu que ele foi escrito. Adivinhar aqui repetiria o erro que se está medindo."
    },
    {
      "code": "    with open(path, encoding=encoding, newline=\"\") as f:\n        lines = sum(1 for _ in f)\n",
      "note": "Contar o que a iteração sobre o arquivo devolve conta linhas físicas, cabeçalho incluído."
    },
    {
      "code": "    with open(path, encoding=encoding, newline=\"\") as f:\n        rows = sum(1 for _ in csv.reader(f, delimiter=delimiter)) - 1\n",
      "note": "`csv.reader` segue as regras de aspas, então um campo entre aspas com quebra de linha continua sendo um registro só. Menos um pelo cabeçalho."
    },
    {
      "code": "    print(f\"{path:24} {lines:7} lines {rows:7} rows\")\n",
      "note": "Uma linha por arquivo, as duas contagens lado a lado."
    }
  ]
}
```

```
ana@lab:~/clean$ python lines_and_rows.py
raw/customers.csv           2414 lines    2413 rows
raw/fx_rates_2025.csv         13 lines      12 rows
raw/invoices.csv              61 lines      60 rows
raw/order_items.csv        99162 lines   99161 rows
raw/orders.csv             28552 lines   28551 rows
raw/products.csv              73 lines      72 rows
raw/store_sales.csv        23595 lines   23594 rows
raw/survey.csv             26495 lines   26494 rows
raw/targets_2025.csv           7 lines       6 rows
```

Todo arquivo tem exatamente uma linha a mais do que registros, que é o cabeçalho. **Quando os dois
números diferem em mais de um, algum campo contém uma quebra de linha**, tipicamente um comentário
livre ou um endereço digitado com Enter, e qualquer ferramenta que separe por linha em vez de ler
CSV de verdade vai cortar esse registro ao meio.

O que anotar desta seção, antes de olhar um único valor:

| arquivo | codificação | separador |
|---|---|---|
| `store_sales.csv` | Latin-1 | `;` |
| todo o resto | UTF-8 | `,` |

A marca decimal não está na lista porque não é propriedade do arquivo. É propriedade de cada valor,
e a aula 7 encontra uma coluna que usa as duas.
