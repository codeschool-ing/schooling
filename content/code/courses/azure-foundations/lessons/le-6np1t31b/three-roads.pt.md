---
title: O caminho público, um service endpoint e um private endpoint
version: 1
---

**Uma storage account tem um endereço público, você querendo ou não.** A lição 2 mostrou de onde ele
vem: o nome da conta vira parte de um nome de host, e `stshopprod` responde em
`stshopprod.blob.core.windows.net` para qualquer pessoa na internet que saiba o nome. A imagem errada
é a de que um recurso na mesma assinatura da sua rede virtual está de algum jeito dentro dela. Não
está. Uma storage account, um banco de dados ou um key vault é um **serviço de plataforma**: mora do
lado da Microsoft, tem um endpoint público, e a aplicação da loja em `snet-app` chega até ele do mesmo
jeito que um notebook num café, a não ser que alguém construa outro caminho.

Há três caminhos, e esta lição é sobre a diferença entre eles:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l19-three-roads\" aria-label=\"Três caminhos da aplicação em snet-app até a storage account stshopprod. À esquerda, a rede virtual vnet-shop-prod guarda snet-app e snet-pe. À direita, do lado da Microsoft, a storage account tem um endpoint público. O caminho público sai da rede para o endpoint público, que está aberto à internet. O caminho do service endpoint chega ao mesmo endpoint público pelo backbone, levando a identidade da sub-rede. O caminho do private endpoint vai até uma interface de rede em 10.20.4.4 dentro de snet-pe, que o Private Link liga à conta, e o endpoint público pode ser desligado.\"><defs><marker id=\"l19-three-roads-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19-three-roads-af-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l19-three-roads-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l19-three-roads-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M20 30 H350 V320 H20 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"36.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rede virtual</text><text x=\"334.0\" y=\"48.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">vnet-shop-prod</text><path d=\"M40 66 H190 V216 H40 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"115.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">snet-app</text><rect x=\"65.0\" y=\"104.0\" width=\"100.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">aplicação</text><path d=\"M40 236 H330 V306 H40 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"56.0\" y=\"252.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">snet-pe</text><rect x=\"200.0\" y=\"248.0\" width=\"116.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"258.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">private endpoint</text><text x=\"258.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.4.4</text><path d=\"M400.0 20.0 L400.0 330.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"560.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o lado da Microsoft</text><rect x=\"450.0\" y=\"120.0\" width=\"230.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stshopprod</text><rect x=\"470.0\" y=\"154.0\" width=\"190.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">endpoint público</text><rect x=\"470.0\" y=\"198.0\" width=\"190.0\" height=\"32.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Private Link</text><path d=\"M166.0 112.0 L300.0 70.0 L560.0 70.0 L560.0 119.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-three-roads-af-ah-amber)\"></path><text x=\"430.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">1  o caminho público</text><path d=\"M166.0 126.0 L360.0 150.0 L469.0 168.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"6 3\" marker-end=\"url(#l19-three-roads-af-ah-paper)\"></path><text x=\"212.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2  service endpoint</text><path d=\"M115.0 135.0 L115.0 225.0 L190.0 225.0 L199.0 262.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-three-roads-af-ah-phosphor)\"></path><text x=\"56.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">3  private</text><text x=\"56.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">endpoint</text><path d=\"M317.0 270.0 L420.0 270.0 L420.0 214.0 L469.0 214.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-three-roads-af-ah-phosphor)\"></path><text x=\"565.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">internet</text><path d=\"M565.0 288.0 L565.0 241.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l19-three-roads-af-ah-paper-dim)\"></path></svg>", "caption": "Os caminhos 1 e 2 terminam no mesmo endpoint público. Só o 3 permite fechá-lo.", "same": ["2 service endpoint", "3 private", "Private Link", "endpoint", "internet", "private endpoint"]}
```

- **O caminho público.** A aplicação resolve o nome, recebe um endereço público, e os pacotes saem da
  rede virtual para o endpoint público da Microsoft. Eles ficam na rede da Microsoft na maior parte do
  trajeto, mas o endpoint está aberto para o mundo e só as chaves, os tokens e o firewall da conta
  ficam na frente dele.
- **Um service endpoint.** Uma chave numa sub-rede que diz ao Azure: o tráfego daqui para este tipo
  de serviço vai pelo backbone **levando a identidade da sub-rede**. O serviço continua respondendo no
  endereço público, e o firewall dele agora pode dizer "permita `snet-app`" em vez de uma lista de
  endereços IP.
- **Um private endpoint.** Uma interface de rede, com um endereço privado de uma das suas sub-redes,
  que **é** a storage account dentro da sua rede. A aplicação fala com `10.20.4.4`, os pacotes nunca
  saem do espaço de endereços da rede virtual, e o endpoint público da conta pode ser desligado por
  completo.

## Um service endpoint, em Bicep

A lição trabalha num diretório próprio:

```sh
mkdir -p ~/azure/private-link && cd ~/azure/private-link
```

Um service endpoint são duas configurações em dois lugares: na sub-rede, para qual serviço ela abre
um caminho, e no serviço, quais sub-redes ele aceita. Salve isto como `se.bicep`:

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: 'vnet-shop-prod'
}

resource snetApp 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: 'snet-app'
  properties: {
    addressPrefix: '10.20.2.0/24'
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
        locations: [
          'brazilsouth'
        ]
      }
    ]
  }
}

resource st 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'stshopprod'
  location: 'brazilsouth'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_ZRS'
  }
  properties: {
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: snetApp.id
          action: 'Allow'
        }
      ]
    }
  }
}
```

