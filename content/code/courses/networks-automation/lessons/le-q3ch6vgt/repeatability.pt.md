---
title: O mesmo resultado, toda vez
version: 1
---

O `mgmt.py` envia sua linha precise o roteador dela ou não. Aqui isso é inofensivo, e é um
hábito que deixa de ser inofensivo quando o comando tem efeitos colaterais: algumas mudanças
derrubam uma sessão, reiniciam um processo ou acrescentam uma linha duplicada. Um script que vale
rodar duas vezes **pergunta antes e muda só o que difere**.

```schooling-example
{
  "language": "python",
  "file": "mgmt_check.py",
  "parts": [
    {
      "code": "from netmiko import ConnectHandler\n\nROUTERS = [\"core1\", \"edge1\", \"edge2\"]\nWANT = \"ip prefix-list MGMT seq 10 permit 192.0.2.0/24\"\n\nfor name in ROUTERS:\n    router = ConnectHandler(device_type=\"cisco_ios\", host=name, username=\"netops\",\n                            use_keys=True, key_file=\"/home/ana/.ssh/id_ed25519\")\n    running = router.send_command(\"show running-config\")",
      "note": "**Pergunte antes de mudar.** O script lê a configuração em execução e compara com a linha que quer."
    },
    {
      "code": "    if WANT in running.splitlines():\n        print(f\"{name}: already as intended\")\n    else:\n        router.send_config_set([WANT])\n        router.save_config()\n        print(f\"{name}: changed\")\n    router.disconnect()",
      "note": "**Mude só o que difere.** Um roteador que já está no estado desejado fica como está e diz isso, e é o que torna segura uma segunda execução."
    }
  ]
}
```

Os três roteadores já estão certos, então a primeira execução não muda nada:

```
ana@ctl:~$ python mgmt_check.py
core1: already as intended
edge1: already as intended
edge2: already as intended
```

Aí alguém entra no `edge2` e remove a lista à mão, o tipo de mudança que ninguém anota:

```
ana@ctl:~$ ssh netops@edge2

Hello, this is FRRouting (version 8.4.4).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

edge2# configure terminal
edge2(config)# no ip prefix-list MGMT
edge2(config)# end
edge2# write memory
Note: this version of vtysh never writes vtysh.conf
Building Configuration...
Integrated configuration saved to /etc/frr/frr.conf
[OK]
edge2# exit
Connection to edge2 closed.
```

O mesmo script, rodado mais duas vezes:

```
ana@ctl:~$ python mgmt_check.py
core1: already as intended
edge1: already as intended
edge2: changed
ana@ctl:~$ python mgmt_check.py
core1: already as intended
edge1: already as intended
edge2: already as intended
```

A primeira execução achou o único roteador que tinha derivado e o pôs de volta. **A segunda não
achou nada para fazer**, e essa é a propriedade que importa: rodar o script de novo é seguro,
então ele pode rodar depois de toda mudança, toda noite, ou sempre que alguém duvidar do estado
da rede.

Essa propriedade tem nome, **idempotência**: aplicar a operação duas vezes deixa a rede
exatamente como aplicá-la uma vez. O Ansible, na aula 9, é construído em torno dela, e a saída
dele diz `changed` ou `ok` pelo mesmo motivo que este script diz `changed` ou
`already as intended`.

**Repetível também é como um script vira evidência.** "Ele disse `already as intended` em todos
os roteadores às 03:00" é uma afirmação sobre a rede que uma pessoa pode conferir. "Acho que fiz
todos" não é.
