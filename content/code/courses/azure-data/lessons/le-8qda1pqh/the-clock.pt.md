---
title: "O relógio: partida, time to live e quanto custa um cluster ocioso"
version: 1
---

**Um cluster Spark leva minutos para subir, e alguém paga esses minutos, seja qual for a ferramenta
que o pediu.** Um data flow num runtime frio espera o cluster antes de ler uma linha; um notebook num
pool pausado espera a sessão. Os dois serviços deixam você manter o cluster quente, e os dois cobram
o calor. Esta seção confere uma declaração com o Terraform, offline; os tempos que ela discute são
descrições da Microsoft, e nenhum foi medido aqui.

## O runtime em que um data flow roda

**Um mapping data flow roda no integration runtime do Azure da lição 19, num cluster Spark que esse
runtime inicia para ele.** As configurações do runtime decidem o cluster: o tipo de computação, o
número de núcleos e o time to live. Acrescente este arquivo a `~/azure/tf/factory`, o diretório que a
lição 19 deixou:

`runtime.tf`:

```hcl
resource "azurerm_data_factory_integration_runtime_azure" "flows" {
  name             = "ir-dataflows-brs"
  data_factory_id  = azurerm_data_factory.etl.id
  location         = "brazilsouth"
  compute_type     = "General"
  core_count       = 8
  time_to_live_min = 10
}
```

```
ana@laptop:~/azure/tf/factory$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/factory$ sed -i 's/core_count       = 8/core_count       = 4/' runtime.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/core_count       = 4/core_count       = 8/' runtime.tf
Error: expected core_count to be one of [8 16 32 48 80 144 272], got 4
ana@laptop:~/azure/tf/factory$ sed -i 's/"General"/"Small"/' runtime.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/"Small"/"General"/' runtime.tf
Error: expected compute_type to be one of ["ComputeOptimized" "General" "MemoryOptimized"], got Small
```

**Oito núcleos é o menor cluster que um data flow recebe**, e os tamanhos sobem em degraus a partir
daí. O provider conhece três tipos de computação, e os dois que importam são o de uso geral e o
otimizado para memória, este para joins e agregações grandes. E `location` fixa o runtime em
`brazilsouth`, o ponto da lição 19 sobre onde os dados são processados.

**`time_to_live_min` mantém o cluster vivo depois que um data flow termina**, dez minutos aqui, para
que o próximo data flow que comece nesses dez minutos o encontre quente em vez de esperar um novo. Sem
ele, cada data flow de um pipeline inicia o próprio cluster, e um pipeline de quatro data flows em
sequência espera quatro vezes. Com ele, o cluster fica ocioso até dez minutos depois do último, e
esses minutos são cobrados à mesma tarifa do trabalho.

## A conta de uma noite

A noite da Quitanda, se fosse escrita como data flows: um flow de limpeza e um de resumo, um depois do
outro, cada um com uns três minutos de trabalho. A Microsoft descreve um cluster frio como levando
alguns minutos para subir; tome cinco como número redondo para a conta, que é ilustrativo e não foi
medido. A **um preço ilustrativo de 0,30 USD por vCore-hora**, com 8 núcleos:

| arranjo | minutos cobrados do cluster | vCore-horas | USD por noite | USD por mês |
|---|---:|---:|---:|---:|
| sem time to live: duas partidas a frio | 5 + 3 + 5 + 3 = 16 | 8 × 16 / 60 = 2,13 | 0,64 | 19,84 |
| dez minutos de time to live | 5 + 3 + 3 + 10 = 21 | 8 × 21 / 60 = 2,80 | 0,84 | 26,04 |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 248\" role=\"img\" aria-label=\"Duas linhas do tempo de minutos de cluster cobrados para os dois data flows da Quitanda. Sem time to live: cinco minutos subindo, três trabalhando, cinco subindo de novo, três trabalhando, 16 minutos. Com dez minutos de time to live: cinco minutos subindo, três trabalhando, três trabalhando, depois dez minutos ocioso e quente, 21 minutos.\" data-fig=\"l20-clock\"><text x=\"188\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sem time to live</text><text x=\"188\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">duas partidas a frio</text><rect x=\"200\" y=\"56\" width=\"108\" height=\"30\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"/><rect x=\"310\" y=\"56\" width=\"64\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><rect x=\"376\" y=\"56\" width=\"108\" height=\"30\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"/><rect x=\"486\" y=\"56\" width=\"64\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"560\" y=\"71\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 min</text><text x=\"188\" y=\"134\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dez minutos de vida</text><text x=\"188\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma partida, ociosa depois</text><rect x=\"200\" y=\"126\" width=\"108\" height=\"30\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"/><rect x=\"310\" y=\"126\" width=\"64\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><rect x=\"376\" y=\"126\" width=\"64\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><rect x=\"442\" y=\"126\" width=\"218\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"/><text x=\"670\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">21 min</text><line x1=\"200\" y1=\"196\" x2=\"200\" y2=\"202\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"200\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"310\" y1=\"196\" x2=\"310\" y2=\"202\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"310\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><line x1=\"420\" y1=\"196\" x2=\"420\" y2=\"202\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"420\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><line x1=\"530\" y1=\"196\" x2=\"530\" y2=\"202\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"530\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">15</text><line x1=\"640\" y1=\"196\" x2=\"640\" y2=\"202\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"640\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><line x1=\"200\" y1=\"196\" x2=\"662\" y2=\"196\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"431.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">minutos cobrados do cluster, com a partida ilustrativa de cinco minutos da lição</text><rect x=\"200\" y=\"14\" width=\"12\" height=\"10\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"218\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cluster subindo</text><rect x=\"340\" y=\"14\" width=\"12\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"/><text x=\"358\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">data flow trabalhando</text><rect x=\"480\" y=\"14\" width=\"12\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"/><text x=\"498\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">mantido quente, ocioso</text></svg>", "caption": "Os mesmos dois data flows, cobrados de dois jeitos. Manter o cluster quente economizou a segunda partida e pagou dez minutos ociosos; para dois flows em sequência, é a aposta pior."}
```

**O time to live deixou esta noite mais cara**, porque o segundo flow começou logo depois do primeiro
e os dez minutos ociosos do fim custaram mais do que a segunda partida economizou. Ele compensa quando
vários flows começam em momentos diferentes dentro da janela, e custa quando o pipeline tem dois
passos. A configuração é uma aposta em quão perto o trabalho chega, e vale fazer esta conta com o
preço real e os tempos reais do pipeline antes de fazê-la.

## O mesmo relógio, para notebooks

**Um pool Spark no Synapse pausa sozinho depois de um número de minutos ociosos**, e um notebook que
começa num pool pausado espera ele subir, a mesma partida a frio com outro nome. O pool é cobrado por
vCore-hora enquanto roda, minutos ociosos incluídos. **O Fabric mantém starter pools quentes**, então
uma sessão de notebook lá começa em segundos e o tempo dela é pago com a capacidade da lição 17,
suavizado ao longo do dia. **O Databricks**, lição 21, tem a mesma escolha em mais formas: clusters
que se encerram depois de minutos ociosos, pools de máquinas mantidas prontas e computação serverless
em que o provedor guarda o calor e cobra só o trabalho.

A pergunta é a mesma em todos: **quantos minutos por noite o cluster roda sem ninguém usando, e
quanto isso vale para quem está esperando**. Numa noite que roda às três da manhã ninguém está
esperando, e uma partida a frio é de graça no sentido que importa.
