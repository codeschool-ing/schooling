---
title: Rode duas vezes, e tenha a mesma resposta
version: 1
---

**Todo pipeline vai rodar duas vezes sobre o mesmo dia, mais cedo ou mais tarde.** Um agendador
repete um job que estourou o tempo depois de já ter terminado; alguém roda a segunda de novo à mão
depois de uma falha; uma correção sobe e a semana é reconstruída. Que vai acontecer é certo; o que
importa é se a segunda execução muda a resposta.

Um passo que dá o mesmo resultado não importa quantas vezes rode é **idempotente**. A palavra é
comprida e o teste é curto: rode duas vezes, e compare.

## A ingestão da seção anterior, rodada de novo

Nada está errado com o pipeline como está, até onde uma execução consegue dizer. Rode a ingestão da
segunda-feira uma segunda vez, como uma repetição faria, e depois o resto do pipeline:

```
ana@lab:~/roda/lifecycle$ python ingest.py 2025-09-15
 187 rides    -> raw/date=2025-09-15/rides.jsonl
  12 stations -> raw/date=2025-09-15/stations.jsonl
ana@lab:~/roda/lifecycle$ wc -l raw/date=2025-09-15/*.jsonl
  374 raw/date=2025-09-15/rides.jsonl
   24 raw/date=2025-09-15/stations.jsonl
  398 total
ana@lab:~/roda/lifecycle$ python transform.py 2025-09-15
374 raw, 352 kept, 22 under 2 minutes dropped
ana@lab:~/roda/lifecycle$ python report.py 2025-09-15
Roda Livre, rides on 2025-09-15: 352
Busiest stations:
  ST02 Rua XV             58
  ST01 Praça Tiradentes   42
  ST08 Parque Barigui     32
```

**Todo número do relatório dobrou, e nada reclamou.** Nenhum erro, nenhum aviso, um relatório que
parece exatamente tão confiável quanto o anterior. É o `twice.py` da aula 1 de novo, na escala de um
pipeline, e é a falha que Marta nunca acharia sozinha: uma segunda movimentada parece uma segunda
movimentada.

A causa é um caractere no `ingest.py`. Ele abre cada arquivo com `"a"`, que acrescenta: a segunda
execução acrescentou as viagens de segunda ao fim do arquivo que já as tinha. A transformação fez o
trabalho dela direito. Sobrescreveu `clean/` e `curated/` e contou fielmente o que o bruto dizia, e o
bruto dizia cada viagem duas vezes.

Os nomes das estações sobreviveram só por sorte. O `stations.jsonl` tem 24 linhas agora, mas a
transformação as põe num dicionário, que guarda um nome por id. Uma junção que mantivesse todas as
correspondências teria casado cada viagem dobrada com duas cópias da sua estação e a contado quatro
vezes.

## Substituir o dia, em vez de acrescentar a ele

O conserto é fazer do **dia** a unidade da ingestão, e substituí-lo inteiro. Este é o mesmo programa
com duas mudanças:

```schooling-example
{"language": "python", "file": "lifecycle/ingest_replace.py", "parts": [
{"code": "# lifecycle/ingest_replace.py\nimport json\nimport os\nimport shutil\nimport sqlite3\nimport sys\n\n", "note": "Os mesmos imports do `ingest.py`, e mais um: `shutil`, para remover um diretório com tudo o que há nele."},
{"code": "day = sys.argv[1]\napp = sqlite3.connect(\"file:app.db?mode=ro\", uri=True)\napp.row_factory = sqlite3.Row\nrides = app.execute(\"SELECT * FROM rides WHERE started_at LIKE ?\", (day + \"%\",)).fetchall()\nstations = app.execute(\"SELECT * FROM stations\").fetchall()\n\n", "note": "Sem mudança: a mesma conexão só de leitura e as mesmas duas consultas."},
{"code": "part = f\"raw/date={day}\"\nif os.path.exists(part):\n    shutil.rmtree(part)\nos.makedirs(part)\n", "note": "A primeira mudança. Se o diretório do dia existe, ele é removido inteiro e criado de novo, vazio. O que uma execução anterior tenha deixado ali some antes de qualquer escrita."},
{"code": "for name, rows in ((\"rides\", rides), (\"stations\", stations)):\n    with open(f\"{part}/{name}.jsonl\", \"w\", encoding=\"utf-8\") as f:\n        for row in rows:\n            f.write(json.dumps(dict(row), ensure_ascii=False) + \"\\n\")\n    print(f\"{len(rows):4} {name:8} -> {part}/{name}.jsonl\")\n", "note": "A segunda: `\"w\"` em vez de `\"a\"`. Qualquer uma das mudanças sozinha resolveria estes dois arquivos; juntas, fazem do dia a unidade, e nem um arquivo deixado por uma versão antiga sobrevive."}
]}
```

Rode duas vezes seguidas, e depois o resto do pipeline:

```
ana@lab:~/roda/lifecycle$ python ingest_replace.py 2025-09-15
 187 rides    -> raw/date=2025-09-15/rides.jsonl
  12 stations -> raw/date=2025-09-15/stations.jsonl
ana@lab:~/roda/lifecycle$ python ingest_replace.py 2025-09-15
 187 rides    -> raw/date=2025-09-15/rides.jsonl
  12 stations -> raw/date=2025-09-15/stations.jsonl
ana@lab:~/roda/lifecycle$ wc -l raw/date=2025-09-15/*.jsonl
  187 raw/date=2025-09-15/rides.jsonl
   12 raw/date=2025-09-15/stations.jsonl
  199 total
ana@lab:~/roda/lifecycle$ python transform.py 2025-09-15
187 raw, 176 kept, 11 under 2 minutes dropped
ana@lab:~/roda/lifecycle$ python report.py 2025-09-15
Roda Livre, rides on 2025-09-15: 176
Busiest stations:
  ST02 Rua XV             29
  ST01 Praça Tiradentes   21
  ST08 Parque Barigui     16
```

A segunda execução deixou os arquivos exatamente como a primeira, e o relatório voltou aos números da
seção anterior. **Agora uma repetição é inofensiva, e rodar um dia de novo é o jeito normal de
consertá-lo**, e não um risco.

## O que isto não cobre

Substituir uma partição é o mais simples de vários jeitos de ser idempotente, e serve a um lote que
copia um dia inteiro por vez. Vale reconhecer outros dois pelo nome:

- **uma chave única**: toda linha carrega um id, e uma segunda cópia de `R000174` substitui a primeira
  em vez de ficar ao lado dela. Um banco faz isso com uma chave primária, e `sql-databases` mostra
  como;
- **gravar e renomear**: o dia novo é gravado num diretório temporário e renomeado para o lugar só
  quando está completo, então um leitor nunca vê meio dia. A aula 4 encontra a mesma ideia pelo lado
  de quem lê, num arquivo que ainda está sendo gravado.

A aula 8 volta ao assunto para fluxos, em que uma queda entre fazer o trabalho e registrar que ele foi
feito é o caso comum, e não a exceção.
