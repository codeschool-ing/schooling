---
title: Tags, e as regras que elas seguem
version: 1
---

**Uma tag é um nome e um valor colados num recurso, e é o único jeito de uma fatura dizer de quem é um
custo.** A assinatura e o grupo de recursos já dizem alguma coisa: a lição 2 montou a árvore para que
produção e staging sejam pagos à parte. Mas o dinheiro de uma empresa se divide por mais coisas do que
ambientes: por equipe, por produto, por centro de custo, por cliente. Um grupo de recursos pode
guardar os servidores web da equipe de checkout e o cache da equipe de catálogo, e a fatura não cita
nenhuma das duas equipes a não ser que uma tag cite.

## O que é uma tag, pelas regras do Azure

Uma tag é um par, como `cost-centre: cc-410`, e a documentação da Microsoft define os seus limites:

| regra | o que ela significa para a loja |
|---|---|
| **até 50 pares** em cada recurso, grupo de recursos e assinatura | o bastante para qualquer esquema sensato; um esquema que precisa de mais está descrevendo o recurso em vez do dono |
| um nome de até **512 caracteres**, um valor de até **256** (uma storage account: 128 para o nome) | curto é melhor: uma tag é digitada em filtros por pessoas |
| **nomes não diferenciam maiúsculas, valores diferenciam** | `Cost-Centre` e `cost-centre` são a mesma tag; `cc-410` e `CC-410` são dois centros de custo |
| **recursos não herdam as tags do seu grupo** | uma tag em `rg-shop-prod-app` não diz nada sobre as máquinas dentro dele, a não ser que algo a copie para baixo |

A terceira regra é a silenciosa. **O Azure guarda a caixa que a primeira pessoa digitou num nome**, e
os relatórios de custo a mostram, então um relatório pode trazer `Cost-Centre` de uma equipe e
`cost-centre` de outra, que o Azure trata como uma tag só e uma planilha trata como duas colunas. E um
valor digitado `CC-410` por uma pessoa e `cc-410` por outra divide o dinheiro de um centro de custo em
duas linhas. **Combine a grafia uma vez, escreva-a, e deixe uma política fazê-la valer**, que é a
próxima seção.

A quarta regra é a cara, e ganha a próxima seção inteira.

## Um esquema de tags, decidido antes do primeiro recurso

O esquema da loja tem quatro tags, e cada uma responde uma pergunta que alguém vai fazer sobre um
custo:

| tag | exemplo | a pergunta |
|---|---|---|
| `cost-centre` | `cc-410` | o orçamento de quem paga isto? |
| `environment` | `prod` | dá para desligar à noite? |
| `owner` | `checkout@shop.example` | a quem perguntamos antes de apagar? |
| `workload` | `checkout` | de que produto isto faz parte? |

`owner` é uma caixa de correio compartilhada, não uma pessoa, pelo mesmo motivo do e-mail do
orçamento da lição 13. E nenhuma delas repete o que o id do recurso já diz: a assinatura e o grupo de
recursos estão em toda linha de dados de custo, com alguém tagueando alguma coisa ou não.

## Tags em Bicep

Uma tag é uma propriedade de um recurso, então vai no arquivo que cria o recurso, e o jeito barato de
manter um esquema consistente é escrevê-lo uma vez como parâmetro. Crie o diretório da lição:

```sh
mkdir -p ~/azure/tags && cd ~/azure/tags
```

e salve isto como `pip.bicep`, um endereço IP público para a frente web da loja, com o esquema como
parâmetro e uma tag a mais só dele:

```bicep
param tags object = {
  'cost-centre': 'cc-410'
  environment: 'prod'
  owner: 'checkout@shop.example'
  workload: 'checkout'
}

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-shop-web'
  location: resourceGroup().location
  tags: union(tags, {
    role: 'web'
  })
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}
```

`union` junta dois objetos, então o recurso recebe as quatro tags do esquema e mais `role: web`.
`cost-centre` vai entre aspas porque um hífen não é permitido num nome de propriedade sem aspas.
Compile:

```
ana@laptop:~/azure/tags$ az bicep build --file pip.bicep --stdout | jq '{default: .parameters.tags.defaultValue, tags: .resources[0].tags}'
{
  "default": {
    "cost-centre": "cc-410",
    "environment": "prod",
    "owner": "checkout@shop.example",
    "workload": "checkout"
  },
  "tags": "[union(parameters('tags'), createObject('role', 'web'))]"
}
```

O esquema viaja como o valor padrão do parâmetro, e as tags do recurso são uma expressão que o
Resource Manager avalia quando o template chega, como a lição 2 viu com os pais. Todo arquivo que cria
um recurso para a loja pode receber o mesmo parâmetro `tags`, e uma implantação pode passar outro para
staging.

Com uma conta, as tags também podem ser definidas pela linha de comando, `az tag update` em qualquer
id de recurso, e no portal. **Nenhum dos dois foi executado**, e os dois são como os esquemas se
degradam: um recurso tagueado à mão, com a caixa que alguém quis naquele dia.
