---
title: Um id de recurso, lido da esquerda
version: 1
---

**Todo recurso no Azure tem um nome completo, o seu id de recurso, e é o nome que uma atribuição de
papel, uma política, uma linha de log e uma mensagem de erro usam.** Ele é um caminho, e lê-lo da
esquerda desce pelas caixas da seção anterior:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l02-resource-id\" aria-label=\"O id de recurso de uma sub-rede cortado nas suas peças, em duas linhas: o id da assinatura bbbbcccc-1111-dddd-2222-eeee3333ffff, o grupo de recursos rg-shop-prod, o namespace do provider Microsoft.Network, o tipo virtualNetworks, o nome vnet-shop-prod, e o filho subnets/snet-app. As palavras literais subscriptions, resourceGroups e providers os separam.\"><text x=\"148.8\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/subscriptions/</text><rect x=\"196.3\" y=\"47.0\" width=\"241.6\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"317.1\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assinatura</text><text x=\"317.1\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bbbbcccc-1111-dddd-2222-eeee3333ffff</text><text x=\"488.7\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/resourceGroups/</text><rect x=\"539.5\" y=\"47.0\" width=\"83.2\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"581.1\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">grupo de recursos</text><text x=\"581.1\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rg-shop-prod</text><text x=\"145.5\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/providers/</text><rect x=\"179.8\" y=\"157.0\" width=\"116.2\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"237.9\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">namespace do provider</text><text x=\"237.9\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Microsoft.Network</text><text x=\"297.3\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/</text><rect x=\"298.6\" y=\"157.0\" width=\"103.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.1\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tipo</text><text x=\"350.1\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">virtualNetworks</text><text x=\"402.9\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/</text><rect x=\"404.2\" y=\"157.0\" width=\"96.4\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"452.4\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nome</text><text x=\"452.4\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">vnet-shop-prod</text><text x=\"501.9\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/</text><rect x=\"503.2\" y=\"157.0\" width=\"109.6\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"558.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">recurso filho</text><text x=\"558.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">subnets/snet-app</text></svg>", "caption": "Lido da esquerda, um id desce pelas caixas: assinatura, grupo, provider, tipo, nome."}
```

Uma assinatura é nomeada pelo seu GUID, nunca pelo nome de exibição, e o resto é o grupo de
recursos, depois `providers`, depois o **namespace do resource provider** dono do tipo:
`Microsoft.Network` para redes, `Microsoft.Compute` para máquinas, `Microsoft.Storage` para storage
accounts. Depois o tipo e o nome, e, para um recurso filho como uma sub-rede, o tipo e o nome dele
acrescentados no fim.

## Desmontando ids no laboratório

A CLI do Azure analisa ids com uma função de uma biblioteca que ela trouxe para o ambiente virtual, e
um programa de poucas linhas pode usar a mesma função. Crie o diretório da lição, e salve isto como
`rid.py` nele:

```sh
mkdir -p ~/azure/hierarchy && cd ~/azure/hierarchy
```

```schooling-example
{"language": "python", "file": "rid.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"rid.py ID...: cut Azure resource ids into the scopes they sit in.\"\"\"\nimport sys\n\nfrom azure.mgmt.core.tools import parse_resource_id\n\n", "note": "`azure.mgmt.core` veio para o ambiente virtual junto com a CLI do Azure, que o usa exatamente para isto. Nada aqui fala com o Azure: um id é um texto, e cortá-lo não precisa de conta."}, {"code": "for rid in sys.argv[1:]:\n    p = parse_resource_id(rid)\n    print(rid)\n", "note": "`parse_resource_id` devolve um dicionário com as peças que reconheceu, e deixa de fora as que o id não tem."}, {"code": "    for key in ('subscription', 'resource_group', 'namespace', 'type', 'name'):\n        if key in p:\n            print(f'  {key:<16}{p[key]}')\n", "note": "As cinco peças que todo recurso tem, de fora para dentro: a assinatura, o grupo, o **namespace do provider** dono do tipo, o tipo e o nome."}, {"code": "    for i in range(1, p.get('last_child_num', 0) + 1):\n        print(f\"  {'child ' + str(i):<16}{p['child_type_' + str(i)]}/{p['child_name_' + str(i)]}\")\n", "note": "Um **recurso filho** mora dentro de outro, como uma sub-rede dentro de uma rede, e acrescenta um tipo e um nome ao fim do id do pai. `last_child_num` diz quantos níveis há."}]}
```

Dê a ele quatro ids: uma sub-rede, o grupo de recursos dela, um grupo de gerenciamento, e a rede de
novo escrita do jeito que uma pessoa descuidada digita:

```
ana@laptop:~/azure/hierarchy$ python3 rid.py /subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod/subnets/snet-app /subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod /providers/Microsoft.Management/managementGroups/mg-shop /subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourcegroups/RG-SHOP-PROD/providers/microsoft.network/virtualnetworks/vnet-shop-prod
/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod/subnets/snet-app
  subscription    bbbbcccc-1111-dddd-2222-eeee3333ffff
  resource_group  rg-shop-prod
  namespace       Microsoft.Network
  type            virtualNetworks
  name            vnet-shop-prod
  child 1         subnets/snet-app
