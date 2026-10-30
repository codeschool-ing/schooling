---
title: Regiões pareadas, e quanto custa atravessar uma fronteira
version: 1
---

**A maioria das regiões do Azure tem um par: uma segunda região, normalmente na mesma geografia, que a
Microsoft trata como parceira.** O pareamento é decisão da Microsoft, não sua, e faz três coisas:

- **as atualizações da plataforma são aplicadas a uma região do par de cada vez**, então uma
  atualização com defeito chega a uma das duas antes da outra;
- **numa pane ampla, uma região de cada par é a primeira da fila de recuperação**;
- **alguns serviços replicam para o par por conta própria.** Uma storage account configurada com
  armazenamento georredundante copia cada escrita para a região pareada, e você não escolhe onde.

O par está em `metadata.pairedRegion` de cada região no `az account list-locations`, que este
laboratório não consegue rodar, e numa tabela da documentação da Microsoft, que é de onde estes dois
vêm:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l01-pairs\" aria-label=\"Quatro regiões e os pares que a Microsoft documenta para elas. brazilsoutheast, no Rio de Janeiro, tem como par brazilsouth, em São Paulo. brazilsouth tem como par southcentralus, no Texas, fora da sua própria geografia. southcentralus e northcentralus são par uma da outra. As setas do Rio para São Paulo e de São Paulo para o Texas vão num sentido só.\"><defs><marker id=\"l01-pairs-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-pairs-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"70.0\" width=\"140.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"100.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">brazilsoutheast</text><text x=\"100.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Rio de Janeiro</text><rect x=\"205.0\" y=\"70.0\" width=\"140.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"275.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">brazilsouth</text><text x=\"275.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">São Paulo</text><rect x=\"380.0\" y=\"70.0\" width=\"140.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"450.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">southcentralus</text><text x=\"450.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Texas</text><rect x=\"555.0\" y=\"70.0\" width=\"140.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"625.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">northcentralus</text><text x=\"625.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Illinois</text><text x=\"117.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">Brasil</text><text x=\"467.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">Estados Unidos</text><path d=\"M30.0 52.0 L345.0 52.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M380.0 52.0 L695.0 52.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M171.0 99.0 L204.0 99.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l01-pairs-af-ah-amber)\"></path><path d=\"M346.0 99.0 L379.0 99.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l01-pairs-af-ah-amber)\"></path><path d=\"M521.0 92.0 L554.0 92.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l01-pairs-af-ah-phosphor)\"></path><path d=\"M554.0 106.0 L521.0 106.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l01-pairs-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">uma seta: o par vale num sentido só, e a região apontada tem outro par</text><text x=\"360.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">duas setas: duas regiões que são par uma da outra</text></svg>", "caption": "O par de São Paulo fica no Texas, e o par do Texas não é São Paulo.", "same": ["Illinois", "Rio de Janeiro", "São Paulo", "Texas"]}
```

**O par de São Paulo não fica no Brasil.** A `brazilsouth` é pareada com a `southcentralus`, no
Texas, e o pareamento vale num sentido só: o par da própria South Central US é a North Central US. A
`brazilsoutheast` é pareada com a `brazilsouth`. Então uma storage account em São Paulo com replicação
georredundante guarda a segunda cópia nos Estados Unidos, e **para uma empresa obrigada a manter os
dados no Brasil essa é uma decisão que o pareamento tomou por ela**. A saída é replicar por conta
própria, para uma região que você escolhe, que para dados que precisam ficar no país é a
`brazilsoutheast`, a região que a Microsoft abre por esse motivo.

Pares são uma propriedade das regiões mais antigas. Várias regiões abertas nos últimos anos não têm
par nenhum, e contam com as suas zonas de disponibilidade; o conselho da própria Microsoft é desenhar a
recuperação em torno das regiões de que o seu sistema precisa, e tratar o par como um dado entre
vários.

## Atravessar uma fronteira tem preço

Toda seta entre dois lugares no Azure é dado se movendo, e mover dado é cobrado por gigabyte, a um
preço que depende de qual fronteira ele atravessa:

| o dado vai | o que a Microsoft cobra, pela lista de preços |
|---|---|
| da internet para dentro do Azure | nada |
| entre zonas de disponibilidade de uma região | nada, quando este curso foi escrito |
| entre duas regiões | um preço por GB, mais alto entre continentes do que dentro de um |
| do Azure para a internet | um preço por GB que cai com o volume, por faixas, e depende da região de onde sai |

**Os valores mesmo estão na lista de preços da Microsoft e em nenhum outro lugar**, e mudam. A lista é
pública por uma API que não precisa de conta, e o programa abaixo a lê.

## Lendo a lista de preços você mesmo

Salve isto como `~/azure/price.py`:

```schooling-example
{"language": "python", "file": "price.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Read Azure's public price list: price.py SERVICE REGION [TEXT].\"\"\"\nimport json\nimport sys\nimport urllib.parse\nimport urllib.request\n\nAPI = 'https://prices.azure.com/api/retail/prices'\n\n", "note": "Só a biblioteca padrão, então roda no ambiente virtual do laboratório e fora dele. `API` é a **Retail Prices API** da Microsoft, que responde a qualquer um: sem conta, sem chave, sem login."}, {"code": "def prices(service, region):\n    query = f\"serviceName eq '{service}' and armRegionName eq '{region}' and priceType eq 'Consumption'\"\n    url = API + '?' + urllib.parse.urlencode({'$filter': query})\n", "note": "O filtro é OData, uma linguagem de consulta escrita dentro do endereço. `serviceName` e `armRegionName` recebem os textos exatos que a lista de preços usa, como `Bandwidth` e `brazilsouth`. `Consumption` fica com os preços de pagamento conforme o uso e deixa de fora as reservas, que a lição 14 lê."}, {"code": "    while url:\n        with urllib.request.urlopen(url, timeout=60) as reply:\n            page = json.load(reply)\n        yield from page['Items']\n        url = page.get('NextPageLink')\n\n\n", "note": "Uma página guarda no máximo mil preços, e `NextPageLink` é o endereço da próxima, ausente na última. Segui-lo até ele sumir é o único jeito de ter certeza de que você pegou todos."}, {"code": "def main():\n    service, region = sys.argv[1], sys.argv[2]\n    text = sys.argv[3].lower() if len(sys.argv) > 3 else ''\n    for p in prices(service, region):\n        name = f\"{p['productName']} | {p['meterName']}\"\n        if text not in name.lower():\n            continue\n        print(f\"{p['retailPrice']:>10.4f} {p['currencyCode']} per {p['unitOfMeasure']:<8}\"\n              f\" from {p['tierMinimumUnits']:>8g}  {name}  ({p['effectiveStartDate'][:10]})\")\n\n\nmain()\n", "note": "Cada preço é um **medidor**: a coisa que se conta, a sua unidade e o seu preço por unidade. `tierMinimumUnits` é onde uma faixa começa, já que alguns medidores ficam mais baratos depois de uma quantidade. **`effectiveStartDate` é a data em que aquele preço passou a valer**, e é a data a citar ao lado de qualquer preço que você repetir."}]}
```

Depois peça a ele os medidores de banda de São Paulo, ficando com os que falam de transferência de
dados:

```sh
python3 price.py Bandwidth brazilsouth 'data transfer'
```

Cada linha que ele imprime é um preço, em dólares americanos, por unidade, a partir da primeira
unidade da faixa, com o nome do medidor e a data em que passou a valer. Rode-o com `southcentralus` no
lugar e compare: o que custa sair de São Paulo contra o que custa sair do Texas é o argumento inteiro
desta seção, em duas listas.

**Este programa não foi executado para o curso.** A máquina onde as lições foram gravadas não tem
permissão para alcançar `prices.azure.com`, então não há transcrição aqui, e nenhum preço destas
lições vem dele. Ele foi conferido como Python correto e que segue as páginas da API; os preços são
seus para ler. As lições 13 a 15, que são sobre dinheiro, não citam nenhum valor como sendo do Azure
sem dizer de onde ele veio, e raciocinam com números redondos que dizem que são redondos.

**Escreva a data ao lado de qualquer preço que você repetir**, a partir do `effectiveStartDate` que o
programa imprime. Um preço sem data é uma afirmação que ninguém consegue conferir, e daqui a um ano
estará errado sem ninguém ter percebido a mudança.
