---
title: Uma fatura, e os preços por volume que ela soma
version: 1
---

**A conta de gerenciamento paga pela organização inteira, e a AWS precifica a organização como se
ela fosse uma conta só.** A imagem errada é um envelope: seis faturas grampeadas e mandadas para um
endereço, cada uma precificada como se as outras não existissem. A primeira metade disso é
verdade. As cobranças de cada membro ainda aparecem sob o número da sua conta. A segunda metade não
é, e onde um preço tem faixas, a diferença é dinheiro.

## Um pagador

O **faturamento consolidado** é a parte do Organizations que toda organização tem, seja qual for o
conjunto de recursos. A conta de gerenciamento é a **pagadora**: ela guarda o meio de pagamento,
recebe a fatura e a paga. Os membros aparecem nessa fatura um por um, com o que cada um usou, então
"quanto custou a `shop-staging` em setembro" é uma linha e não uma estimativa. Uma conta criada
dentro da organização não tem cartão próprio, e a lição 2 disse que ela não custa nada para ter.

## Faixas de volume são contadas pela organização

Alguns preços caem à medida que o uso do mês cresce. A lição 1 imprimiu um deles, dados enviados de
São Paulo para a internet; aqui está ele de novo, da mesma lista:

```
ana@laptop:~/aws$ python3 price.py AWSDataTransfer 20260916132208 sa-east-1 SAE1-DataTransfer-Out-Bytes
AWSDataTransfer 20260916132208, published 2026-09-16, USD
SAE1-DataTransfer-Out-Bytes
          0 to    10,240 GB   0.1500
     10,240 to    51,200 GB   0.1380
     51,200 to   153,600 GB   0.1260
    153,600 to       Inf GB   0.1140
```

Os primeiros 10.240 GB de um mês custam 0,15 por GB, e os seguintes 0,138. **Para as faixas, a AWS
soma o uso de toda conta da organização antes de precificar qualquer parte dele.** Essa é a regra
documentada da AWS para o faturamento consolidado, e a explicação dela usa uma faixa de transferência
de dados como exemplo.

Suponha que a `shop-prod` e a `shop-staging` mandem cada uma 8 TB, 8.192 GB, para a internet num
mês:

| | gigabytes a 0,15 | gigabytes a 0,138 | dólares |
|---|---|---|---|
| duas contas separadas, cada uma | 8.192 | 0 | 1.228,80 |
| duas contas separadas, juntas | 16.384 | 0 | **2.457,60** |
| uma organização | 10.240 | 6.144 | **2.383,87** |

Separadas, nenhuma das contas sai da primeira faixa. Juntas, elas a atravessam em 10.240 GB, e os
6.144 GB além dela custam 0,138: 1.536,00 mais 847,87. **A organização economiza 73,73 dólares nesse
mês sem mudança nenhuma no que foi enviado.** A conta deixa de fora os 100 GB por mês que a AWS dá de
graça, que a lição 1 disse estarem na página de preços da AWS e não nestas linhas. Como a economia
aparece contra cada conta é um detalhe do layout da fatura; o segundo total é o que se paga.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l03-pooling\" aria-label=\"Duas contas mandam cada uma 8.192 GB para a internet a partir de São Paulo num mês. Cobradas separadas, cada uma fica dentro da primeira faixa, 10.240 GB a 0,15 dólar por GB, e as duas pagam 2.457,60 juntas. Numa organização os 16.384 GB são precificados como um só: 10.240 GB a 0,15 e 6.144 GB a 0,138, 2.383,87 no total. Lista de preços de 16 de setembro de 2026.\"><path d=\"M431.2 46.0 L431.2 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M431.2 98.0 L431.2 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M431.2 190.0 L431.2 232.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"431.2\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a primeira faixa termina em 10.240 GB</text><text x=\"140.0\" y=\"78.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cobradas separadas</text><rect x=\"150.0\" y=\"60.0\" width=\"224.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"262.5\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shop-prod: 8.192 a 0,15</text><rect x=\"376.0\" y=\"60.0\" width=\"224.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"487.5\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shop-staging: 8.192 a 0,15</text><text x=\"612.0\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2.457,60</text><text x=\"140.0\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma organização</text><rect x=\"150.0\" y=\"152.0\" width=\"280.2\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"290.6\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">10.240 a 0,15</text><rect x=\"432.2\" y=\"152.0\" width=\"167.8\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"515.6\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">6.144 a 0,138</text><text x=\"612.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2.383,87</text><path d=\"M150.0 240.0 L600.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M150.0 236.0 L150.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"150.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M375.0 236.0 L375.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"375.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8.192</text><path d=\"M431.2 236.0 L431.2 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"431.2\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.240</text><path d=\"M600.0 236.0 L600.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"600.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16.384</text><text x=\"360.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">gigabytes no mês, dólares por gigabyte, lista de preços de 16 de setembro de 2026</text></svg>", "caption": "Os mesmos 16.384 GB, precificados separados e juntos."}
```

## Descontos e créditos também viajam

Mais duas coisas atravessam as paredes na fatura, e a lição 14 lê as duas.

**Reserved Instances e Savings Plans são divididos pela organização.** Os dois são um compromisso
com uma certa quantidade de uso em troca de um preço menor, e por padrão o desconto vale para o uso
correspondente em qualquer conta da organização, não só na que comprou. A lição 14 os lê numa
fatura; aqui o ponto é que a árvore decide quem se beneficia. A divisão pode ser desligada para uma
conta nas preferências de faturamento da conta de gerenciamento.

**Créditos também são divididos.** A AWS às vezes concede créditos, por um programa, uma migração ou
um erro do lado dela, e por padrão eles são gastos contra a fatura da organização inteira. As mesmas
preferências de faturamento podem restringir isso.

## Dois conjuntos de recursos

Uma organização é criada com um de dois conjuntos de recursos, e o `ALL` da transcrição era o
padrão:

- **`ALL`**, todos os recursos: faturamento consolidado mais as políticas que as lições 4 e 5 usam,
  as service control policies primeiro, e a integração com outros serviços da AWS que deixa uma
  conta rodar um serviço para a árvore inteira.
- **`CONSOLIDATED_BILLING`**: a fatura e mais nada. Nenhuma política de tipo algum pode ser anexada.

**Não há motivo para começar só com a fatura.** Esse conjunto existe para organizações que já
existiam antes das políticas, e para uma empresa que só quer uma fatura. Passar de só fatura para
todos os recursos é possível, e a referência da API para `EnableAllFeatures` diz quanto custa: toda
conta **convidada** tem de aprovar a mudança antes de ela valer, então uma organização grande espera
pelo seu administrador mais lento. Voltar atrás não é oferecido.

## O que o moto tem disso

**O moto não tem fatura.** Ele não guarda uso e não calcula cobrança, e o Cost Explorer, o serviço
que a lição 13 usa para ler custos, responde à organização vazia do moto com nada:

```
ana@laptop:~/aws$ aws ce get-cost-and-usage --time-period Start=2026-09-01,End=2026-10-01 --granularity MONTHLY --metrics UnblendedCost --group-by Type=DIMENSION,Key=LINKED_ACCOUNT
{
    "ResultsByTime": [],
    "DimensionValueAttributes": []
}
```

Então tudo nesta seção sobre dinheiro é comportamento documentado da AWS e **não foi rodado**. Os
preços não são de memória: vêm da lista de preços que a AWS publicou em **16 de setembro de 2026**,
lida pelo programa da lição 1, e a conta é a da tabela.
