---
title: Um recurso é uma URL, e criá-lo é um PUT
version: 1
---

**A API do Resource Manager é REST no sentido mais simples: todo recurso é uma URL, e o que você faz com
ele é o método HTTP.** A URL é o id de recurso da lição 2 posto depois de `https://management.azure.com`,
com uma `api-version` no fim. Então a API inteira são quatro verbos sobre um formato:

| método | faz | responde, quando funciona |
|---|---|---|
| `GET` | lê o recurso, ou lista uma coleção | 200 e o recurso |
| `PUT` | cria o recurso, ou o substitui pelo corpo enviado | 200 se substituiu, 201 se criou, às vezes 202 |
| `PATCH` | muda só os campos enviados, como as tags | 200 ou 202 |
| `DELETE` | remove o recurso | 200, 202, ou 204 se não havia nada para remover |

**O `PUT` é o que importa, porque é idempotente**: mandar o mesmo corpo duas vezes deixa o recurso
exatamente como mandá-lo uma vez. Essa propriedade sozinha é o motivo de o Bicep e o Terraform
conseguirem descrever um ambiente inteiro e aplicá-lo de novo e de novo, e é nela que a lição 26 se
apoia.

## De um template aos pedidos

Um arquivo Bicep compilado já guarda, para cada recurso, o tipo, o nome, a `api-version` e o corpo. Um
programa curto consegue montar o pedido em que cada um se transforma. Salve este arquivo Bicep como
`vnet.bicep` em `~/azure/arm`:

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-shop-prod'
  location: 'brazilsouth'
  tags: {
    environment: 'prod'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.20.0.0/16'
      ]
    }
  }
}

resource app 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: 'snet-app'
  properties: {
    addressPrefix: '10.20.2.0/24'
  }
}
```

e este programa como `request.py`:

```schooling-example
{"language": "python", "file": "request.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"request.py TEMPLATE SUBSCRIPTION GROUP: the REST call each resource of a compiled template becomes.\"\"\"\nimport json\nimport sys\n\nARM = 'https://management.azure.com'\nLEFT_OUT = ('type', 'apiVersion', 'name', 'dependsOn', 'condition', 'copy')\n\ntemplate, sub, group = sys.argv[1], sys.argv[2], sys.argv[3]\nresources = json.load(open(template))['resources']\n\n", "note": "Ele lê um template que o `az bicep build` produziu. `LEFT_OUT` são os campos que um template usa para dizer *o que* criar e *em que ordem*; eles viram o endereço e a sequência de pedidos, não o corpo."}, {"code": "for r in resources:\n    if r['name'].startswith('['):\n        print(f\"{r['type']}: the name is {r['name']}\")\n        print('  an expression, which only Resource Manager evaluates; no address can be written yet')\n        continue\n", "note": "Um valor entre colchetes é uma **expressão de template**, avaliada pelo Resource Manager quando a implantação roda. O programa se recusa a adivinhar no que ela vai dar, e diz isso."}, {"code": "    namespace, *types = r['type'].split('/')\n    names = r['name'].split('/')\n    path = f'/subscriptions/{sub}/resourceGroups/{group}/providers/{namespace}'\n    for t, n in zip(types, names):\n        path += f'/{t}/{n}'\n", "note": "O endereço é o id de recurso da lição 2, montado a partir das peças: o namespace, depois cada tipo com o seu nome. Um recurso filho tem dois de cada."}, {"code": "    print(f\"PUT {ARM}{path}?api-version={r['apiVersion']}\")\n    body = {k: v for k, v in r.items() if k not in LEFT_OUT}\n    print(json.dumps(body, indent=2))\n", "note": "**O `PUT` cria ou substitui**: o corpo é o recurso inteiro como ele deve ficar. A `api-version` é a versão depois do `@` no arquivo Bicep, e ela decide quais propriedades o corpo pode levar."}]}
```

Compile o arquivo, olhe o que cada recurso traz, e rode o programa com a assinatura e o grupo de
produção da loja:

```
ana@laptop:~/azure/arm$ az bicep build --file vnet.bicep && jq -c '.resources[] | {type, apiVersion, name, dependsOn}' vnet.json
{"type":"Microsoft.Network/virtualNetworks","apiVersion":"2024-05-01","name":"vnet-shop-prod","dependsOn":null}
{"type":"Microsoft.Network/virtualNetworks/subnets","apiVersion":"2024-05-01","name":"[format('{0}/{1}', 'vnet-shop-prod', 'snet-app')]","dependsOn":["[resourceId('Microsoft.Network/virtualNetworks', 'vnet-shop-prod')]"]}
ana@laptop:~/azure/arm$ python3 request.py vnet.json bbbbcccc-1111-dddd-2222-eeee3333ffff rg-shop-prod
PUT https://management.azure.com/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod?api-version=2024-05-01
{
  "location": "brazilsouth",
  "tags": {
    "environment": "prod"
  },
  "properties": {
    "addressSpace": {
      "addressPrefixes": [
        "10.20.0.0/16"
      ]
    }
  }
}
Microsoft.Network/virtualNetworks/subnets: the name is [format('{0}/{1}', 'vnet-shop-prod', 'snet-app')]
  an expression, which only Resource Manager evaluates; no address can be written yet
