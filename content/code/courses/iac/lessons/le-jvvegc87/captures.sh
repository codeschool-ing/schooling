#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of iac, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh tools        # once: the software the lab runs
#   sudo bash ../../lab.sh hosts up     # starts the Docker daemon
#   sudo bash captures.sh
#
# IT RUNS IN TWO HALVES, and the first is not inside the lab.
#
#   - "the-machines" runs first, OUTSIDE lab.sh's sandbox, as root, with a
#     scratch HOME printed as ~. It builds web1, web2 and db1 with the very
#     Dockerfile and up.sh the lesson shows: from_lesson takes both out of
#     the-machines.md, so the machines every later transcript talks to are made
#     by the script the student reads. It runs as root because the lab's user
#     has no access to Docker's socket on the machine this was recorded on; the
#     one line that shows what that looks like runs as ana. On your own computer
#     you are in the `docker` group and the commands are the same. The key
#     up.sh made is then handed to the lab, which copies it into every run's
#     ~/.ssh, so ana logs in with the key the machines were given.
#   - Everything else runs inside the lab as ana, with LAB_HOSTS=1: on the
#     laptop's own network, where the containers' bridge and the /etc/hosts
#     lines up.sh wrote are.
#
# Every run makes three new machines, and the counts in the PLAY RECAPs
# depend on that: a second run against machines that already have nginx
# reports fewer changes, which is the lesson's own point. The containers reach
# the Ubuntu archive, so apt installs the real package.
#
# The AWS of the other lessons is moto on localhost:4566; this lesson does not
# use it. The Terraform in "from-terraform" uses only the local provider, and
# the machines' addresses are given to it as a variable, because moto runs no
# machine whose address Terraform could read back.
#
# What is STAGED rather than typed, and not shown in the lesson: the files ana
# wrote (put and version below), whose contents the lesson shows in full; ana's
# edit to site.yml before --check, which the lesson shows with grep; and the
# move of the play's templates into the role in "roles", the `quiet` mv lines
# below, which the lesson describes. The colleague's edit on web1 in
# "idempotency" is shown in the lesson as the command it was. The host keys she
# trusts are fetched by ssh-keyscan in the open, in "inventory".
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)

if [ -z "${IN_LAB:-}" ]; then
  # ------------------------------------------------------- the-machines, outside
  (
  . <(sed -n '/^from_lesson()/,/^}/p' "$HERE/../../capture.sh")
  S=$(mktemp -d /tmp/iac-le-jvvegc87-XXXXXX)
  export HOME=$S TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat
  decolour() { sed -u 's/\x1b\[[0-9;]*m//g'; }
  prompt() { printf 'ana@laptop:%s$ %s\n' "${PWD/#$S/\~}" "$1"; }
  run() { prompt "$1"; eval "$1" 2>&1 </dev/null | decolour; return 0; }
  block() { printf '##### %s\n' "$1"; }
  cd "$S"
  mkdir -p hosts
  from_lesson "$HERE/the-machines.md" '~/hosts/Dockerfile' > hosts/Dockerfile
  from_lesson "$HERE/the-machines.md" '~/hosts/up.sh' > hosts/up.sh

  block not-in-group
  prompt 'docker ps'
  runuser -u ana -- env -i PATH=/usr/bin:/bin docker ps 2>&1 </dev/null

  block up
  run 'sh ~/hosts/up.sh'
  run "docker ps --filter network=iac --format '{{.Names}}  {{.Image}}  {{.Status}}'"

  mkdir -p /opt/iac/ssh
  cp "$S/.ssh/id_ed25519" "$S/.ssh/id_ed25519.pub" /opt/iac/ssh/
  rm -rf "$S"
  ) || exit 1
  export LAB_HOSTS=1
fi

. "$(dirname "$0")/../../capture.sh"

# A file that changes during the lesson is written with `version` rather than
# `put`, so that each version is quoted under a name of its own (site.yml#1,
# site.yml#2...). put would print every version under the same name.
version() {
  mkdir -p "$(dirname "$2")" && cat > "$2"
  printf '##### file:%s/%s\n' "${PWD/#\/home\/ana/\~}" "$1"; cat "$2"; printf '##### end-file\n'
}

mkdir -p shop/ansible && cd shop/ansible

block inventory
put inventory.ini <<'CODE'
[web]
web1
web2

[db]
db1

[all:vars]
ansible_user=deploy
ansible_python_interpreter=/usr/bin/python3
CODE
put ansible.cfg <<'CODE'
[defaults]
inventory = inventory.ini
CODE
block keyscan
run 'ssh-keyscan -t ed25519 web1 web2 db1 >> ~/.ssh/known_hosts 2>/dev/null'
block ping
run 'ansible all -m ping'
block graph
run 'ansible-inventory --graph'
block as-yaml
run 'ansible-inventory --list --yaml'
block wrong-user
run 'ansible db1 -m ping -e ansible_user=root'

block ad-hoc
run 'ansible web -m command -a whoami'
block become
run 'ansible web -m command -a whoami --become'
block no-become
run 'ansible web1 -m apt -a "name=tree state=present update_cache=true"'
block apt-1
run 'ansible web -m apt -a "name=tree state=present update_cache=true" --become | grep -E "=>|\"changed\""'
block apt-2
run 'ansible web -m apt -a "name=tree state=present" --become'
block command-twice
run 'ansible web1 -m command -a "tree --version"'
block shell
run 'ansible web1 -m command -a "dpkg -l | grep -c ^ii"'
run 'ansible web -m shell -a "dpkg -l | grep -c ^ii"'

