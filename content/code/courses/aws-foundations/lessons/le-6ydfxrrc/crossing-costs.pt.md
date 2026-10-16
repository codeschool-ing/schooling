---
title: Quanto custa atravessar uma fronteira
version: 1
---

**Dentro da AWS, dados são cobrados pelas fronteiras que atravessam.** Entrar na AWS vindo da
internet é grátis. Entre duas máquinas na mesma zona, pelos endereços privados, é grátis. Todo o
resto tem um preço por gigabyte, e o preço depende de **qual fronteira, e em que sentido**. Esta é a
linha da fatura que ninguém previu, porque ela não está presa a máquina nenhuma: está presa às setas
entre elas.

## Uma lista de preços que se lê sem conta

A AWS publica cada preço que cobra como arquivos JSON, um por serviço e região, em endereços que não
pedem conta nem chave. Cada arquivo é uma **oferta** (*offer*), e a AWS guarda toda versão que já
publicou, então um número de versão fixa uma lista de preços do jeito que um número de versão fixa
um programa. O programa abaixo lê uma oferta e imprime as linhas que você pedir. Salve-o como
`~/aws/price.py`; lições posteriores o usam para outros serviços.

```schooling-example
{"language": "python", "file": "price.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Reads lines of the AWS public price list, with no account and no key.\n\n    python3 price.py OFFER VERSION REGION USAGETYPE...\n\nOFFER is a service's code in the list (AWSDataTransfer, AmazonEC2, ...),\nVERSION one of the versions AWS keeps of it, so the answer never moves, and\neach USAGETYPE a line of that offer's bill. The file is downloaded once into\n~/.cache/aws-prices and read from there afterwards.\n\"\"\"\n", "note": "Para que serve o programa, e como chamá-lo. Os três argumentos antes dos tipos de uso são o que torna uma resposta repetível: a mesma oferta, na mesma versão, para a mesma região, sempre imprime os mesmos preços."}, {"code": "import json\nimport os\nimport sys\nimport urllib.request\n\n", "note": "Só a biblioteca do próprio Python. Nada para instalar, e nada que precise do ambiente virtual."}, {"code": "BASE = 'https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws'\nCACHE = os.path.expanduser('~/.cache/aws-prices')\n\n\n", "note": "Onde a lista de preços mora, e onde o programa guarda o que baixou. O endereço é público: não há conta nele, nem chave."}, {"code": "def offer(code, version, region):\n    os.makedirs(CACHE, exist_ok=True)\n    path = os.path.join(CACHE, f'{code}-{version}-{region}.json')\n    if not os.path.exists(path):\n        url = f'{BASE}/{code}/{version}/{region}/index.json'\n        urllib.request.urlretrieve(url, path + '.part')\n        os.rename(path + '.part', path)\n    with open(path) as f:\n        return json.load(f)\n\n\n", "note": "Busca uma oferta numa versão, uma vez. Grava num arquivo terminado em `.part` e só o renomeia quando o download termina, então um download quebrado nunca é confundido com um completo."}, {"code": "def main():\n    code, version, region, *usages = sys.argv[1:]\n    doc = offer(code, version, region)\n    print(f'{code} {doc[\"version\"]}, published {doc[\"publicationDate\"][:10]}, USD')\n", "note": "Os argumentos, e a linha de cabeçalho: qual oferta, qual versão, e o dia em que a AWS a publicou. Essa data é a que uma lição cita ao lado de um preço."}, {"code": "    for usage in usages:\n        found = []\n        for sku, product in doc['products'].items():\n            if product['attributes'].get('usagetype') != usage:\n                continue\n            for term in doc['terms']['OnDemand'].get(sku, {}).values():\n                for d in term['priceDimensions'].values():\n                    found.append((float(d['beginRange']), d['endRange'],\n                                  d['pricePerUnit']['USD'], d['unit']))\n", "note": "Uma oferta é uma lista de produtos, cada um com um tipo de uso, e uma lista separada de termos que lhes dão preço. Isto percorre as duas e guarda cada preço do tipo de uso pedido. On-demand é o termo sem compromisso; a lição 14 lê os outros."}, {"code": "        print(usage)\n        if not found:\n            print('  not in this offer')\n        for begin, end, price, unit in sorted(found):\n            end = end if end == 'Inf' else f'{float(end):,.0f}'\n            print(f'  {begin:>9,.0f} to {end:>9} {unit:<4} {float(price):.4f}')\n\n\nmain()\n", "note": "Um tipo de uso pode ter várias faixas, cada uma uma faixa de gigabytes ou horas com preço próprio. Elas são impressas em ordem, a partir da primeira unidade do mês."}]}
```

