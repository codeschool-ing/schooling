---
title: Azure PowerShell, e o shell no navegador
version: 1
---

**Há duas linhas de comando oficiais para o Azure, e elas chegam à mesma API.** A CLI do Azure é a que
este curso usa. O **Azure PowerShell** é a outra: um conjunto de módulos para o PowerShell, chamado
`Az`, cujos comandos são cmdlets no formato verbo-substantivo do PowerShell. Nenhuma consegue fazer algo
que a outra não consiga, porque as duas transformam o que você digita nos mesmos pedidos ao Resource
Manager, que a lição 25 abre.

## O Azure PowerShell, lado a lado

O PowerShell 7 roda no Linux, no macOS e no Windows, e o `Az` é instalado da **PowerShell Gallery**, o
repositório de pacotes do PowerShell, com `Install-Module -Name Az -Repository PSGallery -Scope
CurrentUser`. **Nada nesta seção foi executado para o curso**: a máquina onde as lições foram gravadas
não alcança a PowerShell Gallery, então o módulo não pôde ser instalado, e não há transcrições aqui. Os
nomes abaixo são da documentação da Microsoft.

| o quê | CLI do Azure | Azure PowerShell |
|---|---|---|
| fazer login | `az login` | `Connect-AzAccount` |
| qual assinatura | `az account show` | `Get-AzContext` |
| escolher outra | `az account set --subscription shop-staging` | `Set-AzContext -Subscription shop-staging` |
| listar grupos | `az group list` | `Get-AzResourceGroup` |
| criar um | `az group create -n rg-shop-prod -l brazilsouth` | `New-AzResourceGroup -Name rg-shop-prod -Location brazilsouth` |
| implantar um arquivo Bicep | `az deployment group create -g rg-shop-prod -f main.bicep` | `New-AzResourceGroupDeployment -ResourceGroupName rg-shop-prod -TemplateFile main.bicep` |

**A diferença que importa é o que volta.** A CLI imprime texto, JSON por padrão, e você o filtra com
`--query`. O PowerShell devolve **objetos**: o `Get-AzResourceGroup` entrega ao próximo comando do
pipeline uma lista de grupos de recursos com propriedades tipadas, e o `Where-Object` e o
`Select-Object` trabalham diretamente sobre essas propriedades. Escolha pelo que a sua equipe já
escreve: uma equipe de scripts Bash lê a CLI, uma equipe que administra servidores Windows em PowerShell
lê o `Az`. Misturar os dois num pipeline não ganha nada.

## Cloud Shell

**O Cloud Shell é um terminal no navegador, aberto a partir do portal do Azure**, com a CLI do Azure, o
Azure PowerShell, o Terraform, o `git` e as ferramentas Linux de sempre já instalados e mantidos em dia
pela Microsoft. Você escolhe Bash ou PowerShell, e ele **já está logado como você**, com a identidade
que você usou no portal. É para isso que ele serve: os cinco minutos em que você precisa de uma linha de
comando e está no computador de outra pessoa, ou quando quer experimentar um comando com a CLI mais
recente sem atualizar a sua.

Os limites dele estão documentados, e cada um decide o quanto confiar nele:

- **a máquina é temporária**, fornecida por sessão e por usuário, e uma sessão termina depois de **20
  minutos** sem atividade interativa. Qualquer coisa instalada fora do seu diretório pessoal some na
  vez seguinte;
- **os seus arquivos só persistem se você lhe der armazenamento**: ele guarda o `$HOME` num
  compartilhamento de arquivos de **5 GB** numa storage account da sua assinatura. A máquina é
  gratuita; a storage account é cobrada pelo preço normal. Uma sessão *efêmera*, sem armazenamento, não
  guarda nada;
- **ele precisa de uma conta do Azure**, e é por isso que a lição 1 o deixou fora dos três caminhos
  deste curso.

**Nada disso foi executado para este curso**, pelo último desses motivos.

## Mais de uma identidade

Qualquer que seja a linha de comando, ela guarda um **login** e uma **assinatura atual**, e é na segunda
que um erro cai. O `az account show` e o `Get-AzContext` respondem qual é a atual. Dois hábitos mantêm
duas identidades separadas: citar a assinatura em todo comando que muda alguma coisa
(`--subscription shop-staging`), e dar a cada identidade o seu próprio diretório de configuração, que é
o que o `AZURE_CONFIG_DIR` fez pelo laboratório na lição 1. Um terminal de produção que nunca fez login
em staging não pode ser apontado para staging por engano.
