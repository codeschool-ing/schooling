---
title: Acrescentar um campo sem quebrar o mês passado
version: 1
---

**Todo formato chega ao dia em que um campo é acrescentado; o que muda é se os arquivos antigos e os
leitores antigos percebem, e se avisam.** O time do aplicativo da Roda Livre vai começar a alugar
bicicletas elétricas, e a partir de outubro toda viagem vai ter um `kind`. Os arquivos de setembro
foram gravados sem ele, e ninguém vai regravá-los.

O nome disso é **evolução de esquema**, e ela tem duas direções que vale nomear. Um leitor novo que
ainda lê arquivos antigos é **compatível para trás** (*backward compatible*). Um leitor antigo que
ainda lê arquivos novos é **compatível para a frente** (*forward compatible*). Um campo acrescentado
com cuidado dá as duas.

## Avro: dois esquemas, conciliados pelo nome

Um leitor de Avro sempre tem dois esquemas na mão: o **esquema de quem gravou**, que está no
cabeçalho do arquivo, e o **esquema de quem lê**, o que o programa pede. O Avro casa os campos dos
dois pelo nome, não pela posição, e tem uma regra para cada diferença. Um campo que quem gravou tinha
e quem lê não tem é pulado. Um campo que quem lê quer e quem gravou nunca escreveu é preenchido com o
**valor padrão** (*default*) de quem lê, e se o esquema de quem lê não tem padrão, a leitura falha.

Este programa grava duas viagens de setembro com o esquema antigo e depois as lê duas vezes com um
esquema que acrescenta `kind`: uma com padrão, outra sem. Salve-o como `formats/evolve.py`:

```python
# formats/evolve.py
from fastavro import reader, writer

OLD = {"type": "record", "name": "Ride", "fields": [
    {"name": "ride_id", "type": "string"},
    {"name": "minutes", "type": "int"},
]}
WITH_DEFAULT = {"type": "record", "name": "Ride", "fields": [
    {"name": "ride_id", "type": "string"},
    {"name": "minutes", "type": "int"},
    {"name": "kind", "type": "string", "default": "classic"},
]}
WITHOUT_DEFAULT = {"type": "record", "name": "Ride", "fields": [
    {"name": "ride_id", "type": "string"},
    {"name": "minutes", "type": "int"},
    {"name": "kind", "type": "string"},
]}

with open("september.avro", "wb") as f:
    writer(f, OLD, [{"ride_id": "R000001", "minutes": 5},
                    {"ride_id": "R000002", "minutes": 23}])

for label, schema in [("with a default", WITH_DEFAULT),
                      ("without one", WITHOUT_DEFAULT)]:
    with open("september.avro", "rb") as f:
        try:
            print(label + ":", list(reader(f, reader_schema=schema)))
        except Exception as e:
            print(label + ":", type(e).__name__ + ":", e)
```

```
ana@lab:~/roda/formats$ python evolve.py
with a default: [{'ride_id': 'R000001', 'minutes': 5, 'kind': 'classic'}, {'ride_id': 'R000002', 'minutes': 23, 'kind': 'classic'}]
without one: SchemaResolutionError: No default value for field kind in Ride
```

Com padrão, setembro é lido perfeitamente com o esquema de outubro: toda viagem antiga é `classic`,
o que por acaso é verdade, porque não havia bicicletas elétricas antes de outubro. Sem padrão, o
leitor se recusa e diz o nome do campo. **Os dois resultados são bons.** O primeiro está certo e o
segundo é barulhento, e nenhum produz um número errado. Um registro de esquemas, visto na seção
"avro", pode fazer essa mesma conferência antes de aceitar uma versão nova de um esquema, e assim uma
mudança que quebraria os leitores é recusada no dia em que é proposta, e não na manhã em que é lida.

## CSV: pela posição, e em silêncio

O CSV não tem esquema para conciliar, só um cabeçalho que a maioria dos leitores pula e uma posição
em que a maior parte do código confia. Este programa tira a média de minutos da exportação de
setembro e da de outubro, lendo a terceira coluna de cada uma, que é onde `minutes` sempre esteve. A
exportação de outubro ganhou uma coluna `battery` para as bicicletas elétricas, e a pôs em terceiro.
Salve-o como `formats/shifted.py`:

```python
# formats/shifted.py
import csv
import io

SEPTEMBER = "ride_id,station,minutes\nR000001,ST08,5\nR000002,ST12,23\n"
OCTOBER = "ride_id,station,battery,minutes\nR000003,ST04,81,58\nR000004,ST02,64,12\n"


def average_minutes(text):
    rows = list(csv.reader(io.StringIO(text)))[1:]
    return sum(int(row[2]) for row in rows) / len(rows)  # minutes: third column


print("September:", average_minutes(SEPTEMBER))
print("October:  ", average_minutes(OCTOBER))
```

```
ana@lab:~/roda/formats$ python shifted.py
September: 14.0
October:   72.5
```

A média real de outubro é 35 minutos, de 58 e 12. O programa imprimiu 72.5, a média da carga da
bateria, e nada reclamou: uma porcentagem de bateria é um inteiro perfeitamente válido. Esta é a
falha silenciosa de que a aula 1 avisou, causada por nada além de uma coluna inserida no meio. Ler
pelo nome do cabeçalho, com `csv.DictReader`, teria sobrevivido a esta inserção e falhado alto, com
um `KeyError`, numa renomeação, que é a melhor das duas falhas.

## Parquet e ORC

Os dois guardam o esquema no rodapé de cada arquivo, então um leitor que recebe os arquivos de
setembro e os de outubro consegue casar as colunas pelo nome e preencher `kind` com nulos nas linhas
que nunca o tiveram. O que nenhum dos dois faz é decidir o que um valor ausente deve significar; um
nulo não é `classic`. Formatos de tabela como o Apache Iceberg e o Delta Lake vão um passo além e
guardam o histórico do esquema de uma tabela acima dos seus arquivos; este curso os nomeia e os
deixa aí.
