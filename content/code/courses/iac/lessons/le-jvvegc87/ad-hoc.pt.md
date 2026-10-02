---
title: Comandos ad-hoc, e módulos que olham antes de agir
version: 1
---

Antes de escrever um playbook, você pode pedir ao Ansible que faça uma coisa num grupo de máquinas,
pela linha de comando. A forma é sempre a mesma: **quais hosts, qual módulo, quais argumentos.**

```
ana@laptop:~/shop/ansible$ ansible web -m command -a whoami
web2 | CHANGED | rc=0 >>
deploy
web1 | CHANGED | rc=0 >>
deploy
```

`web` é um grupo do inventário, `-m command` é o módulo e `-a whoami` o argumento dele. A resposta
vem por host. Para agir como root, o Ansible entra como `deploy` e depois usa `sudo`, o que ele
chama de **become**:

```
ana@laptop:~/shop/ansible$ ansible web -m command -a whoami --become
web1 | CHANGED | rc=0 >>
root
web2 | CHANGED | rc=0 >>
root
```

Instalar um pacote exige root, e o erro quando você esquece é o do próprio apt, vindo da máquina:

```
ana@laptop:~/shop/ansible$ ansible web1 -m apt -a "name=tree state=present update_cache=true"
[WARNING]: Updating cache and auto-installing missing dependency: python3-apt
[ERROR]: Task failed: Module failed: E: List directory /var/lib/apt/lists/partial is missing. - Acquire (13: Permission denied)
Origin: <adhoc 'apt' task>

{'action': 'apt', 'args': {'name': 'tree', 'state': 'present', 'update_cache': 'true'}, 'timeout': 0, 'async_val': [...]

web1 | FAILED! => {
    "changed": false,
    "cmd": "/usr/bin/apt-get update",
    "msg": "E: List directory /var/lib/apt/lists/partial is missing. - Acquire (13: Permission denied)",
    "rc": 100,
    "stderr": "E: List directory /var/lib/apt/lists/partial is missing. - Acquire (13: Permission denied)\n",
    "stderr_lines": [
        "E: List directory /var/lib/apt/lists/partial is missing. - Acquire (13: Permission denied)"
    ],
    "stdout": "Reading package lists...\n",
    "stdout_lines": [
        "Reading package lists..."
    ]
}
```

Com `--become` o módulo `apt` instala o `tree` nos dois servidores web. A resposta dele por host é
longa, porque carrega toda a saída do apt, então aqui ela está filtrada nas duas linhas que importam:

```
ana@laptop:~/shop/ansible$ ansible web -m apt -a "name=tree state=present update_cache=true" --become | grep -E "=>|\"changed\""
web2 | CHANGED => {
    "changed": true,
web1 | CHANGED => {
    "changed": true,
```

Rode a mesma coisa de novo:

```
ana@laptop:~/shop/ansible$ ansible web -m apt -a "name=tree state=present" --become
web2 | SUCCESS => {
    "cache_update_time": 1790954402,
    "cache_updated": false,
    "changed": false
}
web1 | SUCCESS => {
    "cache_update_time": 1790954403,
    "cache_updated": false,
    "changed": false
}
```

**É sobre essa diferença que o resto da aula se apoia.** O módulo `apt` não rodou `apt-get install`
para depois contar o que aconteceu. Primeiro perguntou à máquina se o `tree` já estava instalado,
viu que estava e não fez nada; por isso responde `"changed": false`, e a linha do host diz SUCCESS
em vez de CHANGED. Um módulo assim descreve um estado, *o tree está presente*, e faz só a diferença,
que é o que o `terraform apply` fez na aula 1.

O `command` não consegue fazer isso. Ele roda um programa e não faz ideia do que o programa fez,
então responde CHANGED toda vez, até para um programa que só imprime a própria versão:

```
ana@laptop:~/shop/ansible$ ansible web1 -m command -a "tree --version"
web1 | CHANGED | rc=0 >>
tree v2.1.1 © 1996 - 2023 by Steve Baker, Thomas Moore, Francesc Rocher, Florian Sesser, Kyosuke Tokoro
```

O `command` também roda o programa diretamente, sem shell no meio, então um pipe chega ao `dpkg`
como mais argumentos. O módulo `shell` põe o `/bin/sh` na frente e o pipe funciona:

```
ana@laptop:~/shop/ansible$ ansible web1 -m command -a "dpkg -l | grep -c ^ii"
[ERROR]: Task failed: Module failed: The command exited with a non-zero return code.
Origin: <adhoc 'command' task>

{'action': 'command', 'args': {'_raw_params': 'dpkg -l | grep -c ^ii'}, 'timeout': 0, 'async_val': 0, 'poll': 15}

web1 | FAILED | rc=1 >>
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name           Version      Architecture Description
+++-==============-============-============-=================================
ii  grep           3.11-4build1 amd64        GNU grep, egrep and fgrepdpkg-query: no packages found matching |
dpkg-query: no packages found matching -c
dpkg-query: no packages found matching ^iiThe command exited with a non-zero return code.
ana@laptop:~/shop/ansible$ ansible web -m shell -a "dpkg -l | grep -c ^ii"
web1 | CHANGED | rc=0 >>
193
web2 | CHANGED | rc=0 >>
193
```

Vale ler a primeira falha uma vez, porque é assim que você vai encontrá-la. O `dpkg -l` recebeu `|`,
`grep`, `-c` e `^ii` como nomes de pacote, listou o único que existe, o pacote `grep`, e falhou nos
outros. Nada quebrou na máquina; o comando queria dizer outra coisa. **Prefira o `command` e use o
`shell` só para um pipe ou um redirecionamento**, já que um shell também expande variáveis e
curingas em tudo o que você passa a ele.

Comandos ad-hoc servem para perguntas e consertos pontuais: qual versão está instalada, quão cheio
está o disco, reinicie este serviço agora. O que você quer guardar, e rodar de novo semana que vem
em máquinas novas, vai para um arquivo. Um comando digitado no prompt não deixa registro que um
revisor possa ler, o mesmo motivo que a aula 1 deu contra o `network.sh`. Esse arquivo é um
playbook.
