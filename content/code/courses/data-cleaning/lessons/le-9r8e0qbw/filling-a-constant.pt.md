---
title: Preencher com uma constante
version: 1
---

**Uma constante é o preenchimento certo quando o significado do vazio é conhecido e é essa
constante.** O desconto vazio do site é zero, então zero não é uma estimativa; é o valor. Em
qualquer outro lugar, uma constante é um palpite que todas as linhas vão compartilhar.

A constante errada mais comum é zero para um número. Preenchendo com zero os tempos de entrega que
faltam na frota própria:

```schooling-example
{
  "language": "python",
  "file": "minutes.py",
  "parts": [
    {
      "code": "import pandas as pd\n\norders = pd.read_csv(\"raw/orders.csv\", dtype=str, keep_default_na=False,\n                     na_values=[\"\"]).drop_duplicates()\n",
      "note": "Os pedidos sem as repetições, lidos como texto."
    },
    {
      "code": "own = orders[(orders[\"courier\"] == \"propria\") & (orders[\"status\"] != \"cancelled\")].copy()\nown[\"minutes\"] = pd.to_numeric(own[\"delivery_minutes\"])\n\n\n",
      "note": "As entregas da frota própria, sem os cancelados, com o tempo como número e os vazios como `NaN`."
    },
    {
      "code": "def report(label, minutes):\n    print(f\"{label:22} mean {minutes.mean():5.1f}  sd {minutes.std():4.1f}  \"\n          f\"late {(minutes >= 90).mean() * 100:4.1f}%\")\n",
      "note": "**Uma linha por estratégia**: a média, a dispersão e a fração de atrasos, que é o que o relatório de operações lê. Os mesmos três números para todo preenchimento os tornam comparáveis."
    }
  ]
}
```

```python
from minutes import own, report

report("recorded only", own["minutes"].dropna())
report("blanks as zero", own["minutes"].fillna(0))
```

```
ana@lab:~/clean$ python fill_zero.py
recorded only          mean  59.4  sd 21.1  late 10.5%
blanks as zero         mean  57.7  sd 23.1  late 10.2%
```

A média cai de 59,4 para 57,7 minutos e a fração de atrasos de 10,5% para 10,2%. **456 entregas que
levaram duas horas ou mais agora constam como instantâneas** — o exato oposto do que aconteceu — e
todo resumo se move na direção que lisonjeia. Parece um efeito pequeno porque 456 linhas são 3% da
coluna; por linha, é o maior erro que uma estratégia conseguiria cometer.

Constantes que acertam com mais frequência:

| vazio | constante | por que está certa |
|---|---|---|
| um desconto do site | `0` | a origem escreve sem cupom como vazio |
| uma categoria que ninguém registrou | `unknown` | mantém a linha e diz com clareza o que não se sabe |
| uma contagem de eventos num período sem eventos | `0` | nenhum evento aconteceu, então a contagem é zero |

A segunda linha é a lição geral. **Para um rótulo, a constante honesta é uma palavra que diz que o
valor é desconhecido**, e um gráfico que mostra uma barra `unknown` é um gráfico dizendo a verdade
sobre o seu dado. Para um número não existe palavra assim, e é por isso que existem as marcas — o
último dos movimentos desta aula.
