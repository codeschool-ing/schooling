---
title: Imagens do Marketplace e os seus quatro nomes
version: 1
---

"Ubuntu 24.04" parece o nome de uma imagem. No Azure é o nome de uma família inteira, e não dá para
criar uma máquina a partir de uma família. **Uma imagem do Marketplace é nomeada por quatro nomes**,
unidos por dois-pontos no que o Azure chama de URN: o *publisher*, quem fez; a *offer*, um grupo de
imagens relacionadas; o *SKU*, uma edição dentro da offer; e a *versão*, um build dessa edição.

| | Ubuntu 24.04 | o que o nome é |
|---|---|---|
| publisher | `Canonical` | a organização que publica |
| offer | `ubuntu-24_04-lts` | um grupo de imagens relacionadas |
| SKU | `server` | uma edição: aqui, geração 2 em x64 |
| versão | `latest`, ou um número de build | um build do SKU |

Juntando, `Canonical:ubuntu-24_04-lts:server:latest`. Nenhum dos quatro é derivado dos outros, e a
offer é a que surpreende: a offer da Canonical para o 22.04 é `0001-com-ubuntu-server-jammy`, para o
24.04 é `ubuntu-24_04-lts`, e antes do 20.04 era `UbuntuServer`. Uma URN é copiada de uma lista,
nunca digitada de memória.

## A lista que a CLI leva consigo

O `az vm image list` responde sem assinatura, o que faz dele o único comando de imagem que este
curso consegue rodar:

```
ana@laptop:~/azure$ az vm image list --output table
WARNING: Failed to retrieve image alias doc 'https://azcliprod.blob.core.windows.net/cli/vm/aliases.json'. Error: 'ConnectionError'. Use local copy instead.
WARNING: You are viewing an offline list of images, use --all to retrieve an up-to-date list
Architecture    Offer                         Publisher               Sku                                 Urn                                                                             UrnAlias                 Version
--------------  ----------------------------  ----------------------  ----------------------------------  ------------------------------------------------------------------------------  -----------------------  ---------
x64             azurelinux-4                  microsoftazurelinux     4                                   microsoftazurelinux:azurelinux-4:4:latest                                       AzureLinux4              latest
Arm64           azurelinux-4                  microsoftazurelinux     4-arm64                             microsoftazurelinux:azurelinux-4:4-arm64:latest                                 AzureLinux4Arm64         latest
x64             azurelinux-4                  microsoftazurelinux     4-gen1                              microsoftazurelinux:azurelinux-4:4-gen1:latest                                  AzureLinux4Gen1          latest
x64             CentOS                        OpenLogic               8_5-gen2                            OpenLogic:CentOS:8_5-gen2:latest                                                CentOS85Gen2             latest
x64             debian-11                     Debian                  11-backports-gen2                   Debian:debian-11:11-backports-gen2:latest                                       Debian11                 latest
x64             flatcar-container-linux-free  kinvolk                 stable-gen2                         kinvolk:flatcar-container-linux-free:stable-gen2:latest                         FlatcarLinuxFreeGen2     latest
x64             openSUSE-leap-15-4            SUSE                    gen2                                SUSE:openSUSE-leap-15-4:gen2:latest                                             OpenSuseLeap154Gen2      latest
x64             RHEL                          RedHat                  8-lvm-gen2                          RedHat:RHEL:8-lvm-gen2:latest                                                   RHELRaw8LVMGen2          latest
x64             sles-15-sp3                   SUSE                    gen2                                SUSE:sles-15-sp3:gen2:latest                                                    SuseSles15SP3            latest
x64             0001-com-ubuntu-server-jammy  Canonical               22_04-lts-gen2                      Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest                    Ubuntu2204               latest
x64             WindowsServer                 MicrosoftWindowsServer  2022-datacenter-g2                  MicrosoftWindowsServer:WindowsServer:2022-datacenter-g2:latest                  Win2022Datacenter        latest
x64             WindowsServer                 MicrosoftWindowsServer  2022-datacenter-azure-edition-core  MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition-core:latest  Win2022AzureEditionCore  latest
x64             WindowsServer                 MicrosoftWindowsServer  2019-datacenter-gensecond           MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest           Win2019Datacenter        latest
x64             WindowsServer                 MicrosoftWindowsServer  2016-datacenter-gensecond           MicrosoftWindowsServer:WindowsServer:2016-datacenter-gensecond:latest           Win2016Datacenter        latest
x64             WindowsServer                 MicrosoftWindowsServer  2012-R2-Datacenter                  MicrosoftWindowsServer:WindowsServer:2012-R2-Datacenter:latest                  Win2012R2Datacenter      latest
x64             WindowsServer                 MicrosoftWindowsServer  2012-Datacenter                     MicrosoftWindowsServer:WindowsServer:2012-Datacenter:latest                     Win2012Datacenter        latest
```

