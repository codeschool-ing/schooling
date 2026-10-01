---
title: Lendo uma lista de preços
version: 1
---

Todo provedor desta aula publica preços, e cada um publica de um jeito. **A AWS publica a lista de
preços inteira como arquivos JSON que qualquer um pode baixar, sem conta e sem chave.** O Azure tem
uma API pública própria de preços de varejo, e os outros publicam os preços em páginas web. Este
curso fixou só a lista da AWS, e é por isso que todo preço nele é da AWS; as páginas dos outros
provedores não foram capturadas, e compará-las é o seu exercício no fim desta seção.

A lista começa num índice:

```
ana@laptop:~/cloud$ curl -s https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json | jq '.offers | length'
272
ana@laptop:~/cloud$ curl -s https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json | jq -r '.publicationDate'
2026-09-28T18:21:50Z
ana@laptop:~/cloud$ curl -s https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json | jq -r '.offers | keys[]' | grep -E '^(AmazonEC2|AmazonS3|AWSLambda)$'
AWSLambda
AmazonEC2
AmazonS3
ana@laptop:~/cloud$ curl -s https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json | jq '.offers.AWSLambda'
{
  "offerCode": "AWSLambda",
  "versionIndexUrl": "/offers/v1.0/aws/AWSLambda/index.json",
  "currentVersionUrl": "/offers/v1.0/aws/AWSLambda/current/index.json",
  "currentRegionIndexUrl": "/offers/v1.0/aws/AWSLambda/current/region_index.json",
  "savingsPlanVersionIndexUrl": "/savingsPlan/v1.0/aws/AWSComputeSavingsPlan/current/index.json",
  "currentSavingsPlanIndexUrl": "/savingsPlan/v1.0/aws/AWSComputeSavingsPlan/current/region_index.json"
}
```

O índice nomeia 272 ofertas, uma por serviço com preço, no dia em que foi lido, e traz o momento em
que foi gerado. Os três nomes que este curso usa estão entre elas, escritos como o índice os
escreve. Cada entrada de oferta é um conjunto de endereços: uma lista de todas as versões já
publicadas, a versão atual, e a versão atual dividida por região.

## Quatro arquivos de profundidade

Os endereços levam a uma pequena árvore. Um preço fica quatro arquivos abaixo do índice:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Quatro caixas ligadas por setas, da esquerda para a direita. index.json, uma entrada por serviço, 272 ofertas no dia da captura. AWSLambda/, uma oferta, que guarda todas as versões. 20260919002359/, uma versão, congelada depois de publicada. sa-east-1/index.json, uma região, com 389 produtos para o Lambda. O arquivo da região se divide em products, o que se vende, e terms, o preço de cada produto. Uma nota diz que o prices.py fixa a versão.\"><defs><marker id=\"plst-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"152\" height=\"84\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"96\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">index.json</text><text x=\"96\" y=\"80.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma entrada</text><text x=\"96\" y=\"91.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">por serviço</text><path d=\"M173 72 L194 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#plst-ah)\"></path><rect x=\"196\" y=\"30\" width=\"152\" height=\"84\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"272\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">AWSLambda/</text><text x=\"272\" y=\"80.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma oferta, que</text><text x=\"272\" y=\"91.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">guarda as versões</text><path d=\"M349 72 L370 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#plst-ah)\"></path><rect x=\"372\" y=\"30\" width=\"152\" height=\"84\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"448\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">20260919002359/</text><text x=\"448\" y=\"80.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma versão, congelada</text><text x=\"448\" y=\"91.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">depois de publicada</text><path d=\"M525 72 L546 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#plst-ah)\"></path><rect x=\"548\" y=\"30\" width=\"152\" height=\"84\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"624\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">sa-east-1/index.json</text><text x=\"624\" y=\"80.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma região</text><text x=\"624\" y=\"91.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">daquela versão</text><text x=\"96\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">272 ofertas naquele dia</text><text x=\"624\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">389 produtos no Lambda</text><rect x=\"372\" y=\"160\" width=\"160\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"452\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">products</text><text x=\"452\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que se vende</text><rect x=\"548\" y=\"160\" width=\"152\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"624\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">terms</text><text x=\"624\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o preço de cada um</text><path d=\"M624 146 L624 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M600 146 L452 146 L452 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"20\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o prices.py fixa este</text><text x=\"20\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">passo, e a tabela não se move</text><path d=\"M200 180 L410 118\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#plst-ah)\"></path></svg>", "caption": "Quatro arquivos separam o índice de um preço. A versão atual muda sempre que a AWS publica; uma versão fixada não muda, e é por isso que a tabela do curso nomeia uma."}
```

A palavra **current** nesses endereços é a armadilha. A versão atual muda sempre que a AWS publica
uma nova, então um script que lê `current` imprime números diferentes no mês que vem e não sabe
dizer por quê. O `prices.py` do curso lê uma versão fixada de cada oferta. É por isso que a tabela
imprime as versões no topo: **um preço sem a versão de onde veio não pode ser conferido por
ninguém.**

Quanto cabe no arquivo de uma região depende do serviço:

```
ana@laptop:~/cloud$ curl -s https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSLambda/20260919002359/sa-east-1/index.json | jq '.products | length'
389
ana@laptop:~/cloud$ jq '.products | length' ~/.cache/cloud-prices/AmazonEC2-20260925174521-sa-east-1.json
65165
```

O Lambda tem 389 produtos em São Paulo. O EC2 tem 65.165, porque cada tamanho de máquina é um
produto várias vezes: por sistema operacional, por modelo de licença, por tipo de locação. Essa
contagem é o que "uma lista de preços com dezenas de milhares de linhas" queria dizer antes nesta
aula, e é de um serviço numa região.

## Duas linhas da tabela

O `prices.py` lê esses arquivos e imprime as poucas linhas que o curso usa. O bloco do EC2, a partir
do diretório do curso:

```
ana@laptop:~/cloud$ python3 prices.py ec2 | sed -n '1,17p'
AWS public price list, USD, excluding tax
  offer AmazonEC2        version 20260925174521
  offer AWSLambda        version 20260919002359
  offer AmazonS3         version 20260926015512
  offer AWSDataTransfer  version 20260916132208
  offer AmazonEFS        version 20260911124425
  offer AmazonVPC        version 20260917190528
                                        sa-east-1    us-east-1

