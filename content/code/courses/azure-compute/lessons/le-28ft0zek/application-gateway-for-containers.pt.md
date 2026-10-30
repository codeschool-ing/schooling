---
title: O Application Gateway for Containers, e os recursos por trás de um Gateway
version: 1
---

Com o nome do AGIC dentro do seu, o Application Gateway for Containers parece a próxima versão do
AGIC: o mesmo gateway, um controller mais novo. **É outro produto, feito para o Kubernetes, com um
control plane e um data plane próprios**; a Microsoft o descreve como moldado pelo que o AGIC
ensinou, e separado dele. O proxy continua fora do cluster e operado pelo Azure. O que mudou é tudo
o que fica entre o cluster e esse proxy. Um controller no cluster, o ALB Controller, lê
recursos da Gateway API além de Ingress. Do lado do Azure o trabalho é dividido em recursos
pequenos com uma tarefa cada, e o gateway ao qual a rota da shop se ligou na seção 03 é, no Azure,
um *frontend*.

## Quatro recursos, e duas dependências

A documentação da Microsoft, lida em 30 de outubro de 2026, lista as partes de uma implantação:

- o recurso *Application Gateway for Containers* em si, do tipo
  `Microsoft.ServiceNetworking/trafficControllers`, um pai que implanta o control plane;
- um *frontend*, um filho que é um ponto de entrada para os clientes. Cada frontend recebe um
  nome que o Azure gera, na forma `*.fzXX.alb.azure.com`, que você usa como está ou para o qual
  aponta um CNAME. Ele escuta só nas portas 80 e 443, e não tem endereço privado;
- uma *association*, um filho que liga o data plane a uma sub-rede da sua rede virtual, uma para
  uma. Hoje um recurso só pode ter uma;
- uma *security policy*, que aponta para uma política de Web Application Firewall.

As duas dependências são uma *sub-rede delegada* a `Microsoft.ServiceNetworking/trafficControllers`,
onde a association põe o data plane, e uma *managed identity atribuída pelo usuário* para o ALB
Controller, com o papel embutido *AppGw for Containers Configuration Manager*. Esse papel tem data
actions que Owner e Contributor não têm, então dar Contributor ao controller não basta. A
identidade chega ao pod do controller por workload identity, a credencial federada da lição 13; a
documentação do add-on exige que ela esteja ligada.

A sub-rede tem uma regra de tamanho. **Cada association conta com pelo menos 256 endereços livres,
então a sub-rede é uma `/24` ou maior**, e vários recursos dividindo uma sub-rede precisam de
n × 256.

## Bring your own, ou gerenciado pelo controller

Há dois jeitos de ser dono desses recursos, e a escolha decide quem cria um frontend.

*Bring your own.* Você cria o recurso, o frontend e a association no Azure, com a CLI, o Bicep ou
o Terraform, e um Gateway no cluster se refere a eles: uma anotação cita o recurso e um endereço
cita o frontend. Apagar o Gateway deixa o frontend onde está, e o FQDN dele junto, porque o dono é
o administrador do Azure. No `gateway.yaml` da shop isso são dois acréscimos:

```yaml
metadata:
  name: shop-gateway
  namespace: infra
  annotations:
    alb.networking.azure.io/alb-id: /subscriptions/<id>/resourceGroups/shop/providers/Microsoft.ServiceNetworking/trafficControllers/shop-agc
spec:
  gatewayClassName: azure-alb-external
  addresses:
  - type: alb.networking.azure.io/alb-frontend
    value: shop-frontend
```

*Gerenciado pelo ALB Controller.* Você cria um custom resource no cluster, um
`ApplicationLoadBalancer` que cita a sub-rede delegada, e o controller cria o recurso do Azure e a
association; a documentação conta de cinco a seis minutos para isso. Cada Gateway que o cita por
duas anotações, `alb.networking.azure.io/alb-namespace` e `alb.networking.azure.io/alb-name`,
ganha um frontend novo, e o perde quando o Gateway é apagado. Um Gateway novo é um FQDN novo, o que
é um motivo para preferir bring-your-own para um endereço que os clientes têm no DNS deles.

