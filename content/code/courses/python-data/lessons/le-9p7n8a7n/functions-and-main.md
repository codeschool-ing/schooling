---
title: Functions, and a main
version: 1
---

**A script worth keeping is a few functions, each doing one step with what it is given, and a `main`
that joins them.** The notebook's cells become the functions; the variables at the top of a cell,
`station = "S05"`, become arguments; and nothing depends on the order somebody ran things in, because
there is only one order, the one the file is written in.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"The notebook&#x27;s four cells on the left become the script&#x27;s parts on the right. The imports stay imports; reading the file becomes load; the station&#x27;s counts become per_month, with the station as an argument; the chart cell becomes chart. A new main reads the command line and calls them in order.\" data-fig=\"refactor\"><defs><marker id=\"refactor-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"130\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">stations.ipynb</text><text x=\"560\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">station_report.py</text><text x=\"20\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[1]</text><rect x=\"50\" y=\"40\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">import pandas …</text><line x1=\"234\" y1=\"56\" x2=\"396\" y2=\"56\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#refactor-ah)\"></line><rect x=\"400\" y=\"40\" width=\"300\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">import pandas …</text><text x=\"20\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[2]</text><rect x=\"50\" y=\"86\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">%time trips = …</text><line x1=\"234\" y1=\"102\" x2=\"396\" y2=\"102\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#refactor-ah)\"></line><rect x=\"400\" y=\"86\" width=\"300\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">def load(path)</text><text x=\"20\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[3]</text><rect x=\"50\" y=\"132\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">station = &quot;S05&quot; …</text><line x1=\"234\" y1=\"148\" x2=\"396\" y2=\"148\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#refactor-ah)\"></line><rect x=\"400\" y=\"132\" width=\"300\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">def per_month(trips, station)</text><text x=\"20\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[4]</text><rect x=\"50\" y=\"178\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fig, ax = …</text><line x1=\"234\" y1=\"194\" x2=\"396\" y2=\"194\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#refactor-ah)\"></line><rect x=\"400\" y=\"178\" width=\"300\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">def chart(counts, station, out)</text><rect x=\"400\" y=\"230\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">def main(): argparse, then each in order</text><text x=\"140\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">run in any order, by hand</text></svg>", "caption": "Each cell becomes a function with its inputs named; main joins them, and argparse supplies what a cell used to hard-code."}
```

Save this as `station_report.py` in `pydata`, beside the data. In JupyterLab, the launcher's **Python
File** opens an empty one, as for `make_data.py` in lesson 1:

```schooling-example
{
  "language": "python",
  "file": "station_report.py",
  "parts": [
    {
      "code": "\"\"\"Trips per month from one station of Maré Bikes, as a table and a chart.\"\"\"\nimport argparse\nimport sys\nfrom pathlib import Path\n\nimport matplotlib.pyplot as plt\nimport pandas as pd\n\nHERE = Path(__file__).parent\n",
      "note": "The docstring says what the script is for, in the first line anyone opening it reads. `HERE` is the folder the script lives in, whatever folder it is run from; the last section of this lesson is about why that matters."
    },
    {
      "code": "\n\ndef load(path):\n    return pd.read_csv(path, parse_dates=[\"started_at\"], date_format=\"%Y-%m-%d %H:%M:%S\")\n\n\ndef per_month(trips, station):\n    mine = trips[trips[\"start_station\"] == station]\n    return mine.groupby(mine[\"started_at\"].dt.month).size()\n",
      "note": "Each step of the notebook becomes a function that takes what it needs as arguments and returns its result. Nothing in them reads a variable defined somewhere else, which is the hidden state of lesson 2 made impossible."
    },
    {
      "code": "\n\ndef chart(counts, station, out):\n    fig, ax = plt.subplots(layout=\"constrained\")\n    ax.bar(counts.index, counts.to_numpy())\n    ax.set_title(f\"Trips from {station}, 2025\")\n    ax.set_xlabel(\"month\")\n    ax.set_ylabel(\"trips\")\n    fig.savefig(out)\n    plt.close(fig)\n",
      "note": "The chart is saved and closed, as lesson 18 said a figure in a script must be. A script has no cell to end and display it."
    },
    {
      "code": "\n\ndef main():\n    parser = argparse.ArgumentParser(description=\"Trips per month from one station of Maré Bikes.\")\n    parser.add_argument(\"station\", help=\"a station code, such as S05\")\n    parser.add_argument(\"--data\", type=Path, default=HERE / \"trips.csv\",\n                        help=\"the trips file (default: trips.csv beside this script)\")\n    parser.add_argument(\"--out\", type=Path, help=\"where to save the chart (default: STATION.png)\")\n    args = parser.parse_args()\n",
      "note": "`argparse` turns the words typed after the script's name into `args`: `args.station`, `args.data`, `args.out`. What was a variable at the top of a notebook cell is now something the person running the script chooses."
    },
    {
      "code": "\n    trips = load(args.data)\n    if args.station not in set(trips[\"start_station\"]):\n        sys.exit(f\"no trips from station {args.station!r}\")\n    counts = per_month(trips, args.station)\n    print(counts.to_string())\n    out = args.out or Path(f\"{args.station}.png\")\n    chart(counts, args.station, out)\n    print(f\"saved {out}\")\n",
      "note": "`main` only joins the steps. A station that does not exist stops the script with a message and a failure status, instead of a chart of nothing; `print` says what a notebook would have shown by itself."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    main()\n",
      "note": "`main()` runs only when the file is run as a program. When another file or a notebook imports it, `__name__` is the module's name instead, and the functions are there to use without anything running."
    }
  ]
}
```

The functions are the notebook's steps with their inputs named. `load` takes a path, `per_month` takes
a table and a station, `chart` takes counts, a station and a file to write. Each could be tested
alone, and each can be used from somewhere else.

That last point is what the two lines at the bottom buy. Importing the file runs everything at its top
level, the imports and the function definitions, and stops before `main()`:

```
(.venv) ana@lab:~/pydata$ python -c 'from station_report import load, per_month; print(per_month(load("trips.csv"), "S12").sum())'
847
(.venv) ana@lab:~/pydata$ ls S12.png
ls: cannot access 'S12.png': No such file or directory
```

`per_month` ran on a station the script was never asked about, and no chart was saved, because
`main` did not run. A notebook can use the script's functions the same way, `from station_report import
load, per_month`, so the calculation lives in one place and both the notebook and the script read it
there. **Code that both use belongs in the file, not copied into the notebook.**
