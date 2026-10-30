---
title: Objetos pequenos, contados
version: 1
---

**Muitos objetos pequenos tornam caro tudo que é cobrado por operação e barato tudo que é cobrado por
byte**, e um projeto que escreve um objeto por evento escolhe o lado caro sem perceber. O
armazenamento de dois milhões de objetos de 4 KiB é o armazenamento de 7,6 GiB. As operações deles
são as operações de dois milhões de objetos, toda vez que alguém os escreve, lista, lê ou passa para
outra classe.

Isso fica mais fácil de acreditar depois de contar as requisições que um comando faz, e o emulador é
o único lugar deste curso onde dá para contar. **O fake-gcs-server registra uma linha por requisição
que responde**: o método, o caminho e o status. No terminal dele, pare-o com `Ctrl+C` e inicie de novo
com a saída copiada para um arquivo além da tela:

```sh
cd ~/gcp && export PATH="$HOME/gcp/bin:$PATH"
fake-gcs-server -scheme http -port 4443 -backend memory -location southamerica-east1 2>&1 | tee -a requests.log
```

O emulador escreve o log na saída de erro, que o `2>&1` junta à saída normal, e o `tee -a` acrescenta
cada linha a `requests.log` em `~/gcp`. **O `-a` importa**: é ele que permite esvaziar o arquivo entre
dois experimentos com `: > requests.log` e ter a próxima linha caindo no começo dele. Reiniciar o
emulador esquece todos os buckets, como a aula 1 disse, então os buckets desta aula são criados de
novo abaixo.

## Um programa que lê o log

Salve isto como `~/gcp/count.py`. Ele põe cada requisição registrada na classe que a página de preços
dá ao método dela, e calcula o preço das que foram respondidas:

```schooling-example
{"language": "python", "file": "count.py", "parts": [{"code": "\"\"\"Count the requests in fake-gcs-server's log, and price them.\"\"\"\nimport re\nimport sys\nfrom collections import Counter\n\n# USD per operation, Standard class, a bucket in one region\nPRICE = {'A': 0.005 / 1000, 'B': 0.0004 / 1000, 'free': 0.0}\nREQUEST = re.compile(r'\\\\\"([A-Z]+) (/[^ ?]*)\\S* HTTP/1\\.1\\\\\" (\\d{3})')\n\n\n", "note": "**Os preços são os da classe Standard, para um bucket numa região**, da tabela de operações da página de preços, divididos por 1.000 porque a página os imprime por mil. `REQUEST` tira o método, o caminho e o status de cada linha que o emulador registra."}, {"code": "def operation(method, path):\n    \"\"\"The JSON API method a request is, and its class.\"\"\"\n    parts = path.strip('/').split('/')\n    if parts[0] == 'upload':\n        return 'objects.insert', 'A'\n    if parts[0] == 'download':\n        return 'objects.get, data', 'B'\n    tail = parts[3:]\n    if method == 'DELETE':\n        return 'delete', 'free'\n    if not tail:\n        return ('buckets.insert' if method == 'POST' else 'buckets.list'), 'A'\n    if len(tail) == 1:\n        return ('buckets.patch', 'A') if method == 'PATCH' else ('buckets.get', 'B')\n    if tail[1] == 'storageLayout':\n        return 'buckets.getStorageLayout', 'B'\n    if tail[1] == 'o' and len(tail) == 2:\n        return 'objects.list', 'A'\n    if tail[1] == 'o' and len(tail) == 3:\n        return 'objects.get, metadata', 'B'\n    return path, '?'\n\n\n", "note": "Cada caminho da API JSON é um método, e a página de preços põe cada método numa classe. **Escrever e listar são Classe A; ler dados ou metadados é Classe B; apagar é de graça.** Um caminho que esta tabela não conhece sai com um `?` em vez de um palpite."}, {"code": "seen = Counter()\nfor line in open(sys.argv[1]):\n    m = REQUEST.search(line)\n    if m:\n        method, path, status = m.groups()\n        name, cls = operation(method, path)\n        answer = 'ok' if status.startswith('2') else status\n        seen[cls, name, answer] += 1\n\n\n", "note": "Uma contagem por classe, método e resposta. Uma requisição recusada fica à parte, porque a página de preços diz que uma requisição respondida com 4xx ou 5xx em geral não é cobrada."}, {"code": "usd = 0.0\nfor (cls, name, answer), n in sorted(seen.items()):\n    if answer == 'ok':\n        usd += n * PRICE.get(cls, 0.0)\n    print(f'{n:>5}  class {cls:<4}  {name:<26} {answer}')\nprint(f'USD {usd:.6f}, for the requests answered ok')\n", "note": "Uma linha por tipo de requisição, e o preço das que foram respondidas. A soma fica em milionésimos de dólar numa rodada deste tamanho, e é esse o ponto: o que escala é a contagem, e o próximo programa a escala."}]}
```

