---
title: Um primeiro playbook
version: 1
---

Um playbook é uma lista de **plays**; um play é um conjunto de hosts e uma lista de **tasks**; uma
task chama um **módulo** com argumentos. Essa é a gramática inteira.

```schooling-example
{
  "language": "yaml",
  "file": "show.yaml",
  "parts": [
    {
      "code": "- name: Ask every router about its OSPF neighbours\n  hosts: routers\n  gather_facts: false\n  tasks:",
      "note": "**Um play diz quais hosts, e uma lista de tarefas a rodar em cada um.** `gather_facts: false` pula os fatos de Linux que o Ansible coleta por padrão, que o CLI de um roteador não tem como dar."
    },
    {
      "code": "    - name: Show the neighbours\n      ansible.netcommon.cli_command:\n        command: show ip ospf neighbor json\n      register: ospf\n",
      "note": "**Uma tarefa chama um módulo com argumentos.** `cli_command` manda um comando pela conexão network_cli e devolve o que o equipamento imprimiu; `register` guarda o resultado numa variável."
    },
    {
      "code": "    - name: Count them\n      ansible.builtin.debug:\n        msg: \"{{ (ospf.stdout | from_json).neighbors | length }} OSPF neighbour(s)\"",
      "note": "**Variáveis são expressões Jinja2.** `from_json` lê o JSON do roteador, e a tarefa imprime uma linha por roteador."
    }
  ]
}
```

```
ana@ctl:~$ cd net && ansible-playbook show.yaml

PLAY [Ask every router about its OSPF neighbours] ******************************

TASK [Show the neighbours] *****************************************************
ok: [edge1]
ok: [edge2]
ok: [core1]

TASK [Count them] **************************************************************
ok: [core1] => {
    "msg": "2 OSPF neighbour(s)"
}
ok: [edge1] => {
    "msg": "1 OSPF neighbour(s)"
}
ok: [edge2] => {
    "msg": "1 OSPF neighbour(s)"
}

PLAY RECAP *********************************************************************
core1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge2                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Três coisas nessa saída são do Ansible e aparecem em toda execução. **Cada task é reportada por
host**, na ordem em que os hosts terminaram, porque o Ansible trabalha neles em paralelo. O status
de cada uma é `ok`, `changed`, `failed` ou `skipped`. E o **play recap** no final os conta por
host; é a linha que uma pessoa ou um pipeline lê primeiro.

O `cli_command` é o equivalente de rede do `send_command` da aula 8, e o `from_json` é o
`json.loads` da aula 8: o roteador respondeu em JSON porque o comando terminava em `json`, e a
expressão contou os vizinhos. As expressões entre `{{` e `}}` são **Jinja2**, a linguagem de
template de que trata a aula 10; num playbook elas calculam valores a partir de variáveis e
resultados.

A task reportou `ok` e não `changed`, e isso não é enfeite. O `cli_command` só lê, e diz isso.
**O que uma task reporta sobre mudança é uma promessa**, e as próximas seções tratam de cumpri-la.
