---
title: As famílias, e o que cada uma combina
version: 1
---

É tentador ler as famílias como degraus, como se `E` fosse uma `D` melhor e `M` a melhor de todas,
e escolher a mais alta que o orçamento permite. **Uma família é uma proporção, não uma posição.**
Cada uma combina processador com memória, e às vezes com discos locais ou uma GPU, numa proporção
que serve a um tipo de trabalho. O tamanho certo é aquele em que o recurso que seu programa esgota
primeiro é o recurso pelo qual você mais paga.

## Seis tipos e as famílias dentro deles

A Microsoft agrupa as famílias em tipos, pelo trabalho a que se destinam. Estes são os atuais,
segundo a visão geral de tamanhos lida em 30 de outubro de 2026:

| tipo | famílias | para que serve |
| --- | --- | --- |
| uso geral | `A`, `B`, `D`, `DC` | servidores web e de aplicação, bancos de dados pequenos e médios, quase tudo quando não há motivo para escolher |
| otimizada para computação | `F`, `FX` | trabalho que mantém o processador ocupado: jobs em lote, servidores de aplicação, simulação |
| otimizada para memória | `E`, `Eb`, `EC`, `M` | bancos de dados relacionais, caches grandes, análises que mantêm os dados em memória |
| otimizada para armazenamento | `L` | bancos de dados que leem e gravam nos próprios discos NVMe locais a taxas muito altas |
| acelerada por GPU | `NC`, `ND`, `NG`, `NV` | treinar e rodar modelos, renderização, desktops virtuais |
| computação de alto desempenho | `HB`, `HC`, `HX` | dinâmica de fluidos, modelos de clima, projeto de chips |

Dentro de uso geral, `A` é a família de entrada e `B` é a burstable, assunto da última seção desta
lição. `DC` é a `D` com computação confidencial, que usa hardware do processador para proteger os
dados da máquina enquanto estão em uso. `Eb` é a `E` com mais banda para discos remotos, e `EC` é a `E`
confidencial. Existe também uma família com FPGA, a `NP`, de que nada neste curso precisa.

## A proporção, medida

Divida a memória pelas vCPUs e cada família cai num número. Uma `Standard_D2s_v6` tem 2 vCPUs e
8 GiB, ou seja, 4 GiB por vCPU; uma `Standard_E2s_v6` tem 2 vCPUs e 16 GiB, ou seja, 8. Uma `M` vai
muito além: a `Standard_M8ms` tem 218,75 GiB em 8 vCPUs, cerca de 27 para cada. As letras `l`, `m`
e `t` deslocam uma série ao longo da mesma linha, então a `Standard_D2ls_v6` tem 4 GiB para as duas
vCPUs, 2 por vCPU, metade do que a `D` comum leva.

