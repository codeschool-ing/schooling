---
title: A conta de armazenamento: tipo, desempenho e replicação
version: 1
---

**Tudo o que o Azure guarda como blobs, arquivos, filas ou tabelas mora dentro de uma conta de
armazenamento.** Três decisões são tomadas ali uma vez, para tudo o que está nela: o tipo, a camada
de desempenho, e quantas cópias de cada byte o Azure mantém e onde. Um contêiner e um
blob não têm voz em nenhuma delas. Escolher errado não é fatal, mas duas das três só mudam movendo os
dados para uma conta nova.

A conta também é um endereço. Uma conta chamada `stquitandadata` responde em
`https://stquitandadata.blob.core.windows.net` para blobs, `.queue.` para filas, `.table.` para
tabelas, `.file.` para compartilhamentos de arquivos e `.dfs.` para a interface de Data Lake da lição
3. É por isso que a próxima seção se demora tanto no nome.

## O tipo

| tipo | o que guarda | quando |
|---|---|---|
| `StorageV2` | blobs, arquivos, filas, tabelas | o padrão, e a resposta para quase tudo |
| `BlockBlobStorage` | só block blobs e append blobs | desempenho premium para blobs: leituras e escritas pequenas e frequentes |
| `FileStorage` | só compartilhamentos de arquivos | compartilhamentos de arquivos premium |
| `Storage`, `BlobStorage` | o que os nomes dizem | tipos legados; a Microsoft os aposenta, e uma conta nova nunca os usa |

**General-purpose v2, o `StorageV2`, é o tipo de que este curso fala sempre que diz conta de
armazenamento.** É o único tipo que oferece todas as camadas de acesso da lição 4, todas as opções de
replicação abaixo e o namespace hierárquico da lição 3.

## Desempenho

**Standard** guarda os dados em discos rígidos e cobra principalmente pelo que você guarda.
**Premium** os guarda em discos de estado sólido, cobra mais por gigabyte e menos por operação, e
responde com latência menor e mais estável. Premium é um tipo de conta à parte para blobs, e por isso
a tabela acima tem o `BlockBlobStorage`; não dá para trocar uma conta Standard existente para Premium.

## Replicação

O Azure sempre mantém pelo menos três cópias de cada byte. O que você escolhe é onde elas ficam.

| opção | cópias | sobrevive a |
|---|---|---|
| LRS, redundância local | 3 num só datacenter | um disco ou servidor com defeito |
| ZRS, redundância de zona | 3, uma em cada uma de três zonas de disponibilidade da região | perder um datacenter inteiro |
| GRS, geo-redundância | LRS aqui, mais 3 na região emparelhada | perder a região inteira |
| GZRS, geo-redundância de zona | ZRS aqui, mais 3 na região emparelhada | as duas coisas acima |

