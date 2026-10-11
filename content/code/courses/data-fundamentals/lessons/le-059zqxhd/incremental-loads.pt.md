---
title: Copiando só o que mudou
version: 1
---

**Quando uma tabela fica grande demais para ser copiada inteira a cada execução, cada execução copia só
o que mudou desde a anterior — e "desde a anterior" é um valor que o pipeline precisa lembrar.** Esse
valor é a **marca d'água** (*watermark*): a mudança mais recente que a execução anterior viu. Copiar
tudo toda vez é uma **carga completa**; copiar da marca d'água em diante é uma **carga incremental**.

A marca d'água de costume é uma coluna que a origem já mantém, `updated_at`, preenchida com o horário
atual sempre que uma linha é escrita. Uma execução incremental pede toda linha com `updated_at` acima da
marca d'água, copia essas linhas e move a marca d'água para a mais recente que leu. Isso pega tanto
linhas novas quanto alteradas, desde que a origem de fato preencha `updated_at` em toda escrita. As
perguntas da aula 4 ao dono de uma origem incluem exatamente essa.

## Uma origem, e uma cópia

A origem é um pequeno banco SQLite no lugar do banco do aplicativo. `morning` escreve quarenta viagens
terminando entre 08:02 e 09:59. `after` escreve o que acontece depois da cópia das 10:00: uma viagem
nova, um estorno, e uma viagem cuja linha diz 09:57. Esta última é o caso de que trata esta seção. Um
dos servidores do aplicativo a carimbou às 09:57, quando a viagem terminou, mas a transação dele foi
lenta e só foi **confirmada** (*commit*) às 10:01, então nenhuma cópia feita às 10:00 poderia tê-la
visto. Salve como `collect/app.py`:

```python
# collect/app.py
import sqlite3
import sys
from datetime import datetime, timedelta

db = sqlite3.connect("app.db")
db.execute("CREATE TABLE IF NOT EXISTS rides "
           "(ride_id TEXT PRIMARY KEY, station TEXT, status TEXT, updated_at TEXT)")


def write(ride_id, station, status, at):
    db.execute("INSERT OR REPLACE INTO rides VALUES (?, ?, ?, ?)",
               (ride_id, station, status, at))


if sys.argv[1] == "morning":
    # forty rides end between 08:02 and 09:59
    for i in range(1, 41):
        at = datetime(2025, 9, 15, 8, 0) + timedelta(minutes=3 * i - 1)
        write(f"R{i:06d}", f"ST{i % 12 + 1:02d}", "ended", str(at))
elif sys.argv[1] == "after":
    # after the 10:00 copy: one new ride, one refund, and one ride stamped
    # 09:57 by a slow server whose transaction committed at 10:01
    write("R000042", "ST02", "ended", "2025-09-15 10:04:00")
    write("R000010", "ST11", "refunded", "2025-09-15 10:02:00")
    write("R000041", "ST05", "ended", "2025-09-15 09:57:00")
db.commit()
n, last = db.execute("SELECT count(*), max(updated_at) FROM rides").fetchone()
print(f"app.db: {n} rides, latest updated_at {last}")
```

A cópia é o programa abaixo. Ele recebe um número, a **sobreposição**: quantos minutos antes da marca
d'água começar a ler. Cada sobreposição guarda a própria marca d'água e a própria cópia, para que duas
delas possam ser comparadas sobre a mesma origem.

