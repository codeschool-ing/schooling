---
title: A rede num arquivo, e uma sub-rede entregue a um serviço
version: 1
---

**Alguns serviços do Azure não pegam um endereço na sua sub-rede; pegam a sub-rede inteira.** Um
servidor flexível de PostgreSQL ligado a uma rede, um app do App Service que alcança uma, um grupo de
contêineres: cada um roda máquinas que a Microsoft gerencia, e precisa colocá-las e trocá-las dentro
da sua rede sem perguntar a você toda vez. **Delegar** uma sub-rede é como você permite isso: a
sub-rede é marcada como pertencente a um serviço, esse serviço pode então criar o que precisa ali, e
pode definir regras de rede próprias na sub-rede que você não consegue remover enquanto ele estiver
lá.

Três consequências decorrem disso, e a documentação da Microsoft as lista:

- **uma sub-rede delegada é do serviço**, e a maioria dos serviços a quer só para si: nada de
  máquinas virtuais ao lado do banco, e nada de private endpoints, que a lição 19 põe em outro lugar;
- **o serviço pode ditar um tamanho mínimo**, e a delegação precisa ser removida antes que a
  sub-rede, ou a rede, possa ser apagada;
- **delegar é decisão do dono da rede**, tomada na sub-rede, antes de o serviço chegar.

A loja delega a `snet-data` ao PostgreSQL, para que o banco more num endereço da rede de produção e
em lugar nenhum da internet.

## Escrevendo a rede

Aqui está a `vnet-shop-prod` inteira em Bicep: o intervalo, as quatro sub-redes e a delegação. Salve
como `~/azure/vnet/vnet.bicep`:

```bicep
param location string = 'brazilsouth'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-shop-prod'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.20.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-web'
        properties: {
          addressPrefix: '10.20.1.0/24'
          defaultOutboundAccess: false
        }
      }
      {
        name: 'snet-app'
        properties: {
          addressPrefix: '10.20.2.0/24'
          defaultOutboundAccess: false
        }
      }
      {
        name: 'snet-data'
        properties: {
          addressPrefix: '10.20.3.0/24'
          defaultOutboundAccess: false
          delegations: [
            {
              name: 'postgres'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
        }
      }
      {
        name: 'snet-pe'
        properties: {
          addressPrefix: '10.20.4.0/24'
          defaultOutboundAccess: false
        }
      }
    ]
  }
}

output appSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'snet-app')
```

**As sub-redes são escritas dentro da rede**, e não como recursos próprios ao lado dela. O Bicep
aceita as duas formas, e a de dentro é a segura: uma rede implantada de novo a partir de um arquivo
que lista as sub-redes as mantém, enquanto um arquivo de rede que as deixa para recursos separados
pode, implantado sozinho, descrever uma rede sem sub-redes e removê-las.

`defaultOutboundAccess: false` torna cada sub-rede **privada**: uma máquina nela só alcança a
internet por uma rota que alguém construiu de propósito, como o firewall da lição 18. A Microsoft fez
disso o padrão para redes novas criadas com versões da API lançadas depois de março de 2026, e as
versões mais antigas mantiveram o padrão antigo, em que toda máquina tinha uma saída que ninguém
tinha escolhido. Escrever o valor faz o arquivo querer dizer a mesma coisa seja qual for a versão que
ele cita.

Compile e leia as sub-redes de volta:

```
ana@laptop:~/azure/vnet$ az bicep build --file vnet.bicep --stdout | jq -c '.resources[0].properties.subnets[] | {name, prefix: .properties.addressPrefix, delegatedTo: .properties.delegations[0].properties.serviceName}'
{"name":"snet-web","prefix":"10.20.1.0/24","delegatedTo":null}
{"name":"snet-app","prefix":"10.20.2.0/24","delegatedTo":null}
{"name":"snet-data","prefix":"10.20.3.0/24","delegatedTo":"Microsoft.DBforPostgreSQL/flexibleServers"}
{"name":"snet-pe","prefix":"10.20.4.0/24","delegatedTo":null}
```

## O que o compilador não vê

O compilador confere nomes e tipos, e nada sobre endereços. Dois experimentos tornam a borda visível.
Primeiro, a `snet-pe` movida para um intervalo fora da rede; depois, uma propriedade escrita errado:

```
ana@laptop:~/azure/vnet$ sed 's#10.20.4.0/24#10.99.4.0/24#' vnet.bicep > outside.bicep && az bicep build --file outside.bicep --stdout | jq -r '.resources[0].properties.subnets[3].properties.addressPrefix'
10.99.4.0/24
```

```
ana@laptop:~/azure/vnet$ sed '0,/defaultOutboundAccess/s//defaultOutbondAccess/' vnet.bicep > typo.bicep && az bicep build --file typo.bicep --stdout | jq -c '.resources[0].properties.subnets[0].properties'
WARNING: /home/ana/azure/vnet/typo.bicep(17,11) : Warning BCP089: The property "defaultOutbondAccess" is not allowed on objects of type "SubnetPropertiesFormat". Did you mean "defaultOutboundAccess"? [https://aka.ms/bicep/core-diagnostics#BCP089]

{"addressPrefix":"10.20.1.0/24","defaultOutbondAccess":false}
```

**Uma sub-rede fora da sua rede compilou sem uma palavra.** `10.99.4.0/24` é um texto perfeitamente
válido, e só o Azure, comparando-o com o intervalo, recusaria a implantação. É para isso que serve o
`plan.py`: a aritmética que o compilador não faz.

**O erro de digitação foi um aviso, e a compilação teve sucesso mesmo assim.** O `BCP089` citou a
propriedade, e até adivinhou a certa, mas o template foi escrito, com o nome errado dentro. Implantada,
a sub-rede teria ficado com o padrão da versão da API, e o arquivo diria uma coisa diferente do que
fez. **Leia os avisos**, ou peça ao Bicep que os trate como erros num `bicepconfig.json`, que é como
costumam rodá-lo as equipes que implantam a partir de um pipeline.

## O mesmo corte, na aritmética do Terraform

O Terraform planeja sub-redes com uma função em vez de à mão. `cidrsubnet(intervalo, bits, número)`
acrescenta `bits` ao prefixo e devolve a fatia de posição `número`, e `cidrhost` o endereço numa
posição dentro de uma. O `terraform console` avalia uma expressão sem configuração nenhuma:

```
ana@laptop:~/azure/vnet$ echo '[for i in range(1, 5) : cidrsubnet("10.20.0.0/16", 8, i)]' | terraform console
[
  "10.20.1.0/24",
  "10.20.2.0/24",
  "10.20.3.0/24",
  "10.20.4.0/24",
]
ana@laptop:~/azure/vnet$ echo 'cidrhost("10.20.2.0/24", 4)' | terraform console
"10.20.2.4"
```

Oito bits a mais num `/16` dão `/24`, e as fatias 1 a 4 são exatamente as quatro sub-redes do plano.
O `cidrhost` na posição 4 é o primeiro endereço que uma máquina na `snet-app` pode receber, o quinto
do intervalo, porque os quatro primeiros são do Azure.
