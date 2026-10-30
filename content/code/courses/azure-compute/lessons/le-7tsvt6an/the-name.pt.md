---
title: Lendo o nome de um tamanho
version: 1
---

`Standard_D2s_v5`, o tamanho que a CLI escolheu quando ninguém informou um, parece um código de
peça copiado do catálogo de um fornecedor. **É uma frase curta numa gramática que a Microsoft
publica**, e cada pedaço dela diz uma coisa sobre a máquina: que família, quantas vCPUs, que
processador, se o host dá a ela um disco próprio e que versão da série. Leia a gramática uma vez e
um tamanho que você nunca viu diz quase tudo o que é antes de você procurá-lo.

A gramática, na ordem em que os pedaços aparecem, é família, subfamília, número de vCPUs, vCPUs
restritas, recursos adicionais, tipo de acelerador, capacidade de memória e versão. Quatro dos oito
são opcionais, e a maioria dos nomes leva só os outros quatro. `Standard_` vem primeiro em todo
tamanho das listas da Microsoft, e a gramática começa depois dele.

```schooling-figure
{"svg": "<svg id=\"fig-size-name\" viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O nome de tamanho Standard_D4pds_v6 dividido em sete partes. Standard_ é o prefixo que todo tamanho leva. D é a família, uso geral, 4 GiB por vCPU. 4 é o número de vCPUs. p é um processador Arm, o Cobalt 100. d acrescenta um disco temporário local, de 220 GiB aqui. s quer dizer que ele aceita qualquer Premium SSD. _v6 é a versão da série.\"><defs><marker id=\"size-name-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10.0\" y=\"20\" width=\"94\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"57.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--phosphor)\" font-weight=\"600\">Standard_</text><line x1=\"57.0\" y1=\"66\" x2=\"57.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#size-name-ah)\"></line><rect x=\"10.0\" y=\"104\" width=\"94\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"57.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">prefixo</text><text x=\"57.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">todo tamanho</text><text x=\"57.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o leva</text><text x=\"57.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">na frente</text><rect x=\"111.0\" y=\"20\" width=\"94\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"158.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">D</text><line x1=\"158.0\" y1=\"66\" x2=\"158.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#size-name-ah)\"></line><rect x=\"111.0\" y=\"104\" width=\"94\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"158.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">família</text><text x=\"158.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uso</text><text x=\"158.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">geral</text><text x=\"158.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 GiB por vCPU</text><rect x=\"212.0\" y=\"20\" width=\"94\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"259.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">4</text><line x1=\"259.0\" y1=\"66\" x2=\"259.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#size-name-ah)\"></line><rect x=\"212.0\" y=\"104\" width=\"94\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"259.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">vCPUs</text><text x=\"259.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">quatro,</text><text x=\"259.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">logo 16 GiB</text><text x=\"259.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">numa D</text><rect x=\"313.0\" y=\"20\" width=\"94\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"360.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">p</text><line x1=\"360.0\" y1=\"66\" x2=\"360.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#size-name-ah)\"></line><rect x=\"313.0\" y=\"104\" width=\"94\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">processador</text><text x=\"360.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Arm:</text><text x=\"360.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Cobalt 100</text><text x=\"360.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">na v6</text><rect x=\"414.0\" y=\"20\" width=\"94\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"461.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">d</text><line x1=\"461.0\" y1=\"66\" x2=\"461.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#size-name-ah)\"></line><rect x=\"414.0\" y=\"104\" width=\"94\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"461.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">recurso</text><text x=\"461.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um disco</text><text x=\"461.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">temporário</text><text x=\"461.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">local, 220 GiB</text><rect x=\"515.0\" y=\"20\" width=\"94\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"562.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">s</text><line x1=\"562.0\" y1=\"66\" x2=\"562.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#size-name-ah)\"></line><rect x=\"515.0\" y=\"104\" width=\"94\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"562.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">recurso</text><text x=\"562.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">aceita</text><text x=\"562.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">qualquer</text><text x=\"562.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Premium SSD</text><rect x=\"616.0\" y=\"20\" width=\"94\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"663.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">_v6</text><line x1=\"663.0\" y1=\"66\" x2=\"663.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#size-name-ah)\"></line><rect x=\"616.0\" y=\"104\" width=\"94\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"663.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">versão</text><text x=\"663.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a sexta</text><text x=\"663.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">versão</text><text x=\"663.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">da série</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">maiúsculas antes do número, minúsculas depois dele</text></svg>", "caption": "Sete partes, e cada uma diz uma coisa. Tire o p e o mesmo tamanho roda em Intel; tire o d e ele fica sem disco local.", "same": ["Arm:", "Cobalt 100", "vCPUs"]}
```

## Antes do número: a família

A letra maiúscula depois de `Standard_` é a **família**, e a família fixa a proporção entre memória
e processador: `D` é uso geral, `E` otimizada para memória, `F` otimizada para computação. A
próxima seção percorre todas. Algumas famílias levam uma segunda maiúscula, a **subfamília**, para
uma variação que a família principal não tem: `DC` e `EC` são as versões de computação confidencial
de `D` e `E`, e `NC`, `ND` e `NV` são três tipos de máquina com GPU na família `N`.

## O número é o tamanho

Aqui a gramática do Azure difere da que você talvez tenha visto em outro lugar, onde o tamanho é
uma palavra depois de um ponto. **Num nome do Azure o tamanho é o número, e o número é a contagem
de vCPUs.** `Standard_D2s_v5` tem 2 vCPUs e `Standard_D4s_v5` tem 4. A memória nem está no nome; ela
vem da proporção da família, então uma `D2s_v5` tem 8 GiB e uma `D4s_v5` tem 16.

