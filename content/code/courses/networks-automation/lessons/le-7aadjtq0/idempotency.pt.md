---
title: changed, ok, e rodar duas vezes
version: 1
---

A aula 1 chamou isso de idempotência: uma operação que deixa a rede igual, rode ela uma vez ou
duas. **O Ansible é construído em torno dela**, e a saída dele é como você a enxerga. A prefix
list da aula 1, como task:

```schooling-example
{
  "language": "yaml",
  "file": "mgmt.yaml",
  "parts": [
    {
      "code": "- name: Every router has the MGMT prefix list\n  hosts: routers\n  gather_facts: false\n  tasks:"
    },
    {
      "code": "    - name: Permit the management network\n      ansible.netcommon.cli_config:\n        config: \"ip prefix-list MGMT seq 10 permit {{ management_network }}\"",
      "note": "**`cli_config` compara antes de enviar.** Ele lê a configuração em execução, manda só as linhas que faltam e informa `changed` só se mandou alguma coisa."
    }
  ]
}
```

**Antes de mudar qualquer coisa, pergunte o que mudaria.** O `--check` roda o play sem aplicar, e
o `--diff` mostra as linhas:

```
ana@ctl:~$ cd net && ansible-playbook mgmt.yaml --check --diff

PLAY [Every router has the MGMT prefix list] ***********************************

TASK [Permit the management network] *******************************************
[WARNING]: To ensure idempotency and correct diff the input configuration lines
should be similar to how they appear if present in the running configuration on
device including the indentation
ip prefix-list MGMT seq 10 permit 192.0.2.0/24
changed: [core1]
ip prefix-list MGMT seq 10 permit 192.0.2.0/24
changed: [edge1]
ip prefix-list MGMT seq 10 permit 192.0.2.0/24
changed: [edge2]

PLAY RECAP *********************************************************************
core1                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge1                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge2                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Cada roteador receberia a única linha. O aviso é o `cli_config` sendo honesto sobre como compara:
ele procura a linha como está escrita na configuração em execução, espaçamento e indentação
incluídos, então uma linha escrita de um jeito diferente de como o roteador a imprime vai parecer
nova toda vez. Aí a execução de verdade:

```
ana@ctl:~$ cd net && ansible-playbook mgmt.yaml

PLAY [Every router has the MGMT prefix list] ***********************************

TASK [Permit the management network] *******************************************
[WARNING]: To ensure idempotency and correct diff the input configuration lines
should be similar to how they appear if present in the running configuration on
device including the indentation
changed: [edge1]
changed: [core1]
changed: [edge2]

PLAY RECAP *********************************************************************
core1                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge1                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge2                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

E uma segunda:

```
ana@ctl:~$ cd net && ansible-playbook mgmt.yaml

PLAY [Every router has the MGMT prefix list] ***********************************

TASK [Permit the management network] *******************************************
ok: [core1]
ok: [edge1]
ok: [edge2]

PLAY RECAP *********************************************************************
core1                      : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge1                      : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge2                      : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

**`changed` na primeira vez, `ok` na segunda, em todos os roteadores.** Essa segunda execução é a
prova de que o playbook pode rodar toda noite: quando a rede já confere, nada é enviado e o recap
diz `changed=0`. O playbook de BGP se comportou do mesmo jeito:

```
ana@ctl:~$ cd net && ansible-playbook bgp.yaml | tail -5
PLAY RECAP *********************************************************************
core1                      : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge1                      : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge2                      : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

O `changed` tem uma segunda função: **é o que um pipeline reporta**. Uma execução noturna que diz
`changed=0` quer dizer que ninguém mexeu na rede; uma que diz `changed=3` quer dizer que três
coisas tinham derivado e foram postas de volta, e alguém deveria descobrir por quê. Isso só
funciona se toda task reportar mudança com verdade, e a próxima seção tem uma que não reporta.