Vale ler os dois avisos antes da tabela. A CLI primeiro tentou baixar um documento curto de aliases
de imagem que a Microsoft publica, não conseguiu, e recorreu a uma cópia embutida nesta versão da
CLI; depois disse o que isso significa. **Esta é uma lista offline de dezesseis imagens populares,
congelada na CLI 2.91.0, e não o que o Azure oferece hoje.** O laptop em que estas transcrições foram
gravadas é barrado no host onde esse documento fica. Uma máquina na internet aberta baixa o
documento e não mostra nenhum dos dois avisos.

A diferença não é cosmética. A cópia embutida nesta CLI tem `Ubuntu2204` e nenhum Ubuntu 24.04. O
documento que ela não conseguiu baixar, lido no GitHub em 30 de outubro de 2026, tem dezoito
aliases, entre eles `Ubuntu2404` para `Canonical:ubuntu-24_04-lts:server:latest`. Então
`--image Ubuntu2404` quer dizer essa URN numa máquina que alcançou o documento, e não quer dizer nada
numa que não alcançou. **Um alias é da CLI, e o Azure nunca ouviu falar dele.** Um arquivo Bicep ou
um template ARM nomeia as quatro partes, que é o que este curso faz daqui em diante.

O filtro funciona na lista offline também, e mostra como ela é pequena:

```
ana@laptop:~/azure$ az vm image list --publisher Canonical --output table
WARNING: Failed to retrieve image alias doc 'https://azcliprod.blob.core.windows.net/cli/vm/aliases.json'. Error: 'ConnectionError'. Use local copy instead.
WARNING: You are viewing an offline list of images, use --all to retrieve an up-to-date list
Architecture    Offer                         Publisher    Sku             Urn                                                           UrnAlias    Version
--------------  ----------------------------  -----------  --------------  ------------------------------------------------------------  ----------  ---------
x64             0001-com-ubuntu-server-jammy  Canonical    22_04-lts-gen2  Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest  Ubuntu2204  latest
```

Para o catálogo de verdade, o `--all` pergunta ao Azure, e o Azure exige uma conta:

```
ana@laptop:~/azure$ az vm image list --all --publisher Canonical --offer ubuntu-24_04-lts --output table
ERROR: Please run 'az login' to setup account.
ana@laptop:~/azure$ az vm image show --urn Canonical:ubuntu-24_04-lts:server:latest
ERROR: Please run 'az login' to setup account.
```

Com uma assinatura, a documentação da Microsoft descreve o caminho de costume pelos quatro nomes
como um comando para cada: `az vm image list-publishers`, `list-offers --publisher Canonical`,
`list-skus --offer ubuntu-24_04-lts`, e `az vm image list --all` com os três nomes para ver todas as
versões. O `--all` sobre o Marketplace inteiro leva vários minutos, pela própria documentação, e é
por isso que a forma filtrada existe. Esses comandos não foram rodados neste curso: precisam de uma
assinatura.

