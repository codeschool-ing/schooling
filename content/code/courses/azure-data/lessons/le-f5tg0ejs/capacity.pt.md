---
title: Capacidade: a única coisa que você dimensiona
version: 1
---

**Tudo o que o Fabric faz é pago com uma capacidade, medida em unidades de capacidade, as CUs.** Um
notebook Spark, uma consulta no warehouse, uma cópia de pipeline, um relatório atualizando: cada um
consome CU-segundos da capacidade do workspace em que roda. Não há um preço para o Spark e outro para
o SQL. Esta seção é ensinada a partir da documentação da Microsoft, exceto a declaração que o
Terraform confere abaixo, e o throttling que ela descreve não foi observado.

## Os tamanhos

**O tamanho de uma capacidade é a SKU dela, e o número no nome é o número de CUs**: a F2 tem 2, a
F64 tem 64. A Microsoft documenta a lista, e o provider do Azure para o Terraform carrega a mesma
lista, o que permite conferi-la num laptop. Crie um diretório, `~/azure/tf/fabric`, e salve isto nele:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.12.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "analytics" {
  name     = "rg-quitanda-analytics-prd"
  location = "brazilsouth"
}

resource "azurerm_fabric_capacity" "analytics" {
  name                   = "fcquitandaprd"
  resource_group_name    = azurerm_resource_group.analytics.name
  location               = azurerm_resource_group.analytics.location
  administration_members = ["dados@quitanda.example"]

  sku {
    name = "F2"
    tier = "Fabric"
  }
}
```

```
ana@laptop:~/azure/tf/fabric$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/fabric$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/fabric$ sed -i 's/"F2"/"F3"/' main.tf && terraform validate -no-color 2>&1 | grep Error
Error: expected sku.0.name to be one of ["F2" "F4" "F8" "F16" "F32" "F64" "F128" "F256" "F512" "F1024" "F2048"], got F3
ana@laptop:~/azure/tf/fabric$ sed -i 's/"F3"/"F2"/; s/fcquitandaprd/fc-quitanda-prd/' main.tf && terraform validate -no-color 2>&1 | grep Error
Error: invalid value for name (`name` must be between 3 and 63 characters. It can contain only lowercase letters and numbers. It must start with a lowercase letter.)
```

**Onze tamanhos, cada um o dobro do anterior.** Não existe F3 nem F48, então crescer é um passo para
o dobro do tamanho e o dobro do preço. O nome da capacidade segue as regras da conta de
armazenamento da lição 1, com mais espaço: letras minúsculas e dígitos, sem hífen.
`administration_members` diz quem pode administrar a capacidade dentro do Fabric, e essas pessoas
não precisam de papel nenhum na assinatura do Azure. Nada foi criado: o `validate` leu o arquivo e o
schema do provider, e não perguntou nada ao Azure.

## Pagando por ela

**Uma capacidade é cobrada por cada hora em que existe, ocupada ou ociosa**, a um preço por CU-hora,
a menos que esteja pausada. Uma capacidade pay-as-you-go pode ser pausada e retomada pelo portal do
Azure ou pela API. Enquanto está pausada, a computação dela não é cobrada e os workspaces nela não
rodam nada; os dados no OneLake continuam lá, e continuam cobrados como armazenamento, que é um
medidor à parte. Uma reserva compra um tamanho por um ano com desconto, e uma capacidade reservada é
paga rodando ou não.

A conta, a **um preço ilustrativo de 0,20 USD por CU-hora**, que é um número para fazer a soma e não
o preço do Azure, num mês de 730 horas:

| capacidade | ligada o mês todo | ligada 12 horas por dia |
|---|---:|---:|
| F2 | 2 × 0,20 × 730 = 292 USD | 146 USD |
| F8 | 8 × 0,20 × 730 = 1.168 USD | 584 USD |
| F64 | 64 × 0,20 × 730 = 9.344 USD | 4.672 USD |

O preço por CU é o mesmo em todos os tamanhos, então **a decisão é o tamanho e as horas, nunca a
tarifa**. A tabela de preços da lição 1 lê o preço real por CU-hora quando recebe o nome do serviço
Fabric do jeito que a Retail Prices API o escreve, o que este curso não conseguiu confirmar, porque a
API estava fora do alcance dele. Há mais um degrau documentado, para o Power BI: abaixo da F64, todo
mundo que abre um relatório precisa de uma licença paga do Power BI, e da F64 para cima pessoas com
a licença gratuita podem ver os relatórios da capacidade. Numa empresa cujos relatórios são lidos
por duzentas pessoas, essa linha mexe mais na conta do que as CUs.

## Suavização

**Uma capacidade não recusa trabalho no instante em que fica ocupada.** O Fabric mede o consumo em
pontos de 30 segundos e espalha os CU-segundos de cada operação para a frente no tempo, o que a
Microsoft chama de suavização (smoothing):

- **operações interativas**, as que alguém está esperando, como as consultas que um relatório do
  Power BI manda enquanto uma pessoa olha para ele, são espalhadas por pelo menos cinco minutos;
- **operações em segundo plano**, as que ninguém está olhando, como um notebook, um pipeline ou uma
  atualização agendada, são espalhadas por vinte e quatro horas.

A suavização é o que deixa uma capacidade pequena rodar um job muito maior do que ela. Um notebook
Spark que carrega a noite da Quitanda e usa 16 CUs por 15 minutos consome 16 × 900 = 14.400
CU-segundos. Espalhado pelos 86.400 segundos de um dia, dá 0,17 CU em média, um doze avos de uma F2.
De que tipo cada operação é cabe ao Fabric, não a você: a documentação da Microsoft mantém uma tabela
delas, e vale a pena lê-la antes de concluir que uma capacidade é pequena demais.

## Throttling

**O throttling é medido por quanto do futuro da capacidade já foi gasto.** Quando o consumo suavizado
passa do tamanho da capacidade, o excesso é levado adiante e pago com o tempo ocioso que vem depois.
O Fabric expressa essa dívida em minutos de capacidade futura, e a Microsoft documenta quatro
estágios:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Um eixo horizontal da capacidade futura já consumida, marcado em 10 minutos, 60 minutos e 24 horas, dividido em quatro estágios. Até 10 minutos, proteção de excesso: tudo roda como pedido. De 10 a 60 minutos, atraso interativo: um pedido interativo novo espera 20 segundos antes de começar. De 60 minutos a 24 horas, rejeição interativa: pedidos interativos novos são recusados e o trabalho em segundo plano continua. Acima de 24 horas, rejeição em segundo plano: todo pedido novo é recusado, inclusive o de segundo plano.\" data-fig=\"l17-throttle\"><defs><marker id=\"l17-ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"/></marker></defs><rect x=\"30\" y=\"60\" width=\"164\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"112.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">proteção de excesso</text><text x=\"112.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">tudo roda</text><text x=\"112.0\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">como pedido</text><rect x=\"200\" y=\"60\" width=\"164\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"282.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">atraso interativo</text><text x=\"282.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um pedido interativo</text><text x=\"282.0\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">novo espera 20 s</text><text x=\"282.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">antes de começar</text><rect x=\"370\" y=\"60\" width=\"164\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"452.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">rejeição interativa</text><text x=\"452.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">pedidos interativos</text><text x=\"452.0\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">novos recusados; o</text><text x=\"452.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">segundo plano roda</text><rect x=\"540\" y=\"60\" width=\"154\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"617.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">rejeição em segundo plano</text><text x=\"617.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">todo pedido novo</text><text x=\"617.0\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">recusado, inclusive</text><text x=\"617.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o segundo plano</text><line x1=\"30\" y1=\"200\" x2=\"700\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l17-ah)\"/><line x1=\"30\" y1=\"194\" x2=\"30\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"/><text x=\"30\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><line x1=\"197\" y1=\"194\" x2=\"197\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"/><text x=\"197\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10 min</text><line x1=\"367\" y1=\"194\" x2=\"367\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"/><text x=\"367\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60 min</text><line x1=\"537\" y1=\"194\" x2=\"537\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"/><text x=\"537\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">24 h</text><text x=\"365\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minutos de capacidade futura já consumidos pelo trabalho suavizado</text><text x=\"365\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o que um pedido novo encontra, conforme quanto a capacidade já gastou adiantado</text></svg>", "caption": "Os estágios de throttling do Fabric, como a Microsoft os documenta. A medida não é quanto a capacidade está ocupada agora, e sim quanto do futuro dela já foi gasto."}
```

**O primeiro estágio é o previsto**: um pico pago em dez minutos é invisível. O segundo é o primeiro
que as pessoas notam, um relatório que demora vinte segundos a mais para começar. No terceiro, os
relatórios falham enquanto os jobs da noite continuam rodando, e quem nota são os analistas às nove
da manhã. No quarto, os jobs da noite também falham. **Pausar a capacidade não cancela a dívida**: a
documentação da Microsoft diz que o consumo levado adiante é cobrado no momento da pausa, então uma
capacidade pausada para fugir do throttling paga pelo que já tinha gasto.

O que um time pode fazer contra o throttling é o mesmo que faz com qualquer máquina compartilhada:
diminuir o trabalho, o que num lago é sobretudo o arranjo dos arquivos da lição 18, dar capacidades
separadas à produção e ao desenvolvimento, e aumentar o tamanho quando o terceiro estágio aparece
toda semana. Mudar um job de horário ajuda menos do que parece, porque o trabalho em segundo plano é
espalhado por um dia inteiro seja qual for a hora em que começa.

O aplicativo Capacity Metrics, que a Microsoft publica para o Fabric, é onde os pontos de tempo e
os estágios aparecem; ele faz parte do produto e não foi visto aqui.
