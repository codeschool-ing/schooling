---
title: O inventário, e como o Ansible chega a uma máquina
version: 2
---

O Terraform termina onde começa o sistema operacional. A aula 1 traçou a linha: a API da nuvem
consegue criar uma máquina e não enxerga quais pacotes estão nela, o que há em `/etc/nginx` ou se um
serviço está rodando. **O Ansible trabalha do outro lado dessa linha**, e chega lá do jeito que você
chegaria à mão: entra por SSH e roda alguma coisa.

A primeira imagem que muita gente tem é a de um servidor no meio e um agente em cada máquina, do
jeito que se monta um sistema de monitoramento. O Ansible não tem nem um nem outro. **Ele roda no
laptop da Ana, que o Ansible chama de nó de controle**, e precisa de duas coisas em cada máquina que
gerencia: um servidor SSH que aceite a chave dela, e Python, a linguagem dos pequenos programas que
ele envia. O Ubuntu já vem com os dois. Nada do Ansible fica instalado lá, e nada roda entre dois
comandos dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"O laptop da Ana guarda o Ansible, o inventário e o playbook. Dele saem três conexões SSH, uma para cada máquina: web1 e web2 no grupo web, db1 no grupo db. Cada máquina roda só o sshd e o Python; nada do Ansible fica instalado nela.\"><defs><marker id=\"ps-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"230\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">laptop da Ana</text><text x=\"135.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o nó de controle</text><text x=\"135.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ansible-playbook</text><text x=\"135.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inventory.ini</text><text x=\"135.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">site.yml</text><text x=\"135.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">tudo mora aqui</text><text x=\"470.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">[web]</text><text x=\"470.0\" y=\"203.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">[db]</text><rect x=\"470\" y=\"50\" width=\"210\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">web1</text><text x=\"575.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sshd e Python, mais nada</text><path d=\"M250 140 L360 140 L360 74 L468 74\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ps-ah-phosphor)\"></path><rect x=\"470\" y=\"115\" width=\"210\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"131.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">web2</text><text x=\"575.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sshd e Python, mais nada</text><path d=\"M250 140 L360 140 L360 139 L468 139\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ps-ah-phosphor)\"></path><rect x=\"470\" y=\"215\" width=\"210\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">db1</text><text x=\"575.0\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sshd e Python, mais nada</text><path d=\"M250 140 L360 140 L360 239 L468 239\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ps-ah-phosphor)\"></path><text x=\"320.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">SSH</text></svg>", "caption": "O Ansible empurra: tudo de que ele precisa está no laptop, e cada máquina é alcançada por SSH quando um comando roda.", "same": ["SSH"]}
```

As máquinas são as três que a seção anterior construiu, `web1`, `web2` e `db1`: Ubuntu 24.04 com
`sshd` e um usuário `deploy` que pode usar `sudo`. São reais o bastante para tudo o que o Ansible
faz. O moto não entra aqui, porque o moto não roda máquina nenhuma.

O primeiro arquivo é o **inventário**: quais máquinas existem e a quais grupos pertencem.

```ini
[web]
web1
web2

[db]
db1

[all:vars]
ansible_user=deploy
ansible_python_interpreter=/usr/bin/python3
```

Um nome entre colchetes é um grupo, e cada linha abaixo dele é um host. `[all:vars]` define
variáveis para todos os hosts: o usuário com que entrar e onde está o Python. Essa segunda linha não
é enfeite. Sem ela o Ansible procura um interpretador em cada máquina, acha um e imprime, a cada
comando, o aviso de que um Python instalado depois poderia ser encontrado no lugar; nomeá-lo diz
qual você quis. Um `ansible.cfg` pequeno ao lado do inventário poupa digitar `-i inventory.ini` em
todo comando:

```ini
[defaults]
inventory = inventory.ini
```

Como a conexão é SSH puro, valem as regras do SSH puro, inclusive as chaves de host. A Ana confia nas
chaves das três máquinas uma vez, antes do primeiro comando. Em máquinas que não foi você que acabou
de criar, compare as impressões digitais com o que o console da máquina mostra antes de confiar
nelas. E depois de cada execução do `up.sh`, que cria máquinas com chaves novas, esqueça antes as
antigas com `ssh-keygen -R web1`, e o mesmo para `web2` e `db1`; senão o SSH recusa, avisando que a
identificação da máquina mudou.

```
ana@laptop:~/shop/ansible$ ssh-keyscan -t ed25519 web1 web2 db1 >> ~/.ssh/known_hosts 2>/dev/null
```

Agora a pergunta com que toda sessão de Ansible começa: eu consigo alcançá-las?

```
ana@laptop:~/shop/ansible$ ansible all -m ping
db1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
web2 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
web1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

**O `ping` aqui não é o ping de rede.** É um módulo: o Ansible entrou como `deploy`, rodou um
programa Python minúsculo em cada máquina e recebeu `pong` de volta, o que prova que o login por SSH
e o interpretador funcionam. Os hosts responderam na ordem em que terminaram, e é por isso que o
`db1` aparece primeiro e o `web1` por último; uma segunda execução pode imprimi-los em outra ordem.

O `ansible-inventory` mostra como o Ansible leu o arquivo, como árvore ou na forma YAML em que um
inventário também pode ser escrito:

```
ana@laptop:~/shop/ansible$ ansible-inventory --graph
@all:
  |--@ungrouped:
  |--@web:
  |  |--web1
  |  |--web2
  |--@db:
  |  |--db1
```

```
ana@laptop:~/shop/ansible$ ansible-inventory --list --yaml
all:
  children:
    db:
      hosts:
        db1:
          ansible_python_interpreter: /usr/bin/python3
          ansible_user: deploy
    web:
      hosts:
        web1:
          ansible_python_interpreter: /usr/bin/python3
          ansible_user: deploy
        web2:
          ansible_python_interpreter: /usr/bin/python3
          ansible_user: deploy
```

O YAML mostra algo que o arquivo INI esconde: no fim, as variáveis pertencem aos hosts. O
`[all:vars]` foi copiado para cada um dos três.

**Uma máquina em que não se consegue entrar fica UNREACHABLE, o que não é o mesmo que FAILED.**
Pedindo `root` em vez de `deploy`, cuja chave não está autorizada lá:

```
ana@laptop:~/shop/ansible$ ansible db1 -m ping -e ansible_user=root
[ERROR]: Task failed: Failed to connect to the host via ssh: root@db1: Permission denied (publickey,password).
Origin: <adhoc 'ping' task>

{'action': 'ping', 'args': {}, 'timeout': 0, 'async_val': 0, 'poll': 15}

db1 | UNREACHABLE! => {
    "changed": false,
    "msg": "Task failed: Failed to connect to the host via ssh: root@db1: Permission denied (publickey,password).",
    "unreachable": true
}
```

UNREACHABLE quer dizer que o Ansible nem chegou a rodar nada; FAILED, que a próxima seção mostra,
quer dizer que ele entrou e a tarefa deu errado. A distinção volta em todo resumo que o Ansible
imprime.