```schooling-example
{"language": "python", "file": "collect/incremental.py", "parts": [
{"code": "# collect/incremental.py\nimport sqlite3\nimport sys\nfrom datetime import datetime, timedelta\n\noverlap = int(sys.argv[1])                 # minutes to read again\nmark_file = f\"watermark-{overlap}.txt\"\ntry:\n    mark = open(mark_file).read()\n    since = str(datetime.fromisoformat(mark) - timedelta(minutes=overlap))\nexcept FileNotFoundError:\n    mark = since = \"\"                      # the first run copies everything\n\n", "note": "A sobreposição vem da linha de comando. A marca d'água fica num arquivo próprio, porque precisa sobreviver à execução que a escreveu. `since` é de onde esta execução começa a ler: a marca d'água, recuada pela sobreposição. Sem arquivo ainda não há marca d'água, e um `since` vazio fica abaixo de qualquer horário."},
{"code": "rows = sqlite3.connect(\"app.db\").execute(\n    \"SELECT * FROM rides WHERE updated_at > ?\", (since,)).fetchall()\n\n", "note": "A pergunta inteira feita à origem: toda linha alterada depois de `since`. Uma execução lê só essas linhas, por maior que a tabela fique."},
{"code": "copy = sqlite3.connect(f\"copy-{overlap}.db\")\ncopy.execute(\"CREATE TABLE IF NOT EXISTS rides \"\n             \"(ride_id TEXT PRIMARY KEY, station TEXT, status TEXT, updated_at TEXT)\")\nbefore = copy.execute(\"SELECT count(*) FROM rides\").fetchone()[0]\ncopy.executemany(\"INSERT OR REPLACE INTO rides VALUES (?, ?, ?, ?)\", rows)\ncopy.commit()\nafter = copy.execute(\"SELECT count(*) FROM rides\").fetchone()[0]\n\n", "note": "A cópia tem `ride_id` como chave, e `INSERT OR REPLACE` grava cada linha por cima de qualquer versão mais antiga dela. É isso que torna inofensivo ler uma linha duas vezes, e é assim que o estorno substitui a viagem que ele estorna."},
{"code": "mark = max([mark] + [r[3] for r in rows])\nopen(mark_file, \"w\").write(mark)\nprint(f\"overlap {overlap:2} min: read {len(rows):2} rows since {since[11:16] or 'the start'},\"\n      f\" {after - before:2} new, watermark now {mark[11:16]}\")\n", "note": "A nova marca d'água é o `updated_at` mais recente lido, e nunca anda para trás. Ela só é salva depois que a cópia foi confirmada: uma execução que morre no meio deixa a marca d'água antiga, e a próxima lê as mesmas linhas de novo."}
]}
```

Gere a manhã, e faça a cópia das 10:00 duas vezes, uma sem sobreposição e outra com dez minutos:

```
ana@lab:~/roda/collect$ python app.py morning
app.db: 40 rides, latest updated_at 2025-09-15 09:59:00
ana@lab:~/roda/collect$ python incremental.py 0
overlap  0 min: read 40 rows since the start, 40 new, watermark now 09:59
ana@lab:~/roda/collect$ python incremental.py 10
overlap 10 min: read 40 rows since the start, 40 new, watermark now 09:59
```

A primeira execução de cada uma não tem marca d'água, então copia tudo. Agora chegam as três mudanças,
e as duas cópias rodam de novo:

```
ana@lab:~/roda/collect$ python app.py after
app.db: 42 rides, latest updated_at 2025-09-15 10:04:00
ana@lab:~/roda/collect$ python incremental.py 0
overlap  0 min: read  2 rows since 09:59,  1 new, watermark now 10:04
ana@lab:~/roda/collect$ python incremental.py 10
overlap 10 min: read  7 rows since 09:49,  2 new, watermark now 10:04
```

A execução sem sobreposição pediu tudo depois de 09:59. Encontrou a viagem nova das 10:04 e o estorno
das 10:02, e moveu a marca d'água para 10:04. A viagem carimbada 09:57 não estava acima de 09:59, então
não foi pedida — e nunca será, porque toda execução seguinte começa acima de 10:04. A execução com dez
minutos de sobreposição começou em 09:49, leu sete linhas, achou duas novas entre elas, e tem a viagem
atrasada. Um terceiro programa compara cada cópia com a origem, linha a linha:

