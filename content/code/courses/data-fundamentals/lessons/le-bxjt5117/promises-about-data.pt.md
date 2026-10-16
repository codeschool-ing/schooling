---
title: Promessas sobre dados, e como medi-las
version: 1
---

**"O dado está atualizado?" não tem resposta útil até alguém dizer quão velho é velho demais, com que
frequência, e para quem isso foi prometido.** Três termos carregam essa ideia, emprestados do livro
*Site Reliability Engineering* (2016), do Google, onde descrevem serviços; times de dados os usam para
tabelas. O erro comum é tratá-los como uma coisa só. São três, e cada um se apoia no anterior.

- Um **SLI**, *indicador* de nível de serviço, é uma medida: a idade da viagem mais recente nas tabelas
  às 09:00.
- Um **SLO**, *objetivo* de nível de serviço, é uma meta que o time define para si sobre essa medida:
  no máximo duas horas, em 95% das manhãs.
- Um **SLA**, *acordo* de nível de serviço, é uma promessa a alguém de fora do time, com uma
  consequência quando é quebrada. A Roda Livre compartilha os dados de viagens com o órgão de
  transporte da prefeitura, e o contrato diz que os dados têm no máximo quatro horas às 09:00, com um
  desconto na mensalidade para cada manhã em que não tiverem.

O objetivo é de propósito mais apertado que o acordo. **Estourar o SLO é o time ficando sabendo do
problema enquanto a promessa lá fora ainda está sendo cumprida**, e isso é tempo para consertar antes
que qualquer outra pessoa perceba.

Para dados, dois indicadores cobrem quase tudo o que importa a quem lê. **Atualidade** é a idade do
dado mais recente. **Completude** é se tudo chegou: as viagens de ontem contadas nas tabelas contra a
contagem que a fonte informa. A aula 7 faz essa conciliação. Esta seção mede a primeira.

## Medindo a atualidade

Cada aula daqui em diante trabalha num diretório próprio; o desta é `~/roda/choose`:

```sh
mkdir -p ~/roda/choose
cd ~/roda/choose
```

Cada fonte da Roda Livre chega como um arquivo, e a hora de modificação de um arquivo diz quando ele
chegou pela última vez. O programa abaixo cria quatro arquivos assim, com horas conhecidas, e depois os
confere como um job de monitoramento faria. Salve como `freshness.py`:

```schooling-example
{"language": "python", "file": "choose/freshness.py", "parts": [
{"code": "# choose/freshness.py\nimport os\nfrom datetime import datetime, timedelta\nfrom zoneinfo import ZoneInfo\n\nSP = ZoneInfo(\"America/Sao_Paulo\")\nNOW = datetime(2025, 10, 6, 9, 0, tzinfo=SP)\nSLO = timedelta(hours=2)\n", "note": "O objetivo, e o momento em que ele é conferido. Uma verificação de verdade pediria `datetime.now(SP)`; esta fica fixa às 09:00 de segunda, 6 de outubro de 2025, quando Marta abre o relatório, para a sua saída bater com a de baixo."},
{"code": "\nLANDED = {\n    \"rides.csv\": datetime(2025, 10, 6, 8, 40, tzinfo=SP),\n    \"docks.csv\": datetime(2025, 10, 6, 7, 5, tzinfo=SP),\n    \"payments.csv\": datetime(2025, 10, 6, 6, 50, tzinfo=SP),\n    \"repairs.csv\": datetime(2025, 10, 3, 17, 30, tzinfo=SP),\n}\nos.makedirs(\"landing\", exist_ok=True)\nfor name, when in LANDED.items():\n    path = os.path.join(\"landing\", name)\n    open(path, \"w\").close()\n    os.utime(path, (when.timestamp(), when.timestamp()))\n", "note": "O substituto de quatro fontes. Cada arquivo está vazio; o que importa é a hora de modificação, que `os.utime` ajusta para o momento em que aquela fonte chegou pela última vez. A planilha de consertos foi salva pela última vez na sexta à tarde."},
{"code": "\nprint(f\"checked {NOW:%a %d/%m %H:%M}, objective: at most {SLO}\")\nfor name in sorted(os.listdir(\"landing\")):\n    mtime = os.path.getmtime(os.path.join(\"landing\", name))\n    landed = datetime.fromtimestamp(mtime, SP)\n    age = NOW - landed\n    status = \"ok\" if age <= SLO else \"BREACH\"\n    hours = age.total_seconds() / 3600\n    print(f\"  {name:13} landed {landed:%a %H:%M}  {hours:5.1f} h  {status}\")\n", "note": "A verificação em si, que não sabe nada dos arquivos além do nome e da hora. A idade é o indicador, medido; compará-la com duas horas é o objetivo."}
]}
```

Rode, e olhe os arquivos que ele criou:

```
ana@lab:~/roda/choose$ python freshness.py
checked Mon 06/10 09:00, objective: at most 2:00:00
  docks.csv     landed Mon 07:05    1.9 h  ok
  payments.csv  landed Mon 06:50    2.2 h  BREACH
  repairs.csv   landed Fri 17:30   63.5 h  BREACH
  rides.csv     landed Mon 08:40    0.3 h  ok
ana@lab:~/roda/choose$ ls -l --time-style=long-iso landing
total 0
-rw-r--r-- 1 ana ana 0 2025-10-06 07:05 docks.csv
-rw-r--r-- 1 ana ana 0 2025-10-06 06:50 payments.csv
-rw-r--r-- 1 ana ana 0 2025-10-03 17:30 repairs.csv
-rw-r--r-- 1 ana ana 0 2025-10-06 08:40 rides.csv
```

