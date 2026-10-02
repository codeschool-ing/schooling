---
title: Running it twice, on purpose
version: 1
---

The test of a playbook is the second run. Nothing has changed on the machines since the first, so a
playbook that describes a state should find every task already true:

```
ana@laptop:~/shop/ansible$ ansible-playbook site.yml

PLAY [Web servers] *************************************************************

TASK [Gathering Facts] *********************************************************
ok: [web2]
ok: [web1]

TASK [Install nginx] ***********************************************************
ok: [web2]
ok: [web1]

TASK [Write the index page] ****************************************************
ok: [web1]
ok: [web2]

TASK [Configure the site] ******************************************************
ok: [web1]
ok: [web2]

TASK [Start nginx] *************************************************************
ok: [web1]
ok: [web2]

PLAY RECAP *********************************************************************
web1                       : ok=5    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=5    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

**`changed=0` on every host is the result to aim for**, the same property lesson 1 named for
`terraform apply`: run it twice, and the second time does nothing. It is also what makes the next
run useful. Some days later a colleague edits the page on `web1` by hand, over `ssh`, from another
machine:

```
ana@laptop:~/shop/ansible$ curl -s http://web1/
<h1>shop (closed for stocktaking)</h1>
```

Ana runs the same playbook again, with nothing new in it:

```
ana@laptop:~/shop/ansible$ ansible-playbook site.yml

PLAY [Web servers] *************************************************************

TASK [Gathering Facts] *********************************************************
ok: [web2]
ok: [web1]

TASK [Install nginx] ***********************************************************
ok: [web1]
ok: [web2]

TASK [Write the index page] ****************************************************
ok: [web2]
changed: [web1]

TASK [Configure the site] ******************************************************
ok: [web2]
ok: [web1]

TASK [Start nginx] *************************************************************
ok: [web1]
ok: [web2]

PLAY RECAP *********************************************************************
web1                       : ok=5    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=5    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

```
ana@laptop:~/shop/ansible$ curl -s http://web1/
<h1>shop</h1>
```

**One change, on one host, in one task.** The playbook put back what it describes and left `web2`
alone, because there was nothing to put back there. That is configuration management's answer to the
drift of lesson 1: run the description often and the machines converge on it. The limit is that
Ansible checks **only what the playbook mentions**. A file it was never told about,
a package somebody installed by hand, a cron job nobody wrote down: those stay, and no run reports
them. There is no state file listing what Ansible made, so deleting a task removes nothing from the
machines; to remove something you write a task that says it is `absent`.

### A task that always says changed

A playbook stays at `changed=0` only if every task is honest. Here is one that is not, a check of
nginx's configuration with `command`:

```yaml
- name: Check nginx's configuration
  hosts: web
  become: true
  tasks:
    - name: Test the configuration
      ansible.builtin.command: nginx -t
```

```
TASK [Test the configuration] **************************************************
changed: [web2]
changed: [web1]

PLAY RECAP *********************************************************************
web1                       : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

That is the second run, and every run looks the same. `nginx -t` changes nothing, but
`command` cannot know that. **A task that reports a change it did not make hides the ones that
matter**, because nobody reads a summary that is never zero. Tell Ansible what counts as a change:

```yaml
- name: Check nginx's configuration
  hosts: web
  become: true
  tasks:
    - name: Test the configuration
      ansible.builtin.command: nginx -t
      changed_when: false
```

```
ana@laptop:~/shop/ansible$ ansible-playbook check.yml

PLAY [Check nginx's configuration] *********************************************

TASK [Gathering Facts] *********************************************************
ok: [web2]
ok: [web1]

TASK [Test the configuration] **************************************************
ok: [web2]
ok: [web1]

PLAY RECAP *********************************************************************
web1                       : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

For a command that does make something, `creates` names the file it makes, and the task is skipped
once that file exists. A self-signed certificate is made once and then left alone:

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
changed: [web1]
changed: [web2]

PLAY RECAP *********************************************************************
web1                       : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

```
ana@laptop:~/shop/ansible$ ansible-playbook cert.yml

PLAY [A certificate for the shop] **********************************************

TASK [Gathering Facts] *********************************************************
ok: [web2]
ok: [web1]

TASK [Make a self-signed certificate, once] ************************************
ok: [web2]
ok: [web1]

PLAY RECAP *********************************************************************
web1                       : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

### Asking before doing

`--check` runs the playbook without changing anything and reports what would change; `--diff` shows
how each file would differ. Ana edits the page's text in `site.yml` and asks first:

```
ana@laptop:~/shop/ansible$ grep h1 site.yml
        content: "<h1>shop, now open</h1>\n"
ana@laptop:~/shop/ansible$ ansible-playbook site.yml --check --diff

PLAY [Web servers] *************************************************************

TASK [Gathering Facts] *********************************************************
ok: [web1]
ok: [web2]

TASK [Install nginx] ***********************************************************
ok: [web1]
ok: [web2]

TASK [Write the index page] ****************************************************
--- before: /var/www/html/index.html
+++ after: /var/www/html/index.html
@@ -1 +1 @@
-<h1>shop</h1>
+<h1>shop, now open</h1>

changed: [web1]
--- before: /var/www/html/index.html
+++ after: /var/www/html/index.html
@@ -1 +1 @@
-<h1>shop</h1>
+<h1>shop, now open</h1>

changed: [web2]

TASK [Configure the site] ******************************************************
ok: [web1]
ok: [web2]

TASK [Start nginx] *************************************************************
ok: [web1]
ok: [web2]

PLAY RECAP *********************************************************************
web1                       : ok=5    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=5    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

```
ana@laptop:~/shop/ansible$ curl -s http://web1/
<h1>shop</h1>
```

**`--check` is Ansible's plan**, and like Terraform's it is only as good as each module's ability to
predict. `copy` can compare two files; a module that runs a program cannot know what the program would
do, so a playbook full of `command` tasks gets a check that says little.