O `az vm image show`, recusado acima, é o comando a rodar antes de usar uma imagem de um publisher
que você nunca usou. A resposta traz um campo `plan`. **Quando `plan` não é `null`, a imagem tem
termos de licença próprios.** Eles são aceitos uma vez por assinatura, com `az vm image terms
accept`, antes que qualquer template crie uma máquina com ela; os três nomes do plano entram também
na declaração da máquina. As imagens Ubuntu da Canonical não têm plano; muitas das imagens
comerciais do Marketplace, como um servidor de banco de dados vendido pelo fabricante, têm.

## `latest` é uma pergunta feita na criação

O quarto nome é o que muda. Um publisher gera uma versão nova de um SKU sempre que lança correções,
e a versão é um número; a documentação da Microsoft mostra um build do Ubuntu 18.04 chamado
`18.04.201901220`. **`latest` não é uma versão. É uma pergunta, e o Azure responde no momento em que
uma máquina é criada.** Duas máquinas criadas a partir da mesma URN com um mês de diferença saem de
dois builds diferentes, e um template que não mudou não diz nada sobre qual.

É o padrão certo para uma máquina única que alguém cuida, que então começa com as correções do mês.
É o errado para um grupo de máquinas que precisam ser iguais, e é por isso que os scale sets da
lição 4 e a galeria da última seção desta lição se importam com isso. Uma versão fixa, como
`18.04.201901220`, deixa toda criação idêntica; também mantém você nesse build até alguém editar o
arquivo. A saída de costume dessa troca é fixar uma imagem sua em vez da de outra pessoa, que é o
assunto das duas próximas seções.

## Nomeando uma em Bicep

Aqui está a máquina onde a API de pedidos da loja rodaria, declarada com uma imagem do Marketplace. A
interface de rede e a chave são parâmetros, porque a lição 16 de `azure-foundations` montou a rede e
nada aqui depende de como. Salve como `vm.bicep`:

```bicep
// vm.bicep
param location string = 'brazilsouth'
param adminUsername string = 'ana'
param sshPublicKey string
param nicId string

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'shop-web-1'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v5'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    osProfile: {
      computerName: 'shop-web-1'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicId
        }
      ]
    }
  }
}
```

`Standard_D2s_v5` é o tamanho que a lição 1 encontrou como padrão da CLI. O perfil de segurança está
escrito por inteiro, como a última seção mandou: Trusted Launch, com o Secure Boot e o TPM virtual
ligados. Compile:

```
ana@laptop:~/azure$ bicep build vm.bicep
ana@laptop:~/azure$ jq ".resources[0].properties.storageProfile.imageReference" vm.json
{
  "publisher": "Canonical",
  "offer": "ubuntu-24_04-lts",
  "sku": "server",
  "version": "latest"
}
```

Nenhum aviso, e os quatro nomes chegam ao template exatamente como foram escritos. **O compilador não
sabe quais imagens existem.** Os quatro são strings comuns para ele, `latest` inclusive; um SKU que a
Canonical nunca publicou compila igualmente limpo, e só o Azure, consultado com uma assinatura,
recusaria. O compilador também não é rígido com o tipo de segurança. Erre a grafia:

```
ana@laptop:~/azure$ sed -i "s/TrustedLaunch/TrustedLaunh/" vm.bicep
ana@laptop:~/azure$ bicep build vm.bicep
ana@laptop:~/azure$ jq ".resources[0].properties.securityProfile" vm.json
{
  "securityType": "TrustedLaunh",
  "uefiSettings": {
    "secureBootEnabled": true,
    "vTpmEnabled": true
  }
}
ana@laptop:~/azure$ sed -i "s/TrustedLaunh/TrustedLaunch/" vm.bicep
```

Nada foi recusado. O compilador conhece `securityType` como uma string que costuma ser um de poucos
valores, então `TrustedLaunh` entrou no template como estava, e o que o Azure faz com isso é decidido
quando a requisição chega, não aqui. A regra da lição 1 cobre o que o compilador recusa; esta é a
outra metade, um valor que nada no laptop verifica. O segundo `sed` devolveu a grafia, e o arquivo
está pronto para a próxima seção.