```

A rede virou um pedido completo: o endereço, a versão, e um corpo de `location`, `tags` e
`properties`, as três partes que o corpo de todo recurso tem. **A sub-rede não virou**, e o motivo é a
lição. O nome dela no template é `[format('{0}/{1}', 'vnet-shop-prod', 'snet-app')]`, uma expressão, e
ela traz um `dependsOn` que cita a rede. O Resource Manager avalia a expressão e **ordena os dois pedidos
por essa dependência**: a rede primeiro, e a sub-rede só quando a rede existir. Um cliente que os
mandasse na ordem errada teria a sub-rede recusada, porque o pai dela ainda não está lá.

Mandar o primeiro à mão é para isso que serve o `az rest`: ele acrescenta o token e o endereço do
Resource Manager, e manda qualquer método com qualquer corpo.

```
ana@laptop:~/azure/arm$ az rest --method put --url "/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod?api-version=2024-05-01" --body @body.json
ERROR: Please run 'az login' to setup account.
```

Recusado antes de ser mandado, como todo pedido deste curso. Ele também precisaria de um `body.json`,
que é o corpo que o programa imprimiu.

## A `api-version` é um contrato

Cada tipo de recurso é publicado em versões datadas da sua API, e **a versão decide quais propriedades
existem e o que elas querem dizer.** É a data depois do `@` no Bicep e a `api-version` na URL. Uma
propriedade acrescentada às redes numa versão de 2024 não existe para um pedido que cita uma de 2020, e
é ignorada ou recusada como desconhecida, conforme o provider. Então uma versão não é um detalhe para
subir sem ler o que mudou. Uma versão de que o Bicep nunca ouviu falar é um aviso, não um erro; salve
isto como `future.bicep`:

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2099-01-01' = {
  name: 'vnet-shop-prod'
  location: 'brazilsouth'
}
```

```
ana@laptop:~/azure/arm$ az bicep build --file future.bicep --stdout > /dev/null
WARNING: /home/ana/azure/arm/future.bicep(1,15) : Warning BCP081: Resource type "Microsoft.Network/virtualNetworks@2099-01-01" does not have types available. Bicep is unable to validate resource properties prior to deployment, but this will not block the resource from being deployed. [https://aka.ms/bicep/core-diagnostics#BCP081]
```

O Bicep carrega as definições de todo tipo que conhece, e confere cada propriedade contra a versão
citada. Para uma versão desconhecida ele não consegue conferir nada, diz isso com o `BCP081`, e compila
mesmo assim: a pergunta de se `2099-01-01` existe pertence ao Resource Manager.

## Operações longas

Alguns pedidos terminam enquanto você espera, e outros não conseguem: uma rede virtual aparece em
segundos, um VPN gateway leva dezenas de minutos. Para esses, o Resource Manager responde **201 ou 202**
na hora, com um `provisioningState` que ainda não é final e um cabeçalho para consultar:
**`Azure-AsyncOperation`**, ou **`Location`** quando aquele não vem, e um **`Retry-After`** dizendo
quantos segundos esperar entre as consultas. A operação terminou quando o estado diz `Succeeded`,
`Failed` ou `Canceled`. A CLI do Azure faz essas consultas por você, e é por isso que o
`az network vnet-gateway create` fica um bom tempo em silêncio; o `--no-wait` volta na hora e deixa as
consultas com você. **Nada disso foi executado aqui**; os nomes dos cabeçalhos e os três estados finais
são da documentação da Microsoft.
