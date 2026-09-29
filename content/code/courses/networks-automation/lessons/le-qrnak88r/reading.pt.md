---
title: Lendo com o ncclient
version: 1
---

Todo script desta aula importa um pequeno módulo. Ele abre a sessão e monta o XML de que as
edições precisam, e traz mais um auxiliar, `describe`, que as seções seguintes usam para imprimir
uma interface de um datastore:

```schooling-example
{
  "language": "python",
  "file": "nc.py",
  "parts": [
    {
      "code": "from ncclient import manager\n\nIF = \"urn:ietf:params:xml:ns:yang:ietf-interfaces\"\nNS = {\"if\": IF}\n\n\ndef connect():\n    return manager.connect(host=\"nc1.example.net\", port=830, username=\"netops\",\n                           key_filename=\"/home/ana/.ssh/id_ed25519\", hostkey_verify=True)\n\n",
      "note": "**Um auxiliar, importado por todo script desta aula.** O `ncclient` cuida do SSH, do hello e do enquadramento; `hostkey_verify=True` confere a chave do nc1 contra `~/.ssh/known_hosts`, a mesma promessa que o HTTPS fez na aula 2."
    },
    {
      "code": "def interface_config(body):\n    return (f'<config xmlns=\"urn:ietf:params:xml:ns:netconf:base:1.0\">'\n            f'<interfaces xmlns=\"{IF}\">{body}</interfaces></config>')\n\n\ndef describe(m, source, name):\n    \"\"\"The description and enabled leaves of one interface, read from a datastore.\"\"\"\n    xpath = f\"/if:interfaces/if:interface[if:name='{name}']\"\n    data = m.get_config(source=source, filter=(\"xpath\", (NS, xpath))).data\n    desc = data.findtext(\".//if:description\", default=\"(none)\", namespaces=NS)\n    enabled = data.findtext(\".//if:enabled\", namespaces=NS)\n    return f\"{source:<9} {name}: description={desc!r} enabled={enabled}\"",
      "note": "**Toda edição desta aula é um `<config>` envolvendo parte da árvore ietf-interfaces.** O elemento de fora pertence ao namespace do NETCONF e os de dentro ao do modelo; a seção 06 mostra o que acontece quando o primeiro fica de fora."
    }
  ]
}
```

Lendo a configuração, e as capacidades que o servidor anunciou:

```schooling-example
{
  "language": "python",
  "file": "read.py",
  "parts": [
    {
      "code": "from nc import NS, connect\n\nwith connect() as m:"
    },
    {
      "code": "    for c in (\"candidate\", \"confirmed-commit\", \"validate\"):\n        print(c, any(f\":{c}:\" in cap for cap in m.server_capabilities))",
      "note": "**A sessão começa com um hello**, e o `ncclient` guarda o que o servidor disse que sabe fazer. Três capacidades decidem o que o resto desta aula pode usar."
    },
    {
      "code": "    reply = m.get_config(source=\"running\", filter=(\"xpath\", (NS, \"/if:interfaces/if:interface/if:description\")))",
      "note": "**Um filtro pede parte da árvore.** Este é XPath: a descrição de cada interface, que traz o nome junto porque o nome é a chave da lista. O prefixo `if:` precisa ser ligado ao namespace do modelo, e `NS` é essa ligação."
    },
    {
      "code": "    for i in reply.data.findall(\".//if:interface\", NS):\n        print(i.findtext(\"if:name\", namespaces=NS), \"-\", i.findtext(\"if:description\", namespaces=NS))",
      "note": "**A resposta é XML, e lê-la também exige o namespace.** `findall` com `if:` acha os elementos do modelo; sem o prefixo ele não acharia nada e não diria nada."
    }
  ]
}
```

```
ana@ctl:~$ python read.py
candidate True
confirmed-commit True
validate True
eth0 - management
eth1 - uplink to core1
```

**O filtro decide quanto volta.** Um `get-config` sem filtro devolve a configuração inteira, o
que num roteador real são milhares de linhas. O NETCONF tem dois tipos de filtro. O filtro
**subtree** da seção anterior é XML no formato da parte que você quer. O filtro **XPath** aqui é
uma expressão, e ele precisa que o servidor anuncie `xpath` no hello, o que o `nc1` faz.

Só `eth0` e `eth1` voltaram. `eth2` existe, mas não tem descrição, e o filtro pediu descrições.
**Um elemento que não está definido está ausente**, não vazio: não existe `<description/>` para
uma folha que ninguém configurou, e um script que espera uma tem que tratar a ausência dela.

A resposta é um elemento `lxml`, e **achar qualquer coisa nela exige o namespace**. `NS` mapeia o
prefixo `if` para o namespace do modelo, e `findall(".//if:interface", NS)` acha as interfaces.
Deixe o prefixo de fora e `findall(".//interface")` devolve uma lista vazia, em silêncio, porque
não existe nenhum elemento chamado `interface` sem namespace. Esse silêncio é o bug clássico do
NETCONF.
