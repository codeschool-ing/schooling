---
title: O Data Map, fontes, coleções e varreduras
version: 1
---

**Esta seção é ensinada a partir da documentação da Microsoft e não foi executada**, a não ser pelo
Terraform conferindo uma declaração sem rede.

**O Data Map é o inventário do Purview**: um registro por ativo que ele conhece, sendo ativo uma conta
de armazenamento, um contêiner, uma pasta, um arquivo, um banco de dados, uma tabela ou uma coluna,
com as relações entre eles. Nada aparece nele sozinho. Alguém registra uma **fonte**, como a conta de
armazenamento do data lake da Quitanda ou o banco Azure SQL dela, e uma **varredura** (scan) lê essa
fonte e grava no mapa o que encontrou.

## Coleções, que também são permissões

**Fontes e ativos moram em coleções**, uma árvore sob a coleção raiz da conta. As da Quitanda podem
ser uma coleção para a zona bruta e uma para a zona curada, ou uma por equipe. A árvore importa duas
vezes: organiza o catálogo, e carrega permissões, porque os papéis do Purview, como quem pode ler o
catálogo, quem pode curar ativos e quem pode registrar fontes e rodar varreduras, são concedidos numa
coleção e herdados pelas coleções abaixo dela. Uma árvore de coleções desenhada como espelho do
organograma é o erro de costume: as equipes se reorganizam mais vezes do que os dados mudam de lugar.

## Uma varredura, e a identidade que a executa

**Uma varredura é um job que se conecta a uma fonte, lê a estrutura dela e uma amostra do conteúdo,
e grava ativos e classificações no mapa.** Ela roda num **integration runtime**, a mesma ideia do
Data Factory na lição 19: o runtime da própria Microsoft no Azure para fontes que ele alcança, um
gerenciado dentro de uma rede virtual para fontes atrás de private endpoints, ou um auto-hospedado,
instalado numa máquina sua, para fontes no seu próprio data center.

**A varredura lê com uma identidade, e essa identidade precisa de permissão para ler.** A de costume
é a identidade gerenciada da própria conta do Purview, e para uma conta de armazenamento a
documentação da Microsoft manda conceder a ela o papel **Storage Blob Data Reader** na conta. É o
assunto da lição 6 visto do outro lado: um catálogo que consegue classificar toda coluna precisa
conseguir ler toda coluna, então a conta do Purview vira um dos leitores mais privilegiados da
empresa, e o acesso dela merece revisão como qualquer outro.

**O que uma varredura lê é definido por um conjunto de regras de varredura (scan rule set)**: quais
tipos de arquivo, e quais regras de classificação aplicar. Uma varredura roda uma vez ou num
agendamento; uma varredura completa lê tudo e uma incremental só o que mudou desde a última. As
varreduras são cobradas pelo processamento que usam, então o agendamento é uma decisão de custo além
de atualidade, e a última seção põe preço numa.

## Declarando a conta

A conta do Purview em si é um recurso do Azure como os outros. Declarada em Terraform, num diretório
próprio como na lição 1:

```sh
mkdir -p ~/azure/tf/purview && cd ~/azure/tf/purview
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

resource "azurerm_resource_group" "governance" {
  name     = "rg-quitanda-governance-prd"
  location = "brazilsouth"
}

resource "azurerm_purview_account" "catalogue" {
  name                        = "pview-quitanda-prd"
  resource_group_name         = azurerm_resource_group.governance.name
  location                    = azurerm_resource_group.governance.location
  managed_resource_group_name = "rg-quitanda-governance-prd-managed"
  public_network_enabled      = false

  identity {
    type = "SystemAssigned"
  }
}
```

```
ana@laptop:~/azure/tf/purview$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/purview$ terraform validate -no-color
Success! The configuration is valid.
```

**Válido, e é a conta e nada dentro dela.** Fontes, coleções, varreduras e seus agendamentos não são
recursos do Azure neste provider; são configurados no próprio Purview, pelo portal ou pela interface
de programação dele. O `identity` dá à conta a identidade gerenciada com que uma varredura lê, e o
`public_network_enabled = false` tira a conta da internet, então o portal e a interface dela são
alcançados por private endpoints. O grupo de recursos gerenciado é onde o Azure põe os recursos que o
Purview cria para si; ele ganha nome aqui para não receber um nome gerado que ninguém reconhece.
