---
title: Rodar duas vezes, de propósito
version: 1
---

O teste de um playbook é a segunda execução. Nada mudou nas máquinas desde a primeira, então um
playbook que descreve um estado deveria encontrar todas as tarefas já verdadeiras:

```
ana@laptop:~/shop/ansible$ ansible-playbook site.yml

PLAY [Web servers] *************************************************************

TASK [Gathering Facts] *********************************************************
ok: [web1]
ok: [web2]

TASK [Install nginx] ***********************************************************
ok: [web1]
ok: [web2]

TASK [Write the index page] ****************************************************
ok: [web2]
ok: [web1]

TASK [Configure the site] ******************************************************
ok: [web2]
ok: [web1]

TASK [Start nginx] *************************************************************
ok: [web2]
ok: [web1]

PLAY RECAP *********************************************************************
web1                       : ok=5    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=5    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

**`changed=0` em todos os hosts é o resultado a buscar**, a mesma propriedade que a aula 1 nomeou para
o `terraform apply`: rode duas vezes, e a segunda não faz nada. É também o que torna útil a próxima
execução. Dias depois, um colega edita à mão a página no `web1`, por `ssh`, de outra máquina:

```
ana@laptop:~/shop/ansible$ curl -s http://web1/
<h1>shop (closed for stocktaking)</h1>
```

A Ana roda o mesmo playbook de novo, sem nada novo nele:

```
ana@laptop:~/shop/ansible$ ansible-playbook site.yml

PLAY [Web servers] *************************************************************

TASK [Gathering Facts] *********************************************************
ok: [web1]
ok: [web2]

TASK [Install nginx] ***********************************************************
ok: [web2]
ok: [web1]

TASK [Write the index page] ****************************************************
ok: [web2]
changed: [web1]

TASK [Configure the site] ******************************************************
ok: [web2]
ok: [web1]

TASK [Start nginx] *************************************************************
ok: [web2]
ok: [web1]

PLAY RECAP *********************************************************************
web1                       : ok=5    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=5    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

```
ana@laptop:~/shop/ansible$ curl -s http://web1/
<h1>shop</h1>
```

**Uma mudança, num host, numa tarefa.** O playbook recolocou o que descreve e deixou o `web2` em paz,
porque lá não havia nada a recolocar. Essa é a resposta da gerência de configuração ao drift da
aula 1: rode a descrição com frequência e as máquinas convergem para ela. Ela tem um limite que vale
dizer com todas as letras. O Ansible confere **só o que o playbook menciona**. Um arquivo de que
ele nunca soube, um pacote que alguém instalou à mão, um cron que ninguém anotou: isso fica, e
nenhuma execução aponta. Não existe um arquivo de estado listando o que o Ansible criou, então
apagar uma tarefa não remove nada das máquinas; para remover algo, você escreve uma tarefa que diz
que aquilo está `absent`.

### Uma tarefa que sempre diz changed

Um playbook só fica em `changed=0` se toda tarefa for honesta. Aqui está uma que não é, uma
verificação da configuração do nginx com `command`:


```
TASK [Test the configuration] **************************************************
changed: [web2]
changed: [web1]

PLAY RECAP *********************************************************************
web1                       : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Essa é a segunda execução, e toda execução sai igual. O `nginx -t` não muda nada, mas o `command`
não tem como saber. **Uma tarefa que aponta uma mudança que não fez esconde as que importam**,
porque ninguém lê um resumo que nunca dá zero. Diga ao Ansible o que conta como mudança:


```
ana@laptop:~/shop/ansible$ ansible-playbook check.yml

PLAY [Check nginx's configuration] *********************************************

TASK [Gathering Facts] *********************************************************
ok: [web2]
ok: [web1]

TASK [Test the configuration] **************************************************
ok: [web1]
ok: [web2]

PLAY RECAP *********************************************************************
web1                       : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Para um comando que de fato cria algo, `creates` nomeia o arquivo que ele cria, e a tarefa é pulada
quando esse arquivo já existe. Um certificado autoassinado é feito uma vez e depois deixado em paz:

```yaml
- name: A certificate for the shop
  hosts: web
  become: true
  tasks:
    - name: Make a self-signed certificate, once
      ansible.builtin.command:
        cmd: >-
          openssl req -x509 -newkey rsa:2048 -nodes -days 365 -subj /CN=shop
          -keyout /etc/ssl/private/shop.key -out /etc/ssl/certs/shop.crt
        creates: /etc/ssl/certs/shop.crt
```

```
TASK [Make a self-signed certificate, once] ************************************
changed: [web2]
changed: [web1]

PLAY RECAP *********************************************************************
web1                       : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

```
ana@laptop:~/shop/ansible$ ansible-playbook cert.yml

PLAY [A certificate for the shop] **********************************************

TASK [Gathering Facts] *********************************************************
ok: [web1]
ok: [web2]

TASK [Make a self-signed certificate, once] ************************************
ok: [web2]
ok: [web1]

PLAY RECAP *********************************************************************
web1                       : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

### Perguntar antes de fazer

`--check` roda o playbook sem mudar nada e informa o que mudaria; `--diff` mostra como cada arquivo
ficaria diferente. A Ana edita o texto da página no `site.yml` e pergunta antes:

```
ana@laptop:~/shop/ansible$ grep h1 site.yml
        content: "<h1>shop, now open</h1>\n"
ana@laptop:~/shop/ansible$ ansible-playbook site.yml --check --diff

PLAY [Web servers] *************************************************************

TASK [Gathering Facts] *********************************************************
ok: [web2]
ok: [web1]

TASK [Install nginx] ***********************************************************
ok: [web1]
ok: [web2]

TASK [Write the index page] ****************************************************
--- before: /var/www/html/index.html
+++ after: /var/www/html/index.html
@@ -1 +1 @@
-<h1>shop</h1>
+<h1>shop, now open</h1>

changed: [web2]
--- before: /var/www/html/index.html
+++ after: /var/www/html/index.html
@@ -1 +1 @@
-<h1>shop</h1>
+<h1>shop, now open</h1>

changed: [web1]

TASK [Configure the site] ******************************************************
ok: [web1]
ok: [web2]

TASK [Start nginx] *************************************************************
ok: [web2]
ok: [web1]

PLAY RECAP *********************************************************************
web1                       : ok=5    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=5    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

```
ana@laptop:~/shop/ansible$ curl -s http://web1/
<h1>shop</h1>
```

**O `--check` é o plan do Ansible**, e como o do Terraform ele só é tão bom quanto a capacidade de
cada módulo de prever. O `copy` consegue comparar dois arquivos; um módulo que roda um programa não
tem como saber o que o programa faria, então um playbook cheio de tarefas `command` ganha uma
verificação que diz pouco.
