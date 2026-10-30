---
title: O que é uma imagem, no Azure
version: 1
---

É fácil imaginar uma imagem como um arquivo: um disco que alguém enviou e por onde uma máquina nova
dá boot, do jeito que um laptop dá boot por uma ISO. **No Azure, nada dá boot por uma imagem.** Uma
imagem é a origem de onde o disco do sistema de uma máquina nova é copiado. Quando uma máquina
virtual é criada, o Azure faz um disco gerenciado novo a partir da imagem, e a máquina dá boot por
esse disco, que passa a ser dela. A imagem fica onde estava e pode ser copiada de novo para a
próxima máquina. A lição 3 é sobre discos gerenciados; esta lição é sobre aquilo de onde eles são
copiados.

A declaração da máquina nomeia a imagem num lugar só, `storageProfile.imageReference`, e esse campo
aceita três tipos de origem:

```schooling-figure
{"svg": "<svg id=\"fig-image-sources\" viewBox=\"0 0 720 316\" role=\"img\" aria-label=\"Três tipos de origem de imagem à esquerda: uma imagem do Marketplace, nomeada por quatro nomes, Canonical:ubuntu-24_04-lts:server:latest; uma imagem gerenciada, um recurso numa região; e uma versão de imagem de galeria, shopgallery/shop-web/1.0.0. Qualquer uma pode ser nomeada no imageReference da VM. Na criação, o Azure copia a nomeada para um disco gerenciado novo, o disco do sistema, e a VM dá boot por esse disco.\"><defs><marker id=\"img-src-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"14\" width=\"688\" height=\"288\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"30\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">brazilsouth, a região</text><rect x=\"30\" y=\"52\" width=\"300\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"180\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">Imagem do Marketplace</text><text x=\"180\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Canonical:ubuntu-24_04-lts:server:latest</text><text x=\"180\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">quatro nomes, publicada pela Canonical</text><line x1=\"330\" y1=\"87\" x2=\"384\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#img-src-ah)\"></line><rect x=\"30\" y=\"136\" width=\"300\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Imagem gerenciada</text><text x=\"180\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Microsoft.Compute/images</text><text x=\"180\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um recurso, uma região, só generalizada</text><line x1=\"330\" y1=\"171\" x2=\"384\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#img-src-ah)\"></line><rect x=\"30\" y=\"220\" width=\"300\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"180\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">Versão de imagem de galeria</text><text x=\"180\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shopgallery/shop-web/1.0.0</text><text x=\"180\" y=\"275\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">versionada, replicada, compartilhável</text><line x1=\"330\" y1=\"255\" x2=\"384\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#img-src-ah)\"></line><rect x=\"386\" y=\"124\" width=\"140\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"456\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">imageReference</text><text x=\"456\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nomeia exatamente uma</text><line x1=\"526\" y1=\"160\" x2=\"552\" y2=\"104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#img-src-ah)\"></line><text x=\"456\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">copiada na criação</text><rect x=\"554\" y=\"52\" width=\"136\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"622\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Disco do sistema</text><text x=\"622\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um disco gerenciado,</text><text x=\"622\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">copiado da imagem</text><line x1=\"622\" y1=\"126\" x2=\"622\" y2=\"194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#img-src-ah)\"></line><rect x=\"554\" y=\"196\" width=\"136\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"622\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">a VM</text><text x=\"622\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dá boot pelo próprio disco</text></svg>", "caption": "Nunca se dá boot por uma imagem. Ela é a origem de onde um disco de sistema novo é copiado, e o imageReference diz qual dos três tipos de origem é."}
```

- uma **imagem do Marketplace**, publicada por outra pessoa e nomeada por quatro nomes, que a
  próxima seção desmonta: `Canonical:ubuntu-24_04-lts:server:latest` é o Ubuntu 24.04 da Canonical;
- uma **imagem gerenciada**, um recurso único na sua assinatura, feito a partir de uma máquina sua;
- uma **versão de imagem de galeria**, uma versão numerada de uma imagem que você guarda numa Azure
  Compute Gallery, que a última seção desta lição constrói.

A ajuda da CLI para o `az vm create` diz o mesmo com outras palavras, e é a primeira coisa que vale
ler sem assinatura:

```
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-image : [^.]*\.[^.]*\."
--image : The name of the operating system image as a URN alias, URN, custom image name or ID, custom image version ID, or VHD blob URI. In addition, it also supports shared gallery image.
```

