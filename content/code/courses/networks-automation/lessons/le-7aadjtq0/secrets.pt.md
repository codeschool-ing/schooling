---
title: Segredos num repositório
version: 2
---

Um diretório de playbooks mora no Git, e a aula 14 o roda a partir de um pipeline. **Senhas e
tokens não podem estar nele como texto**, e precisam estar em algum lugar que o playbook consiga
ler. A resposta do Ansible é o **Vault**: um valor ou um arquivo inteiro cifrado com uma senha do
vault, decifrado em memória quando o playbook roda.

A senha do vault é uma sequência aleatória num arquivo que só a `ana` consegue ler, criada uma
vez:

```
ana@ctl:~$ head -c 24 /dev/urandom | base64 > ~/.vault-pass; chmod 600 ~/.vault-pass
```

O token da central de chamados da aula 7, cifrado como variável:

```
ana@ctl:~$ cd net && printf %s "$(cat ~/.desk-token)" | ansible-vault encrypt_string --vault-password-file ~/.vault-pass --stdin-name desk_token > group_vars/all.yaml && cat group_vars/all.yaml
desk_token: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          66346237633162386465343739653731323563393738373464616632363465636239366539663962
          3265356464646535666633643332656534666263333161300a613230616438323330653931656165
          35306166656536376236386236333535316531313838653835623332373133663830366261613963
          3532343066393662620a656539656436343764656630373230323565383066613339666533646537
          37663562663862366437656330633233653431316363643739393333656138333130303762393639
          3437666533313738616538323462343731383162633063326262
```

O token veio do arquivo em que ele fica e foi direto para a variável cifrada; ele nunca apareceu
na linha de comando nem na tela. O que é escrito em `group_vars/all.yaml` pode ir para um commit
com segurança: sem a senha do vault é ruído, e a própria senha do vault fica em `~/.vault-pass`,
legível só pela `ana`, ou no cofre de segredos do pipeline.

Um playbook que o usa abre um chamado de mudança para o trabalho de BGP:

```schooling-example
{
  "language": "yaml",
  "file": "ticket.yaml",
  "parts": [
    {
      "code": "- name: Tell the service desk\n  hosts: localhost\n  gather_facts: false\n  tasks:"
    },
    {
      "code": "    - name: Open a change ticket\n      ansible.builtin.uri:\n        url: https://tickets.example.net/api/tickets\n        method: POST\n        ca_path: /home/ana/lab-ca.pem\n        headers:\n          Authorization: \"Token {{ desk_token }}\"\n        body_format: json\n        body:\n          title: iBGP configured on core1, edge1 and edge2\n          priority: low\n          requester: ansible\n        status_code: 201",
      "note": "**`desk_token` vem de um arquivo criptografado pelo vault.** O Ansible o decifra em memória quando o playbook roda com a senha do vault, e o arquivo no repositório continua ilegível."
    },
    {
      "code": "      no_log: true\n      register: ticket\n\n    - name: Say which\n      ansible.builtin.debug:\n        msg: \"{{ ticket.json.number }} opened\"",
      "note": "**`no_log` mantém os argumentos e o resultado da tarefa fora da saída.** Sem ele, uma requisição que falha imprime os cabeçalhos, token incluído, no terminal e em qualquer log de CI que os capture."
    }
  ]
}
```

Rodado sem a senha do vault, ele falha:

```
ana@ctl:~$ cd net && ansible-playbook ticket.yaml 2>&1 | grep -E "ERROR|fatal"
fatal: [localhost]: FAILED! => {"censored": "the output has been hidden due to the fact that 'no_log: true' was specified for this result"}
```

**E o motivo fica escondido**, que é o `no_log` fazendo o trabalho dele na direção inconveniente:
ele esconde tudo sobre a task, inclusive por que ela falhou. Pedir a variável fora dessa task
mostra o que deu errado:

```
ana@ctl:~$ cd net && ansible localhost -m ansible.builtin.debug -a var=desk_token 2>&1 | cat
localhost | FAILED! => {
    "msg": "Attempting to decrypt but no vault secrets found"
}
```

Um valor cifrado e nenhuma senha do vault para abri-lo. Com a senha:

```
ana@ctl:~$ cd net && ansible-playbook ticket.yaml --vault-password-file ~/.vault-pass

PLAY [Tell the service desk] ***************************************************

TASK [Open a change ticket] ****************************************************
ok: [localhost]

TASK [Say which] ***************************************************************
ok: [localhost] => {
    "msg": "INC-1001 opened"
}

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

O `INC-1001` foi aberto. Mas olhe o status da task: **`ok`, não `changed`**, embora ela tenha
criado um chamado. O `uri` não tem como saber que um POST mudou algo do outro lado, então ele
reporta o que sabe. Uma task assim deveria dizer isso ela mesma, com `changed_when: true` ou uma
condição sobre o status code, ou o recap mente e o relatório noturno da aula 14 diz que nada
aconteceu.
