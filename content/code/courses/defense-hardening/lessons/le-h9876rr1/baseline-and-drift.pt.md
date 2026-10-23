---
title: A linha de base, e o desvio dela
version: 1
---

**Uma linha de base é uma declaração escrita de como uma máquina de um certo tipo deveria ser.** Sem
ela, um inventário é uma descrição; com ela, é um teste. A coluna de papel do `hosts.csv` diz para que
serve cada máquina, e a linha de base diz, por papel, o que pode escutar na rede, e lista os pacotes
que o escritório decidiu que nenhuma máquina pode ter. Escreva-a no `admin` como `baseline.json`:

```json
{
  "listening": {
    "portal":         ["tcp/0.0.0.0:22", "tcp/0.0.0.0:80", "tcp/127.0.0.1:8080"],
    "workstation":    ["tcp/0.0.0.0:22"],
    "administration": ["tcp/0.0.0.0:22"],
    "bastion":        ["tcp/0.0.0.0:22"],
    "resolver":       ["tcp/0.0.0.0:22", "tcp/0.0.0.0:53", "udp/0.0.0.0:53"]
  },
  "forbidden": ["inetutils-telnetd", "openbsd-inetd", "vsftpd", "rpcbind", "snmpd", "avahi-daemon"]
}
```

Os listeners são o trabalho de cada papel, das aulas anteriores: os três do portal, da aula 1, o SSH em
toda parte e o serviço de nomes no `dns`, que a aula 14 montou. Os pacotes proibidos são os seis que a
aula 1 removeu. Depois o script que compara:

```schooling-example
{"language": "python", "file": "drift.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"drift.py: inventory.json against hosts.csv and baseline.json; one line per difference.\"\"\"\nimport csv, json\n\nhosts = {row[\"name\"]: row for row in csv.DictReader(open(\"hosts.csv\"))}\nbaseline = json.load(open(\"baseline.json\"))\ninventory = json.load(open(\"inventory.json\"))", "note": "Três arquivos: o que o escritório diz que tem (`hosts.csv`), como cada tipo de máquina deveria ser (`baseline.json`) e o que foi encontrado (`inventory.json`)."}, {"code": "\nfor name, facts in inventory.items():\n    if \"error\" in facts:\n        print(f\"{name:6} could not be read: {facts['error']}\")\n        continue\n    if name not in hosts:\n        print(f\"{name:6} not in hosts.csv: nobody owns it\")\n        continue", "note": "Uma máquina que não pôde ser lida é dita primeiro, com o motivo. Uma máquina que respondeu mas não está na lista é o achado seguinte, porque todo o resto sobre ela é desconhecido: ninguém é dono dela, então ninguém a corrige."}, {"code": "    row = hosts[name]\n    expected = set(baseline[\"listening\"][row[\"role\"]])\n    # above 32767 the kernel hands out ports nobody chose: a program's own socket, not a service\n    found = {p for p in facts[\"listening\"] if int(p.rsplit(\":\", 1)[1]) < 32768}\n    for port in sorted(found - expected):\n        print(f\"{name:6} listening, not in the baseline: {port}  (owner {row['owner']})\")\n    for port in sorted(expected - found):\n        print(f\"{name:6} in the baseline, not listening: {port}  (owner {row['owner']})\")\n    installed = {line.split(\" \")[0] for line in facts[\"packages\"]}\n    for pkg in sorted(installed & set(baseline[\"forbidden\"])):\n        print(f\"{name:6} forbidden package installed: {pkg}  (owner {row['owner']})\")", "note": "Depois cada máquina da lista contra a linha de base do papel dela: listeners que não deveriam estar ali, listeners que deveriam estar e não estão, e pacotes que o escritório decidiu que nenhuma máquina pode ter."}, {"code": "for name in sorted(set(hosts) - set(inventory)):\n    print(f\"{name:6} in hosts.csv, not collected\")", "note": "E a última checagem anda no sentido contrário: uma máquina da lista que nada coletou pode estar desligada, ter mudado de nome ou ter sumido, e a lista tem de dizer qual."}]}
```

Rode-o:

```
ana@admin:~$ python3 drift.py
web    listening, not in the baseline: tcp/0.0.0.0:111  (owner Marta)
web    listening, not in the baseline: tcp/0.0.0.0:21  (owner Marta)
web    listening, not in the baseline: tcp/0.0.0.0:23  (owner Marta)
web    listening, not in the baseline: udp/0.0.0.0:111  (owner Marta)
web    listening, not in the baseline: udp/0.0.0.0:161  (owner Marta)
web    listening, not in the baseline: udp/0.0.0.0:5353  (owner Marta)
web    forbidden package installed: avahi-daemon  (owner Marta)
web    forbidden package installed: inetutils-telnetd  (owner Marta)
web    forbidden package installed: openbsd-inetd  (owner Marta)
web    forbidden package installed: rpcbind  (owner Marta)
web    forbidden package installed: snmpd  (owner Marta)
web    forbidden package installed: vsftpd  (owner Marta)
dns    in the baseline, not listening: tcp/0.0.0.0:53  (owner Marta)
dns    in the baseline, not listening: udp/0.0.0.0:53  (owner Marta)
sw     not in hosts.csv: nobody owns it
trap   not in hosts.csv: nobody owns it
printer could not be read: ssh: Could not resolve hostname printer: Temporary failure in name resolution
```

Cada linha é um achado, e cada uma sobre uma máquina da lista tem um dono ao lado. O `web` vem
primeiro, com seis listeners que não estão na linha de base dele e os seis pacotes por trás deles:
exatamente o trabalho da aula 1, encontrado desta vez por um script que o acharia em cinquenta
máquinas tão facilmente quanto em uma. Depois o `dns`, cuja linha de base diz que ele responde nomes
na porta 53 e que não responde, porque toda aula começa com um laboratório novo e o resolvedor da aula
14 não está configurado neste.
Uma máquina que faz menos do que o papel dela diz também é desvio, do
tipo que aparece como indisponibilidade. Por último vêm as duas máquinas sem dono, e o `printer`, que
nem pôde ser lido.

## Fechando o desvio, e provando

O desvio se fecha do jeito que a aula 1 o fechou no `web`, e o inventário é como você prova que fechou:

```
ana@web:~$ sudo apt-get purge -y -q vsftpd openbsd-inetd inetutils-telnetd rpcbind avahi-daemon snmpd >/dev/null 2>&1; echo done
done
ana@admin:~$ python3 inventory.py web desk admin jump dns sw trap > /dev/null; python3 drift.py
dns    in the baseline, not listening: tcp/0.0.0.0:53  (owner Marta)
dns    in the baseline, not listening: udp/0.0.0.0:53  (owner Marta)
sw     not in hosts.csv: nobody owns it
trap   not in hosts.csv: nobody owns it
```

Depois da remoção, uma nova coleta e uma nova comparação, e o `web` não tem mais nada a informar. As
linhas que sobram são as que precisam de uma pessoa, não de um comando: um dono para duas máquinas e
uma decisão sobre o resolvedor.

**O ciclo, medir, comparar e corrigir, é o que a configuração centralizada da aula 3 automatiza.** Lá,
o estado desejado é escrito como playbook e aplicado; aqui, é escrito como linha de base e conferido.
Os dois são necessários, porque uma máquina pode se desviar entre execuções do primeiro, e só o segundo
diz que ela se desviou.
