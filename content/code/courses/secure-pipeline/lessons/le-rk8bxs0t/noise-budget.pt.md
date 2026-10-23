---
title: O orçamento de ruído
version: 1
---

Toda proposta que um bot faz custa a uma pessoa um pouco de atenção: abrir o pull request, ler o que
mudou, olhar o pipeline, decidir. **Um time tem uma quantidade fixa dessa atenção, e um bot
configurado sem levá-la em conta gasta toda ela**, depois do que os pull requests entram sem ser lidos
ou se acumulam. Os dois desfechos são piores que nenhum bot: o primeiro aceita o que ninguém julgou, e
o segundo ensina a todos que os pull requests do bot são ruído, inclusive o que corrige um aviso. É a
fadiga de alertas da aula 7, chegando como pull requests em vez de builds quebrados.

Então, antes de ligar um bot, conte. A contagem que importa é quantas propostas uma configuração teria
feito ao longo de um ano real, e o índice de pacotes tem os dados.

### Contando um ano de versões

Este programa pergunta ao PyPI quando cada pacote fixado publicou cada versão, e conta as versões no
ano anterior a uma data. Depois conta o que três configurações teriam aberto: um pull request por
versão, um por semana que teve versão e um por mês. Salve-o como `~/releases.py`:

```python
"""How many releases each pinned dependency published in the year before a
date, and how many pull requests a bot would have opened for them: one per
release, one per week with a release, or one per month with a release.

    python3 ~/releases.py 2026-10-16 requirements.txt requirements-dev.txt

Versions with a letter in them (alphas, betas, release candidates, post
releases) are left out, as the bots leave them out by default.
"""
import datetime
import json
import re
import sys
import urllib.request


def pinned(paths):
    for path in paths:
        for line in open(path):
            found = re.match(r"([A-Za-z0-9_.-]+)==", line)
            if found:
                yield found.group(1).lower()


def release_days(name, start, end):
    with urllib.request.urlopen(f"https://pypi.org/pypi/{name}/json") as answer:
        releases = json.load(answer)["releases"]
    for version, files in releases.items():
        days = [f["upload_time_iso_8601"][:10] for f in files if not f["yanked"]]
        if days and not re.search(r"[a-z]", version) and start < min(days) <= end:
            yield datetime.date.fromisoformat(min(days))


end = datetime.date.fromisoformat(sys.argv[1])
start = (end - datetime.timedelta(days=365)).isoformat()
every = []
for name in sorted(set(pinned(sys.argv[2:]))):
    days = list(release_days(name, start, end.isoformat()))
    every += days
    print(f"{name:16} {len(days):3}")
weeks = {day.isocalendar()[:2] for day in every}
months = {(day.year, day.month) for day in every}
print(f"{'one per release':16} {len(every):3}")
print(f"{'one per week':16} {len(weeks):3}")
print(f"{'one per month':16} {len(months):3}")
```

Ele lê os nomes dos pacotes nos arquivos de requisitos, então conta as dependências do próprio
linkbox, diretas e transitivas juntas, porque um bot propõe atualizações para todo pin do lock. Rode-o
para o ano que termina na data em que o lock foi compilado:

```
ana@vm:~/linkbox$ git switch -q main
ana@vm:~/linkbox$ python3 ~/releases.py 2026-10-16 requirements.txt requirements-dev.txt
blinker            0
click              7
flask              1
gunicorn          13
iniconfig          3
itsdangerous       0
jinja2             0
markupsafe         1
packaging          4
pluggy             1
pygments           2
pytest             6
werkzeug           6
one per release   44
one per week      29
one per month     12
```

### Lendo a contagem

O linkbox tem 13 pacotes fixados e 3 dependências diretas, e a contagem é por ano:

- Um pull request por versão teria dado 44 deles, quase um por semana, cada um chegando
  quando a versão chegasse.
- Agrupadas por semana, as mesmas versões cabem em 29 pull requests: esse foi o número de
  semanas do ano com pelo menos uma versão.
- Agrupadas por mês, 12: nenhum mês daquele ano passou sem uma versão.

