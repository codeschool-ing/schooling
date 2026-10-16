---
title: Um orçamento para a página
version: 1
---

A aula 10 mediu duas páginas e leu os números a olho. Isso funciona uma vez. **Um orçamento de
desempenho é a mesma leitura escrita de antemão**: um limite para cada número que importa,
combinado antes da próxima mudança, para um relatório poder ser conferido contra ele por um
programa e não por quem por acaso olhar. Um orçamento transforma "a página ficou mais lenta" de
opinião numa linha que diz `OVER`.

**O erro comum é orçar a nota.** Uma nota 0,9 é uma mistura de cinco métricas, então ela pode ficar
parada enquanto uma delas cruza o limite, e ninguém consegue dizer qual mudança comprou a queda.
Orce o que o requisito nomeia, e aquilo sobre o que um desenvolvedor consegue agir:

| tipo | exemplos | por que está no orçamento |
|---|---|---|
| **tempos** | LCP, CLS, TBT | são o requisito, ou o substituto de laboratório dele |
| **peso** | bytes de JavaScript, bytes de imagens, bytes no total | são o que uma mudança acrescenta, visível no diff que acrescenta |
| **contagens** | requisições | cada uma custa uma ida e volta numa rede lenta |

Os tempos dizem se a página está boa o bastante. **Os pesos dizem por que ela deixou de estar**,
e eles se mexem no momento em que alguém acrescenta uma biblioteca ou uma imagem, muito antes de
alguém cronometrar um celular. Também são mais estáveis: os bytes de imagem de uma página são os
mesmos em toda execução, enquanto o LCP dela se mexe um pouco a cada vez.

## O Lighthouse 13 não tem orçamento próprio

Versões antigas do Lighthouse aceitavam um arquivo de orçamento com a flag `--budget-path`. Antes
de escrever um, confira o que a versão instalada oferece:

```
ana@nft:~/boxoffice$ lighthouse --help | grep -ci budget
0
ana@nft:~/boxoffice$ lighthouse --list-all-audits | grep -ci budget
0
```

Nem as flags nem a lista de auditorias citam orçamento, então na 13.5.0 a checagem fica por sua
conta. São poucas linhas, porque o relatório já guarda todos os números.

## A checagem

O `perf/budget.py` guarda o orçamento e a checagem juntos. Crie o diretório com
`mkdir -p ~/boxoffice/perf`, depois `nano perf/budget.py`:

```schooling-example
{"language": "python", "file": "boxoffice/perf/budget.py", "parts": [{"code": "# boxoffice/perf/budget.py\n# The page's performance budget, and the check that holds a page to it.\n# Give it several Lighthouse reports of the same page: every number is the\n# median of them. Exits 1 when anything is over budget.\nimport json, statistics, sys\n\nBUDGET = {                               # milliseconds, bytes or a count\n    \"largest-contentful-paint\": 2500,\n    \"cumulative-layout-shift\": 0.1,      # no unit\n    \"total-blocking-time\": 200,\n    \"script bytes\": 50_000,\n    \"image bytes\": 200_000,\n    \"total bytes\": 400_000,\n    \"total requests\": 15,\n}\n", "note": "O orçamento é uma tabela no alto do arquivo, uma linha por número, e é ali que uma equipe discute sobre ele: mudar um orçamento é mudar este arquivo, revisado como qualquer outro. Os nomes são os que o relatório usa, então a checagem não precisa de tabela de tradução."}, {"code": "def measured(report):\n    audits = report[\"audits\"]\n    seen = {}\n    for name in (\"largest-contentful-paint\", \"cumulative-layout-shift\",\n                 \"total-blocking-time\"):\n        seen[name] = audits[name][\"numericValue\"]\n    for row in audits[\"resource-summary\"][\"details\"][\"items\"]:\n        seen[row[\"resourceType\"] + \" bytes\"] = row[\"transferSize\"]\n        seen[row[\"resourceType\"] + \" requests\"] = row[\"requestCount\"]\n    return seen\n", "note": "`measured` lê um relatório. Os três tempos vêm do `numericValue` de cada auditoria, em milissegundos (o CLS não tem unidade). Os bytes e as contagens vêm de `resource-summary`, uma linha por tipo de recurso, a auditoria que a aula 10 leu com o `jq`."}, {"code": "if len(sys.argv) < 2:\n    sys.exit(\"usage: python3 perf/budget.py REPORT.json [REPORT.json ...]\")\nruns = [measured(json.load(open(path))) for path in sys.argv[1:]]\n", "note": "Cada argumento é um relatório, e precisa haver pelo menos um. Uma checagem chamada sem nada para checar diz isso e reprova, em vez de imprimir uma tabela vazia e passar."}, {"code": "over = 0\nfor name, limit in BUDGET.items():\n    value = statistics.median(run[name] for run in runs)\n    verdict = \"ok\" if value <= limit else \"OVER\"\n    over += verdict == \"OVER\"\n    shown = f\"{value:,.0f}\" if value >= 10 or value == int(value) else f\"{value:.3f}\"\n    print(f\"{name:26} {shown:>12} {limit:>10,}  {verdict}\")\nprint(f\"{len(runs)} runs, {over} over budget\")\nsys.exit(1 if over else 0)", "note": "Para cada linha do orçamento, a mediana entre os relatórios, comparada com o limite. O código de saída é o veredito: 0 quando tudo cabe, 1 quando qualquer coisa passa. É toda a interface de que um pipeline precisa."}]}
```

Os limites são os valores bons das Core Web Vitals para os tempos, e para os pesos um número que
deixa espaço para a página corrigida e nenhum para a imagem da lenta. Os seus números viriam das
suas páginas: quanto elas pesam hoje, e quanto o requisito permite.

Rode o Lighthouse uma vez em cada página da aula 10 e depois a checagem em cada relatório. O
servidor roda no primeiro terminal, como antes:

```
ana@nft:~/boxoffice$ lighthouse http://127.0.0.1:8000/ --quiet --only-categories=performance --output=json --chrome-flags="--headless=new --no-sandbox" --output-path=slow.json
ana@nft:~/boxoffice$ python3 perf/budget.py slow.json; echo "exit $?"
largest-contentful-paint         12,902      2,500  OVER
cumulative-layout-shift           0.139        0.1  OVER
total-blocking-time               1,474        200  OVER
script bytes                        405     50,000  ok
image bytes                   2,431,681    200,000  OVER
total bytes                   2,435,282    400,000  OVER
total requests                        4         15  ok
1 runs, 5 over budget
exit 1
```

```
ana@nft:~/boxoffice$ lighthouse http://127.0.0.1:8000/fast.html --quiet --only-categories=performance --output=json --chrome-flags="--headless=new --no-sandbox" --output-path=fast.json
ana@nft:~/boxoffice$ python3 perf/budget.py fast.json; echo "exit $?"
largest-contentful-paint            915      2,500  ok
cumulative-layout-shift               0        0.1  ok
total-blocking-time                   0        200  ok
script bytes                          0     50,000  ok
image bytes                      20,563    200,000  ok
total bytes                      23,467    400,000  ok
total requests                        3         15  ok
1 runs, 0 over budget
exit 0
```

**Cinco linhas acima na página lenta e nenhuma na corrigida, e o código de saída diz a mesma
coisa**: 1 e 0. O `total requests` da página lenta, 4 contra 15, está dentro do orçamento, o que
lembra que um orçamento só pega o que ele nomeia. Um relatório por página basta para mostrar a
checagem funcionando; as próximas seções dizem por que um portão precisa de mais de um.
