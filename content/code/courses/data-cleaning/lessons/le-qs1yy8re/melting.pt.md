---
title: Derretendo, e a coluna que não é mês
version: 1
---

Ir do largo para o longo se chama **melt** (derreter) no pandas, `pivot_longer` no R e **unpivot**
(despivotar) no Power Query e no SQL. No pandas é uma chamada: diga quais colunas identificam uma
linha, e todas as outras colunas são dobradas em duas, uma para o cabeçalho antigo e outra para o
valor.

A chamada óbvia, no arquivo como ele está:

```
ana@lab:~/clean$ python -c "import pandas as pd; w = pd.read_csv('raw/targets_2025.csv'); long = w.melt(id_vars='loja', var_name='month', value_name='target'); print(len(long)); print(long['target'].sum(), w['Total'].sum())"
78
7602000 3801000
```

78 linhas, não 72, e uma meta anual de R$ 7.602.000 onde a planilha diz R$ 3.801.000. **O `Total`
derreteu junto com os meses**: virou um décimo terceiro "mês" para cada loja, e toda soma sobre a
tabela longa agora conta o ano duas vezes. Nada falhou. Um gráfico de metas por mês até pareceria
razoável, com uma barra estranha no fim que alguém poderia tomar por uma previsão.

Um total guardado como coluna é um **segundo registro do mesmo fato**, exatamente o que a aula 9
usou para pegar os totais digitados errado. Então o movimento certo não é descartá-lo às cegas, e
sim conferi-lo primeiro e descartá-lo depois:

```schooling-example
{
  "language": "python",
  "file": "targets.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "wide = pd.read_csv(\"raw/targets_2025.csv\", dtype=str).set_index(\"loja\").astype(int)\n",
      "note": "A planilha como inteiros, uma linha por loja."
    },
    {
      "code": "MONTHS = [c for c in wide.columns if c != \"Total\"]\n",
      "note": "Toda coluna menos o `Total`."
    },
    {
      "code": "# The Total column is a second record of the same targets: check it, then leave it behind.\noff = wide[MONTHS].sum(axis=1) != wide[\"Total\"]\nif off.any():\n    raise ValueError(f\"Total disagrees with the months for {list(wide.index[off])}\")\n\n",
      "note": "**A verificação**: os meses de cada loja precisam somar o seu `Total`. Senão, pare e diga a loja."
    },
    {
      "code": "MES = {\"jan\": 1, \"fev\": 2, \"mar\": 3, \"abr\": 4, \"mai\": 5, \"jun\": 6,\n       \"jul\": 7, \"ago\": 8, \"set\": 9, \"out\": 10, \"nov\": 11, \"dez\": 12}\n",
      "note": "**Os meses escritos por extenso**, para que nenhum locale decida o que `fev` quer dizer."
    },
    {
      "code": "targets = wide[MONTHS].reset_index().melt(id_vars=\"loja\", var_name=\"header\", value_name=\"target\")\n",
      "note": "**O melt**, só dos meses: uma linha por loja e mês."
    },
    {
      "code": "number = targets[\"header\"].str[:3].map(MES)\n",
      "note": "O número do mês de cada cabeçalho, pelo dicionário."
    },
    {
      "code": "if number.isna().any():\n    raise ValueError(f\"unknown month headers: {sorted(targets.loc[number.isna(), 'header'].unique())}\")\n",
      "note": "**Um cabeçalho desconhecido para o script** em vez de virar um mês vazio."
    },
    {
      "code": "year = 2000 + targets[\"header\"].str[-2:].astype(int)\ntargets[\"month\"] = pd.PeriodIndex.from_fields(year=year, month=number, freq=\"M\")\ntargets = targets.drop(columns=\"header\")\n",
      "note": "O ano pelos dois últimos caracteres, e os dois transformados num `period[M]`; o cabeçalho em texto sai."
    }
  ]
}
```

A primeira metade do arquivo é essa verificação. Se o `Total` de alguma loja discordar dos meses, o
script para e diz qual loja, porque aí ou um mês ou o total foi digitado errado, e quem cuida da
planilha precisa dizer qual. Aqui todo total concorda, então os meses derretem sozinhos, e a
tabela longa soma o próprio total da planilha:

```
ana@lab:~/clean$ python -c "from targets import targets; print(len(targets), targets['target'].sum()); print(targets.head(3).to_string(index=False)); print(targets['month'].dtype)"
72 3801000
     loja  target   month
Pinheiros   52000 2025-01
   Cambuí   14000 2025-01
 Botafogo   23000 2025-01
period[M]
```

72 linhas e R$ 3.801.000. **Conte as linhas e some os valores depois de toda mudança de
formato**: um melt tem de produzir linhas vezes colunas, e a soma não pode se mexer. Os dois
números são baratos, e juntos pegam o total perdido, uma coluna esquecida e uma loja duplicada.