A distribuição é desigual, o que é típico. Só o gunicorn lançou 13 versões; três pacotes
não lançaram nada. Um agrupamento por semana carrega, portanto, uma atualização do gunicorn numa boa
parte dos pull requests, o que é motivo para ler o changelog do gunicorn uma vez por mês, e não para
pulá-lo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 316\" role=\"img\" data-fig=\"sp-l18-releases\" aria-label=\"Versões no ano até 16 de outubro de 2026 de cada pacote que o linkbox fixa: blinker 0, click 7, flask 1, gunicorn 13, iniconfig 3, itsdangerous 0, jinja2 0, markupsafe 1, packaging 4, pluggy 1, pygments 2, pytest 6, werkzeug 6. 44 ao todo.\"><defs></defs><text x=\"120\" y=\"24\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">blinker</text><text x=\"138.0\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"120\" y=\"46\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">click</text><rect x=\"130\" y=\"38\" width=\"269.2307692307692\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"407.2307692307692\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><text x=\"120\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">flask</text><rect x=\"130\" y=\"60\" width=\"38.46153846153846\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"176.46153846153845\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><text x=\"120\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">gunicorn</text><rect x=\"130\" y=\"82\" width=\"500.0\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"638.0\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">13</text><text x=\"120\" y=\"112\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">iniconfig</text><rect x=\"130\" y=\"104\" width=\"115.38461538461539\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"253.3846153846154\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><text x=\"120\" y=\"134\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">itsdangerous</text><text x=\"138.0\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"120\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">jinja2</text><text x=\"138.0\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"120\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">markupsafe</text><rect x=\"130\" y=\"170\" width=\"38.46153846153846\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"176.46153846153845\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><text x=\"120\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">packaging</text><rect x=\"130\" y=\"192\" width=\"153.84615384615384\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"291.8461538461538\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><text x=\"120\" y=\"222\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pluggy</text><rect x=\"130\" y=\"214\" width=\"38.46153846153846\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"176.46153846153845\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><text x=\"120\" y=\"244\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pygments</text><rect x=\"130\" y=\"236\" width=\"76.92307692307692\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"214.9230769230769\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><text x=\"120\" y=\"266\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pytest</text><rect x=\"130\" y=\"258\" width=\"230.76923076923077\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"368.7692307692308\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><text x=\"120\" y=\"288\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">werkzeug</text><rect x=\"130\" y=\"280\" width=\"230.76923076923077\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"368.7692307692308\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text></svg>", "caption": "44 versões num ano, de treze pins, 13 delas de um pacote só, e nenhuma de três."}
```

Um serviço Flask pequeno é o caso fácil. A mesma conta para um serviço com duzentas dependências
transitivas, algumas imagens base e uma dúzia de actions multiplica o primeiro número por dez ou mais,
e é o agrupamento que torna um bot suportável ali. As outras contagens que este programa deixa de fora
apontam na mesma direção: as duas imagens base e as actions do linkbox somariam as atualizações delas
na mesma segunda-feira.

### Definindo o orçamento

Vire a conta ao contrário e pergunte o que o time consegue ler. Se uma pessoa pode dar aos pull
requests do bot uma hora na segunda, e uma revisão cuidadosa de uma atualização agrupada com pipeline
verde leva de dez a quinze minutos, o orçamento é de uns quatro pull requests por semana. A
configuração deve caber nisso, e a do linkbox cabe: um grupo Python, um grupo de actions, as imagens
base à parte e no máximo três abertos de cada vez, para que uma semana perdida não vire uma fila de
oito.

Três regras mantêm o orçamento honesto à medida que o projeto cresce:

1. Meça a produção do próprio bot: quantos pull requests dele foram aceitos, fechados ou deixados
   abertos por mais de uma semana, a cada mês. Um número crescente de abertos é o bot deixando de ser
   lido, e aparece muito antes de alguém admitir.
2. Corte o ruído, nunca as atualizações de segurança. Se o orçamento estourar, agrupe mais, alongue a
   agenda ou pare de propor atualizações minor de ferramentas de teste. As atualizações movidas por
   avisos continuam imediatas e sem grupo, porque são o motivo de o bot existir.
3. **Menos dependências é o orçamento mais barato.** O terceiro movimento da aula 15, substituir uma
   dependência, também remove todo pull request futuro sobre ela. Um pacote que lança uma dúzia de
   versões por ano e te dá uma função são uma dúzia de interrupções por ano por uma função.

A aula 20 transforma contagens como estas nas medidas que um time relata, e pergunta o que cada uma
esconde.
