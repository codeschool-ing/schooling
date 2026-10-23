---
title: A mesma ideia no Linux, com Ansible
version: 1
---

**O Linux não tem Política de Grupo, e precisa da mesma coisa.** A maioria das organizações com
frotas Linux usa em vez disso uma ferramenta de configuração: Ansible, Puppet, Chef ou Salt. Elas
diferem em ter ou não um agente em cada máquina e em a máquina puxar ou receber, e concordam na forma:
**uma descrição do estado desejado, guardada num lugar só, e uma regra de qual parte dela vale para
qual máquina.** A aula 2 usou o Ansible numa máquina. Aqui ele faz o que a Política de Grupo faz,
para três máquinas com trabalhos diferentes.

Suba o laboratório com `sudo bash hostlab.sh up admin web desk jump` e trabalhe no `admin`. O
inventário põe cada máquina num grupo pelo trabalho, e as variáveis moram em arquivos com o nome dos
grupos e dos hosts:

```
ana@admin:~$ head -20 hosts.ini group_vars/*.yml host_vars/*.yml
==> hosts.ini <==
[servers]
web
jump

[workstations]
desk

==> group_vars/all.yml <==
ssh_max_auth_tries: 3
x11_forwarding: "no"
banner: "Jatoba Contabilidade. Authorised use only; sessions are logged."

==> group_vars/workstations.yml <==
x11_forwarding: "yes"

==> host_vars/jump.yml <==
ssh_max_auth_tries: 2
```

`all.yml` guarda o que todas as máquinas compartilham. `workstations.yml` muda um valor para as
estações, porque quem está numa mesa abre programas gráficos por SSH e servidores nunca abrem.
`jump.yml` aperta um valor para uma máquina, porque o `jump` é a porta que a aula 15 constrói e
recebe menos tentativas por conexão que qualquer outra. O Ansible desenha os grupos para você:

```
ana@admin:~$ ansible-inventory -i hosts.ini --graph
@all:
  |--@ungrouped:
  |--@servers:
  |  |--web
  |  |--jump
  |--@workstations:
  |  |--desk
```

## Quem vence

Toda máquina também está no grupo `all`, então o `desk` tem dois valores para `x11_forwarding` e o
`jump` dois para `ssh_max_auth_tries`. O Ansible resolve isso por uma ordem fixa de precedência: **as
variáveis do próprio host vencem as dos grupos, e as de um grupo nomeado vencem as do `all`.**
Pergunte com o que cada máquina fica antes de rodar qualquer coisa; `-f 1` faz o Ansible perguntar a
uma máquina de cada vez, então as respostas voltam na ordem do inventário:

```
ana@admin:~$ ansible all -i hosts.ini -f 1 -m debug -a 'msg="tries={{ ssh_max_auth_tries }} x11={{ x11_forwarding }}"' | grep -E 'SUCCESS|msg'
web | SUCCESS => {
    "msg": "tries=3 x11=no"
jump | SUCCESS => {
    "msg": "tries=2 x11=no"
desk | SUCCESS => {
    "msg": "tries=3 x11=yes"
```

