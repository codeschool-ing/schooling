---
title: Variáveis, templates e handlers
version: 1
---

Até aqui o site é um arquivo fixo copiado para as duas máquinas. Uma configuração de verdade difere
em detalhes entre grupos e entre hosts, e mudá-la tem uma consequência: o nginx lê a configuração
quando inicia ou recarrega, não quando o arquivo muda. Esta seção responde às duas coisas.

**As variáveis de um grupo moram em `group_vars/`**, num arquivo com o nome do grupo. Todo host de
`web` recebe estas duas:

```yaml
shop_server_name: shop.example.com
shop_root: /var/www/shop
```

Um **template** é um arquivo com buracos, preenchidos por host quando a tarefa roda. Os templates do
Ansible são Jinja2: `{{ name }}` é trocado pelo valor da variável. A configuração do site:

```
# Written by Ansible from templates/shop.conf.j2. Edits here are overwritten.
server {
    listen 80 default_server;
    server_name {{ shop_server_name }};
    root {{ shop_root }};

    location / {
        try_files $uri $uri/ =404;
    }
}
```

E a página inicial, que usa uma variável que ninguém declarou. `inventory_hostname` é uma que o
Ansible fornece: o nome do host como o inventário o escreve.

```
<h1>shop</h1>
<p>served by {{ inventory_hostname }}</p>
```

O playbook agora renderiza os dois, e a tarefa que escreve a configuração do nginx **notifica um
handler**:

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

  handlers:
    - name: Reload nginx
      ansible.builtin.service:
        name: nginx
        state: reloaded
```

Um **handler** é uma tarefa que só roda quando é notificada, e uma vez só, no fim da play. Se a
tarefa de configuração informa `changed`, o nginx é recarregado depois de todo o resto; se informa
`ok`, nada acontece. Recarregar a cada execução seria inofensivo em duas máquinas e continuaria
errado, porque faz toda execução apontar uma mudança, que é o problema da seção anterior outra vez.

```
ana@laptop:~/shop/ansible$ ansible-playbook site.yml

PLAY [Web servers] *************************************************************

TASK [Gathering Facts] *********************************************************
ok: [web1]
ok: [web2]

TASK [Install nginx] ***********************************************************
ok: [web1]
ok: [web2]