**GRS e GZRS copiam para a outra região de forma assíncrona**, então um desastre que leve a região
primária pode perder as últimas escritas que ainda não tinham atravessado. A Microsoft não documenta
garantia nenhuma para essa diferença, e descreve o atraso habitual como abaixo de quinze minutos. A
cópia secundária não pode ser lida, a menos que você escolha as variantes com acesso de leitura,
RA-GRS e RA-GZRS. Para `brazilsouth` a região emparelhada é `southcentralus`, no Texas, o que importa
para qualquer empresa com dados que devem ficar no Brasil: as opções geo-redundantes mandam uma cópia
para fora do país.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Quatro opções de replicação como cópias em zonas. LRS guarda três cópias numa zona de brazilsouth. ZRS guarda uma cópia em cada uma de três zonas. GRS guarda três numa zona e mais três na região emparelhada southcentralus, copiadas de forma assíncrona. GZRS guarda uma em cada uma de três zonas e mais três na região emparelhada.\" data-fig=\"l01-replication\"><defs><marker id=\"l01r-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--amber)\"/></marker></defs><text x=\"250\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">região primária</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">região emparelhada</text><text x=\"250\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">brazilsouth</text><text x=\"600\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">southcentralus</text><text x=\"40\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">LRS</text><rect x=\"110\" y=\"70\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"152\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona 1</text><circle cx=\"130\" cy=\"98\" r=\"7\" fill=\"var(--phosphor)\"/><circle cx=\"152\" cy=\"98\" r=\"7\" fill=\"var(--phosphor)\"/><circle cx=\"174\" cy=\"98\" r=\"7\" fill=\"var(--phosphor)\"/><rect x=\"205\" y=\"70\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"247\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona 2</text><rect x=\"300\" y=\"70\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"342\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona 3</text><rect x=\"540\" y=\"70\" width=\"120\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\" stroke-dasharray=\"5 4\"/><text x=\"40\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">ZRS</text><rect x=\"110\" y=\"132\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"152\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona 1</text><circle cx=\"130\" cy=\"160\" r=\"7\" fill=\"var(--phosphor)\"/><rect x=\"205\" y=\"132\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"247\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona 2</text><circle cx=\"225\" cy=\"160\" r=\"7\" fill=\"var(--phosphor)\"/><rect x=\"300\" y=\"132\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"342\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona 3</text><circle cx=\"320\" cy=\"160\" r=\"7\" fill=\"var(--phosphor)\"/><rect x=\"540\" y=\"132\" width=\"120\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\" stroke-dasharray=\"5 4\"/><text x=\"40\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">GRS</text><rect x=\"110\" y=\"194\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"152\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona 1</text><circle cx=\"130\" cy=\"222\" r=\"7\" fill=\"var(--phosphor)\"/><circle cx=\"152\" cy=\"222\" r=\"7\" fill=\"var(--phosphor)\"/><circle cx=\"174\" cy=\"222\" r=\"7\" fill=\"var(--phosphor)\"/><rect x=\"205\" y=\"194\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"247\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona 2</text><rect x=\"300\" y=\"194\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"342\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona 3</text><rect x=\"540\" y=\"194\" width=\"120\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\" stroke-dasharray=\"5 4\"/><circle cx=\"560\" cy=\"222\" r=\"7\" fill=\"var(--amber)\"/><circle cx=\"582\" cy=\"222\" r=\"7\" fill=\"var(--amber)\"/><circle cx=\"604\" cy=\"222\" r=\"7\" fill=\"var(--amber)\"/><line x1=\"397\" y1=\"216\" x2=\"536\" y2=\"216\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01r-ah)\"/><text x=\"466\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">assíncrono</text><text x=\"40\" y=\"278\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">GZRS</text><rect x=\"110\" y=\"256\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"152\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona 1</text><circle cx=\"130\" cy=\"284\" r=\"7\" fill=\"var(--phosphor)\"/><rect x=\"205\" y=\"256\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"247\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona 2</text><circle cx=\"225\" cy=\"284\" r=\"7\" fill=\"var(--phosphor)\"/><rect x=\"300\" y=\"256\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"342\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona 3</text><circle cx=\"320\" cy=\"284\" r=\"7\" fill=\"var(--phosphor)\"/><rect x=\"540\" y=\"256\" width=\"120\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\" stroke-dasharray=\"5 4\"/><circle cx=\"560\" cy=\"284\" r=\"7\" fill=\"var(--amber)\"/><circle cx=\"582\" cy=\"284\" r=\"7\" fill=\"var(--amber)\"/><circle cx=\"604\" cy=\"284\" r=\"7\" fill=\"var(--amber)\"/><line x1=\"397\" y1=\"278\" x2=\"536\" y2=\"278\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01r-ah)\"/><text x=\"466\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">assíncrono</text><text x=\"360\" y=\"328\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cada ponto é uma cópia de cada byte; o Azure guarda três onde quer que guarde alguma</text></svg>", "caption": "Onde ficam as três cópias. Só as opções geo-redundantes saem da região, e saem de forma assíncrona."}
```

A escolha da Quitanda, e a que este curso usa nas suas declarações, é **`StorageV2`, Standard, ZRS**.
As exportações de pedidos e o lake podem ser reconstruídos a partir do banco da loja, então perder uma
região é um desastre do qual se recupera, e não um byte a guardar a qualquer preço. O ZRS sobrevive à
perda de um datacenter sem mandar nada para fora do país.

## O que o Azurite tem no lugar de uma conta

**O Azurite tem uma conta, sempre, e ninguém a criou.** Ela se chama `devstoreaccount1`, e a chave
dela está publicada na documentação da Microsoft. Como no seu notebook não há um nome de domínio para
cada conta, a conta vai para o caminho em vez do nome do host:

```
ana@laptop:~/azure$ az storage blob url -c orders -n exports/2026-10-29.csv -o tsv
http://127.0.0.1:10000/devstoreaccount1/orders/exports/2026-10-29.csv
```

Essa URL é montada pela linha de comando a partir da connection string e não pergunta nada ao
Azurite, e é por isso que funciona para um contêiner que não existe. No Azure o mesmo blob fica em
`https://stquitandadata.blob.core.windows.net/orders/exports/2026-10-29.csv`. **Tipo, desempenho e
replicação não existem no Azurite**: são propriedades de uma conta, e a conta é o plano de controle a
que nenhum emulador responde.

## Declarar uma, e conferir a declaração

O que o curso consegue conferir de uma conta é a declaração dela. Crie um diretório para ela e salve
nele o arquivo abaixo:

```sh
mkdir -p ~/azure/tf/account && cd ~/azure/tf/account
```

`main.tf`:

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

resource "azurerm_resource_group" "data" {
  name     = "rg-quitanda-data-prd"
  location = "brazilsouth"
}

resource "azurerm_storage_account" "data" {
  name                     = "stquitandadataprd"
  resource_group_name      = azurerm_resource_group.data.name
  location                 = azurerm_resource_group.data.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"
}
```

```
ana@laptop:~/azure/tf/account$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/account$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/account$ sed -i 's/"ZRS"/"ZZRS"/' main.tf && terraform validate -no-color

Error: expected account_replication_type to be one of ["LRS" "ZRS" "GRS" "RAGRS" "GZRS" "RAGZRS"], got ZZRS

  with azurerm_storage_account.data,
  on main.tf line 25, in resource "azurerm_storage_account" "data":
  25:   account_replication_type = "ZZRS"

```

**O `validate` lê os arquivos e o esquema do provider, e não pergunta nada ao Azure**: nem login, nem
assinatura, nem rede depois do `init`. Ele pega um valor fora da lista que o provider conhece, e não
consegue pegar uma escolha que o Azure recusaria por motivos próprios, como uma opção de replicação
que uma região não oferece. O que ele diz ainda vale a pena, porque um erro de digitação achado aqui
é uma implantação falha que nunca acontece, e a mensagem diz o arquivo, a linha e a lista de valores
que teria aceitado. `RAGRS` e `RAGZRS` nessa lista são as variantes com acesso de leitura, escritas
sem o hífen.
