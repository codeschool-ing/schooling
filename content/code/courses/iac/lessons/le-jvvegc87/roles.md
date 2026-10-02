---
title: Roles, the unit you reuse
version: 1
---

`site.yml` now holds the tasks, the handler, two templates and the variables they need, for one
purpose: a web server for the shop. A second playbook that wanted the same web server would have to
copy all of it. A **role** packages those pieces into a directory with a fixed layout, so that a play
can say *apply the web role* in one line. It is to Ansible what a module is to Terraform in lesson 10.

`ansible-galaxy` creates the layout, with no network needed:

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

Each directory has one job, and Ansible finds the files by where they are, so the role needs no list
of its own contents:

| directory | what goes in it |
| --- | --- |
| `tasks/main.yml` | the tasks, in order |
| `handlers/main.yml` | the handlers those tasks notify |
| `templates/` | Jinja2 templates; `src:` finds them here without a path |
| `files/` | files copied as they are |
| `defaults/main.yml` | the role's variables with their default values, the weakest of all |
| `vars/main.yml` | variables the role sets for itself, which users are not meant to change |
| `meta/main.yml` | the author, the platforms, and the roles this one depends on |
| `tests/`, `README.md` | a sample inventory and play, and the documentation |

**`defaults` versus `vars` is the role's interface.** A default is a value the caller is expected to
override, which is why it loses to almost everything; a `vars` entry wins over the inventory and
group variables, so anything there is effectively fixed. Ana's variables are things a caller should
choose, so they go in `defaults`:

```yaml
shop_server_name: shop.example.com
shop_root: /var/www/shop
```

The tasks move unchanged, with one level of indentation less because they are no longer inside a
play:

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

The two templates move into `roles/web/templates/` as they are, and the playbook shrinks to what it
should have been about all along, which hosts get which role:

```yaml
- name: Web servers
  hosts: web
  become: true
  roles:
    - web
```

**A restructuring that changes nothing on the machines should prove it**, and here the proof is one
run:

```
ana@laptop:~/shop/ansible$ ansible-playbook site.yml

PLAY [Web servers] *************************************************************

TASK [Gathering Facts] *********************************************************
ok: [web1]
ok: [web2]

TASK [web : Install nginx] *****************************************************
ok: [web2]
ok: [web1]

TASK [web : Create the site's directory] ***************************************
ok: [web2]
ok: [web1]

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

`changed=0` on both hosts. The task names now carry the role, `web : Install nginx`, which is how
you tell in a long run which role a task came from. It also shows the precedence from the previous
section at work: the role's default `shop_server_name` lacks `www`, and `group_vars/web.yml` still
has it. Had the default won, the configuration would have been rewritten and nginx reloaded; nothing
changed, so the group variable won.

### Roles somebody else wrote

The same command, `ansible-galaxy`, installs roles and **collections**, the larger packages of
modules and roles, from Ansible Galaxy or from a git repository, pinned in a `requirements.yml`.
Nothing was installed from Galaxy for this lesson: the lab has `ansible-core` and its built-in
modules only. The advice from lesson 10 about the Terraform Registry applies unchanged: pin a
version, and read a role before running it with `become`, because every task in it runs as root on
your machines.