```
ana@laptop:~/azure/private-link$ az bicep build --file se.bicep --stdout | jq '.resources[] | {type, endpoints: .properties.serviceEndpoints, acls: .properties.networkAcls}'
{
  "type": "Microsoft.Network/virtualNetworks/subnets",
  "endpoints": [
    {
      "service": "Microsoft.Storage",
      "locations": [
        "brazilsouth"
      ]
    }
  ],
  "acls": null
}
{
  "type": "Microsoft.Storage/storageAccounts",
  "endpoints": null,
  "acls": {
    "defaultAction": "Deny",
    "virtualNetworkRules": [
      {
        "id": "[resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-shop-prod', 'snet-app')]",
        "action": "Allow"
      }
    ]
  }
}
```

`existing` cita uma rede que já está lá, a `vnet-shop-prod` da lição 16, sem criá-la. A sub-rede então
liga o `Microsoft.Storage`, e a conta põe o `defaultAction` em `Deny` com uma exceção, o id da
sub-rede, que o compilador transformou numa expressão `resourceId(...)` para o Resource Manager
completar. **Declarar uma sub-rede num segundo arquivo substitui o que o primeiro arquivo dizia sobre
ela**: implantar o `se.bicep` deixaria a `snet-app` sem network security group e sem tabela de rotas,
porque este arquivo não menciona nenhum dos dois. Num template de verdade a sub-rede é declarada uma
vez, junto da rede dela, e o service endpoint é mais uma propriedade ali.

## O que um service endpoint não faz

Um service endpoint é gratuito, rápido de ligar, e mais estreito do que parece:

- **Ele só vale para o tráfego que começa naquela sub-rede.** Uma máquina numa rede com peering
  (lição 20) ou no escritório do outro lado de uma VPN (lição 23) não o usa, e o firewall da conta não
  a deixa entrar.
- **O serviço mantém o endereço público**, e qualquer outra coisa liberada no firewall da conta
  continua chegando a ele pela internet.
- **Ele abre um caminho para o serviço inteiro, não para uma conta.** Uma sub-rede com o
  `Microsoft.Storage` ligado alcança por esse caminho toda storage account da região, inclusive uma que
  pertence a outra pessoa e foi criada para receber os dados da loja. Uma **service endpoint policy**
  o estreita para contas com nome; sem uma, isso é uma rota de saída para quem controla código rodando
  na sub-rede.

Um private endpoint responde às três coisas, a um preço por hora e por gigabyte, e a próxima seção
monta um.

**Nada disto foi implantado.** O compilador conferiu que toda propriedade existe no seu tipo e que o
id da sub-rede é algo a que a conta pode se referir. Se `10.20.2.0/24` cabe dentro da rede, e se o
nome da conta ainda está livre, são perguntas para o Resource Manager.
