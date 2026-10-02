---
title: Variables, templates and handlers
version: 1
---

The site so far is a fixed file copied to both machines. A real configuration differs in small
ways between groups and between hosts, and changing it has a consequence: nginx reads its
configuration when it starts or reloads, not when the file changes. This section answers both.

**Variables for a group live in `group_vars/`**, in a file named after the group. Every host in
`web` gets these two:

```yaml
shop_server_name: shop.example.com
shop_root: /var/www/shop
```

A **template** is a file with holes in it, filled in per host when the task runs. Ansible's
templates are Jinja2: `{{ name }}` is replaced by the variable's value. The site's configuration:

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

And the index page, which uses a variable nobody declared. `inventory_hostname` is one Ansible
provides: the host's name as the inventory spells it.

```
<h1>shop</h1>
<p>served by {{ inventory_hostname }}</p>
```

The playbook now renders both, and the task that writes nginx's configuration **notifies a
handler**:


A **handler** is a task that runs only when notified, and only once, at the end of the play. If the
configuration task reports `changed`, nginx is reloaded after everything else; if it reports `ok`,
nothing happens. Reloading on every run would be harmless on two machines and would still be wrong,
since it makes every run report a change, which is the previous section's problem again.

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

The configuration file changed, from the copied version to the rendered one, so the handler ran.
Each host now serves its own page from the same template:

```
ana@laptop:~/shop/ansible$ curl -s http://web1/
<h1>shop</h1>
<p>served by web1</p>
ana@laptop:~/shop/ansible$ curl -s http://web2/
<h1>shop</h1>
<p>served by web2</p>
```

Run it again, and the recap follows `Start nginx` with no handler between them, because nothing notified it:

```
TASK [Start nginx] *************************************************************
ok: [web1]
ok: [web2]

PLAY RECAP *********************************************************************
web1                       : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two runs of the same play, side by side. In the first, the task that configures the site reports changed and notifies the handler; the handler runs once, after every task, and reloads nginx. In the second run every task reports ok, nothing notifies, and the handler does not run.\"><defs><marker id=\"hd-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"180.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a run where the file changed</text><rect x=\"20\" y=\"42\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"59.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Install nginx</text><text x=\"300.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">ok</text><rect x=\"20\" y=\"86\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Write the index page</text><text x=\"300.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">ok</text><rect x=\"20\" y=\"130\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Configure the shop's site</text><text x=\"300.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">changed</text><rect x=\"20\" y=\"174\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Start nginx</text><text x=\"300.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">ok</text><rect x=\"20\" y=\"238\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"251.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">RUNNING HANDLER</text><text x=\"30.0\" y=\"267.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Reload nginx</text><path d=\"M250 147 L270 147 L270 258 L252 258\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#hd-ah-amber)\"></path><text x=\"305.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">notify</text><text x=\"300.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">changed</text><text x=\"540.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the next run</text><rect x=\"380\" y=\"42\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"59.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Install nginx</text><text x=\"660.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">ok</text><rect x=\"380\" y=\"86\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Write the index page</text><text x=\"660.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">ok</text><rect x=\"380\" y=\"130\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Configure the shop's site</text><text x=\"660.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">ok</text><rect x=\"380\" y=\"174\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Start nginx</text><text x=\"660.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">ok</text><rect x=\"380\" y=\"238\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"390.0\" y=\"251.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">(no handler)</text><text x=\"390.0\" y=\"267.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Reload nginx</text><text x=\"660.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">not run</text><text x=\"360.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the handler waits for the end of the play, and runs once however many tasks notified it</text></svg>", "caption": "A handler runs at the end of the play, and only when a task that notifies it reported a change."}
```

Now a real change: the shop also answers on `www`. Ana edits the variable, not the template, and
runs with `--diff` to see what that means on the machines:

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

**One variable, one rendered line, one reload per host.** The diff names the line in the real file,
and the recap counts two changes on each host: the file and the handler.

### Where a variable can come from

Variables can be set in many places, and when two set the same name, one wins by a fixed order of
precedence that the Ansible documentation lists in full. The places this lesson uses, from weakest
to strongest: a role's `defaults` (the next section), the inventory's `[all:vars]`, `group_vars/`,
`host_vars/<host>.yml` for one machine, and `-e` on the command line, which beats everything, as
it did with `ansible_user=root` in the inventory section. The habit that keeps this readable is to
set each variable in **one** place and keep `-e` for one-off runs.
