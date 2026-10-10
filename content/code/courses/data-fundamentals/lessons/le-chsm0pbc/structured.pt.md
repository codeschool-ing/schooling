---
title: Dado estruturado, e uma tabela que diz não
version: 1
---

**Dado estruturado tem um esquema declarado antes de qualquer parte dele chegar, e cada valor é
conferido contra ele no momento em que é escrito.** Uma tabela num banco de dados relacional é
o caso conhecido: linhas e colunas, um tipo por coluna, as mesmas colunas em toda linha. O jargão para
isso é **schema on write**, esquema na escrita. A conferência roda uma vez, no momento da escrita, e
todo leitor depois pode confiar na forma sem olhar.

Essa confiança é o objetivo inteiro. Uma consulta que soma `minutes` nunca precisa perguntar se um
deles é o texto `9 min`, porque um valor assim não teria conseguido entrar.

## Uma tabela que recusa

O pyarrow, a biblioteca que você instalou na aula 1, monta tabelas na memória com um esquema declarado,
o que o torna um jeito pequeno de ver o esquema na escrita acontecer sem instalar um banco de dados.
Esta aula trabalha num diretório só dela:

```sh
mkdir -p ~/roda/shapes && cd ~/roda/shapes
```

Salve isto como `structured.py` lá:

```schooling-example
{"language": "python", "file": "shapes/structured.py", "parts": [{"code": "# shapes/structured.py\nfrom datetime import datetime\nfrom zoneinfo import ZoneInfo\n\nimport pyarrow as pa\n\n", "note": "A primeira linha dá o nome do arquivo e o diretório onde salvá-lo. `zoneinfo` vem na biblioteca padrão; o `pyarrow` é o que você instalou."}, {"code": "SP = ZoneInfo('America/Sao_Paulo')\nSCHEMA = pa.schema([\n    ('ride_id', pa.string()),\n    ('station', pa.string()),\n    ('started_at', pa.timestamp('s', tz='America/Sao_Paulo')),\n    ('minutes', pa.int32()),\n])\n\n", "note": "O esquema, declarado antes de existir uma única viagem: quatro colunas, cada uma com nome e tipo. `int32` é um número inteiro; o timestamp carrega o fuso de Curitiba."}, {"code": "rides = [\n    {'ride_id': 'R000001', 'station': 'ST02',\n     'started_at': datetime(2025, 9, 14, 7, 52, tzinfo=SP), 'minutes': 12},\n    {'ride_id': 'R000002', 'station': 'ST05',\n     'started_at': datetime(2025, 9, 14, 8, 3, tzinfo=SP), 'minutes': 25},\n]\ntable = pa.Table.from_pylist(rides, schema=SCHEMA)\nprint(table.schema)\nprint(table.num_rows, 'rows accepted')\n\n", "note": "Duas viagens que cabem. `from_pylist` monta uma tabela a partir de uma lista de dicionários e confere cada valor contra o `SCHEMA` enquanto monta."}, {"code": "rides.append({'ride_id': 'R000003', 'station': 'ST06',\n              'started_at': datetime(2025, 9, 14, 8, 31, tzinfo=SP), 'minutes': '9 min'})\ntry:\n    pa.Table.from_pylist(rides, schema=SCHEMA)\nexcept (pa.ArrowInvalid, pa.ArrowTypeError) as err:\n    print('refused:', err)\n", "note": "Uma terceira viagem cujo `minutes` chegou como texto, do jeito que uma exportação descuidada escreve. A mesma chamada é tentada de novo, e o erro que ela levanta é impresso em vez de parar o programa."}]}
```

Rode:

```
ana@lab:~/roda/shapes$ python structured.py
ride_id: string
station: string
started_at: timestamp[s, tz=America/Sao_Paulo]
minutes: int32
2 rows accepted
refused: Could not convert '9 min' with type str: tried to convert to int32
```

As duas viagens boas entraram. A terceira foi barrada na porta, com uma mensagem que diz o valor e o
tipo em que ele não conseguiu se transformar. **Nada foi escrito**: o `from_pylist` monta a tabela
inteira ou nenhuma, então não sobra um estado meio carregado para limpar depois.

Repare na coluna `started_at`. Ela não é um texto que por acaso parece uma hora. É um timestamp com
fuso horário, então ordenar, subtrair e agrupar por hora funcionam direto nela, e nenhum leitor
precisa interpretá-la.

## As mesmas linhas sem esquema

Um arquivo CSV tem os nomes das colunas na primeira linha e mais nada: nenhum tipo, nenhuma regra de que
um valor precisa estar lá. Salve isto como `loose.py`:

```python
# shapes/loose.py
import csv

rows = [
    ['ride_id', 'station', 'started_at', 'minutes'],
    ['R000001', 'ST02', '2025-09-14 07:52', '12'],
    ['R000002', 'ST05', '2025-09-14 08:03', '25'],
    ['R000003', 'ST06', '2025-09-14 08:31', '9 min'],
]
with open('rides.csv', 'w', newline='') as f:
    csv.writer(f).writerows(rows)
print('wrote', len(rows) - 1, 'rides')

with open('rides.csv', newline='') as f:
    rides = list(csv.DictReader(f))
print(rides[2])
total = sum(int(r['minutes']) for r in rides)
print('total minutes:', total)
```

```
ana@lab:~/roda/shapes$ python loose.py
wrote 3 rides
{'ride_id': 'R000003', 'station': 'ST06', 'started_at': '2025-09-14 08:31', 'minutes': '9 min'}
Traceback (most recent call last):
  File "/home/ana/roda/shapes/loose.py", line 17, in <module>
    total = sum(int(r['minutes']) for r in rides)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/roda/shapes/loose.py", line 17, in <genexpr>
    total = sum(int(r['minutes']) for r in rides)
                ^^^^^^^^^^^^^^^^^
ValueError: invalid literal for int() with base 10: '9 min'
```

Quem escreveu aceitou as três linhas. Quem leu recebeu cada valor de volta como texto, que é tudo o que
um CSV consegue guardar, e o programa só falhou na linha 17, quando tentou somar os minutos. **O
erro era o mesmo; ele apareceu para outra pessoa.** No `structured.py` ele parou quem estava escrevendo
a linha ruim. Aqui ele para quem lê o arquivo, talvez uma semana depois, talvez o Caio no meio de outra
coisa, e o arquivo que causou o problema já está guardado e copiado.

Essa é a troca que o dado estruturado faz. Alguém precisa declarar o esquema antes, e mudá-lo depois é
um ato deliberado: uma migração, uma coluna nova, uma conversa com quem lê a tabela. Em troca, todo
erro de tipo é pego no momento mais barato que existe, antes de ser guardado.