O resto dos arquivos da shop não muda. **A rota, os pesos, o casamento de cabeçalho e a permissão
são os mesmos arquivos nas duas estratégias**, e os mesmos que o lab aplicou num cluster sem
controller.

## O controller

O ALB Controller são dois pods: `alb-controller`, que transforma os recursos do cluster em
configuração, e `alb-controller-bootstrap`, que cuida das custom resource definitions dele. Ele usa
o ARM e uma API de configuração do próprio serviço para aplicar as mudanças, e é instalado por Helm
ou por um add-on do AKS que cria a identidade e uma sub-rede delegada chamada `aks-appgateway` para
você. O add-on está em preview, e o quickstart da Microsoft chega a ele pela extensão `aks-preview`
e por dois registros de feature. Os comandos do recurso também moram numa extensão, `alb`, que a
linha de comando deste curso não tem:

```
ana@laptop:~/azure$ az network alb --help
ERROR: 'alb' is misspelled or not recognized by the system.
Did you mean 'lb' ?

https://aka.ms/cli_ref
Read more about the command in reference docs
```

Uma vez instalado, o controller reivindica a classe que o lab escreveu à mão. O quickstart do
add-on confere uma GatewayClass chamada `azure-alb-external` com o nome de controller
`alb.networking.azure.io/alb-controller`, e espera que a condição `Accepted` dela diga `True`, com
a mensagem `Valid GatewayClass`, onde a do lab dizia `Unknown`. A documentação diz que o controller
implementa a versão 1.5 da Gateway API, e lista GatewayClass, Gateway, HTTPRoute, GRPCRoute e
ReferenceGrant entre o que ele suporta, com listeners só nas portas 80 e 443.

No caminho até a shop, o data plane acrescenta três cabeçalhos a toda requisição,
`x-forwarded-for`, `x-forwarded-proto` e `x-request-id`, e espera 60 segundos por uma resposta, a
menos que a rota defina `timeouts.request`. O controller tem a API de configuração do serviço ao
lado do ARM, onde o AGIC só tinha o ARM, mas a documentação não dá número para quanto tempo uma
mudança leva para chegar ao data plane, e este curso não chuta um.

## A metade do Azure, em Bicep

Na estratégia bring-your-own a metade do Azure é um arquivo. O da shop declara a rede virtual com
uma sub-rede para o cluster e uma `/24` delegada para a association, o recurso, um frontend e uma
association. Salve como `agc.bicep`:

```bicep
// agc.bicep
param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'shop-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.20.0.0/16']
    }
    subnets: [
      {
        name: 'aks'
        properties: {
          addressPrefix: '10.20.0.0/22'
        }
      }
      {
        name: 'agc'
        properties: {
          addressPrefix: '10.20.8.0/24'
          delegations: [
            {
              name: 'agc'
              properties: {
                serviceName: 'Microsoft.ServiceNetworking/trafficControllers'
              }
            }
          ]
        }
      }
    ]
  }
}

resource agc 'Microsoft.ServiceNetworking/trafficControllers@2025-01-01' = {
  name: 'shop-agc'
  location: location
}

resource frontend 'Microsoft.ServiceNetworking/trafficControllers/frontends@2025-01-01' = {
  parent: agc
  name: 'shop-frontend'
  location: location
}

resource association 'Microsoft.ServiceNetworking/trafficControllers/associations@2025-01-01' = {
  parent: agc
  name: 'shop-association'
  location: location
  properties: {
    associationType: 'subnets'
    subnet: {
      id: '${vnet.id}/subnets/agc'
    }
  }
}

output frontendFqdn string = frontend.properties.fqdn
```

