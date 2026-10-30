---
title: O que um tier de acesso troca
version: 1
---

**Um tier de acesso é um preço para guardar um gigabyte casado com um preço para lê-lo de volta**, e
cada tier abaixo do hot compra um primeiro preço menor com um segundo maior. As pessoas costumam ler a
lista como "rápido, mais lento, o mais lento", como se os tiers mais baratos fossem discos mais lentos.
Três dos quatro não são. Hot, cool e cold respondem uma leitura em milissegundos; o que muda entre eles
é a conta da leitura, a conta da escrita e a conta por sair cedo. Só o archive é lento, e nele o blob
nem pode ser lido até ser trazido de volta.

Esta seção foi escrita a partir da documentação da Microsoft sobre tiers de acesso para dados de blob,
e nada dela aparece no Azurite, que guarda todo blob do mesmo jeito, diga o tier o que disser.

## Os quatro tiers

| tier | para dados que são | dias mínimos cobrados | primeiro byte |
|---|---|---|---|
| hot | lidos ou escritos com frequência | nenhum | milissegundos |
| cool | lidos raramente, guardados pelo menos um mês | 30 | milissegundos |
| cold | lidos muito raramente, guardados pelo menos uma estação | 90 | milissegundos |
| archive | guardados por muito tempo e quase nunca lidos | 180 | horas, depois de uma reidratação |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Os quatro tiers de acesso e o número mínimo de dias que cada um cobra. Hot não tem mínimo, cool tem 30 dias, cold 90 e archive 180. Hot, cool e cold devolvem o primeiro byte em milissegundos; archive não devolve nada até o blob ser reidratado, o que leva horas.\" data-fig=\"l04-tiers\"><defs><marker id=\"l04-tiers-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">tier</text><text x=\"150\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">dias mínimos cobrados</text><text x=\"20\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Hot</text><text x=\"20\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">primeiro byte: milissegundos</text><text x=\"154\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">nenhum</text><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Cool</text><text x=\"20\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">primeiro byte: milissegundos</text><rect x=\"150\" y=\"104\" width=\"90.0\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"232.0\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">30</text><text x=\"20\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Cold</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">primeiro byte: milissegundos</text><rect x=\"150\" y=\"156\" width=\"270.0\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"412.0\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">90</text><text x=\"20\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Archive</text><text x=\"20\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">primeiro byte: horas, depois de reidratar</text><rect x=\"150\" y=\"208\" width=\"540.0\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"682.0\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">180</text><path d=\"M150.0 260 L150.0 266\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"150.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M240.0 260 L240.0 266\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"240.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><path d=\"M420.0 260 L420.0 266\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"420.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">90</text><path d=\"M690.0 260 L690.0 266\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"690.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">180</text><path d=\"M150 260 L690 260\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"690\" y=\"294\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dias</text></svg>", "caption": "Os dias mínimos e as latências são os números documentados pela Microsoft; nenhum deles aparece no Azurite.", "same": ["tier"]}
```

**O tier é uma propriedade de cada block blob**, não do contêiner nem da conta. Um contêiner pode
guardar a exportação de ontem em hot, a do último trimestre em cool e os arquivos de auditoria de 2019
em archive, lado a lado sob os mesmos prefixos. A conta tem um **tier de acesso padrão**, hot se
ninguém escolheu outro, e um block blob enviado sem tier fica com ele; a próxima seção mostra a
diferença entre um tier definido e um inferido.

**Só block blobs têm esses tiers.** A lição 2 disse isso, e a próxima seção mostra o Azurite recusando
um tier num append blob. Page blobs em contas premium têm tiers de desempenho chamados `P10`, `P20` e
assim por diante, que são outra coisa com a mesma palavra.

## O que muda na conta

A tabela de preços da lição 1 imprime os medidores de cada tier, e a lição 7 trata de operações e
transferência, então o formato basta aqui. Descendo a tabela, do hot ao archive:

- **o preço de guardar um gigabyte por um mês cai**, e cai bastante: o archive é o armazenamento mais
  barato que o Azure vende para blobs;
- **o preço de cada operação sobe**, escritas e leituras, então uma troca de tier em milhões de blobs
  pequenos pode custar mais do que o armazenamento que ela economiza;
- **cool, cold e archive somam um preço por gigabyte lido de volta**, que o hot não cobra;
- **os dias mínimos são cobrados mesmo se o blob sair antes**, apagado, sobrescrito ou movido para
  outro tier; a seção sobre saída antecipada faz a conta.

Duas coisas que parecem tiers não são. **Premium** é o desempenho da conta (lição 1), discos de
estado sólido para a conta inteira, não um tier para onde um blob possa ir. E o provedor do Terraform
deste curso aceita um quinto valor para o padrão de uma conta, `Smart`, como a próxima seção imprime.
Pela descrição da Microsoft, ele move blobs entre os tiers online de acordo com o uso. É mais novo que
o resto desta lição, não é tratado aqui e nada neste curso o rodou.
