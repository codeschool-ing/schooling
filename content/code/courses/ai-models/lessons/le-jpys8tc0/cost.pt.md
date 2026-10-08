---
title: Duas formas de pagar
version: 1
---

Um modelo fechado é pago **por token**, ao provedor ou a uma nuvem que o revende. Um modelo aberto
pode ser pago do mesmo jeito, a qualquer das empresas que o hospedam, ou **por hora**, por uma
máquina em que você mesmo o roda. A aula 3 trata do segundo caso. Esta seção trata de como o
primeiro fica para cada tipo, lido na tabela.

## A tabela

Cada provedor publica os preços na própria página, no próprio formato. O **LiteLLM**, uma biblioteca
de código aberto que chama cem provedores por uma interface só, guarda todos eles num arquivo JSON,
para poder dar preço às chamadas que faz. Esse arquivo é a tabela que este curso lê: uma cópia,
feita por terceiros, das páginas dos provedores. Todo número tirado dela diz isso, e ela é lida num
commit só, para que os mesmos números saiam no ano que vem. O `sheet.py` baixa o arquivo uma vez,
guarda-o ao lado de si em `~/desk`, e responde oito perguntas sobre ele:

```python
"""sheet.py: the model catalogue every number in ai-models comes from.

LiteLLM is an open-source library that calls a hundred model providers through
one interface, and to price their calls it keeps a file of every model it
knows: its window, its output ceiling, its price per token, and what it
supports. This reads that file at ONE PINNED COMMIT, so the same sheet comes
out next year, and keeps it beside the program after the first download.

    python sheet.py count                         entries per provider
    python sheet.py provider NAME [--mode chat]   one provider's models
    python sheet.py where TEXT                    every entry whose name contains TEXT
    python sheet.py show NAME                     everything the sheet says about one
    python sheet.py compare NAME...               one row per named entry, in that order
    python sheet.py cost NAME IN OUT              what IN input and OUT output tokens cost
    python sheet.py retiring [--provider P]       entries with a deprecation date, soonest first
    python sheet.py pick [--provider P] [--min-window N] [--needs a,b] [--max-in X]
                                                  filter, then sort by input price; an entry
                                                  priced 0 is left out, because the sheet
                                                  writes 0 for free AND for unknown

Prices are dollars per million tokens (MTok). Standard library only.
"""
import argparse
import json
import os
import signal
import sys
import urllib.request
from collections import Counter
from decimal import Decimal

COMMIT = "21881c571181fc0e409dd717b8a277e5b43152a7"
URL = ("https://raw.githubusercontent.com/BerriAI/litellm/" + COMMIT
       + "/model_prices_and_context_window.json")
CACHE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "litellm-%s.json" % COMMIT[:8])
FLAGS = [("vision", "V"), ("function_calling", "F"), ("response_schema", "S"),
         ("prompt_caching", "C"), ("reasoning", "R"), ("pdf_input", "P")]


def load():
    if not os.path.exists(CACHE):
        with urllib.request.urlopen(URL) as r, open(CACHE + ".part", "wb") as f:
            f.write(r.read())
        os.rename(CACHE + ".part", CACHE)
    with open(CACHE) as f:
        d = json.load(f)
    d.pop("sample_spec", None)
    return d


def mtok(per_token):
    if per_token in (None, ""):
        return "-"
    v = Decimal(str(per_token)) * 1000000
    return f"{v.normalize():f}"


def flags(e):
    return "".join(c if e.get("supports_" + k) else "." for k, c in FLAGS)


def window(e):
    n = e.get("max_input_tokens")
    return f"{n:,}" if isinstance(n, int) else "-"


def table(rows):
    """V vision, F function calling, S response schema, C prompt caching, R reasoning, P PDF input."""
    print(f"{'model':44} {'window':>10} {'max out':>8} {'in $/M':>8} {'out $/M':>8}  VFSCRP")
    for k, e in rows:
        out = e.get("max_output_tokens")
        print(f"{k[:44]:44} {window(e):>10} {out if isinstance(out, int) else '-':>8} "
              f"{mtok(e.get('input_cost_per_token')):>8} {mtok(e.get('output_cost_per_token')):>8}  {flags(e)}")


def main():
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)  # a pipe into head is not an error
    p = argparse.ArgumentParser(prog="sheet.py")
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("count")
    a = sub.add_parser("provider"); a.add_argument("name"); a.add_argument("--mode", default="chat")
    a = sub.add_parser("where"); a.add_argument("text")
    a = sub.add_parser("show"); a.add_argument("name")
    a = sub.add_parser("compare"); a.add_argument("names", nargs="+")
    a = sub.add_parser("cost"); a.add_argument("name"); a.add_argument("tin", type=int); a.add_argument("tout", type=int)
    a = sub.add_parser("retiring"); a.add_argument("--provider"); a.add_argument("--mode", default="chat")
    a = sub.add_parser("pick")
    a.add_argument("--provider"); a.add_argument("--min-window", type=int, default=0)
    a.add_argument("--needs", default=""); a.add_argument("--max-in", type=Decimal)
    a.add_argument("--top", type=int, default=12)
    args = p.parse_args()
    d = load()
    print(f"# LiteLLM model sheet at {COMMIT[:8]}, {len(d)} entries")
    if args.cmd == "count":
        c = Counter(e.get("litellm_provider") for e in d.values())
        for name, n in c.most_common(int(os.environ.get("SHEET_TOP", "15"))):
            print(f"{n:5}  {name}")
        print(f"{len(c):5}  providers in all")
    elif args.cmd == "provider":
        rows = [(k, e) for k, e in d.items()
                if e.get("litellm_provider") == args.name and e.get("mode") == args.mode]
        table(sorted(rows))
    elif args.cmd == "where":
        rows = [(k, e) for k, e in d.items() if args.text in k]
        print(f"{'entry':52} {'provider':26} {'in $/M':>8} {'out $/M':>8}")
        for k, e in sorted(rows, key=lambda r: (r[1].get("litellm_provider", ""), r[0])):
            print(f"{k[:52]:52} {e.get('litellm_provider', '')[:26]:26} "
                  f"{mtok(e.get('input_cost_per_token')):>8} {mtok(e.get('output_cost_per_token')):>8}")
    elif args.cmd == "show":
        if args.name not in d:
            sys.exit(f"sheet.py: no entry named {args.name}")
        for k, v in sorted(d[args.name].items()):
            print(f"{k:42} {v}")
    elif args.cmd == "compare":
        missing = [n for n in args.names if n not in d]
        if missing:
            sys.exit("sheet.py: no entry named " + ", ".join(missing))
        table([(n, d[n]) for n in args.names])
    elif args.cmd == "cost":
        e = d[args.name]
        cin = Decimal(str(e["input_cost_per_token"])) * args.tin
        cout = Decimal(str(e["output_cost_per_token"])) * args.tout
        print(f"{args.tin:,} in  x ${mtok(e['input_cost_per_token'])}/M = ${cin:.4f}")
        print(f"{args.tout:,} out x ${mtok(e['output_cost_per_token'])}/M = ${cout:.4f}")
        print(f"total ${cin + cout:.4f}")
    elif args.cmd == "retiring":
        rows = [(e["deprecation_date"], k, e.get("litellm_provider", "")) for k, e in d.items()
                if e.get("deprecation_date") and e.get("mode") == args.mode
                and (not args.provider or e.get("litellm_provider") == args.provider)]
        print(f"{len(rows)} entries carry a deprecation date")
        for date, k, prov in sorted(rows):
            print(f"{date}  {k[:50]:50} {prov}")
    elif args.cmd == "pick":
        needs = [n for n in args.needs.split(",") if n]
        rows = []
        for k, e in d.items():
            if e.get("mode") != "chat" or not isinstance(e.get("input_cost_per_token"), (int, float)):
                continue
            if args.provider and e.get("litellm_provider") != args.provider:
                continue
            if not e["input_cost_per_token"]:
                continue  # a price of 0 in the sheet is free or unknown, and is neither a price
            if not isinstance(e.get("max_input_tokens"), int) or e["max_input_tokens"] < args.min_window:
                continue
            if any(not e.get("supports_" + n) for n in needs):
                continue
            if args.max_in is not None and Decimal(str(e["input_cost_per_token"])) * 1000000 > args.max_in:
                continue
            rows.append((k, e))
        print(f"{len(rows)} entries pass")
        table(sorted(rows, key=lambda r: (r[1]["input_cost_per_token"], r[0]))[:args.top])


if __name__ == "__main__":
    main()
```

