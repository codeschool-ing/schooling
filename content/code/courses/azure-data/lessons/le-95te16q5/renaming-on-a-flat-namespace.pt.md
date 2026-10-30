---
title: Renomeando uma pasta que não existe
version: 1
---

**Num espaço de nomes plano, renomear uma pasta é renomear cada blob dela, um por vez.** A lição 2
mostrou que uma pasta é a resposta a uma listagem e não uma coisa; a consequência aparece na primeira
vez que alguém precisa mover uma. O Blob Storage não tem operação de renomear nem para um blob só,
então "mover" é copiar para o nome novo e apagar o antigo, e uma pasta de mil arquivos são dois mil
desses passos. Esta seção os conta no Azurite, que tem espaço de nomes plano como toda conta que não
pede um hierárquico.

Os dados são do tipo de que um lake está cheio. O app da Quitanda manda eventos de clique, e o stream
que os grava (lição 22) escreve muitos arquivos pequenos por dia. Mil para 29 de outubro, num
contêiner chamado `lake`:

`seed.py`:

```python
from concurrent.futures import ThreadPoolExecutor
from azure.storage.blob import BlobServiceClient

service = BlobServiceClient.from_connection_string("UseDevelopmentStorage=true")
lake = service.get_container_client("lake")
if not lake.exists():
    lake.create_container()


def put(n):
    lake.upload_blob(f"clicks/2026/10/29/part-{n:04d}.json", b'{"event": "view"}\n', overwrite=True)


with ThreadPoolExecutor(8) as pool:
    list(pool.map(put, range(1000)))
print(sum(1 for _ in lake.list_blobs(name_starts_with="clicks/")), "blobs under clicks/")
```

```
ana@laptop:~/azure$ python seed.py
1000 blobs under clicks/
```

Os analistas querem o diretório do dia chamado `date=2026-10-29`, o formato que a lição 18 explica e
que os motores de consulta leem como uma coluna. O programa que move um prefixo:

```schooling-example
{"language": "python", "file": "rename.py", "parts": [{"code": "import sys\nfrom azure.storage.blob import BlobServiceClient\n\nrequests = 0\n\n\ndef count(response):\n    global requests\n    requests += 1\n\n\nservice = BlobServiceClient.from_connection_string(\n    \"UseDevelopmentStorage=true\", raw_response_hook=count)\nlake = service.get_container_client(\"lake\")\n", "note": "`raw_response_hook` é chamado uma vez para cada resposta que o serviço devolve, então `requests` conta as idas e voltas ao serviço, que é como o Azure cobra operações."}, {"code": "\nold, new = sys.argv[1], sys.argv[2]\nstop_after = int(sys.argv[3]) if len(sys.argv) > 3 else None\n", "note": "O prefixo antigo e o novo vêm da linha de comando. O terceiro argumento, opcional, faz o programa parar depois de tantos blobs, no papel de uma queda."}, {"code": "\nmoved = 0\nfor item in lake.list_blobs(name_starts_with=old):\n    source = lake.get_blob_client(item.name)\n    target = lake.get_blob_client(new + item.name[len(old):])\n    copy = target.start_copy_from_url(source.url)\n    if copy[\"copy_status\"] != \"success\":\n        sys.exit(f\"{item.name}: copy is {copy['copy_status']}, source kept\")\n    source.delete_blob()\n    moved += 1\n    if moved == stop_after:\n        print(\"stopped after\", moved)\n        break\n", "note": "Um espaço de nomes plano não tem renomear, então cada blob é copiado para o nome novo e depois apagado. Uma cópia dentro da mesma conta costuma terminar na hora; quando responde `pending`, apagar a origem perderia os dados, então o programa para."}, {"code": "print(\"moved\", moved, \"blobs in\", requests, \"requests\")\n", "note": "A listagem também conta requisições, uma por página de até 5.000 nomes."}]}
```

## Mil arquivos, parados no meio

A primeira execução para depois de 400 blobs, como faria uma queda ou uma conexão perdida:

```
ana@laptop:~/azure$ python rename.py clicks/2026/10/29/ clicks/date=2026-10-29/ 400
stopped after 400
moved 400 blobs in 801 requests
ana@laptop:~/azure$ az storage blob list -c lake --prefix clicks/2026/10/29/ --num-results 5000 --query "length(@)"
600
ana@laptop:~/azure$ az storage blob list -c lake --prefix clicks/date=2026-10-29/ --num-results 5000 --query "length(@)"
400
```

