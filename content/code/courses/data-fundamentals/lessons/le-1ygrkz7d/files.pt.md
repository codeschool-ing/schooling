---
title: Arquivos, e como saber que um terminou de chegar
version: 1
---

**Um arquivo é o jeito mais antigo de duas empresas trocarem dados, e a única pergunta difícil dele é
se terminou de chegar.** As bicicletas da Roda Livre são consertadas por uma oficina contratada, cujo
sistema exporta os consertos do dia como CSV toda noite e o deixa onde a Roda Livre pode ler. Dois
lugares são comuns: um diretório num servidor, acessado por SFTP, ou um bucket num armazenamento de
objetos, assunto de `cloud`. O lado de Davi olha o lugar num horário marcado e carrega o que encontrar.

A imagem errada é a de que um arquivo que existe é um arquivo completo. Um arquivo aparece no momento
em que quem escreve o abre, e cresce enquanto a escrita acontece. **Um arquivo ainda sendo escrito e um
arquivo cujo escritor morreu no meio parecem exatamente iguais de fora**: mesmo nome, mesmo lugar,
algumas linhas. Um leitor que carrega o que encontrar vai, um dia, carregar metade de uma noite.

## O marcador vai por último

A resposta de costume é um acordo entre quem escreve e quem lê: quem escreve grava os dados primeiro e
outra coisa **por último**, e quem lê não toca em nada até essa última coisa existir. O Spark e o Hadoop
escrevem um arquivo vazio chamado `_SUCCESS` ao lado da saída quando um job termina. Um **manifesto**
diz mais: quais arquivos fazem parte da entrega, quantas linhas eles têm, e um checksum dos bytes, para
quem lê conferir que o que leu é o que foi escrito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"Uma linha do tempo de duas exportações. A primeira escreve rides.csv e depois manifest.json. A segunda escreve parte de rides.csv e para. Um leitor verifica duas vezes: na primeira, as duas mostram algumas linhas e nenhum manifesto; na segunda, só a primeira tem manifesto.\" data-fig=\"drop\"><defs><marker id=\"drop-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"130\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">a exportação que termina</text><rect x=\"130\" y=\"44\" width=\"330\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rides.csv, crescendo</text><rect x=\"480\" y=\"44\" width=\"140\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">manifest.json</text><text x=\"130\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">a exportação que morre</text><rect x=\"130\" y=\"110\" width=\"200\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rides.csv, crescendo</text><rect x=\"340\" y=\"110\" width=\"120\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"400.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o escritor para</text><line x1=\"290\" y1=\"24\" x2=\"290\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><line x1=\"650\" y1=\"24\" x2=\"650\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><text x=\"290\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">primeira verificação</text><text x=\"290\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">as duas: algumas linhas, sem manifesto</text><text x=\"706\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">segunda verificação</text><text x=\"706\" y=\"192\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma tem manifesto, a outra nunca terá</text><line x1=\"130\" y1=\"224\" x2=\"700\" y2=\"224\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#drop-ah)\"></line><text x=\"122\" y=\"224\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tempo</text></svg>", "caption": "Na primeira verificação as duas exportações não se distinguem: cada uma deixou parte de um arquivo e nenhum manifesto. Só a exportação que termina escreve o marcador."}
```

Há uma segunda convenção para um arquivo só: escrevê-lo com um nome temporário e renomeá-lo quando
estiver completo, porque num mesmo sistema de arquivos uma renomeação acontece de uma vez. O
armazenamento de objetos não tem renomeação, e esse é um dos motivos de o marcador ser a convenção ali.

## Metade de uma noite, carregada

Este programa faz o papel da exportação da oficina. Ele escreve mil linhas e depois um manifesto com o
número de linhas e um checksum SHA-256 dos dados. Recebendo um número, ele para depois de tantos bytes,
que é como o laboratório encena um escritor que morre:

```schooling-example
{"language": "python", "file": "sources/export.py", "parts": [
{"code": "# sources/export.py\nimport hashlib\nimport json\nimport os\nimport sys\n\n"},
{"code": "DAY = \"drop/2025-09-15\"\ncrash_at = int(sys.argv[1]) if len(sys.argv) > 1 else None   # a byte count, to stage a crash\nos.makedirs(DAY, exist_ok=True)\nif os.path.exists(f\"{DAY}/manifest.json\"):\n    os.remove(f\"{DAY}/manifest.json\")          # the old marker goes first\n\n", "note": "O diretório de um dia. Um manifesto deixado por uma execução anterior é removido antes, para uma queda desta vez não ser confundida com o sucesso da vez passada."},
{"code": "lines = [\"ride_id,bike_id,station,minutes\\n\"]\nfor n in range(1, 1001):\n    lines.append(f\"R{n:06d},B{n % 90 + 1:03d},ST{n % 12 + 1:02d},{n % 50 + 3}\\n\")\ndata = \"\".join(lines).encode()\n\n", "note": "Mil linhas geradas, guardadas na memória como bytes."},
{"code": "with open(f\"{DAY}/rides.csv\", \"wb\") as f:\n    f.write(data[:crash_at])\nif crash_at is not None:\n    sys.exit(f\"export stopped after {crash_at} bytes\")\n\n", "note": "Os dados vão primeiro. `data[:None]` é tudo; um número corta antes, no meio de uma linha, e o programa para ali, como um escritor que caiu."},
{"code": "manifest = {\"file\": \"rides.csv\", \"rows\": 1000, \"sha256\": hashlib.sha256(data).hexdigest()}\nwith open(f\"{DAY}/manifest.json\", \"w\") as f:\n    json.dump(manifest, f)\nprint(\"wrote rides.csv, then manifest.json\")\n", "note": "O manifesto vai por último, e só se tudo antes dele deu certo: o arquivo que descreve, o número de linhas e o SHA-256 dos seus bytes."}
]}
```

O carregador lê o arquivo. Com `--careful`, ele exige antes o manifesto e o checksum:

```python
# sources/load.py
import csv
import hashlib
import json
import os
import sys

