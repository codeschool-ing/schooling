---
title: Verificações na porta
version: 1
---

**O momento mais barato para pegar uma linha ruim é o momento em que ela chega, antes que qualquer coisa
adiante a tenha lido.** O plano comum é carregar tudo e limpar depois. Até lá, um relatório já contou a
linha ruim, um modelo já treinou com ela, e alguém já tomou uma decisão com ela; limpar então significa
encontrar todo mundo que já a usou.

As verificações na chegada são de dois tipos, e falham de jeitos diferentes:

- **verificações do arquivo**: ele tem as colunas que deveria, e tantas linhas quanto a origem diz que
  enviou? Um arquivo que falha numa delas é **recusado inteiro**. Carregar parte de um dia faz o dia
  parecer tranquilo, e isso é um número errado, não um número faltando.
- **verificações de cada linha**: um valor obrigatório está presente, dentro da faixa, único onde
  precisa ser, e apontando para algo que existe? Uma linha que falha numa delas vai para a
  **quarentena**: separada num arquivo próprio, com o motivo, onde alguém pode olhá-la. Ela nunca é
  descartada em silêncio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Uma entrega, um arquivo CSV com a contagem de linhas que a origem enviou, passa primeiro pelas verificações do arquivo: as colunas e a contagem de linhas. Se falham, o arquivo é recusado inteiro e nada é carregado. Se passam, cada linha passa por verificações de valor ausente, faixa, unicidade e referência, e é aceita ou vai para a quarentena com o motivo.\" data-fig=\"door\"><defs><marker id=\"door-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"72\" width=\"124\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"76.0\" y=\"86.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">a entrega</text><text x=\"76.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um arquivo CSV</text><text x=\"76.0\" y=\"117.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">e a contagem</text><line x1=\"138\" y1=\"102\" x2=\"176\" y2=\"102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#door-ah)\"></line><rect x=\"178\" y=\"57\" width=\"170\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"263.0\" y=\"86.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">verificações do arquivo</text><text x=\"263.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">as colunas</text><text x=\"263.0\" y=\"117.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a contagem de linhas</text><line x1=\"263\" y1=\"147\" x2=\"263\" y2=\"177\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#door-ah)\"></line><text x=\"271\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">falha</text><rect x=\"178\" y=\"179\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"263.0\" y=\"194.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">recusado inteiro</text><text x=\"263.0\" y=\"209.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nada é carregado</text><line x1=\"348\" y1=\"102\" x2=\"386\" y2=\"102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#door-ah)\"></line><text x=\"367\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">passa</text><rect x=\"388\" y=\"32\" width=\"180\" height=\"140\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"478.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">verificações de cada linha</text><text x=\"478.0\" y=\"86.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">valor ausente</text><text x=\"478.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">faixa</text><text x=\"478.0\" y=\"117.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">unicidade</text><text x=\"478.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">referência</text><line x1=\"568\" y1=\"78\" x2=\"594\" y2=\"62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#door-ah)\"></line><rect x=\"596\" y=\"30\" width=\"112\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"652.0\" y=\"48.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">aceita</text><text x=\"652.0\" y=\"63.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">carregada</text><line x1=\"568\" y1=\"126\" x2=\"594\" y2=\"142\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#door-ah)\"></line><rect x=\"596\" y=\"116\" width=\"112\" height=\"68\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"652.0\" y=\"134.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">quarentena</text><text x=\"652.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a linha,</text><text x=\"652.0\" y=\"165.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">e o motivo</text></svg>", "caption": "Dois tipos de verificação na chegada. Um arquivo que falha é recusado inteiro; uma linha que falha é separada com o motivo, e nunca descartada."}
```

## Uma entrega com problemas dentro

A exportação noturna de viagens do aplicativo chega como um arquivo CSV, com um segundo arquivo, minúsculo,
ao lado, em que a origem escreve quantas linhas enviou. Este programa gera dois dias delas. O dia 15 tem
quatro problemas plantados nas suas 200 linhas, e o dia 16 foi cortado depois de 137 linhas de 200, como
ficaria uma cópia interrompida no meio. Salve como `collect/deliver.py`:

```python
# collect/deliver.py
import csv
import random
from datetime import datetime, timedelta

random.seed(15)