## Vinte toques, um por vez e empacotados

O aplicativo da Quitanda manda um evento a cada toque que o cliente dá, algumas dezenas de bytes de
JSON. Vinte deles, como vinte arquivos, enviados com um só comando:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-raw-prod --location=southamerica-east1
Creating gs://quitanda-raw-prod/...
ana@laptop:~/gcp$ mkdir -p taps && for i in $(seq -w 1 20); do printf "{\"tap\":%d,\"screen\":\"cart\"}\n" $((10#$i)) > taps/tap-$i.json; done && ls taps | head -3
tap-01.json
tap-02.json
tap-03.json
ana@laptop:~/gcp$ : > requests.log
ana@laptop:~/gcp$ gcloud storage cp --no-user-output-enabled taps/*.json gs://quitanda-raw-prod/raw/taps/dt=2026-10-01/
ana@laptop:~/gcp$ python3 count.py requests.log
   20  class A     objects.insert             ok
    1  class A     objects.list               ok
   40  class B     buckets.getStorageLayout   404
    1  class B     objects.get, metadata      404
USD 0.000105, for the requests answered ok
```

**Vinte arquivos são vinte `objects.insert`, um por objeto**, e o `gcloud` acrescentou uma listagem
própria para conferir o que já havia no destino. Essas 21 são Classe A, e são a conta:
21 × 0,005 / 1.000 = 0,000105. As 41 recusadas são o cliente fazendo perguntas que o emulador não sabe
responder. `buckets.getStorageLayout` é como o `gcloud storage` pergunta se um bucket tem namespace
hierárquico antes de escrever, duas vezes por arquivo aqui, e **o fake-gcs-server não o implementa,
então responde 404**. O Cloud Storage implementa e responde 200, e a página de preços o põe na Classe
B, então num bucket de verdade essas 40 seriam cobradas pela tarifa barata. Uma contagem feita contra
um emulador é um piso, não uma medida.

As mesmas vinte linhas, empacotadas antes num arquivo só:

```
ana@laptop:~/gcp$ : > requests.log && cat taps/*.json > taps.jsonl && gcloud storage cp --no-user-output-enabled taps.jsonl gs://quitanda-raw-prod/raw/taps-packed/dt=2026-10-01/
ana@laptop:~/gcp$ python3 count.py requests.log
    1  class A     objects.insert             ok
    1  class A     objects.list               ok
    2  class B     buckets.getStorageLayout   404
    1  class B     objects.get, metadata      404
USD 0.000010, for the requests answered ok
```

**Duas Classe A em vez de vinte e uma**, pelos mesmos bytes. A diferença é um décimo de centavo com
vinte toques, e a mesma proporção com dois milhões.

## Lendo de volta, e listando

Um painel que quer os toques de ontem precisa achá-los e depois lê-los:

```
ana@laptop:~/gcp$ : > requests.log && gcloud storage cat 'gs://quitanda-raw-prod/raw/taps/dt=2026-10-01/*.json' | wc -l
20
ana@laptop:~/gcp$ python3 count.py requests.log
    1  class A     objects.list               ok
   21  class B     buckets.getStorageLayout   404
   20  class B     objects.get, data          ok
USD 0.000013, for the requests answered ok
ana@laptop:~/gcp$ : > requests.log && gcloud storage cat gs://quitanda-raw-prod/raw/taps-packed/dt=2026-10-01/taps.jsonl | wc -l
20
ana@laptop:~/gcp$ python3 count.py requests.log
    2  class B     buckets.getStorageLayout   404
    1  class B     objects.get, data          ok
    1  class B     objects.get, metadata      ok
USD 0.000001, for the requests answered ok
```

**O curinga é uma listagem**: o Cloud Storage não tem requisição de "ler tudo debaixo deste prefixo",
então o `gcloud` lista o prefixo, uma Classe A, e depois lê cada objeto que achou, vinte Classe B. O
arquivo empacotado são duas Classe B, os metadados e depois os dados. A página de preços avisa
justamente disso, que uma ferramenta pode usar duas ou mais operações para fazer o que parece uma, e
o log é como você descobre quantas.

```
ana@laptop:~/gcp$ : > requests.log && gcloud storage ls gs://quitanda-raw-prod/raw/taps/dt=2026-10-01/ | wc -l
20
ana@laptop:~/gcp$ python3 count.py requests.log
    2  class A     objects.list               ok
    1  class B     objects.get, metadata      404
USD 0.000010, for the requests answered ok
```

**Duas listagens para imprimir vinte nomes.** O `gcloud storage ls` lista o prefixo como foi escrito
e de novo com a barra no fim, e uma listagem é Classe A seja o que for que devolva. Um prefixo de dois
milhões de nomes são duas mil páginas de mil, duas mil Classe A por passada.

## A mesma conta no tamanho da Quitanda

O aplicativo da Quitanda manda 2 milhões de toques por mês, cerca de 4 KiB cada depois que levam o
aparelho, a sessão e a tela. O primeiro projeto escreve cada um como um objeto próprio, e um painel lê
todos eles toda manhã para desenhar o último mês. Salve isto como `~/gcp/reads.py`; ele calcula o
preço desse projeto e de outros três, a partir das páginas:

```schooling-example
{"language": "python", "file": "reads.py", "parts": [{"code": "\"\"\"What reading costs against what storing costs, Cloud Storage in southamerica-east1.\"\"\"\nimport math\n\n# USD, from cloud.google.com/storage/pricing and /cdn/pricing, read 2026-10-30\nSTORE = 0.035            # Standard, per GiB-month, southamerica-east1\nA = 0.005 / 1000         # Class A: insert, list, copy, rewrite, compose\nB = 0.0004 / 1000        # Class B: get, data or metadata\nOUT = [(10_240, 0.12), (143_360, 0.11), (None, 0.08)]   # to the internet\nCDN_OUT = [(10_240, 0.09), (143_360, 0.06), (870_400, 0.05), (None, 0.04)]\nCDN_FILL = 0.02          # per GiB, from a bucket in South America\nCDN_LOOKUP = 0.0075 / 10_000\nDAYS = 30\n\n\n", "note": "**Cada preço é uma linha de uma página de preços**, com a região quando a página tem uma. `OUT` são as faixas de internet do Cloud Storage, cada uma um número de GiB e seu preço: os primeiros 10 TiB, os 140 seguintes, depois o resto. `CDN_OUT` é a escada do próprio Cloud CDN para quem está na América do Sul."}, {"code": "def tiers(gib, table):\n    \"\"\"USD for gib in one month, tier by tier.\"\"\"\n    usd, left = 0.0, gib\n    for size, price in table:\n        step = left if size is None else min(left, size)\n        usd += step * price\n        left -= step\n        if left <= 0:\n            break\n    return usd\n\n\n", "note": "Um preço em faixas é uma escada, não uma tarifa única: os primeiros 10.240 GiB do mês a 0,12, os 143.360 seguintes a 0,11. Cada degrau leva tanto do que sobra quanto a faixa dele comporta."}, {"code": "def gib(objects, kib):\n    return objects * kib / 1024 / 1024\n\n\ndef show(name, stored, requests, out):\n    store = stored * STORE\n    print(f'{name:<34}{store:>9,.2f}{requests:>10,.2f}{out:>11,.2f}'\n          f'{store + requests + out:>11,.2f}')\n\n\n", "note": "Uma contagem de objetos de um tamanho em KiB, em GiB. E uma linha da tabela: um mês de armazenamento, as requisições do mês em dólares, a transferência do mês, e a soma."}, {"code": "taps = gib(2_000_000, 4)\nfiles = math.ceil(taps * 1024 / 64)\npages = math.ceil(2_000_000 / 1000)\nprint(f'{\"a month\":<34}{\"storage\":>9}{\"requests\":>10}{\"transfer\":>11}{\"total\":>11}')\nshow('2M taps of 4 KiB, read daily', taps,\n     (2_000_000 + pages * DAYS) * A + 2_000_000 * DAYS * B, 0)\nshow(f'the same, in {files} files of 64 MiB', taps,\n     (files + DAYS) * A + files * DAYS * B, 0)\n\n\n", "note": "**Os toques são escritos uma vez no mês e lidos uma vez por dia.** Lê-los significa listar o prefixo antes, mil nomes por página, o que é Classe A, e depois um `GET` por objeto, que é Classe B. Empacotados em arquivos de 64 MiB, os mesmos bytes são 123 objetos."}, {"code": "downloads = 20 * 1024 * 1024 * 1024 // 400\nmisses = downloads // 20\nshow('500 GiB of images, 20 TiB out', 500, downloads * B, tiers(20_480, OUT))\nshow('the same behind Cloud CDN', 500,\n     misses * B + downloads * CDN_LOOKUP,\n     tiers(20_480, CDN_OUT) + 1_024 * CDN_FILL)\n", "note": "As imagens de produtos da Quitanda: uma biblioteca de 500 GiB da qual saem 20 TiB por mês em downloads, em arquivos de 400 KiB. Atrás do Cloud CDN, 19 de cada 20 downloads são respondidos pelo cache dele, e todo download é uma consulta ao cache."}]}
```

```
ana@laptop:~/gcp$ python3 reads.py
a month                             storage  requests   transfer      total
2M taps of 4 KiB, read daily           0.27     34.30       0.00      34.57
the same, in 123 files of 64 MiB       0.27      0.00       0.00       0.27
500 GiB of images, 20 TiB out         17.50     21.47   2,355.20   2,394.17
the same behind Cloud CDN             17.50     41.34   1,556.48   1,615.32
```

**O mês do painel dá 34,57, dos quais 0,27 são armazenamento.** O resto são requisições: 2.000.000 de
inserts a 0,005 o milhar dão 10,00; a listagem da manhã, 2.000 páginas por 30 dias, dá 0,30; e
2.000.000 de leituras por dia durante 30 dias são 60 milhões a 0,0004 o milhar, 24,00. Ler e escrever
custam 128 vezes o que guardar custa, e nada nos dados mudou além de como foram cortados.

**Empacotar os toques em arquivos de 64 MiB leva as requisições a 0,00**: 123 arquivos, escritos uma
vez e lidos 123 vezes por dia, custam frações de centavo, pelos mesmos 7,63 GiB. Esse é um dos
motivos de data lakes manterem arquivos grandes, e a aula 17 encontra a mesma pressão do lado do
BigQuery, quando uma consulta lê arquivos direto de um bucket e cada arquivo pequeno é mais um para
abrir.

## De onde vêm os objetos pequenos

Ninguém projeta dois milhões de arquivos minúsculos de propósito. Eles chegam:

- **de streams**, onde algo escreve o que chegou nos últimos segundos, que as aulas 21 e 22 encontram
  com o Dataflow e suas janelas;
- **de partições finas demais para os dados**, um prefixo por hora por cliente, cada um com um arquivo
  de poucas linhas;
- **de projetos de um objeto por registro**, o toque acima, cômodo de escrever e ruinoso de ler.

A cura é a mesma em todos os casos: escrever menos objetos, e maiores, ou juntar os pequenos em
grandes num horário fixo. O Cloud Storage tem uma requisição para a segunda, `objects.compose`, que
junta até 32 objetos num só sem baixá-los, a uma Classe A por chamada. E as classes mais frias da aula
2 punem objetos pequenos duas vezes: cada leitura de um toque de 4 KiB guardado no Coldline é uma
Classe B a 0,01 o milhar, vinte e cinco vezes a do Standard, antes da taxa de recuperação.

## Passá-los para uma classe mais fria também é uma operação

**Mudar a classe de um objeto é uma operação Classe A, cobrada pela tarifa da classe para onde ele
vai.** A página de preços diz isso numa nota de rodapé, e acrescenta que vale quando quem faz a
mudança é uma regra de ciclo de vida da aula 3, com o aviso de que isso pesa muito numa conta em que a
maioria dos objetos tem menos de 1 MB. Para os toques, a conta é curta:

```
ana@laptop:~/gcp$ python3 -c 'print(2_000_000 * 0.02 / 1000, round(7.63 * (0.035 - 0.007), 4))'
40.0 0.2136
```

**Passar dois milhões de toques para o Coldline custa 40,00 uma vez, para economizar 0,2136 por
mês.** Isso se paga depois de quinze anos, e isso antes da primeira leitura pelos preços do Coldline.
Uma regra de ciclo de vida que estava certa para 500 GiB de exportações de pedidos em algumas centenas
de arquivos está errada quando apontada para um prefixo de toques, e nada na regra diz qual dos dois
ela está olhando. Conte os objetos debaixo de um prefixo antes que uma regra os mova.

As duas últimas linhas da tabela são da próxima seção.