DAY = "drop/2025-09-15"
data = open(f"{DAY}/rides.csv", "rb").read()
if "--careful" in sys.argv:
    if not os.path.exists(f"{DAY}/manifest.json"):
        sys.exit("no manifest.json yet: the export is not finished, loading nothing")
    manifest = json.load(open(f"{DAY}/manifest.json"))
    if hashlib.sha256(data).hexdigest() != manifest["sha256"]:
        sys.exit("rides.csv does not match its manifest, loading nothing")
rows = list(csv.DictReader(data.decode().splitlines()))
print(len(rows), "rows loaded, the last one:", rows[-1])
```

Encene a queda, carregue como um leitor apressado carregaria, e depois carregue com cuidado:

```
ana@lab:~/roda/sources$ python export.py 15000
export stopped after 15000 bytes
ana@lab:~/roda/sources$ python load.py
718 rows loaded, the last one: {'ride_id': 'R000718', 'bike_id': 'B089', 'station': 'ST', 'minutes': None}
ana@lab:~/roda/sources$ python load.py --careful
no manifest.json yet: the export is not finished, loading nothing
```

O carregamento simples levou 718 linhas de mil e não mostrou erro nenhum. A última linha é aquela que o
escritor estava escrevendo: a estação é `ST`, que não é estação nenhuma, e `minutes` é `None`, porque o
`csv.DictReader` preenche as colunas que faltam numa linha curta com `None` em vez de reclamar. O
carregamento cuidadoso procurou o marcador antes, não o achou, e não carregou nada.

Agora a exportação que termina:

```
ana@lab:~/roda/sources$ python export.py
wrote rides.csv, then manifest.json
ana@lab:~/roda/sources$ python load.py --careful
1000 rows loaded, the last one: {'ride_id': 'R001000', 'bike_id': 'B011', 'station': 'ST05', 'minutes': '3'}
ana@lab:~/roda/sources$ ls drop/2025-09-15
manifest.json
rides.csv
```

Mil linhas, e a última completa. Não carregar nada na primeira manhã é um relatório atrasado, que
alguém nota e pergunta. Carregar 718 linhas é um relatório errado em silêncio, sobre o qual ninguém
pergunta. **O carregador cuidadoso escolhe a falha que alguém vai notar.**

O checksum se paga num outro dia: um arquivo copiado com o fim cortado, ou reescrito depois de o
manifesto ser feito. Nenhum dos dois aconteceu aqui, e o manifesto também diz quantas linhas esperar,
que a aula 7 usa para conferir uma entrega contra o que foi prometido.
