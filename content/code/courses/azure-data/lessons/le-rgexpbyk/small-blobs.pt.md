---
title: O problema dos blobs pequenos
version: 1
---

**Muitos blobs pequenos deixam caro tudo o que tem preço por operação e barato tudo o que tem preço
por byte**, e um desenho que escreve um blob por evento escolhe o lado caro sem perceber. Dois milhões
de toques de 4 KB são 7,63 GB de armazenamento. São também dois milhões de blobs, toda vez que alguém
os lê, lista, copia ou move para outro nível.

O app da Quitanda manda uns 2 milhões de toques por mês. O primeiro desenho escreve cada toque como
um blob próprio, como o `count.py` fez, e um painel lê todos eles toda manhã para desenhar o último
mês. O programa abaixo põe preço nisso e em outros quatro desenhos, aos preços ilustrativos desta
lição. Ele não precisa de emulador. Salve-o como `~/azure/costs.py`:

```schooling-example
{"language": "python", "file": "costs.py", "parts": [{"code": "\"\"\"A month of Blob Storage, meter by meter, at ILLUSTRATIVE prices.\"\"\"\nimport math\n\n# Round numbers to do the sums with, NOT Azure's prices: prices.py prints those.\nTIERS = {  # USD: per GB-month, per 10,000 writes, per 10,000 reads, per GB retrieved\n    \"hot\": (0.020, 0.05, 0.004, 0.00),\n    \"cool\": (0.010, 0.10, 0.010, 0.01),\n}\nLIST = 0.05            # per 10,000 list operations\nEGRESS = 0.10          # per GB to the internet, past the free allowance\nFREE = 100             # GB a month to the internet at no charge\nDAYS = 30\n", "note": "**Todo preço aqui é inventado, e o comentário diz isso em maiúsculas.** São números redondos com o formato que a tabela da Microsoft tem: o nível cool cobra menos para guardar e mais para mexer, escritas custam mais que leituras, e ler do cool tem uma cobrança por gigabyte que o hot não tem. Troque-os pelo que o `prices.py` imprime para a sua região e o programa faz as mesmas contas com dinheiro de verdade."}, {"code": "\n\ndef money(x):\n    return '-' if x is None else f'{x:,.2f}'\n\n\ndef show(name, tier, stored_gb, writes, reads, lists, read_gb, out_gb):\n    store_p, write_p, read_p, retrieve_p = TIERS[tier]\n    store = stored_gb * store_p\n    ops = (writes * write_p + reads * read_p + lists * LIST) / 10_000\n    retrieval = read_gb * retrieve_p\n    out = None if out_gb is None else max(0, out_gb - FREE) * EGRESS\n    total = None if out is None else store + ops + retrieval + out\n    print(f'{name:<34}{money(store):>8}{money(ops):>10}{money(retrieval):>11}'\n          f'{money(out):>10}{money(total):>10}')\n", "note": "Uma linha da tabela: um mês de armazenamento, de operações, de recuperação e de transferência para a internet, e a soma. **As operações são divididas por 10.000 porque essa é a unidade em que o Azure as precifica**, o erro de que a lição 1 avisou. Uma transferência que o programa não sabe precificar imprime um traço, e o total também."}, {"code": "\n\ntaps_gb = 2_000_000 * 4 / 1024 / 1024\npages = math.ceil(2_000_000 / 5_000)\nfiles = math.ceil(taps_gb * 1024 / 64)\ndownloads = 20_480 * 1024 * 1024 // 400\n", "note": "**O mês da Quitanda, em contagens.** Dois milhões de toques de 4 KB cada, que são 7,63 GB. Listá-los leva uma requisição a cada 5.000 nomes. Empacotados em arquivos de 64 MiB, são 123 arquivos. E as imagens dos produtos: 20 TB servidos para a internet em fotos de 400 KB são 53.687.091 downloads."}, {"code": "\nprint(f'{\"a month\":<34}{\"storage\":>8}{\"ops\":>10}{\"retrieval\":>11}'\n      f'{\"transfer\":>10}{\"total\":>10}')\nshow('2M taps, a blob each, hot', 'hot', taps_gb,\n     2_000_000, 2_000_000 * DAYS, pages * DAYS, taps_gb * DAYS, 0)\nshow('the same, in cool', 'cool', taps_gb,\n     2_000_000, 2_000_000 * DAYS, pages * DAYS, taps_gb * DAYS, 0)\nshow(f'the same, {files} files of 64 MiB, hot', 'hot', taps_gb,\n     files, files * 9 * DAYS, DAYS, taps_gb * DAYS, 0)\nshow('500 GB of images, 20 TB out', 'hot', 500, 0, downloads, 0, 0, 20_480)\nshow('the same behind a CDN', 'hot', 500, 0, downloads // 20, 0, 0, None)\n", "note": "**Cinco desenhos, uma linha cada.** Os toques são escritos uma vez no mês e cada um é lido toda manhã, depois de listados. Os mesmos toques em arquivos de 64 MiB são lidos em nove requisições cada, porque é assim que a biblioteca busca um blob desse tamanho, como o `count.py` mostrou para 80 MiB em treze. Atrás de uma rede de entrega de conteúdo, um download em vinte chega à conta e o resto sai das cópias da rede; o preço da própria rede não está neste programa."}]}
```