Um **tipo de uso** (*usage type*) é o nome que uma fatura dá a um tipo de consumo, como gigabytes
enviados de São Paulo para a Virgínia. Cada região prefixa os seus, `SAE1-` para São Paulo; a
`us-east-1`, a região mais antiga, na maior parte não tem prefixo nenhum. Rode-o para São Paulo:

```
ana@laptop:~/aws$ python3 price.py AWSDataTransfer 20260916132208 sa-east-1 SAE1-DataTransfer-Regional-Bytes SAE1-USE1-AWS-Out-Bytes SAE1-DataTransfer-Out-Bytes SAE1-DataTransfer-In-Bytes
AWSDataTransfer 20260916132208, published 2026-09-16, USD
SAE1-DataTransfer-Regional-Bytes
          0 to       Inf GB   0.0100
SAE1-USE1-AWS-Out-Bytes
          0 to       Inf GB   0.1380
SAE1-DataTransfer-Out-Bytes
          0 to    10,240 GB   0.1500
     10,240 to    51,200 GB   0.1380
     51,200 to   153,600 GB   0.1260
    153,600 to       Inf GB   0.1140
SAE1-DataTransfer-In-Bytes
          0 to       Inf GB   0.0000
```

E para as mesmas travessias, partindo da Virgínia:

```
ana@laptop:~/aws$ python3 price.py AWSDataTransfer 20260916132208 us-east-1 USE1-SAE1-AWS-Out-Bytes DataTransfer-Out-Bytes
AWSDataTransfer 20260916132208, published 2026-09-16, USD
USE1-SAE1-AWS-Out-Bytes
          0 to       Inf GB   0.0200
DataTransfer-Out-Bytes
          0 to    10,240 GB   0.0900
     10,240 to    51,200 GB   0.0850
     51,200 to   153,600 GB   0.0700
    153,600 to       Inf GB   0.0500
ana@laptop:~/aws$ ls ~/.cache/aws-prices
AWSDataTransfer-20260916132208-sa-east-1.json
AWSDataTransfer-20260916132208-us-east-1.json
```

Estes são os preços da lista que a AWS publicou em **16 de setembro de 2026**, em dólares e sem
impostos.

## Lendo as quatro linhas

| travessia | saindo de São Paulo | saindo da Virgínia |
|---|---|---|
| entre duas zonas da região | 0,0100 por GB, **em cada sentido** | 0,0100 por GB, em cada sentido |
| para a outra região | 0,1380 por GB | 0,0200 por GB |
| para a internet, primeiros 10 TB do mês | 0,1500 por GB | 0,0900 por GB |
| vindo da internet | grátis | grátis |

**Entre zonas, a cobrança é dos dois lados.** O tipo de uso é uma linha só, e a documentação da AWS
diz que ele é cobrado nos dados que saem de uma zona *e* nos que chegam à outra, então um gigabyte
que atravessa custa 0,02 no total. Um banco de dados replicando 500 GB por mês para uma réplica na
zona vizinha custa 500 × 0,02 = **10 dólares por mês só de transferência**, antes de qualquer das
duas máquinas.

**Entre regiões, o sentido decide.** Um gigabyte saindo de São Paulo para a Virgínia custa 0,138; o
mesmo gigabyte saindo da Virgínia para São Paulo custa 0,02, quase sete vezes menos. Uma cópia
noturna de 2 TB de backups de `sa-east-1` para `us-east-1` sai por 2.048 × 0,138 = **282,62 dólares
por mês**; a cópia no outro sentido sairia por 40,96. Isso não é uma esquisitice a contornar; é o
preço de levar os bytes por um caminho longo e caro, e é o que você pesa ao decidir onde mora a
cópia de alguma coisa.

