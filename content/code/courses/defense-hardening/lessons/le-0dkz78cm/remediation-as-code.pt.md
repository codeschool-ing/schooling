---
title: A correção, escrita como código
version: 1
---

**Uma mudança aplicada à mão é aplicada uma vez, nas máquinas de que alguém se lembrou, na ordem em
que se lembrou.** As verificações da última seção dizem o que está errado. A correção também pertence
a um arquivo, para poder ser lida antes de rodar, rodada na próxima máquina do mesmo jeito e rodada
de novo amanhã para devolver o que se desviou. Isso é **configuração como código**, e no Linux a
ferramenta que a maioria das organizações escolhe é o **Ansible**: ele não precisa de nada nas
máquinas que administra além de SSH e Python, e os dois já estão em todas as máquinas do laboratório.

O Ansible roda a partir de uma máquina de controle, que aqui é o `admin`. Ele precisa de um
**inventário**, a lista de máquinas em que pode mexer, agrupadas por papel. Um grupo com uma máquina
basta por enquanto:

```
ana@admin:~$ printf "[portal]\nweb\n" > hosts.ini; ansible -i hosts.ini portal -m ping
web | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

`-m ping` não é um ping de rede: ele entra por SSH, roda um pequeno programa em Python e responde
`pong`. Prova as três coisas de que o playbook vai precisar, o caminho de rede, a chave e o Python do
outro lado.

## O playbook

No `admin`, crie `harden.yml`. Cada tarefa descreve um estado em que o portal deve estar, e o arquivo
inteiro é a linha de base do portal, escrita como mudanças e não como verificações:

```schooling-example
{"language": "yaml", "file": "harden.yml", "parts": [{"code": "- name: Jatobá baseline for the portal\n  hosts: portal\n  become: true\n  tasks:", "note": "Um playbook é uma lista de plays, e um play diz em quais máquinas (`portal`, um grupo do inventário) e o que tornar verdade nelas. `become: true` roda cada tarefa com `sudo` do outro lado, pela chave SSH em que todas as máquinas do laboratório já confiam."}, {"code": "    - name: Services the portal does not need are not installed\n      ansible.builtin.apt:\n        name: [vsftpd, openbsd-inetd, inetutils-telnetd, rpcbind, avahi-daemon, snmpd]\n        state: absent\n        purge: true", "note": "Cada tarefa descreve um estado, nunca um comando. `state: absent` quer dizer \"garanta que estes não estejam lá\": numa máquina que os tem, remove; numa que não tem, não faz nada e diz `ok`. É isso que deixa o playbook seguro para rodar duas vezes, ou toda noite."}, {"code": "    - name: Only root has user id 0\n      ansible.builtin.lineinfile:\n        path: \"{{ item }}\"\n        regexp: '^suporte:'\n        state: absent\n      loop: [/etc/passwd, /etc/shadow, /etc/group, /etc/gshadow]", "note": "O segundo root sai do jeito que a aula 1 o tirou, apagando a linha dele dos quatro arquivos de contas, nunca com `userdel -r`. `loop` repete a tarefa uma vez por arquivo."}, {"code": "    - name: The intern's account cannot log in\n      ansible.builtin.user:\n        name: estagio\n        password_lock: true\n        shell: /usr/sbin/nologin\n        expires: 1\n\n    - name: The intern has no sudo rule\n      ansible.builtin.file:\n        path: /etc/sudoers.d/estagio\n        state: absent", "note": "A conta do estagiário é travada, fica sem shell e expirada, e a regra de `sudo` dela é removida: as mesmas três mudanças da aula 1, escritas como o estado que deixam."}, {"code": "    - name: SSH refuses root and passwords\n      ansible.builtin.copy:\n        dest: /etc/ssh/sshd_config.d/10-hardening.conf\n        content: |\n          PermitRootLogin no\n          PasswordAuthentication no\n          X11Forwarding no\n          MaxAuthTries 3\n        validate: /usr/sbin/sshd -t -f %s\n      notify: reload ssh", "note": "`validate` roda `sshd -t` no arquivo novo antes de substituir qualquer coisa, então um erro no playbook nunca chega ao servidor. `notify` pede o handler no fim, e só se esta tarefa mudou alguma coisa."}, {"code": "    - name: nginx does not announce its version\n      ansible.builtin.lineinfile:\n        path: /etc/nginx/nginx.conf\n        regexp: '^\\s*#?\\s*server_tokens'\n        line: \"\\tserver_tokens off;\"\n      notify: restart nginx\n\n  handlers:\n    - name: reload ssh\n      ansible.builtin.service: {name: ssh, state: reloaded}\n    - name: restart nginx\n      ansible.builtin.service: {name: nginx, state: restarted}", "note": "Handlers rodam uma vez, depois de todas as tarefas, seja qual for o número de tarefas que os chamou. Uma segunda execução que não muda nada não chama ninguém, então nenhum dos dois serviços é tocado."}]}
```

Rode:

```
ana@admin:~$ ansible-playbook -i hosts.ini harden.yml