block playbooks
version site.yml#1 site.yml <<'CODE'
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
CODE
block play-1
run 'ansible-playbook site.yml'
block curl-1
run 'curl -s http://web1/'

block idempotency
block play-2
run 'ansible-playbook site.yml'
block by-hand
# a colleague's edit on web1, typed over ssh on another day: the lesson shows
# the command and not its (empty) output
quiet "ssh deploy@web1 'echo \"<h1>shop (closed for stocktaking)</h1>\" | sudo tee /var/www/html/index.html'"
run 'curl -s http://web1/'
block play-3
run 'ansible-playbook site.yml'
block curl-3
run 'curl -s http://web1/'
version check.yml#1 check.yml <<'CODE'
- name: Check nginx's configuration
  hosts: web
  become: true
  tasks:
    - name: Test the configuration
      ansible.builtin.command: nginx -t
CODE
block check-1
run 'ansible-playbook check.yml'
block check-1b
run 'ansible-playbook check.yml'
version check.yml#2 check.yml <<'CODE'
- name: Check nginx's configuration
  hosts: web
  become: true
  tasks:
    - name: Test the configuration
      ansible.builtin.command: nginx -t
      changed_when: false
CODE
block check-2
run 'ansible-playbook check.yml'
put cert.yml <<'CODE'
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
CODE
block cert-1
run 'ansible-playbook cert.yml'
block cert-2
run 'ansible-playbook cert.yml'
block check-diff
quiet "sed -i 's|<h1>shop</h1>|<h1>shop, now open</h1>|' site.yml"
run 'grep h1 site.yml'
run 'ansible-playbook site.yml --check --diff'
block still-old
run 'curl -s http://web1/'

block templates-handlers
mkdir -p group_vars templates
put group_vars/web.yml <<'CODE'
shop_server_name: shop.example.com
shop_root: /var/www/shop
CODE
put templates/shop.conf.j2 <<'CODE'
# Written by Ansible from templates/shop.conf.j2. Edits here are overwritten.
server {
    listen 80 default_server;
    server_name {{ shop_server_name }};
    root {{ shop_root }};

    location / {
        try_files $uri $uri/ =404;
    }
}
CODE
put templates/index.html.j2 <<'CODE'
<h1>shop</h1>
<p>served by {{ inventory_hostname }}</p>
CODE
version site.yml#2 site.yml <<'CODE'
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
CODE
block tpl-1
run 'ansible-playbook site.yml'
block tpl-curl
run 'curl -s http://web1/'
run 'curl -s http://web2/'
block tpl-2
run 'ansible-playbook site.yml'
block tpl-3
quiet "sed -i 's|shop.example.com|shop.example.com www.shop.example.com|' group_vars/web.yml"
run 'cat group_vars/web.yml'
run 'ansible-playbook site.yml --diff'

block roles
run 'ansible-galaxy role init --init-path roles web'
run 'tree roles'
# STAGED: moving the play's pieces into the role, which the lesson describes
quiet 'mv templates/shop.conf.j2 templates/index.html.j2 roles/web/templates/'
quiet 'rmdir templates'
put roles/web/defaults/main.yml <<'CODE'
shop_server_name: shop.example.com
shop_root: /var/www/shop
CODE
put roles/web/tasks/main.yml <<'CODE'
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
CODE
put roles/web/handlers/main.yml <<'CODE'
- name: Reload nginx
  ansible.builtin.service:
    name: nginx
    state: reloaded
CODE
version site.yml#3 site.yml <<'CODE'
- name: Web servers
  hosts: web
  become: true
  roles:
    - web
CODE
block role-run
run 'ansible-playbook site.yml'

block from-terraform
mkdir -p ../infra && cd ../infra
put main.tf <<'CODE'
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
  }
}

# moto runs no machines, so the addresses come in as a variable here.
# Against a real account they would be aws_instance.web[*].private_ip.
variable "web_hosts" {
  type = map(string)
}

variable "db_hosts" {
  type = map(string)
}

resource "local_file" "inventory" {
  filename        = "../ansible/hosts.ini"
  file_permission = "0644"
  content = templatefile("${path.module}/inventory.tftpl", {
    web = var.web_hosts
    db  = var.db_hosts
  })
}

output "inventory" {
  value = local_file.inventory.filename
}
CODE
put inventory.tftpl <<'CODE'
# Written by Terraform from inventory.tftpl. Edits here are overwritten.
[web]
%{ for name, addr in web ~}
${name} ansible_host=${addr}
%{ endfor ~}

[db]
%{ for name, addr in db ~}
${name} ansible_host=${addr}
%{ endfor ~}

[all:vars]
ansible_user=deploy
ansible_python_interpreter=/usr/bin/python3
CODE
put terraform.tfvars <<'CODE'
web_hosts = {
  web1 = "172.30.0.11"
  web2 = "172.30.0.12"
}
db_hosts = {
  db1 = "172.30.0.21"
}
CODE
quiet 'terraform init'
block tf-apply
run 'terraform apply -auto-approve'
block tf-inventory
cd ../ansible
run 'ssh-keyscan -t ed25519 172.30.0.11 172.30.0.12 172.30.0.21 >> ~/.ssh/known_hosts 2>/dev/null'
run 'cat hosts.ini'
run 'ansible-inventory -i hosts.ini --graph'
block tf-play
run 'ansible-playbook -i hosts.ini site.yml'