```
ana@laptop:~/azure$ bicep build agc.bicep
ana@laptop:~/azure$ jq -c '.resources[] | [.type, .name]' agc.json
["Microsoft.Network/virtualNetworks","shop-vnet"]
["Microsoft.ServiceNetworking/trafficControllers","shop-agc"]
["Microsoft.ServiceNetworking/trafficControllers/frontends","[format('{0}/{1}', 'shop-agc', 'shop-frontend')]"]
["Microsoft.ServiceNetworking/trafficControllers/associations","[format('{0}/{1}', 'shop-agc', 'shop-association')]"]
ana@laptop:~/azure$ jq -c '.resources[] | select(.type | endswith("associations")) | .dependsOn' agc.json
["[resourceId('Microsoft.ServiceNetworking/trafficControllers', 'shop-agc')]","[resourceId('Microsoft.Network/virtualNetworks', 'shop-vnet')]"]
```

Nenhum aviso, quatro recursos, e a association espera pela rede e pelo seu pai. O frontend não tem
propriedade nenhuma, e o output lê o `fqdn` dele de volta: quem escolhe é o Azure. Agora quatro
erros numa cópia: um FQDN escolhido pela shop no frontend, `subnet` no lugar de `subnets`, uma
`/26`, e o nome da delegação sem a última letra:

```
ana@laptop:~/azure$ sed -e "/name: 'shop-frontend'/a\\  properties: {\n    fqdn: 'shop.example.com'\n  }" -e "s/'subnets'/'subnet'/" -e 's#10.20.8.0/24#10.20.8.0/26#' -e '26s/trafficControllers/trafficController/' agc.bicep > slips.bicep
ana@laptop:~/azure$ diff agc.bicep slips.bicep
21c21
<           addressPrefix: '10.20.8.0/24'
---
>           addressPrefix: '10.20.8.0/26'
26c26
<                 serviceName: 'Microsoft.ServiceNetworking/trafficControllers'
---
>                 serviceName: 'Microsoft.ServiceNetworking/trafficController'
43a44,46
>   properties: {
>     fqdn: 'shop.example.com'
>   }
52c55
<     associationType: 'subnets'
---
>     associationType: 'subnet'
ana@laptop:~/azure$ bicep build slips.bicep
/home/ana/azure/slips.bicep(45,5) : Warning BCP073: The property "fqdn" is read-only. Expressions cannot be assigned to read-only properties. If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP073]
```

**Um aviso para quatro erros.** O compilador sabe que `fqdn` é somente leitura, então recusa um
nome escrito ali; é o desenho do frontend aparecendo pelo tipo. Os outros três passam. O tipo da
association e o nome do serviço da delegação são texto para o compilador, e um prefixo é uma
string, então nada aqui conhece o `/24` da documentação. O que o Azure faria com cada um na
implantação o compilador não sabe dizer, e este curso não tem assinatura para descobrir. A regra da
lição 1 vale também ao contrário: nenhum aviso não é o mesmo que correto.

Implantá-lo seria, **não executado neste curso: precisa de uma assinatura**:

```sh
az deployment group create --resource-group shop --template-file agc.bicep
```

## Escolhendo entre eles

Para a shop, as três opções desta lição se resumem a onde o proxy roda e ao que os arquivos
conseguem dizer:

| | AGIC | application routing, Gateway API | Application Gateway for Containers |
|---|---|---|---|
| lê | Ingress | Gateway API | Gateway API e Ingress |
| proxy | um Application Gateway seu | pods no cluster, nos seus nodes | operado pelo Azure, fora do cluster |
| canary por peso | não | sim | sim |

Um time com um Application Gateway e uma política de firewall em que já confia tem um motivo para
o AGIC. Um cluster que quer a porta de entrada nos próprios nodes e a Gateway API tem o add-on, que
é o que o AKS Automatic escolhe agora. A shop, uma API pública com um canary a cada lançamento, é o
caso para o qual o Application Gateway for Containers foi feito, e os arquivos da seção 03 já estão
escritos para ele.