Ele não usa nada além da biblioteca padrão do Python, e a primeira execução demora alguns segundos a
mais enquanto baixa o arquivo. Toda tabela que ele imprime começa com o commit e o número
de entradas, então um número citado dela diz de onde veio.

O `python sheet.py where` lista toda entrada cujo nome contém uma string. Aqui está um modelo
aberto, a Llama 3.3 70B, e todos os hosts a que a tabela dá preço:

```
ana@desk:~/desk$ python sheet.py where llama-3.3-70b
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
cerebras/llama-3.3-70b                               cerebras                       0.85      1.2
cloudflare/@cf/meta/llama-3.3-70b-instruct-fp8-fast  cloudflare                    0.293    2.253
novita/meta-llama/llama-3.3-70b-instruct             novita                        0.135      0.4
oci/meta.llama-3.3-70b-instruct                      oci                            0.72     0.72
oci/meta.llama-3.3-70b-instruct-fp8-dynamic          oci                            0.72     0.72
openrouter/meta-llama/llama-3.3-70b-instruct         openrouter                     0.22      0.5
scaleway/meta/llama-3.3-70b-instruct                 scaleway                        0.9      0.9
snowflake/snowflake-llama-3.3-70b                    snowflake                      0.72     0.72
vercel_ai_gateway/meta/llama-3.3-70b                 vercel_ai_gateway              0.72     0.72
vertex_ai/meta/llama-3.3-70b-instruct-maas           vertex_ai-llama_models         0.72     0.72
```