Um segundo número depois de um hífen é uma contagem de **vCPUs restritas**. `Standard_M8-2ms` é a
`M8ms`, oito vCPUs e 218,75 GiB de memória, com seis das vCPUs desligadas: a máquina mantém toda a
memória e os limites de disco do tamanho de oito vCPUs e roda com duas. A última seção desta lição
diz quem quer isso e por quê. Repare que o próprio exemplo da página de nomenclatura escreve esse
tamanho como `M8-2ms_v2`, enquanto a página da série M e a lista de tamanhos restritos o chamam de
`Standard_M8-2ms`, sem versão. As listas de tamanhos são as que merecem confiança, porque são o que
o Azure vai aceitar.

## Depois do número: os recursos adicionais

Letras minúsculas depois do número são **recursos adicionais**, uma letra cada. Estas são as que
você vai encontrar neste curso:

| letra | o que diz | exemplo |
| --- | --- | --- |
| *(nenhuma)* | um processador Intel, x86-64 | `Standard_D2s_v5` |
| `a` | um processador AMD, x86-64 | `Standard_E8as_v5` |
| `p` | um processador Arm: o Cobalt 100 da Microsoft, ou o Ampere Altra | `Standard_D4pds_v6` |
| `d` | um disco temporário local no host | `Standard_D4ds_v5` |
| `s` | aceita qualquer tipo de Premium SSD | `Standard_D2s_v5` |
| `l` | menos memória por vCPU que o normal da família | `Standard_D2ls_v6` |
| `m` | mais memória por vCPU que o normal da família | `Standard_M8ms` |
| `t` | a menor memória por vCPU da série | `Standard_B2ts_v2` |
| `b` | mais banda para discos remotos | `Standard_E96bds_v5` |

A página de nomenclatura lista mais algumas: `n` para mais banda de rede, `e` para computação
confidencial com o TDX da Intel, `i` para um tamanho isolado, e outras. Nos nomes que a Microsoft
publica, a letra do processador vem primeiro e o `s` vem por último, então `pds` e `ads` se leem
do mesmo jeito sempre.

**Não há letra para Intel.** Um nome sem `a` nem `p` roda em Intel, e é por isso que o padrão da
CLI, `Standard_D2s_v5`, não diz nada sobre o processador e ainda assim diz exatamente qual é.

## Cinco nomes, destrinchados

- `Standard_D2s_v5`: família `D`, uso geral; 2 vCPUs; Intel, porque nenhuma letra diz o contrário;
  `s`, qualquer Premium SSD; versão 5. 8 GiB de memória, pela proporção da família.
- `Standard_D4ds_v5`: a mesma série com `d` acrescentado e o dobro de vCPUs. O `d` é um disco
  temporário local de 150 GiB, e *temporário* é a palavra que importa: a lição 3 diz o que acontece
  com ele quando a máquina para.
- `Standard_E8as_v5`: família `E`, otimizada para memória; 8 vCPUs; `a`, um processador AMD;
  versão 5. 64 GiB, oito para cada vCPU.
- `Standard_D4pds_v6`: família `D`, 4 vCPUs, `p` de Arm, que na versão 6 é o Cobalt 100; um disco
  local de 220 GiB; versão 6. A figura acima o desmonta.
- `Standard_NC4as_T4_v3`: família `N`, subfamília `C`; 4 vCPUs; AMD; Premium SSD; e o
  **acelerador** entre sublinhados, uma NVIDIA T4. Só os tamanhos com GPU lançados a partir do
  terceiro trimestre de 2020 levam o acelerador no nome.

## A versão, e o que a CLI tem escrito

O sufixo é a **versão** da série: `_v5`, `_v6`, `_v7`. Uma primeira versão muitas vezes não leva
nenhuma, e é por isso que os tamanhos burstable da primeira série B eram `Standard_B2s` e os atuais
são `Standard_B2s_v2`.

A versão é também onde um nome envelhece. A Microsoft põe cada série numa etapa do ciclo de vida. Para
as famílias de uso geral, a documentação dela, lida em 30 de outubro de 2026, diz que v6 e v7
são *Current*, v4 e v5 são *Extended*, e v1 a v3 são *End of Life* quando uma aposentadoria foi
anunciada. A CLI que você instalou traz dois tamanhos da família D na ajuda do `az vm create`:

```
ana@laptop:~/azure$ az vm create --help | grep -o "Standard_D[A-Za-z0-9_]*"
Standard_D2s_v5
Standard_DS2_v2
```

O primeiro é o padrão, e é uma v5: com suporte completo, e uma geração atrás do que a Microsoft
recomenda para uma máquina nova. O segundo vem de um exemplo mais abaixo na ajuda. `DS2_v2` é da
série Dsv2, escrita no estilo antigo em que o `S` era maiúsculo e fazia parte do nome da série, e
essa série está em End of Life, com aposentadoria marcada para 1º de maio de 2028. **Nada na CLI
avisa você**: um texto de ajuda é escrito uma vez e copiado por anos, e um tamanho digitado a partir
dele é o tamanho que você recebe. Leia a versão de todo nome que copiar, e prefira uma v6 ou v7 para
qualquer coisa nova, a menos que um motivo das duas próximas seções diga o contrário.

O que o nome não diz é se o tamanho é oferecido em `brazilsouth`, nem se sua assinatura tem cota
para ligar um. Essas perguntas vão para o Azure, e a próxima seção mostra o comando que as faz e a
resposta que ele recebe aqui.
