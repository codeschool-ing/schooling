---
title: O que o Spot vende, e o que ele não promete
version: 1
---

É fácil imaginar o Spot como uma categoria mais barata de máquina: menor, mais lenta, ou em hardware
velho. Não é nada disso. **Uma máquina virtual Spot é uma máquina virtual comum rodando em capacidade
que o Azure não está usando no momento, vendida com desconto, com uma condição: o Azure toma a
capacidade de volta sempre que precisar dela.** O guia da Microsoft sobre construir em Spot diz isso
com todas as letras: as mesmas imagens, o mesmo hardware, os mesmos discos e, portanto, o mesmo
desempenho de uma máquina regular. O que muda é a prioridade. Uma máquina regular recebe capacidade
quando pede; uma máquina Spot recebe o que sobra, e só fica com ela até uma máquina regular precisar
do hardware.

## O que é prometido, e o que não é

A documentação da Microsoft, lida em 2026-10-30, põe o desconto em **até 90%**. A página do Spot
Priority Mix diz "save up to 90%" em computação, e o guia diz que máquinas Spot "can be up to 90%
cheaper" do que as pay-as-you-go. Isso é um teto, não uma cotação. O preço varia com a região, o
tamanho, o sistema operacional e a demanda, então um tamanho que todo mundo quer numa região
movimentada tem um desconto bem menor do que um mais antigo que ninguém pede.

A outra metade do acordo está escrita com a mesma clareza: **não há SLA para uma máquina Spot**, nem
garantia de alta disponibilidade de tipo nenhum. O próprio FAQ da documentação pergunta se uma
máquina Spot, depois de criada, é igual a uma padrão, e responde que é, a não ser por não ter SLA e
poder ser despejada a qualquer momento. A lição 6 trata do que um SLA promete a uma máquina regular;
para o Spot, a promessa é nenhuma.

Quatro restrições decidem cedo se o Spot é possível:

- **Nada da série B**, nem tamanhos promocionais. A família burstable da lição 1 não roda como Spot.
- **Fora de um availability set.** A lista de erros da documentação tem um código exatamente para
  isso, `AzureSpotVMNotSupportedInAvailabilitySet`; a lição 6 explica o que é um availability set.
- **O Spot é decidido na criação.** Uma máquina existente não pode virar Spot, e uma máquina Spot
  não pode virar padrão. Mudar de ideia significa uma máquina nova.
- **Uma cota própria.** Os núcleos Spot saem de um conjunto de cota separado, compartilhado entre
  máquinas avulsas e instâncias de scale set, e aumentado pelo pedido de cota de sempre.

## O preço, que esta lição não tem

Este curso não cita preço nenhum da tabela do Azure, pelo motivo que a lição 1 dá, e um preço Spot é
o menos citável de todos, porque muda enquanto você lê. O verdadeiro está nas páginas de preço, e
atrás do link *View pricing history and compare prices in nearby regions* que o portal mostra
enquanto você cria uma máquina Spot. Está também na Retail Prices API, onde um medidor Spot traz
`Spot` no `meterName` e no `skuName`. Esta requisição pede os medidores de um `D2s_v5` em São Paulo e fica
com os Spot. Ela não foi executada neste curso:

```sh
curl -s "https://prices.azure.com/api/retail/prices?\$filter=armRegionName%20eq%20'brazilsouth'%20and%20armSkuName%20eq%20'Standard_D2s_v5'" | jq '.Items[] | select(.meterName | contains("Spot")) | {productName, meterName, retailPrice}'
```

## Pedindo uma

Para a linha de comando, o Spot é um valor de uma opção:

```
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o -- "--priority : [^:]*Allowed values: [A-Za-z, ]*\."
--priority : Priority. Use 'Spot' or 'SpotPlus' to run short-lived workloads in a cost-effective way. 'Low' enum will be deprecated in the future. Please use 'Spot' or 'SpotPlus' to deploy Azure spot VM and/or VMSS. Default to Regular. Allowed values: Low, Regular, Spot, SpotPlus.
```