PLAY [Jatobá baseline for the portal] ******************************************

TASK [Gathering Facts] *********************************************************
ok: [web]

TASK [Services the portal does not need are not installed] *********************
changed: [web]

TASK [Only root has user id 0] *************************************************
changed: [web] => (item=/etc/passwd)
changed: [web] => (item=/etc/shadow)
ok: [web] => (item=/etc/group)
ok: [web] => (item=/etc/gshadow)

TASK [The intern's account cannot log in] **************************************
changed: [web]

TASK [The intern has no sudo rule] *********************************************
changed: [web]

TASK [SSH refuses root and passwords] ******************************************
changed: [web]

TASK [nginx does not announce its version] *************************************
changed: [web]

RUNNING HANDLER [reload ssh] ***************************************************
changed: [web]

RUNNING HANDLER [restart nginx] ************************************************
changed: [web]

PLAY RECAP *********************************************************************
web                        : ok=9    changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Cada tarefa imprime `changed` onde teve de mudar alguma coisa e `ok` onde a máquina já estava certa.
Duas linhas da tarefa de contas dizem `ok`: `suporte` foi criado no grupo 0 e nunca teve grupo
próprio, então não havia linha a tirar de `/etc/group` nem de `/etc/gshadow`. O resumo conta oito
mudanças, as seis tarefas e os dois handlers que elas acionaram.

## A segunda execução é o teste

Um playbook só é seguro de agendar se rodá-lo numa máquina que já está certa não muda nada. Essa
propriedade se chama **idempotência**, e a segunda execução a confere:

```
ana@admin:~$ ansible-playbook -i hosts.ini harden.yml | tail -2
web                        : ok=7    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

`changed=0`. Sete tarefas rodaram, a coleta de fatos e as seis do playbook, acharam todos os estados
já verdadeiros e não mexeram em nada, então nenhum handler disparou e nenhum serviço reiniciou. Um
playbook cuja segunda execução informa mudanças está ou brigando com outra ferramenta pelo mesmo
arquivo ou escrito como comandos e não como estados, e em qualquer dos casos não deve rodar sem
supervisão.

Depois pergunte à máquina, com a verificação da última seção, que não sabe nada de Ansible:

```
ana@web:~$ sudo bash check.sh; echo "failed: $?"
PASS JAT-01 only root has user id 0
PASS JAT-02 nothing listens for telnet
PASS JAT-03 no FTP server is installed
PASS JAT-04 root may not log in over SSH
PASS JAT-05 SSH refuses passwords
PASS JAT-06 the intern's password is locked
PASS JAT-07 nginx hides its version
failed: 0
```

Os sete passam. **Correção e verificação são dois programas separados de propósito**: um playbook só
sabe dizer o que fez, e uma verificação diz o que é verdade. O Lynis, rodado de novo:

```
ana@web:~$ sudo lynis audit system --quick --no-colors > lynis.txt 2>&1; grep -E "Hardening index|Tests performed" lynis.txt
  Hardening index : 69 [#############       ]
  Tests performed : 257
ana@web:~$ sudo grep '^warning' /var/log/lynis-report.dat | cut -d'|' -f1,2
warning[]=PKGS-7392|Found one or more vulnerable packages.
warning[]=NETW-2704|Nameserver 8.8.8.8 does not respond
warning[]=NETW-2704|Nameserver 8.8.4.4 does not respond
warning[]=NETW-2705|Couldn't find 2 responsive nameservers
warning[]=FIRE-4512|iptables module(s) loaded, but no rules active
warning[]=FINT-4315|No AIDE configuration file was found, needed for AIDE functionality
```

Os dois avisos sobre o segundo root sumiram. O índice de endurecimento não se mexeu: 69 de novo,
agora sobre 257 testes em vez de 259, porque dois testes ficaram sem nada para olhar depois que os
serviços foram removidos. Esse é o limite do índice numa linha. Ele é aritmética sobre o que a
ferramenta contou, e **uma linha de base é julgada pelos controles passando, não por uma nota
subindo.** Os avisos que sobram são a internet que o laboratório não tem, o firewall que a aula 5
acrescenta, os pacotes de que a aula 16 trata e o banco de integridade que a aula 11 monta.
