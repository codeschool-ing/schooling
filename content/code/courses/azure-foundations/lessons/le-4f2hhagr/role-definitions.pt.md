---
title: Um papel é uma lista de ações
version: 1
---

**No Azure, ninguém recebe acesso direto a um recurso. Recebe um papel, num escopo.** O papel diz o
que pode ser feito, o escopo diz onde, e a união dos dois com uma entidade de segurança é uma
**atribuição de papel**. Esta lição pega as três peças uma de cada vez: o papel aqui, a regra que o
lê na próxima seção, e a atribuição na seguinte.

Uma primeira imagem comum é uma lista de pessoas em cada recurso, como a de uma pasta compartilhada.
Essa lista não existe. Pergunte ao Azure quem pode mudar a `vnet-shop-prod` e ele responde juntando
toda atribuição na rede, no grupo de recursos dela, na assinatura e em cada grupo de gerenciamento
acima, e lendo os papéis que elas citam. As caixas da lição 2 são de onde a resposta vem.

## O que uma definição de papel guarda

**Uma definição de papel é uma lista de operações com nome.** Toda operação no Azure tem um nome
montado como um id de recurso, começando pelo namespace do provider:
`Microsoft.Network/virtualNetworks/write` é criar ou mudar uma rede,
`Microsoft.Compute/virtualMachines/start/action` é ligar uma máquina,
`Microsoft.Storage/storageAccounts/listKeys/action` é ler as chaves de uma storage account. Uma
definição guarda quatro listas delas, e uma quinta lista de lugares:

| campo | o que guarda |
|---|---|
| `actions` | as operações de gerenciamento que o papel permite: criar, ler, mudar e apagar recursos |
| `notActions` | operações tiradas de `actions`, normalmente porque `actions` usou um curinga |
| `dataActions` | operações sobre os dados dentro de um recurso: ler um blob, ler o valor de um segredo |
| `notDataActions` | a mesma subtração, para dados |
| `assignableScopes` | onde o papel pode ser atribuído: `/` para qualquer lugar, ou uma lista de assinaturas e grupos |

**Gerenciamento e dados ficam separados de propósito.** Mudar uma storage account e ler os arquivos
dentro dela são poderes diferentes, nas mãos de pessoas diferentes: a equipe de plataforma cuida da
conta, e a aplicação lê os arquivos. A lição 25 chama as duas metades de plano de controle e plano de
dados.

## Os papéis nativos

A Microsoft entrega várias centenas de papéis, e quatro deles carregam quase todo o peso. Os ids
deles são os mesmos GUIDs em todo tenant do planeta, e é por isso que um template pode citar um pelo
id:

| papel | o que permite | id |
|---|---|---|
| **Owner** | tudo, inclusive dar acesso a outros | `8e3af657-a8ff-443c-a75c-2fe8c4bcb635` |
| **Contributor** | tudo, menos dar acesso | `b24988ac-6180-42a0-ab88-20f7382dd24c` |
| **Reader** | olhar, e não mudar nada | `acdd72a7-3385-48ef-bd42-f606fba81ae7` |
| **User Access Administrator** | dar acesso, e nada mais | `18d7d88d-d35e-4fb5-a5c3-7773c20a72d9` |

Ao lado deles fica o **Role Based Access Control Administrator**,
`f58310d9-a9f6-439a-9e8d-f62e7b41a168`, que dá acesso por atribuições e pode ser limitado por
condições a certos papéis; e os papéis específicos, como Network Contributor ou Storage Blob Data
Reader, que é onde o menor privilégio de fato mora.

## Lendo uma definição você mesmo

A lista de papéis é uma pergunta para o Resource Manager, e o laboratório recebe a resposta de
sempre:

```
ana@laptop:~/azure$ az role definition list --name Contributor
ERROR: Please run 'az login' to setup account.
```

As definições são públicas, porém. **A Microsoft publica o JSON de todo papel nativo na sua
documentação**, e o código-fonte da documentação é um repositório público no GitHub. Crie o
diretório da lição, e salve este programa como `roledef.py`:

```sh
mkdir -p ~/azure/rbac && cd ~/azure/rbac
```