**Os dois nomes estão em uso ao mesmo tempo.** 600 arquivos ainda estão em `clicks/2026/10/29/` e
400 estão em `clicks/date=2026-10-29/`, e as 400 movimentações custaram 801 requisições: a listagem,
400 cópias e 400 exclusões. Qualquer job que leu o dia nesse momento leu parte dele. Um job lendo o
prefixo antigo perdeu 400 arquivos; um lendo o novo achou menos de meio dia; e nada no Blob Storage
diz que havia uma movimentação em andamento, porque não há movimentação, só uma longa série de
escritas separadas.

Rode de novo sem o terceiro argumento e ele termina o serviço:

```
ana@laptop:~/azure$ python rename.py clicks/2026/10/29/ clicks/date=2026-10-29/
moved 600 blobs in 1201 requests
ana@laptop:~/azure$ az storage blob list -c lake --prefix clicks/2026/10/29/ --num-results 5000 --query "length(@)"
0
ana@laptop:~/azure$ az storage blob list -c lake --prefix clicks/date=2026-10-29/ --num-results 5000 --query "length(@)"
1000
```

Os outros 600 levaram 1.201 requisições, a listagem e duas por blob. **A renomeação inteira custou
2.002 requisições**, duas listagens e duas mil escritas, para trocar uma palavra num caminho. O Azure
cobra operações por dez mil, e na escala de um lake um dia tem centenas de milhares de arquivos, não
mil.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Renomear um diretório de 1.000 arquivos, de dois jeitos. Num espaço de nomes plano não há diretório: uma listagem, depois uma cópia e uma exclusão para cada um dos 1.000 blobs, 2.001 requisições feitas um blob por vez, e quem lê no meio vê parte dos arquivos em cada nome. Com espaço de nomes hierárquico o diretório 2026/10/29/ é um objeto próprio, e uma renomeação o move, com os 1.000 arquivos de baixo, numa operação só.\" data-fig=\"l03-rename\"><defs><marker id=\"l03-rename-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><rect x=\"20\" y=\"20\" width=\"330\" height=\"260\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"185\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">espaço de nomes plano</text><rect x=\"34\" y=\"62\" width=\"302\" height=\"22\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"44\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">clicks/2026/10/29/part-0000.json</text><rect x=\"34\" y=\"92\" width=\"302\" height=\"22\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"44\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">clicks/2026/10/29/part-0001.json</text><text x=\"185\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">…</text><rect x=\"34\" y=\"152\" width=\"302\" height=\"22\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"44\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">clicks/2026/10/29/part-0999.json</text><text x=\"185\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1 listagem</text><text x=\"185\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">+ 1.000 cópias + 1.000 exclusões</text><text x=\"185\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">= 2.001 requisições, um blob por vez</text><text x=\"185\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quem lê no meio vê os dois nomes</text><rect x=\"370\" y=\"20\" width=\"330\" height=\"260\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"535\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">espaço de nomes hierárquico</text><rect x=\"384\" y=\"62\" width=\"140\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"454\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">clicks/</text><rect x=\"404\" y=\"104\" width=\"140\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"474\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026/10/29/</text><line x1=\"424\" y1=\"88\" x2=\"424\" y2=\"103\" stroke=\"var(--wire)\" stroke-width=\"1.4\"/><rect x=\"424\" y=\"146\" width=\"180\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"514\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1.000 arquivos</text><line x1=\"444\" y1=\"130\" x2=\"444\" y2=\"145\" stroke=\"var(--wire)\" stroke-width=\"1.4\"/><line x1=\"548\" y1=\"117\" x2=\"600\" y2=\"117\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rename-ah)\"/><rect x=\"602\" y=\"104\" width=\"90\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"647\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">date=…</text><text x=\"535\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">1 renomeação de um diretório</text><text x=\"535\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">os arquivos de baixo vão junto</text><text x=\"535\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quem lê vê a árvore velha ou a nova</text></svg>", "caption": "A conta da esquerda é a que o rename.py fez contra o Azurite, numa execução só em vez de duas. A da direita é o comportamento documentado pela Microsoft e não foi rodada."}
```

## O que seria preciso para fazer melhor num espaço plano

Nada torna isso atômico. Os desenhos defensivos todos evitam a renomeação: gravar cada dia no nome
final desde o começo, ou gravar uma cópia nova e trocar os leitores para ela com um blob de manifesto
pequeno, atualizado pela escrita condicional da lição 2. Formatos de tabela para lake, como o Delta da
lição 18, seguem o segundo caminho e mantêm um log de quais arquivos pertencem a uma tabela, para que
"renomear" nunca precise tocar num arquivo.

O espaço de nomes hierárquico segue o outro caminho. Ele faz do diretório um objeto de verdade, do
qual os arquivos dependem, e a mesma renomeação vira uma operação numa entrada, atômica, seja o que for
que estiver debaixo dela. A seção anterior descreveu isso a partir da documentação da Microsoft; a
próxima mostra o que o Azurite diz quando alguém pede.
