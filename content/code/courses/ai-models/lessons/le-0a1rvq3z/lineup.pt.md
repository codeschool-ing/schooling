---
title: A linha
version: 1
---

**Esta aula e as cinco seguintes são um diretório.** Cada uma descreve uma família de modelos como
ela estava no dia em que o curso foi gravado, lida nas páginas do próprio provedor onde a máquina
conseguiu alcançá-las, e na tabela do LiteLLM onde não conseguiu. Todo nome, preço e data abaixo vai
mudar. O que não deve mudar é como lê-los, que as aulas 2 a 5 ensinaram e estas aulas aplicam.

A Anthropic publica uma tabela comparativa dos modelos atuais. O `card.py` a lê da página, diz a
data em que a leu, e imprime um bloco por modelo:

```python
import datetime
import html
import re
import sys
import urllib.request

URL = "https://platform.claude.com/docs/en/about-claude/models/overview"
raw = urllib.request.urlopen(urllib.request.Request(URL, headers={"User-Agent": "curl/8.5.0"})).read().decode()
raw = re.sub(r"<script.*?</script>|<style.*?</style>", "", raw, flags=re.S)
# one line per piece of visible text, the way a reader meets it on the page
lines = [t.strip() for t in html.unescape(re.sub(r"<[^>]+>", "\n", raw)).splitlines() if t.strip()]
print(f"# {URL}, read {datetime.date.today()}")
table = lines.index("Feature")  # the comparison table starts here
names = [lines[table + 1 + 2 * k] for k in range(4)]


def row(label):
    """The cells that follow a row's label in the table: one per model, two for prices."""
    i = lines.index(label, table)
    cells = lines[i + 1:i + 1 + (8 if label == "Pricing" else 4)]
    return [" ".join(cells[k:k + 2]) for k in range(0, 8, 2)] if label == "Pricing" else cells


wanted = sys.argv[2:] if len(sys.argv) > 2 else ["Claude API ID", "Context window", "Max output"]
for k, name in enumerate(names):
    if sys.argv[1] in ("all", name):
        print(name)
        for label in wanted:
            print(f"  {label:27} {row(label)[k]}")
```

```
ana@desk:~/desk$ python card.py all "Claude API ID" "Comparative latency" Pricing
# https://platform.claude.com/docs/en/about-claude/models/overview, read 2026-10-07
Claude Fable 5.1
  Claude API ID               claude-fable-5-1
  Comparative latency         Slower
  Pricing                     $10 / input MTok $50 / output MTok
Claude Opus 5.5
  Claude API ID               claude-opus-5-5
  Comparative latency         Moderate
  Pricing                     $4 / input MTok $20 / output MTok
Claude Sonnet 5.5
  Claude API ID               claude-sonnet-5-5
  Comparative latency         Fast
  Pricing                     $2 / input MTok $10 / output MTok
Claude Haiku 4.5
  Claude API ID               claude-haiku-4-5-20251001
  Comparative latency         Fastest
  Pricing                     $1 / input MTok $5 / output MTok
```

**Quatro faixas, um nome cada**, e o formato que todo provedor grande compartilha: um modelo menor,
mais rápido e mais barato (**Haiku**), um do meio (**Sonnet**), um grande (**Opus**) e, acima deles,
o **Fable**, o mais caro e mais lento. Cada degrau custa de duas a duas vezes e meia o de baixo, na
entrada e na saída.

A tabela enxerga mais do que a página mostra:

```
ana@desk:~/desk$ python sheet.py provider anthropic | grep -v -- "-20[0-9]*  "
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
claude-fable-5                                1,000,000   128000       10       50  VFSCRP
claude-fable-5-1                              1,000,000   128000       10       50  VFSCRP
claude-haiku-4-5                                200,000    64000        1        5  VFSCRP
claude-mythos-5                               1,000,000   128000       10       50  VFSCRP
claude-mythos-5-1                             1,000,000   128000       10       50  VFSCRP
claude-mythos-preview                         1,000,000   128000       10       50  VFSCRP
claude-opus-4-5                                 200,000    64000        5       25  VFSCRP
claude-opus-4-6                               1,000,000   128000        5       25  VFSCRP
claude-opus-4-7                               1,000,000   128000        5       25  VFSCRP
claude-opus-4-8                               1,000,000   128000        5       25  VFSCRP
claude-opus-5                                 1,000,000   128000        5       25  VFSCRP
claude-opus-5-5                               1,000,000   128000        4       20  VFSCRP
claude-sonnet-4-5                             1,000,000    64000        3       15  VFSCRP
claude-sonnet-4-6                             1,000,000   128000        3       15  VFSCRP
claude-sonnet-5                               1,000,000   128000        2       10  VFSCRP
claude-sonnet-5-5                             1,000,000   128000        2       10  VFSCRP
```

(o `grep` esconde as duplicatas datadas.) Versões mais antigas do Opus e do Sonnet ainda listadas, aos
preços antigos, e entradas que a tabela comparativa nem menciona. **A página lista o que a Anthropic
recomenda agora; a tabela lista o que ainda dá para chamar.** As duas diferem, e um projeto que fixou
`claude-opus-4-6` um ano atrás ainda está na segunda lista e fora da primeira.

Leia as duas juntas para a lista curta da ana. O Haiku 4.5 é a faixa que a aula 4 precificou para
rascunho em US$ 18,72 por mês com cache; o Sonnet 5.5 custa o dobro. Os dois passaram em todos os
limites de saída estruturada e de janela que ela definiu. O que os separa para a Lantern Books são os
casos da aula 5, e uma data, que a seção 03 lê.