Um alias é um nome curto que a CLI traduz em quatro nomes, e a próxima seção mostra que essa
tradução é menos fixa do que parece. Uma VHD blob URI é um arquivo de disco numa conta de
armazenamento, o jeito mais antigo de todos e o que este curso não usa.

## O que uma imagem diz sobre a máquina

Uma imagem é mais que os bytes dela. Ela também declara que tipo de máquina pode virar, e três
dessas declarações decidem se uma criação funciona ou não.

**A geração.** O Azure roda dois tipos de hardware virtual, e uma imagem é feita para um deles. Uma
máquina de *geração 1* inicia por firmware BIOS e vê os discos por uma controladora IDE; uma de
*geração 2* inicia por firmware UEFI e vê os discos por SCSI. O sistema operacional dentro da imagem
foi instalado para uma ou para a outra, então uma imagem de geração 1 não dá boot como geração 2. A
geração 2 também permite um disco do sistema maior que 2 TB, e é a única que o Trusted Launch,
abaixo, protege. Os publishers dizem qual é no SKU, o terceiro dos quatro nomes: para o Ubuntu 22.04
a Canonical publica `22_04-lts` para geração 1 e `22_04-lts-gen2` para geração 2, e para o 24.04 o
`server` simples é geração 2 e o `server-gen1` é o tipo antigo. Os tamanhos também têm voz. A
documentação da Microsoft lista a família A e as séries Dv2 e Dv3 entre os tamanhos que não rodam
geração 2 de jeito nenhum, e alguns tamanhos grandes, como a série Mv2, que não rodam outra coisa.

**A arquitetura.** Uma imagem é feita para `x64` ou para `Arm64`, e só roda num tamanho com esse
processador. A lição 1 leu o `p` no nome de um tamanho como o processador Arm; um `Standard_D2ps_v6`
precisa de uma imagem Arm64, e a Canonical publica uma para o 24.04 como o SKU `server-arm64`.

**O tipo de segurança.** A CLI aceita três valores:

```
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-security-type : [^.]*\. Allowed values: [A-Za-z, ]*"
--security-type : Specify the security type of the virtual machine. Allowed values: ConfidentialVM, Standard, TrustedLaunch
```

`Standard` é uma máquina sem proteção extra no boot. `TrustedLaunch` acrescenta duas coisas a uma
máquina de geração 2. O **Secure Boot** se recusa a iniciar um boot loader, kernel ou driver que
não esteja assinado por um publisher confiável. Um **TPM virtual** é um cofre privado para chaves,
e guarda um registro de cada etapa do boot que pode ser conferido de fora. A documentação da
Microsoft diz que o Trusted Launch não acrescenta nada ao preço da máquina. `ConfidentialVM` vai
além e criptografa a memória da máquina, em tamanhos feitos para isso.

## O padrão depende de quem pergunta

**A CLI e o portal criam uma máquina de geração 2 com Trusted Launch,
a não ser que alguém diga o contrário. Um template não faz isso, a não ser que seja novo o bastante
ou que diga.** A documentação da Microsoft descreve os dois comportamentos lado a lado. Uma
declaração que usa a versão `2024-07-01` da API de máquinas virtuais, como a desta lição, e deixa de
fora o perfil de segurança recebe uma máquina `Standard`. A partir da versão `2025-11-01` a mesma
omissão recebe Trusted Launch, desde que a imagem, o disco e o tamanho suportem, e recebe `Standard`
em silêncio quando um deles não suporta.

Então a mesma máquina, criada uma vez com `az vm create` e outra a partir de um arquivo Bicep, pode
sair com dois boots diferentes, e nada falha para avisar. A regra que este curso segue é a que a
lição 1 deu para os avisos, aplicada aos padrões: **uma propriedade que muda o que a máquina é fica
escrita**, seja qual for o valor que a ferramenta escolheria. A declaração da próxima seção escreve o
tipo de segurança e as duas chaves dele.

Uma consequência chega até a última seção. **O Trusted Launch não suporta imagens gerenciadas.**
Uma máquina feita a partir de uma imagem gerenciada é uma máquina `Standard`, e a resposta da
Microsoft para uma imagem sua que mantenha o Secure Boot é a Compute Gallery. É um dos três motivos,
até o fim desta lição, para as suas imagens morarem na galeria.

## Lendo sem assinatura

Tudo acima que dá para conferir num laptop foi conferido: os três tipos de origem e os três tipos de
segurança são o que a ajuda da CLI diz, e o texto de ajuda é gerado a partir das mesmas definições
com que a CLI monta as requisições. O que não dá para conferir aqui é quais imagens uma região
realmente oferece, e a próxima seção encontra essa recusa.