**Para a internet, as faixas caem com o volume**, e São Paulo começa mais caro que a Virgínia: 0,15
contra 0,09 nos primeiros 10 TB do mês. O que as quatro linhas não mostram é que a AWS dá de graça
os primeiros 100 GB por mês enviados à internet, somados em todas as regiões de uma conta; essa
franquia está na página de preços da AWS, e não nessas linhas, então foi lida lá e não impressa pelo
programa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" data-fig=\"l01-crossings\" aria-label=\"Quanto custa atravessar cada fronteira, pela lista de preços de 16 de setembro de 2026, em dólares por gigabyte. Dentro da região de São Paulo, sa-east-1, duas Availability Zones. Entre duas máquinas na mesma zona: grátis. Entre as duas zonas: 0,01 em cada sentido. De São Paulo para a Virgínia, us-east-1: 0,138. Da Virgínia para São Paulo: 0,02. De São Paulo para a internet: 0,15 nos primeiros 10 TB do mês. Da internet para dentro: grátis.\"><defs><marker id=\"l01-crossings-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-crossings-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"430.0\" height=\"240.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"36.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"45.0\" y=\"80.0\" width=\"180.0\" height=\"170.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sa-east-1a</text><rect x=\"250.0\" y=\"80.0\" width=\"180.0\" height=\"170.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"340.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sa-east-1b</text><rect x=\"58.0\" y=\"130.0\" width=\"52.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"160.0\" y=\"130.0\" width=\"52.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M112.0 147.0 L158.0 147.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-phosphor)\" marker-start=\"url(#l01-crossings-af-ah-phosphor)\"></path><text x=\"135.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">mesma zona: grátis</text><rect x=\"310.0\" y=\"130.0\" width=\"60.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M214.0 147.0 L308.0 147.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-amber)\" marker-start=\"url(#l01-crossings-af-ah-amber)\"></path><text x=\"340.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">entre zonas:</text><text x=\"340.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">0,01 em cada sentido</text><rect x=\"520.0\" y=\"40.0\" width=\"180.0\" height=\"110.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"536.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">us-east-1</text><rect x=\"580.0\" y=\"85.0\" width=\"60.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M372.0 140.0 L432.0 127.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M432.0 127.0 L577.0 95.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-amber)\"></path><text x=\"476.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">0,138</text><path d=\"M577.0 112.0 L432.0 145.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M432.0 145.0 L374.0 158.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-phosphor)\"></path><text x=\"486.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">0,02</text><rect x=\"130.0\" y=\"330.0\" width=\"210.0\" height=\"56.0\" rx=\"26\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"358.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a internet</text><path d=\"M195.0 283.0 L195.0 326.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-amber)\"></path><text x=\"185.0\" y=\"305.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">saída: 0,15</text><path d=\"M275.0 326.0 L275.0 283.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-phosphor)\"></path><text x=\"285.0\" y=\"305.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">entrada: grátis</text><text x=\"360.0\" y=\"408.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">dólares por gigabyte, lista de preços de 16 de setembro de 2026</text></svg>", "caption": "O preço está nas setas, não nas caixas. Sair de São Paulo é o sentido caro."}
```

## O que isso muda num projeto

Três regras saem da tabela, e as lições de rede usam todas:

- **Espalhar por zonas vale o que custa, e não é de graça.** A lição 16 põe sub-redes em todas as
  zonas; a lição 22 põe um balanceador de carga na frente delas. Cada escolha de projeto que manda
  tráfego por uma fronteira de zona a cada requisição é uma linha na fatura, e o número pequeno por
  gigabyte é multiplicado por cada requisição.
- **Mantenha pares tagarelas numa zona quando a falha não importa**, como uma máquina de build e o
  cache dela, e em zonas diferentes quando importa, como um banco de dados e a réplica dele.
- **Onde mora uma cópia é um preço.** Uma segunda região para recuperação de desastre custa a
  transferência para alcançá-la todo dia, não só as máquinas que esperam lá. A lição 14 lê uma fatura
  inteira, e as linhas de transferência são por onde ela começa.

O programa deixou os arquivos que baixou em `~/.cache/aws-prices`, então perguntar de novo não custa
nada. As lições 14, 17 e 20 o rodam contra outras ofertas.
