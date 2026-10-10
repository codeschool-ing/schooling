---
title: "JSON: seis tipos e todos os nomes, toda vez"
version: 1
---

**O JSON traz alguns tipos consigo, e paga por eles escrevendo o nome de cada campo em cada
registro.** A aula 5 viu o JSON como forma, com aninhamento e campos opcionais. Aqui a pergunta é o
arquivo: o que sobrevive à viagem por ele, e quanto ele custa em disco.

O JSON tem exatamente seis tipos de valor: texto, número, `true` ou `false`, `null`, objeto e lista.
Isso já é mais do que o CSV, que tem um. Quem lê consegue distinguir `5` de `"5"`, e um valor
ausente pode ser `null` em vez de um texto vazio. Todo o resto precisa ser escrito como um desses
seis. Não há data nem instante, não há dado binário, e o formato não distingue inteiro de decimal:
número é número, e se `4.5` chega como float ou como decimal exato depende de quem lê.

## O que sobrevive à viagem

Salve isto como `formats/as_json.py`. Ele pega a primeira viagem de `rides.py`, tenta gravá-la como
JSON e a lê de volta:

```python
# formats/as_json.py
import json
from rides import make

ride = make(1)[0]
try:
    json.dumps(ride)
except TypeError as e:
    print("TypeError:", e)

line = json.dumps(ride, default=str)
print(line)
back = json.loads(line)
for key in ["started_at", "minutes", "member"]:
    print(f"  {key}: {type(ride[key]).__name__} -> {type(back[key]).__name__}")

names = sum(len(json.dumps(key)) for key in ride)
print(len(line), "bytes, of which", names, "are field names in quotes")
```

```
ana@lab:~/roda/formats$ python as_json.py
TypeError: Object of type datetime is not JSON serializable
{"ride_id": "R000001", "bike_id": "B011", "start_station": "ST08", "end_station": "ST05", "started_at": "2025-09-01 06:01:23-03:00", "minutes": 5, "member": true}
  started_at: datetime -> str
  minutes: int -> int
  member: bool -> bool
162 bytes, of which 75 are field names in quotes
```

A primeira tentativa falha, e alto, porque um `datetime` não é um dos seis. `default=str` diz ao
`json` para transformar em texto qualquer coisa que ele não conheça, e a segunda tentativa funciona.
Ler de volta mostra o custo: `minutes` e `member` voltaram com os tipos com que saíram, e
`started_at` voltou como texto. Todo leitor deste arquivo agora precisa saber que aquele texto é um
instante, e em que formato, exatamente como no CSV.

A última linha é o outro custo. Dos 162 bytes dessa única viagem, 75 são os nomes dos campos, com as
aspas, e eles vão ser escritos de novo na viagem seguinte e na outra. A seção
"the-same-data-five-ways" mostra quanto isso soma em um mês.

## Uma lista, ou um objeto por linha

Um arquivo JSON pode guardar os seus registros de dois jeitos, e eles se comportam de modo bem
diferente.

**Uma lista** é um valor só: `[`, depois todas as viagens separadas por vírgulas, depois `]`. Ela só
é JSON válido quando o último colchete está lá, então um leitor usando o `json.load` do Python
precisa ler o arquivo inteiro antes de ter qualquer viagem. Um arquivo cortado no meio não é um
arquivo menor; é um arquivo inválido. Uma API costuma responder assim, porque cada resposta é
pequena.

**JSON Lines** põe um objeto em cada linha, e nada em volta deles: a linha impressa acima, uma vez
por viagem. Não é outra sintaxe, só uma convenção, e ela muda tudo o que importa para um pipeline.
Quem grava acrescenta uma linha quando uma viagem termina. Quem lê pega uma linha por vez, então um
arquivo de qualquer tamanho só precisa da memória de uma viagem. Um arquivo pode ser dividido em
qualquer quebra de linha e os pedaços lidos por trabalhadores diferentes. E uma linha estragada custa
um registro, não o arquivo. Logs e arquivos brutos de eventos são gravados assim; você também vai
ver o nome NDJSON, JSON delimitado por quebra de linha.

Os dois são formatos de linhas, e os dois são texto, então uma pessoa consegue abri-los e lê-los.
Onde o dado é lido por pessoas, ou chega de uma API, JSON é o arquivo certo. Onde ele é lido por um
programa, um milhão de linhas por vez, os nomes e o texto começam a custar mais do que dão.
