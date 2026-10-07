#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of networks-automation, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Ansible is Ubuntu 24.04's package: ansible-core 2.16.3 with the collections
# of Ansible 9.2, among them frr.frr 2.0.2 and ansible.netcommon. The service
# desk is deskd, written for the lab.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset; the empty ~/net, which the lesson tells the
# student to make; and the files ana wrote (put below), whose contents the
# lesson shows. ~/.vault-pass is typed, in secrets.md.
# The vault ciphertext differs on every run, because encryption is salted.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on HOST 'command': what ana typed at her prompt on one machine, and what it printed.
on() {
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
# The same, run as root and not shown: the lab's own housekeeping.
quiet() { local h=$1; shift; lab exec "$h" root "$*" >/dev/null 2>&1 || true; }
# put PATH: a file ana wrote on ctl, from stdin. Its content is shown in the lesson.
put() { lab exec ctl ana "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
# typed ROUTER 'line' ...: an interactive SSH session from ctl to a router's CLI,
# each line typed at the prompt, and the terminal as it looked afterwards.
typed() {
  local h=$1; shift
  printf 'ana@ctl:~$ ssh netops@%s\n' "$h"
  local script='sleep 1.2;' l
  for l in "$@"; do script+=" printf '%s\\n' '$l'; sleep 0.5;"; done
  lab exec ctl ana "( $script ) | ssh -tt netops@$h 2>&1 | tr -d '\\r'" || true
}
block() { printf '##### %s\n' "$1"; }
# A command left running on one machine while others are typed, the way a
# second terminal would be: its prompt and output are printed when it ends.
bgon() {
  printf 'ana@%s:~$ %s\n' "$1" "$2" > /tmp/bg.out
  lab exec "$1" ana "$2" >> /tmp/bg.out 2>&1 &
  BG=$!
  sleep "${3:-1.5}"
}
fgon() { wait "$BG"; cat /tmp/bg.out; rm -f /tmp/bg.out; }

lab reset
lab exec ctl ana 'mkdir -p net'
on ctl 'head -c 24 /dev/urandom | base64 > ~/.vault-pass; chmod 600 ~/.vault-pass'

put net/ansible.cfg <<'CODE'
[defaults]
inventory = inventory
stdout_callback = default
retry_files_enabled = false
CODE
put net/inventory/hosts.yaml <<'CODE'
all:
  children:
    routers:
      children:
        core:
          hosts:
            core1: {ansible_host: core1.example.net}
        branches:
          hosts:
            edge1: {ansible_host: edge1.example.net}
            edge2: {ansible_host: edge2.example.net}
CODE
put net/group_vars/routers.yaml <<'CODE'
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: frr.frr.frr
ansible_network_cli_ssh_type: paramiko
ansible_user: netops
ansible_ssh_private_key_file: /home/ana/.ssh/id_ed25519
bgp_as: 64512
management_network: 192.0.2.0/24
CODE
put net/host_vars/core1.yaml <<'CODE'
router_id: 203.0.113.251
bgp_neighbours: [203.0.113.252, 203.0.113.253]
CODE
put net/host_vars/edge1.yaml <<'CODE'
router_id: 203.0.113.252
bgp_neighbours: [203.0.113.251]
CODE
put net/host_vars/edge2.yaml <<'CODE'
router_id: 203.0.113.253
bgp_neighbours: [203.0.113.251]
CODE
put net/show.yaml <<'CODE'
- name: Ask every router about its OSPF neighbours
  hosts: routers
  gather_facts: false
  tasks:
    - name: Show the neighbours
      ansible.netcommon.cli_command:
        command: show ip ospf neighbor json
      register: ospf

    - name: Count them
      ansible.builtin.debug:
        msg: "{{ (ospf.stdout | from_json).neighbors | length }} OSPF neighbour(s)"
CODE
put net/mgmt.yaml <<'CODE'
- name: Every router has the MGMT prefix list
  hosts: routers
  gather_facts: false
  tasks:
    - name: Permit the management network
      ansible.netcommon.cli_config:
        config: "ip prefix-list MGMT seq 10 permit {{ management_network }}"
CODE
put net/bgp.yaml <<'CODE'
- name: iBGP between the loopbacks
  hosts: routers
  gather_facts: false
  tasks:
    - name: Configure BGP, one neighbour at a time
      frr.frr.frr_bgp:
        config:
          bgp_as: "{{ bgp_as }}"
          router_id: "{{ router_id }}"
          neighbors:
            - neighbor: "{{ item }}"
              remote_as: "{{ bgp_as }}"
              update_source: lo
        operation: merge
      loop: "{{ bgp_neighbours }}"
CODE
put net/bgp_check.yaml <<'CODE'
- name: Are the BGP sessions up?
  hosts: routers
  gather_facts: false
  tasks:
    - name: Read BGP state
      ansible.netcommon.cli_command:
        command: show bgp summary json
      register: bgp

    - name: Every peer is Established
      ansible.builtin.assert:
        that: item.value.state == "Established"
        quiet: true
      loop: "{{ (bgp.stdout | from_json).ipv4Unicast.peers | dict2items }}"
      loop_control:
        label: "{{ item.key }} {{ item.value.state }}"
CODE
put net/facts.yaml <<'CODE'
- name: What the collection knows about each router
  hosts: branches
  gather_facts: false
  tasks:
    - name: Gather interface facts
      frr.frr.frr_facts:
        gather_subset: interfaces
    - name: Show a few
      ansible.builtin.debug:
        msg: "{{ ansible_net_hostname }} runs FRR {{ ansible_net_version }}, interfaces {{ ansible_net_interfaces.keys() | sort | join(', ') }}"
CODE
put net/ticket.yaml <<'CODE'
- name: Tell the service desk
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Open a change ticket
      ansible.builtin.uri:
        url: https://tickets.example.net/api/tickets
        method: POST
        ca_path: /home/ana/lab-ca.pem
        headers:
          Authorization: "Token {{ desk_token }}"
        body_format: json
        body:
          title: iBGP configured on core1, edge1 and edge2
          priority: low
          requester: ansible
        status_code: 201
      no_log: true
      register: ticket

    - name: Say which
      ansible.builtin.debug:
        msg: "{{ ticket.json.number }} opened"
CODE

block tree
on ctl 'cd net && find . -type f | sort'
block graph
on ctl 'cd net && ansible-inventory --graph'
block host
on ctl 'cd net && ansible-inventory --host edge1'
block show
on ctl 'cd net && ansible-playbook show.yaml'
block check
on ctl 'cd net && ansible-playbook mgmt.yaml --check --diff'
block mgmt
on ctl 'cd net && ansible-playbook mgmt.yaml'
block mgmt-again
on ctl 'cd net && ansible-playbook mgmt.yaml'
block facts
on ctl 'cd net && ansible-playbook facts.yaml'
block bgp
on ctl 'cd net && ansible-playbook bgp.yaml'
block bgp-again
on ctl 'cd net && ansible-playbook bgp.yaml | tail -5'
block bgp-running
on ctl 'ssh netops@edge1 "show running-config" | sed -n "/^router bgp/,/^exit/p"'
sleep 8
block bgp-check
on ctl 'cd net && ansible-playbook bgp_check.yaml'
block vault
on ctl 'cd net && printf %s "$(cat ~/.desk-token)" | ansible-vault encrypt_string --vault-password-file ~/.vault-pass --stdin-name desk_token > group_vars/all.yaml && cat group_vars/all.yaml'
block ticket-no-pass
on ctl 'cd net && ansible-playbook ticket.yaml 2>&1 | grep -E "ERROR|fatal"'
block vault-missing
on ctl 'cd net && ansible localhost -m ansible.builtin.debug -a var=desk_token 2>&1 | cat'
block ticket
on ctl 'cd net && ansible-playbook ticket.yaml --vault-password-file ~/.vault-pass'