```schooling-example
{"language": "python", "file": "roledef.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"roledef.py PAGE ROLE: a built-in role's definition, from the source of Microsoft's documentation.\"\"\"\nimport json\nimport re\nimport sys\nimport urllib.request\n\nBASE = ('https://raw.githubusercontent.com/MicrosoftDocs/azure-docs/main/'\n        'articles/role-based-access-control/built-in-roles/')\n\n", "note": "A Microsoft escreve a documentação em Markdown, num repositório público no GitHub, e as páginas sobre papéis nativos trazem a definição de cada papel como um bloco JSON. `BASE` é a pasta onde essas páginas moram. Ler isso não precisa de conta."}, {"code": "page, role = sys.argv[1], sys.argv[2]\nwith urllib.request.urlopen(BASE + page + '.md', timeout=60) as reply:\n    text = reply.read().decode()\n", "note": "Os papéis estão espalhados por páginas de assunto: `general` tem o Reader, `privileged` tem o Owner e o Contributor, `storage` os papéis de armazenamento."}, {"code": "section = text.split('\\n## ' + role + '\\n', 1)[1].split('\\n## ', 1)[0]\nblock = re.search(r'```json\\n(.*?)\\n```', section, re.S).group(1)\nprint(json.dumps(json.loads(block), indent=2))\n", "note": "Cada papel tem um título próprio, `## Contributor`, e o primeiro bloco JSON debaixo dele é a definição. O programa recorta esse bloco e o imprime, o que também confere que ele é um JSON válido. **Se a Microsoft reorganizar as páginas, isto quebra com estardalhaço** em vez de imprimir o papel errado."}]}
```

Busque quatro definições e guarde-as como arquivos, depois leia o que o Contributor tira:

```
ana@laptop:~/azure/rbac$ python3 roledef.py privileged Contributor > contributor.json
ana@laptop:~/azure/rbac$ python3 roledef.py privileged Owner > owner.json
ana@laptop:~/azure/rbac$ python3 roledef.py general Reader > reader.json
ana@laptop:~/azure/rbac$ python3 roledef.py storage 'Storage Blob Data Reader' > blob-reader.json
ana@laptop:~/azure/rbac$ jq .permissions contributor.json
[
  {
    "actions": [
      "*"
    ],
    "notActions": [
      "Microsoft.Authorization/*/Delete",
      "Microsoft.Authorization/*/Write",
      "Microsoft.Authorization/elevateAccess/Action",
      "Microsoft.Blueprint/blueprintAssignments/write",
      "Microsoft.Blueprint/blueprintAssignments/delete",
      "Microsoft.Compute/galleries/share/action",
      "Microsoft.Purview/consents/write",
      "Microsoft.Purview/consents/delete",
      "Microsoft.Resources/deploymentStacks/manageDenySetting/action",
      "Microsoft.Subscription/cancel/action",
      "Microsoft.Subscription/enable/action"
    ],
    "dataActions": [],
    "notDataActions": []
  }
]
ana@laptop:~/azure/rbac$ jq -c .permissions owner.json reader.json
[{"actions":["*"],"notActions":[],"dataActions":[],"notDataActions":[]}]
[{"actions":["*/read"],"notActions":[],"dataActions":[],"notDataActions":[]}]
ana@laptop:~/azure/rbac$ jq -c .permissions blob-reader.json
[{"actions":["Microsoft.Storage/storageAccounts/blobServices/containers/read","Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action"],"notActions":[],"dataActions":["Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read"],"notDataActions":[]}]
```

As `actions` do Contributor são um único `*`: toda operação de gerenciamento do Azure. Depois os
`notActions` tiram onze de volta, e **as duas primeiras são a razão de ser do papel**: nada debaixo
de `Microsoft.Authorization` pode ser escrito ou apagado, e `Microsoft.Authorization` é onde as
atribuições de papel moram. Um Contributor pode construir qualquer coisa e não pode dar acesso a
ninguém, nem a si mesmo. O Owner é `*` sem nada tirado, e o Reader é `*/read`: toda operação cujo
nome termina em `read`, em todo provider.

**Leia a última linha, a do Storage Blob Data Reader**: as `actions` dele deixam ver que os
contêineres existem, e as `dataActions` deixam ler os blobs dentro deles. As `dataActions` do
Contributor estão vazias. A próxima seção pergunta o que isso quer dizer para quem tem esse papel.
