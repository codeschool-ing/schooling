---
title: O Azure Firewall, e forçar a internet a passar pelo escritório
version: 1
---

**O Azure Firewall é um firewall que a Microsoft roda para você, dentro da sua rede**: você dá a ele
uma sub-rede chamada `AzureFirewallSubnet`, de pelo menos um `/26`, e um endereço público, e ele
aparece como um endereço privado para o qual as tabelas de rotas podem apontar. Ele escala acrescentando
instâncias próprias, que é o motivo de a sub-rede ter esse tamanho, e é cobrado por hora desde o
momento em que existe, mais por gigabyte processado, mande-se algo por ele ou não. **Este curso não
cita valor nenhum para ele**: a lista de preços é o programa da lição 1, e o firewall é a coisa mais
cara da rede da loja, então leia o preço antes de criar um.

Ele vem em três camadas, Basic, Standard e Premium, que diferem na vazão e no que conseguem
inspecionar; o Premium acrescenta inspeção de tráfego criptografado e um sistema de detecção de
intrusão. A loja usa o Standard.

## Um firewall nega até ouvir o contrário

**Um Azure Firewall sem regras não deixa nada passar.** É o oposto dos padrões de um NSG, e é esse o
objetivo: um pacote que a tabela de rotas mandou ao firewall é recusado a não ser que uma regra o
permita. As regras moram numa **firewall policy**, um recurso próprio que um ou muitos firewalls
usam, e se arrumam em três camadas:

- uma política guarda **rule collection groups**, cada um com uma prioridade;
- um grupo guarda **rule collections**, cada uma com uma prioridade e uma ação, permitir ou negar;
- uma coleção guarda **regras** de um tipo.

Os tipos são três, e **são processados numa ordem fixa, sejam quais forem as prioridades**: primeiro
as regras DNAT, que traduzem um endereço que chega da internet para um privado; depois as regras de
rede, que casam endereços, protocolos e portas; depois as regras de aplicação, que casam nomes, como
`api.payments.example` sobre HTTPS. Dentro de cada tipo, grupos e coleções são lidos por prioridade,
o menor número primeiro, de 100 a 65.000, e o primeiro casamento decide, como num NSG.

Aqui está a política da loja para o tráfego de saída da produção. Salve como
`~/azure/routes/fwpolicy.bicep`:

```bicep
param location string = 'brazilsouth'

resource policy 'Microsoft.Network/firewallPolicies@2024-05-01' = {
  name: 'afwp-shop'
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Deny'
  }
}

resource rules 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-05-01' = {
  parent: policy
  name: 'shop-prod'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'prod-to-office'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'erp'
            ipProtocols: ['TCP']
            sourceAddresses: ['10.20.2.0/24']
            destinationAddresses: ['192.168.10.0/24']
            destinationPorts: ['1433']
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'prod-to-internet'
        priority: 200
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'payments'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            sourceAddresses: ['10.20.2.0/24']
            targetFqdns: ['api.payments.example']
          }
        ]
      }
    ]
  }
}
```

A camada de aplicação pode alcançar o banco do ERP do escritório na 1433, e o provedor de pagamento
pelo nome na 443, e nada mais: o staging, o resto do escritório e o resto da internet encontram o
padrão do firewall. `threatIntelMode: 'Deny'` também recusa tráfego de e para endereços que a
inteligência de ameaças da Microsoft lista como maliciosos, antes de qualquer regra ser lida. Compile
e leia as coleções de volta:

```
ana@laptop:~/azure/routes$ az bicep build --file fwpolicy.bicep --stdout | jq -c '.resources[] | select(.type | endswith("ruleCollectionGroups")) | .properties.ruleCollections[] | {name, priority, action: .action.type, rules: [.rules[] | {ruleType, name}]}'
{"name":"prod-to-office","priority":100,"action":"Allow","rules":[{"ruleType":"NetworkRule","name":"erp"}]}
{"name":"prod-to-internet","priority":200,"action":"Allow","rules":[{"ruleType":"ApplicationRule","name":"payments"}]}
```

**Uma regra de aplicação casa um nome, e só um firewall que enxerga o nome pode usá-la.** No HTTPS o
nome viaja na abertura da conversa criptografada, que o Standard lê sem descriptografar nada. Esse é o
motivo de a internet de saída da loja passar por um firewall e não por um NSG: um NSG conhece
endereços, e os endereços de um provedor de pagamento mudam sem aviso.

## Forced tunnelling: a internet passando pelo escritório

Algumas empresas exigem que **todo o tráfego para a internet saia pelo próprio escritório**, passando
pelo firewall delas, para que um lugar só registre e filtre tudo. No Azure isso é o **forced
tunnelling**: a rota para `0.0.0.0/0` aponta não para a internet, e sim para o escritório, pelo
gateway de VPN ou de ExpressRoute da lição 23, seja escrita como rota, seja anunciada pelo escritório
por BGP.

Com o Azure Firewall no meio, a rota padrão vai na própria sub-rede do firewall: a produção manda
tudo para o firewall, e a sub-rede do firewall manda a parte destinada à internet adiante para o
gateway. A documentação da Microsoft acrescenta três condições, e **nenhuma delas pôde ser executada
aqui**:

- **o firewall precisa do tráfego de gerenciamento separado**, por uma segunda sub-rede chamada
  `AzureFirewallManagementSubnet`, de pelo menos um `/26`, com um endereço público próprio que só o
  gerenciamento da Microsoft usa. No plano do hub da loja essa sub-rede é `10.0.3.0/26`. Nas camadas
  Standard e Premium ela é ligada quando o firewall é criado, ou depois, parando e iniciando o
  firewall; no Basic ela sempre existe;
- **o firewall traduz o tráfego destinado à internet para um dos seus endereços privados** antes de
  passá-lo adiante, então o firewall do escritório vê o firewall do Azure como remetente, não a
  máquina;
- **o DNAT a partir da internet deixa de funcionar** num firewall cujo tráfego de internet é forçado
  para outro lugar, já que as respostas sairiam por um caminho diferente daquele por onde o pedido
  entrou.

**O forced tunnelling põe a internet mais longe**: todo pedido a um provedor de pagamento atravessa
até o escritório de São Paulo e volta. É uma decisão sobre controle paga em latência e na banda do
escritório, e a loja não a toma. O firewall dela manda a internet direto para fora, e registra tudo
no Azure.