```schooling-figure
{"svg": "<svg id=\"fig-family-ratio\" viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Memória por vCPU das séries atuais de seis famílias, numa escala em que cada passo dobra, de 0,5 a 32 GiB. B: Bts_v2 em 0,5, Bls_v2 em 2, Bs_v2 em 4. D: Dls_v6 em 2, Ds_v6 em 4. F: Fals_v6 em 2, Fas_v6 em 4, Fams_v6 em 8. E: Es_v6 em 8. L: Ls_v3 em 8, com discos NVMe locais. M: M8ms em cerca de 27.\"><line x1=\"250.0\" y1=\"20\" x2=\"250.0\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"250.0\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">0,5</text><line x1=\"323.3\" y1=\"20\" x2=\"323.3\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"323.3\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><line x1=\"396.7\" y1=\"20\" x2=\"396.7\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"396.7\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><line x1=\"470.0\" y1=\"20\" x2=\"470.0\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"470.0\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><line x1=\"543.3\" y1=\"20\" x2=\"543.3\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"543.3\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><line x1=\"616.7\" y1=\"20\" x2=\"616.7\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"616.7\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">16</text><line x1=\"690.0\" y1=\"20\" x2=\"690.0\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"690.0\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">32</text><line x1=\"240\" y1=\"268\" x2=\"700\" y2=\"268\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"470.0\" y=\"308\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">GiB de memória por vCPU, e cada passo para a direita dobra o valor</text><rect x=\"16\" y=\"31\" width=\"214\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--phosphor)\" font-weight=\"600\">B</text><text x=\"56\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">burstable</text><line x1=\"250.0\" y1=\"46\" x2=\"470.0\" y2=\"46\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\"></line><circle cx=\"250.0\" cy=\"46\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"250.0\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bts_v2</text><circle cx=\"396.7\" cy=\"46\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"396.7\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bls_v2</text><circle cx=\"470.0\" cy=\"46\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"470.0\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bs_v2</text><rect x=\"16\" y=\"71\" width=\"214\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--phosphor)\" font-weight=\"600\">D</text><text x=\"56\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">uso geral</text><line x1=\"396.7\" y1=\"86\" x2=\"470.0\" y2=\"86\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\"></line><circle cx=\"396.7\" cy=\"86\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"396.7\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Dls_v6</text><circle cx=\"470.0\" cy=\"86\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"470.0\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ds_v6</text><rect x=\"16\" y=\"111\" width=\"214\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--phosphor)\" font-weight=\"600\">F</text><text x=\"56\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">otimizada p/ computação</text><line x1=\"396.7\" y1=\"126\" x2=\"543.3\" y2=\"126\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\"></line><circle cx=\"396.7\" cy=\"126\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"396.7\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Fals_v6</text><circle cx=\"470.0\" cy=\"126\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"470.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Fas_v6</text><circle cx=\"543.3\" cy=\"126\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"543.3\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Fams_v6</text><rect x=\"16\" y=\"151\" width=\"214\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--phosphor)\" font-weight=\"600\">E</text><text x=\"56\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">otimizada p/ memória</text><circle cx=\"543.3\" cy=\"166\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"543.3\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Es_v6</text><rect x=\"16\" y=\"191\" width=\"214\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--phosphor)\" font-weight=\"600\">L</text><text x=\"56\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">otimizada p/ disco</text><circle cx=\"543.3\" cy=\"206\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"543.3\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ls_v3</text><text x=\"555.3\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">+ NVMe</text><rect x=\"16\" y=\"231\" width=\"214\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--phosphor)\" font-weight=\"600\">M</text><text x=\"56\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a maior memória</text><circle cx=\"673.4\" cy=\"246\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"673.4\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">M8ms</text></svg>", "caption": "A família define onde uma série fica nesta linha, e as letras l, m e t a deslocam. A F é a exceção que vale conhecer: na v6 ela não vende menos memória que a D, vende um núcleo inteiro por vCPU.", "same": ["burstable", "+ NVMe"]}
```

A `L` fica em 8 GiB por vCPU como a `E`, e o que ela acrescenta são discos: uma `Standard_L8s_v3`
traz um dispositivo NVMe de 1,92 TB no host para cada 8 vCPUs. A lição 3 trata de por que um disco
dentro do host é rápido e de por que ele não é onde a única cópia de qualquer coisa deve morar.

**A `F` não é a família com menos memória**, e essa é a crença a largar se você vem de uma
plataforma onde ela era. Na versão 6 a família otimizada para computação vem nas três proporções,
`Fals_v6` com 2, `Fas_v6` com 4 e `Fams_v6` com 8 GiB por vCPU. O que ela vende no lugar disso é o
processador: a série Fasv6 roda sem multithreading simultâneo, então cada vCPU é um núcleo físico
inteiro em vez de uma de duas threads dividindo um. Uma `Standard_D2s_v5` em Intel são duas threads
que dividem um núcleo. Uma `Standard_F2as_v6` são dois núcleos.

## Gerações, e qual processador

As gerações atuais são v6 e v7, e cada uma vem com uma escolha de processador que o nome soletra:

- **Intel**, sem letra: `Dsv6` em Xeon de quinta geração (Emerald Rapids), `Dsv7` em Xeon 6
  (Granite Rapids).
- **AMD**, `a`: `Dasv6` em EPYC de quarta geração, `Dasv7` em EPYC de quinta geração.
- **Arm**, `p`: `Dpsv6`, `Dpdsv6` e `Epsv6` no Cobalt 100, o processador Arm que a Microsoft
  projeta. A `Dpsv5`, mais antiga, e a burstable `Bpsv2` usam Ampere Altra, que é Arm de outro
  fabricante.

