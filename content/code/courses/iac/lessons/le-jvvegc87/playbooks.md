---
title: A playbook, and how to read what it printed
version: 1
---

A **playbook** is a YAML file with one or more **plays**. A play names a group of hosts and a list
of **tasks**; each task calls one module with its arguments, exactly as `-m` and `-a` did on the
command line, and has a name a person can read. Ana's first playbook makes the two web servers into
web servers:

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

Read it as a description rather than a script. *nginx is present*, *this file has this content*,
*the service is started*. Each module finds out whether that is already true and acts only if it is
not. `become: true` on the play makes every task use `sudo`. The modules are written with their full
names, `ansible.builtin.apt` rather than `apt`, which is how current Ansible documentation writes them
and which says exactly where each one comes from once other collections are installed.

`cache_valid_time: 3600` means the package lists are refreshed only if they are more than an hour old,
so a second run does not download them again. The `Configure the site` task replaces Ubuntu's
default site with a server block of three lines, which is enough for nginx to serve the page.

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
changed: [web1]
changed: [web2]

TASK [Start nginx] *************************************************************
changed: [web2]
changed: [web1]

PLAY RECAP *********************************************************************
web1                       : ok=5    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=5    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

**The output is one heading per task, and under it one line per host.** Tasks run in order, and
every host finishes a task before any host starts the next, so the order of tasks is the order in
the file; the order of hosts inside a task is whichever finished first. `Gathering Facts` is a task
nobody wrote: before the first task, Ansible collects what it can learn about each machine, its
distribution, addresses and memory, into variables the play can use.

The **PLAY RECAP** is the line to read first:

- `ok=5` is every task that succeeded on that host, the facts included, whether or not it changed
  anything;
- `changed=4` is how many of those five changed something: a package, two files, and a service that
  was not running and now is;
- `unreachable` and `failed` are the two failures from the inventory section, a host Ansible could
  not log into and a task that went wrong on one it could;
- `skipped`, `rescued` and `ignored` count tasks a condition skipped and failures that the play was
  written to handle, which this playbook does not use.

`ok` includes `changed`, which surprises people the first time: four of the five successful tasks
changed something, and one, the facts, did not.

**When a task fails on one host, that host stops and the others carry on.** The play does not roll
anything back: whatever the earlier tasks did on that host stays done, as a half-finished `apply`
stays in Terraform's state in lesson 9, and the next run starts again from the top and finds those
tasks already satisfied.

And the result, from the laptop:

```
ana@laptop:~/shop/ansible$ curl -s http://web1/
<h1>shop</h1>
```

A playbook can hold several plays, one for the `web` group and one for `db`, and runs them in
order. Ana's has one, because `db1` has nothing to do yet in this lesson.
