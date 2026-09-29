---
title: Edite o candidate, depois faça o commit
version: 1
---

Uma mudança no NETCONF acontece em dois passos, e o espaço entre eles é o que importa.
**`edit-config` escreve no candidate**; o running, a configuração em vigor, não se mexe até que o
**`commit`** copie o candidate para ele.

```schooling-example
{
  "language": "python",
  "file": "candidate.py",
  "parts": [
    {
      "code": "from nc import connect, describe, interface_config\n\nwith connect() as m:"
    },
    {
      "code": "    m.edit_config(target=\"candidate\", config=interface_config(\n        \"<interface><name>eth2</name><description>to pc1</description><enabled>true</enabled></interface>\"))\n    print(describe(m, \"candidate\", \"eth2\"))\n    print(describe(m, \"running\", \"eth2\"))",
      "note": "**A edição vai para o candidate**, uma cópia de trabalho. O running, a configuração em vigor, não se mexe."
    },
    {
      "code": "    m.commit()\n    print(\"-- after commit\")\n    print(describe(m, \"running\", \"eth2\"))",
      "note": "**`commit` copia o candidate para o running, numa só operação.**"
    }
  ]
}
```

```
ana@ctl:~$ python candidate.py
candidate eth2: description='to pc1' enabled=true
running   eth2: description='(none)' enabled=false
-- after commit
running   eth2: description='to pc1' enabled=true
```

Entre a edição e o commit, os dois datastores discordavam: o candidate tinha a descrição e
`enabled=true`, o running não tinha nenhum dos dois. Qualquer coisa que lesse o running nesse
momento, um sistema de monitoramento ou outro script, via a configuração antiga. **Nada ficou
aplicado pela metade**, porque nada foi aplicado até o `commit`.

`edit-config` **mescla** por padrão: o XML enviado é sobreposto à árvore existente, então o `type`
da interface e as outras folhas dela ficaram como estavam. O protocolo tem outras operações para
quando mesclar é errado, definidas com um atributo `operation` num elemento: `replace` faz desse
elemento exatamente o que foi enviado, `delete` o remove e falha se ele não existe, `remove` o
remove e não falha, e `create` falha se ele já existe.

O candidate é compartilhado. **No `nc1` há um candidate para todas as sessões**, então uma edição
deixada ali por um script ainda está lá quando o próximo script faz o commit. As duas próximas
seções são sobre o que isso custa, e como evitar.