/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod
  subscription    bbbbcccc-1111-dddd-2222-eeee3333ffff
  resource_group  rg-shop-prod
/providers/Microsoft.Management/managementGroups/mg-shop
  name            /providers/Microsoft.Management/managementGroups/mg-shop
/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourcegroups/RG-SHOP-PROD/providers/microsoft.network/virtualnetworks/vnet-shop-prod
  subscription    bbbbcccc-1111-dddd-2222-eeee3333ffff
  resource_group  RG-SHOP-PROD
  namespace       microsoft.network
  type            virtualnetworks
  name            vnet-shop-prod
```

Três coisas nessa resposta valem mais do que o programa.

**O id da assinatura está em todo id abaixo dela**, que é como se lê de quem é um recurso, e a
primeira coisa a conferir quando um script cita algo que ninguém reconhece. O GUID daqui,
`bbbbcccc-1111-dddd-2222-eeee3333ffff`, é o tipo de valor inventado que a própria documentação da
Microsoft usa, e representa a assinatura de produção da loja em todas as lições deste curso.

**O id de um grupo de gerenciamento não começa com uma assinatura**, e o analisador não o entendeu:
devolveu o texto inteiro como nome. Um grupo de gerenciamento fica acima de toda assinatura, então o
id dele começa em `/providers/Microsoft.Management/managementGroups/`, sem assinatura e sem grupo de
recursos. O mesmo vale para qualquer coisa no nível do tenant. Um programa que supõe que todo id começa
com `/subscriptions/` acerta sobre recursos e erra sobre a árvore.

**Maiúsculas e minúsculas não importam para o Azure, e importam para todo o resto.** O último id foi
digitado com `resourcegroups`, `RG-SHOP-PROD` e `microsoft.network`, e o Resource Manager o trata como
o mesmo recurso: ids são comparados sem levar em conta a caixa das letras. O analisador devolveu as
peças exatamente como digitadas, porém, e o mesmo faz toda ferramenta que compara textos. Dois scripts
que guardam o mesmo id em duas grafias e os comparam com `==` discordam sobre se um recurso existe.
**Passe um id para minúsculas antes de compará-lo**, ou use uma comparação que ignore a caixa.

## Nomes, que não são ids

O id é feito de nomes, e os nomes têm regras que só o Azure aplica:

- um nome precisa ser **único entre os irmãos**: dois grupos de recursos chamados `rg-shop-prod` não
  podem existir numa assinatura, e duas redes com o mesmo nome não podem existir num grupo;
- alguns nomes precisam ser **únicos em todo o Azure**, porque viram parte de um endereço. Uma storage
  account chamada `shopassets` vira `shopassets.blob.core.windows.net`, e ninguém mais no planeta pode
  tê-la. A lição 19 volta a esses endereços;
- cada tipo tem o seu **tamanho e os seus caracteres**: um grupo de recursos aceita até 90, uma
  storage account de 3 a 24 letras minúsculas e dígitos e nada mais.

**Uma convenção de nomes é a governança mais barata que existe.** Este curso usa a do Cloud Adoption
Framework da Microsoft, que a lição 5 apresenta: um prefixo curto para o tipo, depois a carga de
trabalho, depois o ambiente. `rg-shop-prod` é um grupo de recursos, `vnet-shop-prod` uma rede virtual,
`snet-app` uma sub-rede. Um nome que diz o que uma coisa é é lido corretamente pela pessoa que não a
criou, que, mais cedo ou mais tarde, é todo mundo.
