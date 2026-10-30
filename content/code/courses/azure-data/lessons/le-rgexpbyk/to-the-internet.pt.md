---
title: Servindo arquivos para a internet
version: 1
---

**Bytes que saem do Azure para a internet são a coisa mais cara que o Blob Storage faz**, e são
cobrados do dono da conta, seja quem for que os pediu. As imagens de um site público, os downloads de
um app, um relatório que um cliente baixa: cada byte que sai é medido por GB, a um preço várias vezes
maior que o de guardar esse byte por um mês. Esta seção é ensinada a partir da página de preços de
banda da Microsoft, e nada nela foi rodado; o Azurite não envia nada para lugar nenhum onde um
medidor possa ver.

As imagens de produtos da Quitanda são 500 GB, e o app e o site servem uns 20 TB delas por mês. Esse é
o quarto desenho do `costs.py`:

```
500 GB of images, 20 TB out          10.00     21.47       0.00  2,038.00  2,069.47
```

**O armazenamento é 10,00 de um mês que custa 2.069,47.** As leituras, 53.687.091 operações
`Get Blob`, são 21,47. Os outros 2.038,00 são a transferência: 20.480 GB, menos os 100 GB gratuitos, a
ilustrativos 0,10 por GB.

**Os primeiros 100 GB por mês para a internet são de graça**, pela página de banda da Microsoft, e
depois deles o preço por GB cai em degraus conforme o volume do mês cresce. O `costs.py` usa uma tarifa
ilustrativa única em vez dos degraus, o que deixa a conta legível e mantém a sua forma: a 20 TB por
mês, os 100 GB gratuitos são meio por cento da transferência, e a transferência é 98,5% da fatura.

## Atrás de uma rede de entrega de conteúdo

**Uma rede de entrega de conteúdo busca um blob da conta uma vez, guarda uma cópia perto de quem vê e
serve as próximas requisições a partir da cópia.** A do Azure é o Azure Front Door, que a lição 22 de
`azure-foundations` põe entre os balanceadores de carga do Azure. A conta vê um `Get Blob` onde teria
visto muitos, e manda bem menos para a internet ela mesma.

O último desenho supõe que 19 de cada 20 downloads são respondidos pelas cópias da rede, então a conta
responde 2.684.354 leituras, que custam 1,07:

```
the same behind a CDN                10.00      1.07       0.00         -         -
```

**Os traços são honestos.** A rede cobra para entregar os bytes a quem vê, e pelas requisições, numa
lista de preços própria, e essa lista também diz se o trecho da conta até a rede é cobrado. O
`costs.py` não lê nada disso, então não imprime transferência nem total. O que a linha mostra é a
metade que é da conta: os 2.038,00 da linha de cima saem da fatura dela, e as leituras caem de 21,47
para 1,07. Se o todo fica mais barato depende do preço da rede e de quantos downloads as cópias dela
respondem, e nenhum dos dois foi verificado aqui.

Há um segundo efeito que importa tanto quanto: **a conta deixa de ser o endereço com que a internet
fala.** Com a rede na frente, o contêiner pode ficar privado, com o acesso anônimo da lição 6
desligado, e a conta acessada só através da rede.

## Ninguém mais paga

**O Blob Storage não tem configuração que mande a conta para quem lê.** Um parceiro que copia os 5 TB
de histórico de pedidos da Quitanda para outra região, com um token SAS que a Quitanda lhe deu, tira
5 TB de `brazilsouth`, e a transferência cai na fatura da Quitanda. Compartilhar dados sem pagar cada
leitura é um acordo, não uma configuração: copiar para o parceiro uma vez, numa conta que ele paga, ou
combinar quanto ele paga a você. Um token SAS com validade curta, da lição 6, limita quanto tempo a
porta fica aberta. Não muda nada sobre quem paga enquanto ela está.