Os tamanhos Arm trazem duas consequências. O Cobalt 100 dá a cada vCPU um núcleo físico inteiro,
como a `Fasv6`, então duas vCPUs são mais processador que duas threads Intel. E um processador Arm
roda só programas compilados para Arm, então a imagem de que a máquina parte tem de ser `arm64`. A
API de pedidos da loja é um programa Python, e o Python e a maioria das distribuições Linux publicam
os dois builds. Onde a mudança para é num binário fechado de um fornecedor, ou numa biblioteca
nativa que ninguém compilou para `arm64`. A lição 2 é onde a imagem é escolhida, e onde esse par é
conferido.

## O que o compilador sabe sobre um tamanho

Um tamanho é uma propriedade do recurso de máquina virtual, `hardwareProfile.vmSize`. Eis a API de
pedidos da loja declarada como uma máquina, só com a parte de que esta lição trata. Uma máquina de
verdade precisa também de uma imagem (lição 2), de um disco (lição 3) e de uma interface de rede
(lição 16 do `azure-foundations`), então esta declaração não bastaria para criar uma. Salve como
`vm.bicep`:

```bicep
// vm.bicep
param location string = 'brazilsouth'

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'shop-api'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2ps_v6'
    }
  }
}
```

Ela compila sem nada a dizer. Agora troque o tamanho por `Standard_D3ps_v6`, que não existe: a série
vai de duas vCPUs para quatro, e não há três. Depois troque pelo número `2`:

```
ana@laptop:~/azure$ bicep build vm.bicep
ana@laptop:~/azure$ grep vmSize vm.bicep
      vmSize: 'Standard_D3ps_v6'
ana@laptop:~/azure$ bicep build vm.bicep
ana@laptop:~/azure$ grep vmSize vm.bicep
      vmSize: 2
ana@laptop:~/azure$ bicep build vm.bicep
/home/ana/azure/vm.bicep(9,15) : Warning BCP036: The property "vmSize" expected a value of type "null | string" but the provided value is of type "2". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

**O tamanho que não existe compilou sem aviso.** O número foi recusado, porque o tipo que a
Microsoft publica para `vmSize` nesta versão da API é `null | string`: qualquer texto. O compilador
sabe que um tamanho é uma string e não tem a lista das strings que são tamanhos, então um erro de
digitação no nome de um tamanho é um dos enganos que ele não consegue pegar por você.

O comando que sabe é o `az vm list-skus`, que pergunta ao Azure os tamanhos que uma região oferece e
quais deles sua assinatura pode usar. Aqui ele recebe a resposta que você viu na primeira seção:

```
ana@laptop:~/azure$ az vm list-skus --size Standard_D2ps_v6 --output table
ERROR: Please run 'az login' to setup account.
```

Contra uma assinatura real, o mesmo comando lista cada tamanho que casa com as zonas em que é
oferecido e qualquer restrição da sua assinatura; ele não foi executado neste curso. **Quais
tamanhos existem em `brazilsouth` é uma pergunta que só o Azure responde**, e é o motivo para rodar
esse comando antes de escrever um tamanho num template, e não depois que a implantação falhar.

## Escolhendo pelo que acaba primeiro

Todo programa esgota um recurso primeiro, e a família é escolhida por esse recurso. Dois da própria
loja:

**A API de pedidos** responde a pequenos pedidos JSON e guarda quase nada em memória. Duas vCPUs
bastam e 4 GiB é mais do que ela usa, então uma `D2ls_v6` serve com folga, e uma `D2ps_v6` também
serviria depois que a imagem dela fosse compilada para Arm.

**O relatório noturno de vendas** carrega os pedidos do dia na memória e os soma, e precisa de cerca
de 12 GiB e de uma vCPU ocupada. O tamanho de uso geral que comporta 12 GiB é a `D4s_v6`: 16 GiB, e
quatro vCPUs das quais três ficam paradas. Uma `E2s_v6` tem os mesmos 16 GiB com duas vCPUs. Pela
mesma memória você paga metade dos processadores, e isso em cada cópia do job que rodar.

Nada disso é visível de fora do programa. O uso de memória e de processador vem de medi-lo sob carga
real, o que no Azure é o Azure Monitor, e as lições 8 a 13 do `azure-operations` montam isso. Sem
nada medido ainda, comece num tamanho atual de uso geral e trate-o como um palpite: redimensionar
uma máquina a reinicia no novo tamanho, `az vm resize`, e a lição 4 torna rotina trocar máquinas.