```
ana@laptop:~/azure$ python costs.py
a month                            storage       ops  retrieval  transfer     total
2M taps, a blob each, hot             0.15     34.06       0.00      0.00     34.21
the same, in cool                     0.08     80.06       2.29      0.00     82.43
the same, 123 files of 64 MiB, hot    0.15      0.01       0.00      0.00      0.17
500 GB of images, 20 TB out          10.00     21.47       0.00  2,038.00  2,069.47
the same behind a CDN                10.00      1.07       0.00         -         -
```

**O mês do painel é 34,21, dos quais 0,15 é armazenamento.** O resto são operações: 2.000.000 de
escritas a 0,05 por 10.000 dão 10,00, 2.000.000 de leituras por dia durante 30 dias são 60 milhões a
0,004 por 10.000, que dão 24,00, e as 400 listagens por dia são 0,06. Só as leituras custam 160 vezes
o armazenamento.

**Mover os mesmos blobs para o cool piora**: 82,43 contra 34,21. O armazenamento cai pela metade, de
0,15 para 0,08, e todo o resto cresce, porque o cool cobra mais por cada operação e soma 0,01 por cada
um dos 228,88 GB lidos de volta no mês, 2,29. O cool é para dados guardados e raramente tocados, a
regra que a lição 4 tirou dos dias mínimos. A fonte de um painel lido toda manhã é o oposto.

**Empacotar os toques em arquivos de 64 MiB leva as operações a 0,01**: 123 arquivos, escritos uma vez
e lidos em nove requisições cada, toda manhã. Os bytes guardados são os mesmos 7,63 GB, e o mês cai de
34,21 para 0,17. Esse é um dos motivos de lagos de dados manterem os arquivos grandes, e a lição 18
volta a isso com os arquivos pequenos que um job de streaming deixa para trás e a compactação que os
junta.

## De onde vêm os blobs pequenos

Ninguém desenha dois milhões de arquivos minúsculos de propósito. Eles chegam:

- **de streams**, onde algo grava o que chegou nos últimos segundos, que a lição 22 encontra com o
  Event Hubs e a sua captura para o armazenamento;
- **de partições finas demais para os dados**, uma pasta por hora por cliente, cada uma com um arquivo
  de poucas linhas;
- **de desenhos de um blob por registro**, o toque acima, cômodo de escrever e ruinoso de ler.

A cura é a mesma toda vez: escrever menos blobs, maiores, ou compactar os pequenos em grandes numa
agenda. Os níveis mais frios castigam os blobs pequenos ainda mais, já que cada blob lido deles é uma
operação ao preço mais alto daquele nível, por menos bytes que tenha.

As duas últimas linhas da tabela são da próxima seção.
