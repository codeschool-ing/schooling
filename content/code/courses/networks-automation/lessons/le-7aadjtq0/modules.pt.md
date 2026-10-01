---
title: Módulos que conhecem a plataforma
version: 1
---

O `cli_command` envia o que receber. Os módulos que fazem o Ansible valer a pena numa rede são os
que **conhecem a plataforma**: eles recebem dados, leem o estado do equipamento e descobrem os
comandos sozinhos. As collections os trazem por fabricante, e a collection `frr.frr` tem dois, um
coletor de facts e um módulo de BGP.

Facts primeiro. O `frr_facts` roda comandos `show` e transforma a saída em variáveis:

```schooling-example
{
  "language": "yaml",
  "file": "facts.yaml",
  "parts": [
    {
      "code": "- name: What the collection knows about each router\n  hosts: branches\n  gather_facts: false\n  tasks:"
    },
    {
      "code": "    - name: Gather interface facts\n      frr.frr.frr_facts:\n        gather_subset: interfaces\n    - name: Show a few\n      ansible.builtin.debug:\n        msg: \"{{ ansible_net_hostname }} runs FRR {{ ansible_net_version }}, interfaces {{ ansible_net_interfaces.keys() | sort | join(', ') }}\"",
      "note": "**`frr_facts` transforma saídas de `show` em variáveis** chamadas `ansible_net_…`, para tarefas seguintes decidirem com base nelas."
    }
  ]
}
```

```
ana@ctl:~$ cd net && ansible-playbook facts.yaml

PLAY [What the collection knows about each router] *****************************

TASK [Gather interface facts] **************************************************
ok: [edge1]
ok: [edge2]

TASK [Show a few] **************************************************************
ok: [edge1] => {
    "msg": "edge1 runs FRR 8.4.4, interfaces eth0, eth1, eth2, lo"
}
ok: [edge2] => {
    "msg": "edge2 runs FRR 8.4.4, interfaces eth0, eth1, eth2, lo"
}

PLAY RECAP *********************************************************************
edge1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge2                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

O play rodou só em `branches`, os dois roteadores de borda, porque esse é o `hosts` dele. As variáveis ficam
disponíveis para toda task posterior do play, que é como um playbook decide, por exemplo, pular
uma task num roteador cujo software é antigo demais.

Depois, configuração como dados. O `frr_bgp` recebe o BGP como uma estrutura, com os valores
vindo das variáveis de cada host:

```schooling-example
{
  "language": "yaml",
  "file": "bgp.yaml",
  "parts": [
    {
      "code": "- name: iBGP between the loopbacks\n  hosts: routers\n  gather_facts: false\n  tasks:"
    },
    {
      "code": "    - name: Configure BGP, one neighbour at a time\n      frr.frr.frr_bgp:\n        config:\n          bgp_as: \"{{ bgp_as }}\"\n          router_id: \"{{ router_id }}\"\n          neighbors:\n            - neighbor: \"{{ item }}\"\n              remote_as: \"{{ bgp_as }}\"\n              update_source: lo\n        operation: merge",
      "note": "**Um módulo de fornecedor fala em dados, não em linhas.** `frr_bgp` recebe a configuração BGP como estrutura, e a coleção calcula os comandos do FRR, deixando de fora os que já estão lá."
    },
    {
      "code": "      loop: \"{{ bgp_neighbours }}\"",
      "note": "**Uma execução da tarefa por item da lista do próprio host.** A lista do core1 tem dois vizinhos e a de cada edge tem um; o playbook é o mesmo para os três."
    }
  ]
}
```

```
ana@ctl:~$ cd net && ansible-playbook bgp.yaml

PLAY [iBGP between the loopbacks] **********************************************

TASK [Configure BGP, one neighbour at a time] **********************************
changed: [edge1] => (item=203.0.113.251)
changed: [edge2] => (item=203.0.113.251)
changed: [core1] => (item=203.0.113.252)
changed: [core1] => (item=203.0.113.253)

PLAY RECAP *********************************************************************
core1                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge1                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge2                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

**O mesmo playbook fez três configurações diferentes**, porque a lista `bgp_neighbours` de cada
host é diferente: o `core1` recebeu dois vizinhos e cada roteador de borda, um. O que o módulo enviou ao
`edge1`, lido de volta pelo CLI dele:

```
ana@ctl:~$ ssh netops@edge1 "show running-config" | sed -n "/^router bgp/,/^exit/p"
router bgp 64512
 bgp router-id 203.0.113.252
 neighbor 203.0.113.251 remote-as 64512
 neighbor 203.0.113.251 update-source lo
exit
```

E a verificação de que as sessões de fato subiram, como um playbook próprio que falha se não
subiram:

```schooling-example
{
  "language": "yaml",
  "file": "bgp_check.yaml",
  "parts": [
    {
      "code": "- name: Are the BGP sessions up?\n  hosts: routers\n  gather_facts: false\n  tasks:\n    - name: Read BGP state\n      ansible.netcommon.cli_command:\n        command: show bgp summary json\n      register: bgp\n"
    },
    {
      "code": "    - name: Every peer is Established\n      ansible.builtin.assert:\n        that: item.value.state == \"Established\"\n        quiet: true\n      loop: \"{{ (bgp.stdout | from_json).ipv4Unicast.peers | dict2items }}\"\n      loop_control:\n        label: \"{{ item.key }} {{ item.value.state }}\"",
      "note": "**Uma asserção transforma uma verificação numa falha.** Se algum par não estiver `Established`, a tarefa falha naquele roteador e o play diz isso, que é o que um script depois de uma mudança deve fazer."
    }
  ]
}
```

```
ana@ctl:~$ cd net && ansible-playbook bgp_check.yaml

PLAY [Are the BGP sessions up?] ************************************************

TASK [Read BGP state] **********************************************************
ok: [edge2]
ok: [core1]
ok: [edge1]

TASK [Every peer is Established] ***********************************************
ok: [core1] => (item=203.0.113.252 Established)
ok: [core1] => (item=203.0.113.253 Established)
ok: [edge1] => (item=203.0.113.251 Established)
ok: [edge2] => (item=203.0.113.251 Established)

PLAY RECAP *********************************************************************
core1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge2                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

**Quatro sessões, todas `Established`.** O `assert` é como um playbook transforma uma expectativa
numa falha que interrompe a execução; a aula 13 monta as verificações dela do mesmo jeito, com
`pytest` no lugar.

As collections de outros fabricantes têm muito mais módulos que a `frr.frr`: `cisco.ios`,
`arista.eos` e `junipernetworks.junos` têm um por área de configuração, interfaces, VLANs, OSPF,
ACLs, cada um recebendo dados num formato quase igual entre as três.