EC2, Linux, on demand, USD per hour
  t3.micro    2 vCPU   1 GiB              0.01680      0.01040
  t4g.small   2 vCPU   2 GiB              0.02680      0.01680
  t3.medium   2 vCPU   4 GiB              0.06720      0.04160
  m7i.large   2 vCPU   8 GiB              0.16065      0.10080
  m7g.large   2 vCPU   8 GiB              0.13010      0.08160
  c7i.large   2 vCPU   4 GiB              0.13755      0.08925
  m7i.xlarge  4 vCPU  16 GiB              0.32130      0.20160
ana@laptop:~/cloud$ python3 -c 'print(round(0.16065 / 0.10080, 2))'
1.59
```

A tabela é a lista pública de `sa-east-1` (São Paulo) e `us-east-1` (Norte da Virgínia), em dólares
americanos, sem impostos, nas versões de oferta que ela imprime. Leia uma linha de ponta a ponta:
`m7i.large`, dois processadores virtuais e 8 GiB de memória, custa `0.16065` USD por hora em São
Paulo e `0.10080` na Virgínia. **A mesma máquina, do mesmo provedor, custa em São Paulo 1,59 vez o preço da Virgínia.** As outras linhas mais ou menos concordam: `t3.micro` custa `0.01680` contra `0.01040`, que
dá 1,62.

Um preço por hora é difícil de sentir, então transforme-o num mês. O programa abaixo faz a conta às
claras, e é ele que você vai estender ao comparar provedores:

```schooling-example
{
  "language": "python",
  "file": "compare.py",
  "parts": [
    {
      "code": "HOURS = 730  # 24 * 365 / 12\n\n",
      "note": "Um mês em horas: 24 × 365 / 12 dá 730. Uma lista de preços cota por hora e um orçamento se escreve por mês, então esta é a ponte entre os dois."
    },
    {
      "code": "m7i_large = {  # USD per hour, Linux, on demand\n    'sa-east-1': 0.16065,\n    'us-east-1': 0.10080,\n}\n\n",
      "note": "Duas linhas da tabela, copiadas com todos os dígitos que ela imprimiu. Arredondar aqui é como uma comparação se afasta da fonte. Ao comparar provedores, é aqui que entram os preços deles, cada um com a data em que você o leu."
    },
    {
      "code": "for region, hourly in m7i_large.items():\n    print(f'{region}  {hourly * HOURS:7.2f} USD a month')\n\n",
      "note": "Preço por hora vezes as horas de um mês: a máquina ligada o mês inteiro, que é o que um servidor faz."
    },
    {
      "code": "print(f'ratio      {m7i_large[\"sa-east-1\"] / m7i_large[\"us-east-1\"]:.2f}')\n",
      "note": "A razão diz o mesmo que os dois valores, num número só que não depende de quanto tempo a máquina roda."
    }
  ],
  "output": "sa-east-1   117.27 USD a month\nus-east-1    73.58 USD a month\nratio      1.59\n"
}
```

Uma máquina que roda o mês inteiro em São Paulo custa `117.27` USD a preço de tabela, e `73.58` na
Virgínia. A diferença é real, e também é só uma linha. A aula 9 trata do que a distância até a
Virgínia custa a um usuário no Brasil, que é o outro lado da mesma escolha.

## O que a lista não diz

Uma lista de preços é o ponto de partida de uma fatura, não a fatura. Ela deixa de fora três coisas:

- Descontos. A tabela traz preços reservados ao lado dos preços sob demanda, e clientes grandes
  negociam os próprios. A aula 10 trata dos dois.
- Níveis gratuitos. Alguns serviços dão uma quantidade por mês, e o bloco do Lambda na tabela lista a
  dele.
- O formato da fatura. Uma máquina chega com um disco, um endereço e os dados que envia, cada um com
  preço numa linha própria da tabela. O preço por hora da máquina é, em geral, a maior linha, e nunca
  a única.

## O seu exercício

Para comparar com os provedores cujas páginas este curso não capturou, use o mesmo método:

1. escolha um formato de máquina, como 2 vCPU e 8 GiB, e uma região por provedor;
2. anote cada preço com a data em que o leu e a página de onde veio;
3. leve todos os preços à mesma unidade, por hora ou por mês de 730 horas;
4. anote o que o preço inclui: o disco, o endereço público, uma cota de transferência;
5. compare o total do que a sua aplicação precisa, e não só a linha da máquina.

O passo 4 é onde os provedores menores defendem o seu caso, e o passo 5 é onde a comparação deixa de
ser sobre um número só.