O `web` mantém os padrões. O `desk` recebe o `yes` das estações. O `jump` recebe o próprio `2`. Repare
na direção: aqui o arquivo da própria máquina vence. Na Política de Grupo a política local da própria
máquina é a que perde, porque é aplicada primeiro e tudo o que vem do domínio a sobrescreve, e quem
está acostumado com um sistema se surpreende com o outro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l03-vars\" aria-label=\"De onde cada máquina tira os seus dois valores. O arquivo all.yml dá a todas as máquinas 3 tentativas e nada de encaminhamento X11. O arquivo workstations.yml muda o X11 para yes no desk. O arquivo jump.yml muda as tentativas para 2 no jump. Resultado: web fica com 3 e no, desk com 3 e yes, jump com 2 e no. O arquivo mais específico vence.\"><defs><marker id=\"l03-vars-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"680.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36.0\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">group_vars/all.yml</text><text x=\"330.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ssh_max_auth_tries: 3</text><text x=\"560.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">x11_forwarding: &quot;no&quot;</text><rect x=\"250.0\" y=\"100.0\" width=\"220.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">group_vars/workstations.yml</text><text x=\"360.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">x11_forwarding: &quot;yes&quot;</text><rect x=\"490.0\" y=\"100.0\" width=\"210.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">host_vars/jump.yml</text><text x=\"595.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ssh_max_auth_tries: 2</text><rect x=\"40.0\" y=\"190.0\" width=\"180.0\" height=\"56.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">web</text><text x=\"90.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><text x=\"160.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">no</text><path d=\"M130.0 80.0 L130.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-vars-dh-ah-paper-dim)\"></path><rect x=\"270.0\" y=\"190.0\" width=\"180.0\" height=\"56.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><text x=\"320.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><text x=\"390.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">yes</text><path d=\"M360.0 150.0 L360.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-vars-dh-ah-paper-dim)\"></path><rect x=\"505.0\" y=\"190.0\" width=\"180.0\" height=\"56.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">jump</text><text x=\"555.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2</text><text x=\"625.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">no</text><path d=\"M595.0 150.0 L595.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-vars-dh-ah-paper-dim)\"></path><text x=\"130.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nada mais específico</text></svg>", "caption": "Um arquivo de host vence um de grupo, e um grupo nomeado vence o all."}
```

## O playbook

No `admin`, crie `baseline.yml`:

```schooling-example
{"language": "yaml", "file": "baseline.yml", "parts": [{"code": "- name: Jatobá baseline for every machine\n  hosts: all\n  become: true\n  tasks:", "note": "`hosts: all` são todas as máquinas do inventário. O que difere entre elas não está neste arquivo: vem das variáveis que cada máquina herda dos seus grupos, que é o assunto da seção acima."}, {"code": "    - name: The banner shown before login\n      ansible.builtin.copy:\n        dest: /etc/issue.net\n        content: \"{{ banner }}\\n\"", "note": "`{{ banner }}` é trocado pelo valor de `banner` da máquina antes de o arquivo ser gravado. Todas as máquinas têm o mesmo, porque ele só é definido em `all.yml`."}, {"code": "    - name: SSH, with this machine's values\n      ansible.builtin.copy:\n        dest: /etc/ssh/sshd_config.d/10-baseline.conf\n        content: |\n          PermitRootLogin no\n          PasswordAuthentication no\n          MaxAuthTries {{ ssh_max_auth_tries }}\n          X11Forwarding {{ x11_forwarding }}\n          Banner /etc/issue.net\n        validate: /usr/sbin/sshd -t -f %s\n      notify: reload ssh", "note": "Uma tarefa, três arquivos diferentes: o `web` recebe 3 e `no`, o `desk` recebe 3 e `yes`, o `jump` recebe 2 e `no`. As configurações iguais em todo lugar são escritas como texto, e só as duas que variam são variáveis."}, {"code": "  handlers:\n    - name: reload ssh\n      ansible.builtin.service: {name: ssh, state: reloaded}", "note": "O handler recarrega o SSH só nas máquinas cujo arquivo de fato mudou."}]}
```

Antes de rodá-lo, veja o que as três máquinas fazem agora, com um comando avulso que pergunta ao
`sshd` de cada uma:

```
ana@admin:~$ ansible all -i hosts.ini -f 1 -b -m shell -a "sshd -T | grep -E '^(maxauthtries|x11forwarding) '" | sed 's/ | CHANGED | rc=0 >>//'
web
maxauthtries 6
x11forwarding yes
jump
maxauthtries 6
x11forwarding yes
desk
maxauthtries 6
x11forwarding yes
```

Os padrões do Ubuntu, iguais nas três. Aplique a linha de base e pergunte de novo; cada máquina
informa três mudanças, o banner, o arquivo do SSH e o reload:

```
ana@admin:~$ ansible-playbook -i hosts.ini baseline.yml | tail -6

PLAY RECAP *********************************************************************
desk                       : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
jump                       : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web                        : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

```
ana@admin:~$ ansible all -i hosts.ini -f 1 -b -m shell -a "sshd -T | grep -E '^(maxauthtries|x11forwarding|banner) '" | sed 's/ | CHANGED | rc=0 >>//'
web
maxauthtries 3
x11forwarding no
banner /etc/issue.net
jump
maxauthtries 2
x11forwarding no
banner /etc/issue.net
desk
maxauthtries 3
x11forwarding yes
banner /etc/issue.net
```

Três máquinas, três resultados diferentes de um playbook e de um conjunto de variáveis, e cada um o
valor que o grupo ou o arquivo próprio dela dizia. **A regra está num lugar só e as diferenças são
declaradas**, que é tudo o que a Política de Grupo oferece, tirando o registro do Windows.