TASK [Create the site's directory] *********************************************
changed: [web1]
changed: [web2]

TASK [Write the index page] ****************************************************
changed: [web2]
changed: [web1]

TASK [Configure the shop's site] ***********************************************
changed: [web2]
changed: [web1]

TASK [Start nginx] *************************************************************
ok: [web2]
ok: [web1]

RUNNING HANDLER [Reload nginx] *************************************************
changed: [web2]
changed: [web1]

PLAY RECAP *********************************************************************
web1                       : ok=7    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=7    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

O arquivo de configuração mudou, da versão copiada para a renderizada, então o handler rodou. Cada
host agora serve a própria página a partir do mesmo template:

```
ana@laptop:~/shop/ansible$ curl -s http://web1/
<h1>shop</h1>
<p>served by web1</p>
ana@laptop:~/shop/ansible$ curl -s http://web2/
<h1>shop</h1>
<p>served by web2</p>
```

Rode de novo, e o resumo vem logo depois de `Start nginx`, sem handler entre os dois, porque nada o
notificou:

```
TASK [Start nginx] *************************************************************
ok: [web1]
ok: [web2]

PLAY RECAP *********************************************************************
web1                       : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas execuções da mesma play, lado a lado. Na primeira, a tarefa que configura o site informa changed e notifica o handler; o handler roda uma vez, depois de todas as tarefas, e recarrega o nginx. Na segunda, todas as tarefas informam ok, nada notifica e o handler não roda.\"><defs><marker id=\"hd-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"180.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma execução em que o arquivo mudou</text><rect x=\"20\" y=\"42\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"59.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Install nginx</text><text x=\"300.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">ok</text><rect x=\"20\" y=\"86\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Write the index page</text><text x=\"300.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">ok</text><rect x=\"20\" y=\"130\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Configure the shop's site</text><text x=\"300.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">changed</text><rect x=\"20\" y=\"174\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Start nginx</text><text x=\"300.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">ok</text><rect x=\"20\" y=\"238\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"251.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">RUNNING HANDLER</text><text x=\"30.0\" y=\"267.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Reload nginx</text><path d=\"M250 147 L270 147 L270 258 L252 258\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#hd-ah-amber)\"></path><text x=\"305.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">notify</text><text x=\"300.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">changed</text><text x=\"540.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a execução seguinte</text><rect x=\"380\" y=\"42\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"59.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Install nginx</text><text x=\"660.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">ok</text><rect x=\"380\" y=\"86\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Write the index page</text><text x=\"660.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">ok</text><rect x=\"380\" y=\"130\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Configure the shop's site</text><text x=\"660.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">ok</text><rect x=\"380\" y=\"174\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Start nginx</text><text x=\"660.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">ok</text><rect x=\"380\" y=\"238\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"390.0\" y=\"251.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">(no handler)</text><text x=\"390.0\" y=\"267.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Reload nginx</text><text x=\"660.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não roda</text><text x=\"360.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o handler espera o fim da play e roda uma vez, quantas tarefas o tenham notificado</text></svg>", "caption": "Um handler roda no fim da play, e só quando uma tarefa que o notifica informou uma mudança.", "same": ["notify"]}
```

Agora uma mudança de verdade: a loja também responde em `www`. A Ana edita a variável, não o
template, e roda com `--diff` para ver o que isso significa nas máquinas:

```
ana@laptop:~/shop/ansible$ cat group_vars/web.yml
shop_server_name: shop.example.com www.shop.example.com
shop_root: /var/www/shop
ana@laptop:~/shop/ansible$ ansible-playbook site.yml --diff

PLAY [Web servers] *************************************************************

TASK [Gathering Facts] *********************************************************
ok: [web1]
ok: [web2]

TASK [Install nginx] ***********************************************************
ok: [web2]
ok: [web1]

TASK [Create the site's directory] *********************************************
ok: [web2]
ok: [web1]

TASK [Write the index page] ****************************************************
ok: [web1]
ok: [web2]

TASK [Configure the shop's site] ***********************************************
--- before: /etc/nginx/sites-available/default
+++ after: /home/ana/.ansible/tmp/ansible-local-5971afgvyntr/tmpieyt_7wq/shop.conf.j2
@@ -1,7 +1,7 @@
 # Written by Ansible from templates/shop.conf.j2. Edits here are overwritten.
 server {
     listen 80 default_server;
-    server_name shop.example.com;
+    server_name shop.example.com www.shop.example.com;
     root /var/www/shop;
 
     location / {

changed: [web2]
--- before: /etc/nginx/sites-available/default
+++ after: /home/ana/.ansible/tmp/ansible-local-5971afgvyntr/tmpk2__edua/shop.conf.j2
@@ -1,7 +1,7 @@
 # Written by Ansible from templates/shop.conf.j2. Edits here are overwritten.
 server {
     listen 80 default_server;
-    server_name shop.example.com;
+    server_name shop.example.com www.shop.example.com;
     root /var/www/shop;
 
     location / {

changed: [web1]

TASK [Start nginx] *************************************************************
ok: [web1]
ok: [web2]

RUNNING HANDLER [Reload nginx] *************************************************
changed: [web2]
changed: [web1]

PLAY RECAP *********************************************************************
web1                       : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

**Uma variável, uma linha renderizada, um reload por host.** O diff aponta a linha no arquivo real, e
o resumo conta duas mudanças em cada host: o arquivo e o handler.

### De onde uma variável pode vir

Variáveis podem ser definidas em muitos lugares, e quando dois definem o mesmo nome, um vence por uma
ordem de precedência fixa que a documentação do Ansible lista inteira. Os lugares que esta aula usa,
do mais fraco ao mais forte: os `defaults` de um role (a próxima seção), o `[all:vars]` do
inventário, `group_vars/`, `host_vars/<host>.yml` para uma máquina, e `-e` na linha de comando, que
vence tudo, como venceu com `ansible_user=root` na seção do inventário. O hábito que mantém isso
legível é definir cada variável em **um** lugar e deixar o `-e` para execuções pontuais.
