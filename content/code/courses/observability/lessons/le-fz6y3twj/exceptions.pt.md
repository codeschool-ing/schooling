---
title: Exceções: um erro, um registro
version: 1
---

O `crash.py` lê um pedido malformado e deixa a exceção escapar, como faz um erro não tratado num
serviço. O Python imprime o traceback na saída de erro como texto puro:

```python
import json


def load(text):
    return json.loads(text)


load("{not json")
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python crash.py 2>&1 | grep -v Container | wc -l
17
ana@obs:~/shop$ docker compose run --rm sandbox python crash.py 2>&1 | grep -v Container | head -4
Traceback (most recent call last):
  File "/scratch/crash.py", line 8, in <module>
    load("{not json")
  File "/scratch/crash.py", line 5, in load
```

**Dezessete linhas**, e uma esteira de logs que recolhe a saída uma linha por vez guarda dezessete
registros. O primeiro diz *Traceback*, o último diz o que deu errado, e os do meio são o caminho no
código. Num serviço movimentado, linhas de outras requisições chegam entre eles; uma busca pelo tipo
do erro acha a última linha sozinha, sem o código que o levantou; e nenhuma das dezessete carrega o
id do rastro da requisição que falhou.

O `caught.py` captura a mesma exceção e a registra pelo formatador da loja com `log.exception`, que
registra a mensagem em `ERROR` e anexa o traceback:

```python
import json

from common import logs

log = logs.setup()
try:
    json.loads("{not json")
except ValueError:
    log.exception("could not read the order")
```

```
ana@obs:~/shop$ docker compose run --rm -e PYTHONPATH=/app sandbox python caught.py 2>/dev/null | wc -l
1
ana@obs:~/shop$ docker compose run --rm -e PYTHONPATH=/app sandbox python caught.py 2>/dev/null | jq -r '.message, .exception'
could not read the order
Traceback (most recent call last):
  File "/scratch/caught.py", line 7, in <module>
    json.loads("{not json")
  File "/usr/local/lib/python3.12/json/__init__.py", line 346, in loads
    return _default_decoder.decode(s)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.12/json/decoder.py", line 338, in decode
    obj, end = self.raw_decode(s, idx=_w(s, 0).end())
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.12/json/decoder.py", line 354, in raw_decode
    obj, end = self.scan_once(s, idx)
               ^^^^^^^^^^^^^^^^^^^^^^
json.decoder.JSONDecodeError: Expecting property name enclosed in double quotes: line 1 column 2 (char 1)
```

**Uma linha.** O traceback inteiro está dentro do campo `exception`, com as quebras de linha escapadas
pelo JSON, e o `jq -r` o imprime de volta como era. Ele viaja com a mensagem, o nível e, num serviço,
o id do rastro, e nunca é partido.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma exceção, de dois jeitos. À esquerda, o traceback não capturado impresso como texto: 17 linhas, e a esteira de logs guarda cada uma como um registro separado, então uma busca pelo tipo do erro acha a última linha sem o código que a levantou, e linhas de outras requisições podem cair entre elas. À direita, a mesma exceção registrada pelo formatador JSON: 1 registro, com a mensagem, o id do rastro e o traceback inteiro dentro de um campo.\"><defs><marker id=\"exc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">impresso como texto: 17 registros</text><rect x=\"60\" y=\"44\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"57\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"70\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"83\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"96\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"109\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"122\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"135\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"148\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"161\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"174\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"187\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"200\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"213\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"226\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"239\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"252\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"257\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">o tipo do erro, sozinho</text><text x=\"540\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">registrado como JSON: 1 registro</text><rect x=\"430\" y=\"110\" width=\"220\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um registro</text><text x=\"540.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">message, level, trace_id</text><text x=\"540.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">exception: o traceback inteiro</text><text x=\"540\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">buscável por qualquer campo, nunca partido</text></svg>", "caption": "Dezessete registros contra um, para o mesmo erro. O traceback continua inteiro à direita; só está dentro de um campo, onde não pode ser separado do evento a que pertence.", "same": ["message, level, trace_id"]}
```

A regra que acompanha: **registre uma exceção uma vez, onde ela é tratada**, não em cada nível por
onde passa na subida. Um traceback registrado pela camada de banco, de novo pela camada de serviço e
de novo pelo tratador da requisição são três erros na contagem e um na realidade.
