---
title: Ações menos not-actions, e papéis somados
version: 1
---

**A Microsoft enuncia a regra para ler um papel em duas linhas**: o que as actions do papel permitem,
menos o que os not-actions removem, dá as operações que ele permite; e a mesma subtração, feita à
parte, dá as operações de dados. Um curinga em `actions` é expandido primeiro, e um curinga em
`notActions` tira tudo o que ele casar.

A imagem errada a largar é a de um not-action como proibição. **`notActions` não é um deny.** Ele só
tira algo do papel em que está. Se um segundo papel, atribuído à mesma pessoa, permite a mesma
operação, a pessoa pode fazê-la. Essa é a segunda metade da regra, e a documentação da Microsoft a
diz com todas as letras: o RBAC do Azure é **aditivo**, e as permissões efetivas de uma pessoa são a
soma de todas as atribuições de papel dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l09-additive\" aria-label=\"Duas atribuições de papel da mesma pessoa, somadas. Contributor permite toda operação menos as de Microsoft.Authorization, que os notActions dele removem. User Access Administrator permite as operações de Microsoft.Authorization. As permissões efetivas da pessoa são a união: tudo, inclusive escrever atribuições de papel. Os notActions do Contributor removeram a operação só do Contributor, não da pessoa.\"><rect x=\"30.0\" y=\"30.0\" width=\"200.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Contributor</text><text x=\"46.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">permite</text><text x=\"130.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">*</text><text x=\"46.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">remove</text><text x=\"130.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Microsoft.Authorization/*/Write</text><text x=\"255.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper-dim)\">+</text><rect x=\"280.0\" y=\"30.0\" width=\"200.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">User Access Administrator</text><text x=\"296.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">permite</text><text x=\"380.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Microsoft.Authorization/*</text><text x=\"296.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">remove</text><text x=\"380.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">nada</text><text x=\"505.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper-dim)\">=</text><rect x=\"530.0\" y=\"30.0\" width=\"160.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">efetivo</text><text x=\"610.0\" y=\"91.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">toda operação,</text><text x=\"610.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">atribuições de</text><text x=\"610.0\" y=\"118.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">papel incluídas</text><text x=\"360.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">notActions tira do próprio papel, não da pessoa</text><text x=\"360.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">só uma deny assignment tira de tudo</text></svg>", "caption": "Papéis se somam. Um not-action estreita o próprio papel e nada mais.", "same": ["Contributor", "User Access Administrator"]}
```

## A regra, como programa

O laboratório não consegue perguntar ao Resource Manager se uma operação seria permitida. Ele
consegue aplicar a regra documentada às definições que a seção anterior baixou, e isso faz da regra
algo que se testa em vez de algo que se recita. Salve isto como `can.py` em `~/azure/rbac`:

```schooling-example
{"language": "python", "file": "can.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"can.py [--data] ACTION ROLE.json...: which of these roles grant ACTION?\n\nThe course's model of the rule Microsoft documents, not Azure's own evaluator.\"\"\"\nimport fnmatch\nimport json\nimport sys\n\n\n", "note": "**Este é o modelo do curso, não o Azure.** Ele segue a regra que a documentação da Microsoft enuncia, sobre as definições que você acabou de baixar, para a regra poder ser testada no seu próprio computador. A avaliação real do Resource Manager também pesa deny assignments e condições, que a próxima seção cita."}, {"code": "def matches(pattern, action):\n    return fnmatch.fnmatchcase(action.lower(), pattern.lower())\n\n\n", "note": "Um `*` numa permissão casa com qualquer coisa, barras incluídas, então `*/read` é toda leitura de todo provider. O modelo compara sem levar em conta maiúsculas e minúsculas, como o Azure compara ids."}, {"code": "def grants(role, action, data):\n    allow, remove = ('dataActions', 'notDataActions') if data else ('actions', 'notActions')\n    for p in role['permissions']:\n        if any(matches(a, action) for a in p[allow]) and not any(matches(n, action) for n in p[remove]):\n            return True\n    return False\n\n\n", "note": "A regra documentada: **o que as actions permitem, menos o que os not-actions removem**. Gerenciamento e dados são duas listas separadas, e `--data` escolhe qual é consultada."}, {"code": "args = sys.argv[1:]\ndata = args[0] == '--data'\naction, files = (args[1], args[2:]) if data else (args[0], args[1:])\nfor path in files:\n    with open(path) as f:\n        role = json.load(f)\n    print('yes' if grants(role, action, data) else 'no ', role['roleName'])\n", "note": "Uma linha por arquivo de papel dado: `yes` ou `no`, e o nome do papel."}]}
```

Faça a ele quatro perguntas, cada uma contra os papéis que tornam a resposta interessante:

```
ana@laptop:~/azure/rbac$ python3 can.py Microsoft.Network/virtualNetworks/write contributor.json reader.json owner.json
yes Contributor
no  Reader
yes Owner
ana@laptop:~/azure/rbac$ python3 can.py Microsoft.Authorization/roleAssignments/write contributor.json owner.json
no  Contributor
yes Owner
ana@laptop:~/azure/rbac$ python3 can.py --data Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read owner.json contributor.json blob-reader.json
no  Owner
no  Contributor
yes Storage Blob Data Reader
ana@laptop:~/azure/rbac$ python3 can.py Microsoft.Storage/storageAccounts/listKeys/action contributor.json reader.json
yes Contributor
no  Reader
```

As duas primeiras respostas são a fama dos papéis, agora lida nas definições: o Contributor pode
mudar a rede e o Reader não; o Contributor não pode criar uma atribuição de papel e o Owner pode.

**A terceira resposta surpreende as pessoas.** Nem o Owner nem o Contributor podem ler um blob pelo
plano de dados, porque os dois têm `dataActions` vazias; só o Storage Blob Data Reader pode. Ser
Owner de uma assinatura não mostra, por esse caminho, um único arquivo dela.

**A quarta resposta é o motivo de isso não ser a história toda.** O Contributor pode rodar `listKeys`
numa storage account, e a chave de uma storage account abre todo blob dela, sem papel nenhum
envolvido. Então um Owner ou um Contributor que queira os dados pode buscar a chave e lê-los. A
separação entre gerenciamento e dados só vale onde as chaves compartilhadas estão desligadas, e o
curso `azure-data` volta a essa chave.

## O que o programa não sabe

O programa é honesto sobre uma definição de cada vez, e o Resource Manager pesa mais do que isso. A
documentação da Microsoft lista a ordem em que um pedido é julgado:

1. **Toda deny assignment que cobre o recurso é conferida primeiro.** Se uma nega a operação a essa
   entidade, o pedido é recusado e nada mais é lido.
2. **As atribuições de papel que se aplicam são reunidas**: as da própria entidade e as de todo grupo
   a que ela pertence, no recurso e em todo escopo acima dele.
3. **A operação é procurada nesses papéis**, com a subtração acima.
4. **As condições são avaliadas** onde uma atribuição tem uma, como um papel de storage limitado a
   blobs com certa tag.

O `can.py` faz o passo 3 para os papéis que você entrega, e nada mais. Ele não sabe quais atribuições
uma entidade tem, em que grupos ela está, se uma deny assignment cobre o recurso, nem se uma condição
valeria. Esses são fatos sobre um tenant num dia, e moram no Resource Manager.

**Deny assignments são raras, e você não consegue escrever uma.** Elas são criadas pelo Azure em seu
nome: um deployment stack com deny settings, que o curso `azure-operations` monta na lição 5 dele, põe
uma sobre os recursos que gerencia para ninguém apagá-los à mão, e uma aplicação gerenciada põe uma
sobre o próprio grupo de recursos. Uma deny assignment vence qualquer permissão, inclusive a de um
Owner, que é a propriedade que a torna útil e o motivo de ela não ser distribuída.