Dez entradas de nove provedores, e o preço de entrada mais barato é **US$ 0,135** por milhão de
tokens contra **US$ 0,90** no mais caro: quase sete vezes mais pelos mesmos pesos. Os preços de
saída vão de US$ 0,40 a US$ 2,253. Parte da diferença é real: `fp8` num nome quer dizer que o host
roda os pesos com precisão reduzida, o que a aula 3 explica, e os hosts diferem em velocidade e no
que prometem de disponibilidade. Mas boa parte é **concorrência**. Qualquer um com o hardware pode
servir esses pesos, então muitos servem, e o preço cai em direção ao custo da máquina.

Agora um modelo fechado, o Claude Sonnet 5.5:

```
ana@desk:~/desk$ python sheet.py where claude-sonnet-5-5
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
claude-sonnet-5-5                                    anthropic                         2       10
azure_ai/claude-sonnet-5-5                           azure_ai                          2       10
bedrock/us-gov-east-1/anthropic.claude-sonnet-5-5    bedrock                         2.4       12
bedrock/us-gov-west-1/anthropic.claude-sonnet-5-5    bedrock                         2.4       12
anthropic.claude-sonnet-5-5                          bedrock_converse                  2       10
apac.anthropic.claude-sonnet-5-5                     bedrock_converse                2.2       11
au.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
eu.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
global.anthropic.claude-sonnet-5-5                   bedrock_converse                  2       10
jp.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
us-gov.anthropic.claude-sonnet-5-5                   bedrock_converse                2.4       12
us.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
bedrock_mantle/anthropic.claude-sonnet-5-5           bedrock_mantle                  2.2       11
bedrock_mantle/us-gov-west-1/anthropic.claude-sonnet bedrock_mantle                  2.4       12
perplexity/anthropic/claude-sonnet-5-5               perplexity                        2       10
vertex_ai/claude-sonnet-5-5                          vertex_ai-anthropic_models        2       10
vertex_ai/claude-sonnet-5-5@default                  vertex_ai-anthropic_models        2       10
```

Dezessete entradas, e todas são o modelo da Anthropic revendido, ou acessado pela API da própria
Anthropic. Os preços quase não se mexem: **US$ 2** na entrada e **US$ 10** na saída na própria
Anthropic, na Azure, no Vertex do Google e na rota `global` do Bedrock; dez por cento a mais nas
rotas regionais do Bedrock, vinte por cento a mais nas regiões do governo americano. Nenhum host
consegue cobrar menos que o autor, porque nenhum host tem nada a vender além do acesso ao modelo do
autor.

## O que isso significa para escolher

- **Um modelo aberto é uma mercadoria, e mercadoria se pesquisa.** O modelo é fixo; escolha o
  host por preço, velocidade e termos, e troque de host sem mudar uma linha do prompt. A aula 15
  mostra um roteador que faz essa pesquisa a cada requisição.
- **Um modelo fechado tem um preço**, definido por quem o fez, com pequenas diferenças regionais.
  O que se negocia é volume, não a taxa por token da página.
- **Por token nunca é a conta inteira.** É a parte que cresce com o uso. A aula 4 soma as outras
  partes, e a aula 21 as que só aparecem quando algo dá errado.

A tabela é uma cópia de terceiros tirada num commit, e as duas listas vão ter mudado quando você ler
isto. **O formato é o que dura**: muitos hosts e uma faixa larga para pesos abertos, um autor e uma
faixa estreita para os fechados.
