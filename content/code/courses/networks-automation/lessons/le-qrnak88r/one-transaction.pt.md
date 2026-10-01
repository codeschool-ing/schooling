---
title: Uma transação, verificada contra o modelo
version: 1
---

O modelo YANG diz o que é uma configuração válida: que `prefix-length` no `ietf-ip` é um número de
0 a 32, que toda interface no `ietf-interfaces` tem um `type`. **O candidate pode ficar inválido
enquanto está sendo editado**; ele tem que ser válido para virar running. `validate` pergunta sem
fazer o commit:

```schooling-example
{
  "language": "python",
  "file": "invalid.py",
  "parts": [
    {
      "code": "from ncclient.operations import RPCError\n\nfrom nc import connect, interface_config\n\nBAD = \"\"\"<interface><name>eth2</name>\n  <ipv4 xmlns=\"urn:ietf:params:xml:ns:yang:ietf-ip\">\n    <address><ip>192.0.2.99</ip><prefix-length>33</prefix-length></address>\n  </ipv4></interface>\"\"\"\n\nwith connect() as m:\n    m.edit_config(target=\"candidate\", config=interface_config(BAD))\n    print(\"edit-config: ok\")"
    },
    {
      "code": "    try:\n        m.validate(source=\"candidate\")\n    except RPCError as e:\n        print(\"validate:\", e.tag)\n        print(\" \", e.message)\n    m.discard_changes()\n    print(\"discard-changes: ok\")",
      "note": "**`validate` confere o candidate inteiro contra o modelo** sem aplicá-lo. `RPCError` traz a tag do erro, a mensagem e o caminho da folha que falhou."
    }
  ]
}
```

```
ana@ctl:~$ python invalid.py
edit-config: ok
validate: bad-element
  Number 33 out of range: 0 - 32: yang node: "leaf prefix-length" with parent: "choice subnet" in file "/etc/clixon/yang/ietf-ip.yang" error-path: /interfaces/interface[name="eth2"]/ipv4/address[ip="192.0.2.99"]/prefix-length
discard-changes: ok
```

A edição em si foi aceita: o candidate é um rascunho, e rascunhos podem estar errados. O
`validate` então a recusou com uma **error tag**, `bad-element`, uma mensagem dizendo a faixa que o
modelo permite, e o **caminho** da folha que a violou. Um script pode agir sobre os três, e a aula
13 faz de validar antes do commit um passo de toda mudança.

**Um commit é tudo ou nada.** Duas mudanças numa edição, uma certa e outra sem o `type`
obrigatório:

```schooling-example
{
  "language": "python",
  "file": "transaction.py",
  "parts": [
    {
      "code": "from ncclient.operations import RPCError\n\nfrom nc import connect, describe, interface_config\n\nwith connect() as m:"
    },
    {
      "code": "    m.edit_config(target=\"candidate\", config=interface_config(\n        \"<interface><name>eth1</name><description>uplink to core1, port 7</description></interface>\"\n        \"<interface><name>eth3</name></interface>\"))\n    try:\n        m.commit()\n    except RPCError as e:\n        print(\"commit:\", e.tag, \"-\", e.message.split(\".\")[0])",
      "note": "**Duas mudanças numa edição.** A primeira está certa. A segunda cria `eth3` sem `type`, que o modelo diz que toda interface precisa ter."
    },
    {
      "code": "    print(describe(m, \"running\", \"eth1\"))\n    print(describe(m, \"candidate\", \"eth1\"))\n    m.discard_changes()\n    print(describe(m, \"candidate\", \"eth1\"))",
      "note": "**Nada foi aplicado**: nem a metade quebrada, nem a boa. A edição continua no candidate até ser descartada, e um script precisa fazer isso antes que o commit da próxima pessoa a leve junto."
    }
  ]
}
```

```
ana@ctl:~$ python transaction.py
commit: missing-element - Missing mandatory XML type node
running   eth1: description='uplink to core1' enabled=true
candidate eth1: description='uplink to core1, port 7' enabled=true
candidate eth1: description='uplink to core1' enabled=true
```

O commit foi recusado, e o running manteve a descrição antiga da `eth1` mesmo com aquela metade da
edição sendo válida. Essa é a transação: **o equipamento nunca fica entre duas configurações**. As
duas últimas linhas mostram a outra metade da lição. A edição rejeitada continuava no candidate
depois da falha, e só o `discard-changes` a removeu. Um script que esquece esse passo deixa o erro
dele para o próximo commit pegar.

Um erro acontece antes de tudo isso, e não é do modelo. O XML tem dois namespaces: `<config>` é um
elemento do próprio NETCONF e pertence a `urn:ietf:params:xml:ns:netconf:base:1.0`, enquanto tudo
dentro dele pertence ao modelo. Deixe o primeiro de fora:

```
ana@ctl:~$ python -c 'from nc import connect; connect().edit_config(target="candidate", config="<config><interfaces xmlns=\"urn:ietf:params:xml:ns:yang:ietf-interfaces\"/></config>")' 2>&1 | tail -1
ncclient.operations.rpc.RPCError: Missing namespace
```

**`Missing namespace`**, e o servidor tem razão. É por isso que o `interface_config` no `nc.py`
escreve os dois.