`Spot` é o valor que esta lição usa. A própria ajuda diz que `Low` será descontinuado, e `SpotPlus`
é um valor que esta versão da CLI lista e que a documentação de Spot lida para esta lição não
descreve, então a lição não mexe nele. `Regular`, o padrão, é o que foi toda máquina das lições 1
a 4.

A loja tem uma primeira candidata óbvia. O relatório de vendas noturno roda por umas quatro horas
numa máquina só dele, `shop-report-1`, e ninguém espera por ele antes de amanhecer. Aqui está ela
como máquina Spot. É o `vm.bicep` da lição 2 com um nome novo, sem o perfil de segurança para ficar
curto, e com três propriedades novas no alto de `properties`. Salve como `report-vm.bicep`:

```bicep
// report-vm.bicep
param location string = 'brazilsouth'
param adminUsername string = 'ana'
param sshPublicKey string
param nicId string

resource report 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'shop-report-1'
  location: location
  properties: {
    priority: 'Spot'
    evictionPolicy: 'Deallocate'
    billingProfile: {
      maxPrice: -1
    }
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
    osProfile: {
      computerName: 'shop-report-1'
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

`priority: 'Spot'` é a escolha inteira. `evictionPolicy` e `billingProfile.maxPrice` dizem o que
acontece quando o Azure quer a capacidade de volta e se o preço é um dos motivos pelos quais ele
pode querer; as duas são o assunto da próxima seção. Todo o resto é a máquina que você já declarou
antes. Compile:

```
ana@laptop:~/azure$ bicep build report-vm.bicep
ana@laptop:~/azure$ jq ".resources[0].properties | {priority, evictionPolicy, billingProfile}" report-vm.json
{
  "priority": "Spot",
  "evictionPolicy": "Deallocate",
  "billingProfile": {
    "maxPrice": -1
  }
}
```

Nenhum aviso, e as três propriedades estão no template como foram escritas. Agora o erro de quem copia
de memória, um `spot` em minúsculas:

```
ana@laptop:~/azure$ sed "s/'Spot'/'spot'/" report-vm.bicep > lower.bicep
ana@laptop:~/azure$ bicep build lower.bicep
ana@laptop:~/azure$ jq ".resources[0].properties.priority" lower.json
"spot"
ana@laptop:~/azure$ sed "s/'Spot'/1/" report-vm.bicep > number.bicep
ana@laptop:~/azure$ bicep build number.bicep
/home/ana/azure/number.bicep(11,15) : Warning BCP036: The property "priority" expected a value of type "null | string" but the provided value is of type "1". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

O valor em minúsculas compilou sem aviso e foi para o template como `"spot"`. Pôr um número no mesmo
lugar mostra por quê: **o tipo que o compilador usa para `priority` nesta versão da API é
`null | string`, qualquer texto**, sem lista de valores permitidos. Na lição 2 o compilador recusou a
grafia britânica `Generalised` porque `osState` é, para ele, uma de exatamente duas palavras; aqui ele
não tem palavras com que comparar. Se o Resource Manager aceitaria `"spot"` é decisão do serviço de
computação, e um laptop não tem como perguntar a ele. A grafia a copiar é a da lista da CLI acima,
com a maiúscula.

## Quanto vale o desconto

Sem um preço real à mão, use a tarifa ilustrativa da lição 1 para um `D2s_v5`, 0,10 USD por hora, e
**suponha, só para a conta, um desconto Spot de 70%**, o que põe a máquina em 0,03 USD por hora.
Nenhum dos dois números é do Azure. O relatório roda quatro horas por noite, 120 horas num mês de
trinta noites: 12,00 USD numa máquina regular e 3,60 USD em Spot, uma economia de 8,40 USD.

Essa é a forma a guardar. **A economia é o desconto vezes as horas que rodam em Spot**, e as horas que
podem rodar em Spot são limitadas pelo que custa um despejo. Um relatório despejado às três da manhã
que recomeça do início não economizou nada se ainda estiver rodando quando a loja abrir. O resto
desta lição é sobre esse custo: quando vem um despejo, o que ele deixa para trás, que aviso ele dá e
que trabalho pode arcar com ele.
