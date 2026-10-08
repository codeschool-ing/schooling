---
title: Roles, a unidade que você reaproveita
version: 2
---

O `site.yml` agora guarda as tarefas, o handler, dois templates e as variáveis de que eles precisam,
para um propósito só: um servidor web para a loja. Um segundo playbook que quisesse o mesmo servidor
web teria de copiar tudo. Um **role** empacota essas peças num diretório com estrutura fixa, para que
uma play possa dizer *aplique o role web* numa linha. Ele está para o Ansible como um módulo está
para o Terraform na aula 10.

O `ansible-galaxy` cria a estrutura, sem precisar de rede:

```
ana@laptop:~/shop/ansible$ ansible-galaxy role init --init-path roles web
- Role web was created successfully
ana@laptop:~/shop/ansible$ tree roles
roles
└── web
    ├── README.md
    ├── defaults
    │   └── main.yml
    ├── files
    ├── handlers
    │   └── main.yml
    ├── meta
    │   └── main.yml
    ├── tasks
    │   └── main.yml
    ├── templates
    ├── tests
    │   ├── inventory
    │   └── test.yml
    └── vars
        └── main.yml

10 directories, 8 files
```

Cada diretório tem um trabalho, e o Ansible acha os arquivos pelo lugar onde estão, então o role não
precisa de uma lista do próprio conteúdo:

| diretório | o que vai nele |
| --- | --- |
| `tasks/main.yml` | as tarefas, em ordem |
| `handlers/main.yml` | os handlers que essas tarefas notificam |
| `templates/` | templates Jinja2; o `src:` os acha aqui sem caminho |
| `files/` | arquivos copiados como estão |
| `defaults/main.yml` | as variáveis do role com seus valores padrão, as mais fracas de todas |
| `vars/main.yml` | variáveis que o role define para si, que os usuários não devem mudar |
| `meta/main.yml` | o autor, as plataformas e os roles de que este depende |
| `tests/`, `README.md` | um inventário e uma play de exemplo, e a documentação |

**`defaults` contra `vars` é a interface do role.** Um default é um valor que quem chama deve
sobrescrever, e é por isso que ele perde para quase tudo; uma entrada em `vars` vence o inventário e
as variáveis de grupo, então o que está lá fica, na prática, fixo. As variáveis da Ana são coisas
que quem chama deve escolher, então vão em `defaults`:

```yaml
shop_server_name: shop.example.com
shop_root: /var/www/shop
```

As tarefas se mudam sem alteração, com um nível de indentação a menos porque não estão mais dentro
de uma play:

```yaml
- name: Install nginx
  ansible.builtin.apt:
    name: nginx
    state: present
    update_cache: true
    cache_valid_time: 3600

- name: Create the site's directory
  ansible.builtin.file:
    path: "{{ shop_root }}"
    state: directory
    mode: "0755"

- name: Write the index page
  ansible.builtin.template:
    src: index.html.j2
    dest: "{{ shop_root }}/index.html"
    mode: "0644"

- name: Configure the shop's site
  ansible.builtin.template:
    src: shop.conf.j2
    dest: /etc/nginx/sites-available/default
    mode: "0644"
  notify: Reload nginx

- name: Start nginx
  ansible.builtin.service:
    name: nginx
    state: started
```

```yaml
- name: Reload nginx
  ansible.builtin.service:
    name: nginx
    state: reloaded
```

Os dois templates vão para `roles/web/templates/` como estão, e o playbook encolhe para aquilo de que
devia tratar desde o começo, quais hosts recebem qual role:

```yaml
- name: Web servers
  hosts: web
  become: true
  roles:
    - web
```

**Uma reestruturação que não muda nada nas máquinas deveria provar isso**, e aqui a prova é uma
execução:

```
ana@laptop:~/shop/ansible$ ansible-playbook site.yml

PLAY [Web servers] *************************************************************

TASK [Gathering Facts] *********************************************************
ok: [web2]
ok: [web1]

TASK [web : Install nginx] *****************************************************
ok: [web1]
ok: [web2]

TASK [web : Create the site's directory] ***************************************
ok: [web1]
ok: [web2]

TASK [web : Write the index page] **********************************************
ok: [web1]
ok: [web2]

TASK [web : Configure the shop's site] *****************************************
ok: [web1]
ok: [web2]

TASK [web : Start nginx] *******************************************************
ok: [web2]
ok: [web1]

PLAY RECAP *********************************************************************
web1                       : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

`changed=0` nos dois hosts. Os nomes das tarefas agora carregam o role, `web : Install nginx`, que é
como você distingue, numa execução longa, de qual role veio uma tarefa. Ela também mostra a
precedência da seção anterior funcionando: o default `shop_server_name` do role não tem o `www`, e
o `group_vars/web.yml` continua tendo. Se o default tivesse vencido, a configuração teria sido
reescrita e o nginx recarregado; nada mudou, então a variável de grupo venceu.

### Roles que outra pessoa escreveu

O mesmo comando, `ansible-galaxy`, instala roles e **coleções** (collections), os pacotes maiores de
módulos e roles, do Ansible Galaxy ou de um repositório git, fixados num `requirements.yml`. Nada foi
instalado do Galaxy para esta aula, que usa o `ansible-core` e só os módulos que vêm com ele. O
conselho da aula 10 sobre o Terraform Registry vale sem mudança: fixe uma versão, e leia um role
antes de rodá-lo com `become`, porque cada tarefa dele roda como root nas suas máquinas.
