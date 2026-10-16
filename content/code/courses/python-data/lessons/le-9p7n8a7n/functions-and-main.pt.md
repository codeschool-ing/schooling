---
title: Funções, e um main
version: 1
---

**Um script que vale guardar são algumas funções, cada uma fazendo um passo com o que recebe, e um
`main` que as junta.** As células do notebook viram as funções; as variáveis no topo de uma célula,
`station = "S05"`, viram argumentos; e nada depende da ordem em que alguém rodou as coisas, porque só
há uma ordem, a ordem em que o arquivo está escrito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"As quatro células do notebook, à esquerda, viram as partes do script, à direita. Os imports continuam imports; ler o arquivo vira load; as contagens da estação viram per_month, com a estação como argumento; a célula do gráfico vira chart. Um main novo lê a linha de comando e as chama em ordem.\" data-fig=\"refactor\"><defs><marker id=\"refactor-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"130\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">stations.ipynb</text><text x=\"560\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">station_report.py</text><text x=\"20\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[1]</text><rect x=\"50\" y=\"40\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">import pandas …</text><line x1=\"234\" y1=\"56\" x2=\"396\" y2=\"56\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#refactor-ah)\"></line><rect x=\"400\" y=\"40\" width=\"300\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">import pandas …</text><text x=\"20\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[2]</text><rect x=\"50\" y=\"86\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">%time trips = …</text><line x1=\"234\" y1=\"102\" x2=\"396\" y2=\"102\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#refactor-ah)\"></line><rect x=\"400\" y=\"86\" width=\"300\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">def load(path)</text><text x=\"20\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[3]</text><rect x=\"50\" y=\"132\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">station = &quot;S05&quot; …</text><line x1=\"234\" y1=\"148\" x2=\"396\" y2=\"148\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#refactor-ah)\"></line><rect x=\"400\" y=\"132\" width=\"300\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">def per_month(trips, station)</text><text x=\"20\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[4]</text><rect x=\"50\" y=\"178\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fig, ax = …</text><line x1=\"234\" y1=\"194\" x2=\"396\" y2=\"194\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#refactor-ah)\"></line><rect x=\"400\" y=\"178\" width=\"300\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">def chart(counts, station, out)</text><rect x=\"400\" y=\"230\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">def main(): argparse, e cada um em ordem</text><text x=\"140\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rodadas em qualquer ordem, à mão</text></svg>", "caption": "Cada célula vira uma função com as entradas nomeadas; o main as junta, e o argparse fornece o que uma célula deixava fixo no código."}
```

Salve isto como `station_report.py` em `pydata`, ao lado dos dados. No JupyterLab, o botão **Python
File** do lançador abre um vazio, como para o `make_data.py` na aula 1:

```schooling-example
{
  "language": "python",
  "file": "station_report.py",
  "parts": [
    {
      "code": "\"\"\"Trips per month from one station of Maré Bikes, as a table and a chart.\"\"\"\nimport argparse\nimport sys\nfrom pathlib import Path\n\nimport matplotlib.pyplot as plt\nimport pandas as pd\n\nHERE = Path(__file__).parent\n",
      "note": "A docstring diz para que serve o script, na primeira linha que qualquer um que o abrir lê. `HERE` é a pasta onde o script mora, de qualquer pasta que ele seja rodado; a última seção desta aula é sobre por que isso importa."
    },
    {
      "code": "\n\ndef load(path):\n    return pd.read_csv(path, parse_dates=[\"started_at\"], date_format=\"%Y-%m-%d %H:%M:%S\")\n\n\ndef per_month(trips, station):\n    mine = trips[trips[\"start_station\"] == station]\n    return mine.groupby(mine[\"started_at\"].dt.month).size()\n",
      "note": "Cada passo do notebook vira uma função que recebe o que precisa como argumentos e devolve o resultado. Nada nelas lê uma variável definida em outro lugar, o que torna impossível o estado escondido da aula 2."
    },
    {
      "code": "\n\ndef chart(counts, station, out):\n    fig, ax = plt.subplots(layout=\"constrained\")\n    ax.bar(counts.index, counts.to_numpy())\n    ax.set_title(f\"Trips from {station}, 2025\")\n    ax.set_xlabel(\"month\")\n    ax.set_ylabel(\"trips\")\n    fig.savefig(out)\n    plt.close(fig)\n",
      "note": "O gráfico é salvo e fechado, como a aula 18 disse que uma figura num script precisa ser. Um script não tem célula que termine e a exiba."
    },
    {
      "code": "\n\ndef main():\n    parser = argparse.ArgumentParser(description=\"Trips per month from one station of Maré Bikes.\")\n    parser.add_argument(\"station\", help=\"a station code, such as S05\")\n    parser.add_argument(\"--data\", type=Path, default=HERE / \"trips.csv\",\n                        help=\"the trips file (default: trips.csv beside this script)\")\n    parser.add_argument(\"--out\", type=Path, help=\"where to save the chart (default: STATION.png)\")\n    args = parser.parse_args()\n",
      "note": "O `argparse` transforma as palavras digitadas depois do nome do script em `args`: `args.station`, `args.data`, `args.out`. O que era uma variável no topo de uma célula do notebook agora é algo que quem roda o script escolhe."
    },
    {
      "code": "\n    trips = load(args.data)\n    if args.station not in set(trips[\"start_station\"]):\n        sys.exit(f\"no trips from station {args.station!r}\")\n    counts = per_month(trips, args.station)\n    print(counts.to_string())\n    out = args.out or Path(f\"{args.station}.png\")\n    chart(counts, args.station, out)\n    print(f\"saved {out}\")\n",
      "note": "O `main` só junta os passos. Uma estação que não existe para o script com uma mensagem e um status de falha, em vez de um gráfico de nada; o `print` diz o que um notebook teria mostrado sozinho."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    main()\n",
      "note": "O `main()` só roda quando o arquivo é executado como programa. Quando outro arquivo ou um notebook o importa, `__name__` é o nome do módulo, e as funções ficam disponíveis sem nada rodar."
    }
  ]
}
```

As funções são os passos do notebook com as entradas nomeadas. `load` recebe um caminho, `per_month`
recebe uma tabela e uma estação, `chart` recebe contagens, uma estação e um arquivo para gravar. Cada
uma poderia ser testada sozinha, e cada uma pode ser usada de outro lugar.

Esse último ponto é o que as duas linhas no fim compram. Importar o arquivo roda tudo o que está no
nível de cima, os imports e as definições das funções, e para antes do `main()`:

```
(.venv) ana@lab:~/pydata$ python -c 'from station_report import load, per_month; print(per_month(load("trips.csv"), "S12").sum())'
847
(.venv) ana@lab:~/pydata$ ls S12.png
ls: cannot access 'S12.png': No such file or directory
```

O `per_month` rodou para uma estação sobre a qual o script nunca foi perguntado, e nenhum gráfico foi
salvo, porque o `main` não rodou. Um notebook pode usar as funções do script do mesmo jeito,
`from station_report import load, per_month`, então o cálculo mora num lugar só e tanto o notebook
quanto o script o leem de lá. **Código que os dois usam pertence ao arquivo, não a uma cópia no
notebook.**
