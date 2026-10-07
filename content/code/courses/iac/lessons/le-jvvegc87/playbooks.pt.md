---
title: Um playbook, e como ler o que ele imprimiu
version: 2
---

Um **playbook** é um arquivo YAML com uma ou mais **plays**. Uma play nomeia um grupo de hosts e
uma lista de **tarefas** (tasks); cada tarefa chama um módulo com seus argumentos, exatamente como
`-m` e `-a` faziam na linha de comando, e tem um nome que uma pessoa consegue ler. O primeiro
playbook da Ana transforma os dois servidores web em servidores web:

```yaml
- name: Web servers
  hosts: web
  become: true
  tasks:
    - name: Install nginx
      ansible.builtin.apt:
        name: nginx
        state: present
        update_cache: true
        cache_valid_time: 3600

    - name: Write the index page
      ansible.builtin.copy:
        dest: /var/www/html/index.html
        content: "<h1>shop</h1>\n"
        mode: "0644"

    - name: Configure the site
      ansible.builtin.copy:
        dest: /etc/nginx/sites-available/default
        content: |
          server {
              listen 80 default_server;
              root /var/www/html;
          }
        mode: "0644"

    - name: Start nginx
      ansible.builtin.service:
        name: nginx
        state: started
```

Leia como uma descrição, não como um script. *O nginx está presente*, *este arquivo tem este
conteúdo*, *o serviço está iniciado*. Cada módulo descobre se aquilo já é verdade e só age se não
for. `become: true` na play faz toda tarefa usar `sudo`. Os módulos estão escritos com o nome
completo, `ansible.builtin.apt` em vez de `apt`, que é como a documentação atual do Ansible os
escreve e que diz exatamente de onde cada um vem quando outras coleções estão instaladas.

`cache_valid_time: 3600` quer dizer que as listas de pacotes só são atualizadas se tiverem mais de
uma hora, então uma segunda execução não as baixa de novo. A tarefa `Configure the site` troca o
site padrão do Ubuntu por um bloco server de três linhas, o bastante para o nginx servir a página.

```
ana@laptop:~/shop/ansible$ ansible-playbook site.yml

PLAY [Web servers] *************************************************************

TASK [Gathering Facts] *********************************************************
ok: [web1]
ok: [web2]

TASK [Install nginx] ***********************************************************
changed: [web2]
changed: [web1]

TASK [Write the index page] ****************************************************
changed: [web2]
changed: [web1]

TASK [Configure the site] ******************************************************
changed: [web2]
changed: [web1]

TASK [Start nginx] *************************************************************
changed: [web2]
changed: [web1]

PLAY RECAP *********************************************************************
web1                       : ok=5    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=5    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

**A saída é um cabeçalho por tarefa, e embaixo dele uma linha por host.** As tarefas rodam em ordem,
e todos os hosts terminam uma tarefa antes que qualquer host comece a seguinte, então a ordem das
tarefas é a do arquivo; a ordem dos hosts dentro de uma tarefa é a de quem terminou primeiro.
`Gathering Facts` é uma tarefa que ninguém escreveu: antes da primeira, o Ansible coleta o que
consegue saber de cada máquina, distribuição, endereços, memória, em variáveis que a play pode usar.

O **PLAY RECAP** é a linha para ler primeiro:

- `ok=5` são todas as tarefas que deram certo naquele host, os fatos incluídos, tenham ou não mudado
  alguma coisa;
- `changed=4` é quantas dessas cinco mudaram algo: um pacote, dois arquivos e um serviço que não
  estava rodando e agora está;
- `unreachable` e `failed` são as duas falhas da seção do inventário, um host em que o Ansible não
  conseguiu entrar e uma tarefa que deu errado num host em que conseguiu;
- `skipped`, `rescued` e `ignored` contam tarefas que uma condição pulou e falhas que a play foi
  escrita para tratar, coisa que este playbook não usa.

O `ok` inclui o `changed`, o que surpreende na primeira vez: quatro das cinco tarefas bem-sucedidas
mudaram algo, e uma, a dos fatos, não.

**Quando uma tarefa falha num host, aquele host para e os outros seguem.** A play não desfaz nada: o
que as tarefas anteriores fizeram naquele host continua feito, como um `apply` pela metade fica no
estado do Terraform na aula 9, e a próxima execução começa de novo do topo e encontra essas tarefas
já satisfeitas.

E o resultado, visto do laptop:

```
ana@laptop:~/shop/ansible$ curl -s http://web1/
<h1>shop</h1>
```

Um playbook pode ter várias plays, uma para o grupo `web` e outra para `db`, e as roda em ordem. O
da Ana tem uma, porque o `db1` ainda não tem nada para fazer nesta aula.