```python
# collect/compare.py
import sqlite3


def rides(path):
    return {r[0]: r for r in sqlite3.connect(path).execute("SELECT * FROM rides")}


source = rides("app.db")
for overlap in (0, 10):
    copy = rides(f"copy-{overlap}.db")
    missing = sorted(set(source) - set(copy))
    stale = sorted(k for k in copy if copy[k] != source.get(k))
    print(f"overlap {overlap:2} min: source {len(source)}, copy {len(copy)},"
          f" missing {missing or 'none'}, stale {stale or 'none'}")
```

```
ana@lab:~/roda/collect$ python compare.py
overlap  0 min: source 42, copy 41, missing ['R000041'], stale none
overlap 10 min: source 42, copy 42, missing none, stale none
```

**Nada falhou, nada imprimiu um aviso, e uma das cópias perdeu uma viagem para sempre.** As duas pegaram
o estorno, porque uma mudança numa linha antiga empurra o `updated_at` dela para a frente. O que a marca
d'água simples não consegue pegar é uma linha que chega carregando um horário do passado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 232\" role=\"img\" aria-label=\"Uma linha do tempo das 09:40 às 10:10. As viagens escritas até 09:59 foram copiadas às 10:00, o que pôs a marca d’água em 09:59. A viagem R000041 tem o carimbo 09:57, mas foi confirmada às 10:01. A execução seguinte sem sobreposição lê só acima de 09:59 e a perde; com dez minutos de sobreposição lê acima de 09:49 e a encontra, junto com as viagens das 10:02 e das 10:04.\" data-fig=\"watermark\"><defs><marker id=\"watermark-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"70\" y1=\"120\" x2=\"696\" y2=\"120\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#watermark-ah)\"></line><text x=\"80\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">09:40</text><text x=\"280\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">09:50</text><text x=\"480\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10:00</text><text x=\"680\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10:10</text><line x1=\"460\" y1=\"50\" x2=\"460\" y2=\"214\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></line><text x=\"454\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\" font-weight=\"600\">marca d’água 09:59</text><line x1=\"480\" y1=\"64\" x2=\"480\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"2 3\"></line><text x=\"486\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a cópia das 10:00</text><circle cx=\"100\" cy=\"120\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></circle><circle cx=\"160\" cy=\"120\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></circle><circle cx=\"220\" cy=\"120\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></circle><circle cx=\"280\" cy=\"120\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></circle><circle cx=\"340\" cy=\"120\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></circle><circle cx=\"400\" cy=\"120\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></circle><circle cx=\"460\" cy=\"120\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></circle><circle cx=\"520\" cy=\"120\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><circle cx=\"560\" cy=\"120\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><circle cx=\"420\" cy=\"120\" r=\"6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"420\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">R000041</text><text x=\"428\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">carimbo 09:57, confirmada 10:01</text><rect x=\"460\" y=\"162\" width=\"220\" height=\"20\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sem sobreposição: acima de 09:59</text><rect x=\"260\" y=\"192\" width=\"420\" height=\"20\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"470.0\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dez minutos de sobreposição: acima de 09:49</text><text x=\"150\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a execução depois das 10:00 lê</text></svg>", "caption": "Uma linha carrega a hora em que foi escrita e fica visível quando é confirmada. Ler alguns minutos antes da marca d’água é o que pega a que foi confirmada tarde."}
```

## O preço da sobreposição

A sobreposição relê os últimos dez minutos a cada execução: sete linhas lidas para duas novas. Duas
coisas tornam isso seguro. A escrita usa `ride_id` como chave, então uma linha lida duas vezes substitui
a si mesma em vez de aparecer duas vezes; a aula 3 chama isso de idempotente. E a janela é mais larga que
o commit mais lento que se espera da origem. **Nenhuma janela é larga o bastante para todo caso**: um
servidor com o relógio um dia atrasado derrota uma sobreposição de dez minutos, e uma linha apagada na
origem nunca tem um `updated_at` pelo qual ser encontrada. A aula 4 mostrou o apagamento se perdendo, e a
leitura do próprio registro de mudanças do banco no lugar disso. Extração a fundo, com seus recuos e
linhas atrasadas, é `pipelines-etl`.