Duas violações, e elas querem dizer coisas diferentes. **Pagamentos é uma violação de verdade**: a
exportação que deveria chegar toda hora chegou pela última vez às 06:50, então às 09:00 o dado mais
recente tinha 2,2 horas. Alguém deveria olhar o job de pagamentos agora, antes que o relatório de Marta
mostre uma manhã sem receita.

**Consertos é um objetivo errado.** Os mecânicos salvam a planilha na sexta à tarde, então na segunda
de manhã ela sempre tem uns dois dias e meio. Uma verificação que a acusa toda segunda é uma
verificação que ensina o time a ignorá-la. A correção não está na fonte. Cada fonte precisa do seu
próprio objetivo, definido pelo que os seus leitores precisam: duas horas para viagens, uma semana
para consertos.

## De uma manhã para um mês

Uma verificação diz se esta manhã foi boa. O **indicador** que importa para um objetivo como "95% das
manhãs" é uma proporção ao longo de um período. Este programa simula a exportação de viagens durante
setembro: ela chega aos quarenta minutos de cada hora, e em algumas manhãs uma execução falha e o dado
das 09:00 está mais velho. Salve como `month.py`:

```python
# choose/month.py
import random
from datetime import date, timedelta

rng = random.Random(9)
OBJECTIVE = 0.95              # within the SLO on 95% of mornings

fresh, breaches = 0, []
for n in range(30):
    day = date(2025, 9, 1) + timedelta(days=n)
    failed = 0                # hourly exports that failed before 09:00
    if rng.random() < 0.15:
        failed = rng.randint(1, 4)
    age = 20 + 60 * failed    # minutes since the last export landed
    if age <= 120:
        fresh += 1
    else:
        breaches.append(f"{day:%d/%m} ({age // 60}h{age % 60:02d})")

sli = fresh / 30
print(f"SLI: {fresh} of 30 mornings fresh = {sli:.1%}")
print(f"objective {OBJECTIVE:.0%}:", "met" if sli >= OBJECTIVE else "MISSED")
print("breaches:", ", ".join(breaches) or "none")
```

Rode:

```
ana@lab:~/roda/choose$ python month.py
SLI: 28 of 30 mornings fresh = 93.3%
objective 95%: MISSED
breaches: 16/09 (2h20), 23/09 (3h20)
```

Vinte e oito manhãs boas em trinta são 93,3%, e o objetivo não foi cumprido. Parece duro por duas
manhãs ruins, e é a aritmética da meta: 95% de trinta manhãs permite uma e meia, então na prática
**um objetivo de 95% num mês tolera uma manhã ruim**. Se esse é o número certo é uma conversa com
Marta, e o programa faz dela uma conversa sobre um fato.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Um gráfico de barras com a idade dos dados de viagens às 09:00 em cada uma das trinta manhãs de setembro de 2025. Vinte e sete barras ficam em vinte minutos e uma, em 3 de setembro, em uma hora e vinte, ainda dentro do objetivo. Em 16 de setembro a idade é de 2 horas e 20 minutos e em 23 de setembro de 3 horas e 20 minutos, as duas acima da linha do objetivo de duas horas e abaixo da linha do acordo de quatro horas.\" data-fig=\"month\"><defs><marker id=\"month-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"70\" y1=\"250\" x2=\"670\" y2=\"250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"70\" y1=\"250\" x2=\"70\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"62\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 h</text><text x=\"62\" y=\"203.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1 h</text><text x=\"62\" y=\"156.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2 h</text><text x=\"62\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3 h</text><text x=\"62\" y=\"63.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4 h</text><text x=\"62\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">idade às 09:00</text><rect x=\"73.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"93.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"113.0\" y=\"187.8\" width=\"14.0\" height=\"62.2\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"133.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"153.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"173.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"193.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"213.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"233.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"253.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"273.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"293.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"313.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"333.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"353.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"373.0\" y=\"141.1\" width=\"14.0\" height=\"108.9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"393.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"413.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"433.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"453.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"473.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"493.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"513.0\" y=\"94.4\" width=\"14.0\" height=\"155.6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"533.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"553.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"573.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"593.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"613.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"633.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"653.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"80.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">01/09</text><text x=\"220.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">08/09</text><text x=\"360.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15/09</text><text x=\"500.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">22/09</text><text x=\"640.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">29/09</text><line x1=\"70\" y1=\"156.7\" x2=\"670\" y2=\"156.7\" stroke=\"var(--phosphor)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></line><line x1=\"70\" y1=\"63.3\" x2=\"670\" y2=\"63.3\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></line><text x=\"78\" y=\"146.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">objetivo (SLO): no máximo 2 h</text><text x=\"78\" y=\"53.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">acordo com a prefeitura (SLA): no máximo 4 h</text><text x=\"380.0\" y=\"132.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2h20</text><text x=\"520.0\" y=\"85.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3h20</text></svg>", "caption": "Trinta manhãs de setembro de 2025. Duas passaram do objetivo que o time definiu para si, e nenhuma chegou ao acordo com a prefeitura."}
```

A figura mostra por que existem duas linhas. Em 3 de setembro uma exportação falhou e o dado tinha
uma hora e vinte minutos: uma falha, e ainda assim uma manhã dentro do prazo. As duas violações passaram do objetivo e ficaram dentro
do acordo: em 23 de setembro o dado tinha 3 horas e 20 minutos, o que é uma manhã ruim para o time e
ainda uma promessa cumprida para a prefeitura. A folga que um objetivo deixa, e o que o time faz
quando ela acaba, se chama orçamento de erro (*error budget*); `observability` vai além nisso.