def deliver(day, first, rows, sent):
    start = datetime.fromisoformat(day + " 06:00")
    out = []
    for i in range(first, first + rows):
        at = start + timedelta(seconds=random.randrange(17 * 3600))
        out.append([f"R{i:06d}", f"ST{random.randint(1, 12):02d}", str(at),
                    str(random.randint(3, 60))])
    if day == "2025-09-15":
        out[40][1] = "ST13"           # a station that does not exist
        out[77][3] = "-4"             # a ride of minus four minutes
        out[120][2] = ""              # no start time
        out[150] = out[149]           # a ride written over the next one
    with open(f"delivery-{day}.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["ride_id", "start_station", "started_at", "minutes"])
        w.writerows(out[:sent])
    with open(f"delivery-{day}.count", "w") as f:
        f.write(f"{rows}\n")          # what the source says it sent
    print(f"delivery-{day}.csv: {sent} rows written, the source says {rows}")


deliver("2025-09-15", 1, 200, 200)
deliver("2025-09-16", 201, 200, 137)   # the copy was cut off halfway
```

As verificações são o programa abaixo. As duas do alto olham o arquivo inteiro e o param com
`sys.exit`, que imprime o motivo e encerra o programa com erro. `problem` olha uma linha e devolve o
motivo pelo qual ela falha, ou um texto vazio. O laço do fim classifica cada linha como aceita ou em
quarentena e escreve os dois arquivos. Salve como `collect/door.py`:

```python
# collect/door.py
import csv
import sys

COLUMNS = ["ride_id", "start_station", "started_at", "minutes"]
STATIONS = {f"ST{n:02d}" for n in range(1, 13)}
day = sys.argv[1]

with open(f"delivery-{day}.csv", newline="") as f:
    header, *rows = list(csv.reader(f))
promised = int(open(f"delivery-{day}.count").read())

# checks on the whole file: if one fails, nothing is loaded
if header != COLUMNS:
    sys.exit(f"refused: the columns are {header}")
if len(rows) != promised:
    sys.exit(f"refused: {len(rows)} rows arrived, the source says {promised}")


def problem(row, seen):
    ride_id, station, started_at, minutes = row
    if ride_id in seen:
        return "ride_id seen before"
    if station not in STATIONS:
        return "unknown station"
    if not started_at.startswith(day):
        return "started_at empty or not on " + day
    if not minutes.isdigit() or not 1 <= int(minutes) <= 720:
        return "minutes outside 1-720"
    return ""


def save(path, rows):
    with open(path, "w", newline="") as f:
        csv.writer(f).writerows(rows)


# checks on each row: a bad row is set aside with its reason, never dropped
seen, accepted, quarantined = set(), [], []
for row in rows:
    reason = problem(row, seen)
    seen.add(row[0])
    if reason:
        quarantined.append(row + [reason])
    else:
        accepted.append(row)
save(f"accepted-{day}.csv", [COLUMNS] + accepted)
save(f"quarantine-{day}.csv", [COLUMNS + ["reason"]] + quarantined)
print(f"{day}: {len(rows)} rows, {len(accepted)} accepted, {len(quarantined)} quarantined")
```

Gere as entregas, e passe o dia 15 pela porta:

```
ana@lab:~/roda/collect$ python deliver.py
delivery-2025-09-15.csv: 200 rows written, the source says 200
delivery-2025-09-16.csv: 137 rows written, the source says 200
ana@lab:~/roda/collect$ python door.py 2025-09-15
2025-09-15: 200 rows, 196 accepted, 4 quarantined
```

Quatro das 200 foram separadas, e o arquivo de quarentena diz quais e por quê:

```
ana@lab:~/roda/collect$ cat quarantine-2025-09-15.csv
ride_id,start_station,started_at,minutes,reason
R000041,ST13,2025-09-15 06:45:11,60,unknown station
R000078,ST03,2025-09-15 07:49:29,-4,minutes outside 1-720
R000121,ST11,,35,started_at empty or not on 2025-09-15
R000150,ST06,2025-09-15 12:53:05,45,ride_id seen before
```

Cada linha é um tipo diferente de verificação. `ST13` aponta para uma estação que não existe, uma
verificação de **referência**. Uma viagem de menos quatro minutos está fora da **faixa**. Uma viagem sem
horário de início falha na verificação de **valor ausente**. E `R000150` chegou duas vezes: a exportação
a escreveu de novo por cima da viagem que deveria vir em seguida, `R000151`. Só uma verificação de
**unicidade** vê a repetição, porque sozinha a linha é perfeita. Nada na porta vê a viagem que falta, já
que o arquivo continua com as 200 linhas que prometeu; para isso é preciso a lista da própria origem, que
é a seção 07.

O dia 16 nem chega até aí:

```
ana@lab:~/roda/collect$ python door.py 2025-09-16; echo $?
refused: 137 rows arrived, the source says 200
1
```

**O arquivo é recusado antes que uma única linha seja julgada**, porque 137 linhas boas são piores que
nenhuma quando o leitor acredita que elas são o dia inteiro. O programa terminou com erro, que é o que um
agendador observa: o relatório da manhã espera, e alguém pede à origem o resto do arquivo.

## As regras são decisões, e alguém é dono delas

Cada número numa verificação foi escolhido. 720 minutos são doze horas, mais que qualquer viagem honesta,
e alguém decidiu que uma viagem mais longa é um erro e não um cliente que esqueceu de devolver a
bicicleta na doca. Anote cada regra com o motivo dela, e combine-a com o dono da origem, porque uma regra
que a origem não conhece quebra na primeira vez que a origem muda. Esse acordo é o contrato de dados que a
aula 4 descreveu.

A quarentena também precisa de um dono. **Um arquivo de quarentena que ninguém lê é um descarte
silencioso com um passo a mais**: as linhas somem de todo relatório, e o arquivo que as guarda cresce em
silêncio. Decida quem olha e com que frequência, e conte: quatro linhas por dia é ruído, quatrocentas é
uma origem que mudou.

Esta seção é a porta e nada mais. Medir a qualidade de uma tabela inteira, fazer o perfil dela e
consertar o que está errado é `data-cleaning`; verificações escritas como testes que rodam dentro de todo
pipeline são `pipelines-etl`.
