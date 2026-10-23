---
title: O que cada máquina roda
version: 1
---

**Uma lista de máquinas diz onde olhar. Um inventário de software diz o que está lá**: o sistema
operacional, cada pacote e sua versão, o que está rodando, o que escuta na rede e o que está segurado.
A aula 1 fez essas perguntas a uma máquina, à mão. Aqui um script as faz a todas, pelo acesso SSH que a
aula 15 tornou o único caminho de entrada, e guarda as respostas num arquivo só.

```schooling-example
{"language": "python", "file": "inventory.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"inventory.py HOST...: what each machine is and runs, collected over SSH, written to inventory.json.\"\"\"\nimport json, subprocess, sys\n\nASK = {\n    \"os\": \". /etc/os-release && echo $PRETTY_NAME\",\n    \"packages\": \"dpkg-query -W -f='${Package} ${Version}\\\\n'\",\n    \"services\": \"systemctl list-units --type=service --state=running --no-legend --plain | cut -d' ' -f1\",\n    \"listening\": \"ss -Htuln | awk '{print $1 \\\"/\\\" $5}' | sort -u\",\n    \"held\": \"apt-mark showhold\",\n}", "note": "Cinco perguntas, cada uma um comando que toda máquina Ubuntu já tem. Um inventário não precisa de agente para começar: o mesmo acesso SSH que a aula 15 controla basta, e o que é coletado é exatamente o que as aulas anteriores perguntaram a uma máquina por vez."}, {"code": "\ndef ask(host, command):\n    r = subprocess.run([\"ssh\", \"-o\", \"ConnectTimeout=3\", host, command], capture_output=True, text=True)\n    if r.returncode != 0:\n        raise RuntimeError(r.stderr.strip() or f\"exit {r.returncode}\")\n    return r.stdout.strip().splitlines()", "note": "Toda resposta passa por uma função só, e uma máquina que não responde gera um erro em vez de devolver uma lista vazia. **Uma resposta vazia pareceria uma máquina sem nada dentro**, que é o pior erro que um inventário pode cometer."}, {"code": "\ninventory = {}\nfor host in sys.argv[1:]:\n    try:\n        facts = {name: ask(host, command) for name, command in ASK.items()}\n    except RuntimeError as e:\n        inventory[host] = {\"error\": str(e)}\n        print(f\"{host:6} UNREACHABLE  {e}\")\n        continue\n    facts[\"os\"] = facts[\"os\"][0]\n    inventory[host] = facts\n    print(f'{host:6} {facts[\"os\"]:22} {len(facts[\"packages\"]):4} packages  '\n          f'{len(facts[\"services\"]):3} services  listening: {\" \".join(facts[\"listening\"])}')\n\njson.dump(inventory, open(\"inventory.json\", \"w\"), indent=1)", "note": "Uma máquina que não pôde ser lida é anotada como tal, com o motivo, e a execução segue com as outras. O resultado inteiro fica em `inventory.json`, para o próximo script comparar."}]}
```

Rode-o sobre cada máquina da lista, as duas não listadas e um nome que não existe, para ver como é uma
falha:

```
ana@admin:~$ python3 inventory.py web desk admin jump dns sw trap printer
web    Ubuntu 24.04 LTS        322 packages   17 services  listening: tcp/0.0.0.0:111 tcp/0.0.0.0:21 tcp/0.0.0.0:22 tcp/0.0.0.0:23 tcp/0.0.0.0:80 tcp/127.0.0.1:8080 udp/0.0.0.0:111 udp/0.0.0.0:161 udp/0.0.0.0:46010 udp/0.0.0.0:5353
desk   Ubuntu 24.04 LTS        308 packages   10 services  listening: tcp/0.0.0.0:22
admin  Ubuntu 24.04 LTS        308 packages   10 services  listening: tcp/0.0.0.0:22
jump   Ubuntu 24.04 LTS        308 packages   10 services  listening: tcp/0.0.0.0:22
dns    Ubuntu 24.04 LTS        308 packages   10 services  listening: tcp/0.0.0.0:22
sw     Ubuntu 24.04 LTS        308 packages   10 services  listening: tcp/0.0.0.0:22
trap   Ubuntu 24.04 LTS        308 packages   10 services  listening: tcp/0.0.0.0:22
printer UNREACHABLE  ssh: Could not resolve hostname printer: Temporary failure in name resolution
```

Uma linha por máquina, e a forma já informa. Seis máquinas rodam os mesmos 308 pacotes e os mesmos 10
serviços, porque vêm da mesma imagem e ninguém as mudou, e cada uma escuta só o SSH. O `web` se
destaca: 322 pacotes, 17 serviços e dez listeners, entre eles FTP na 21, telnet na 23 e SNMP na 161,
cada um deles um achado da aula 1, de volta porque toda aula começa com um laboratório novo.

A última linha é a falha: `printer` não é um nome que o laboratório conhece, e o script diz isso em vez
de informar uma máquina vazia. O arquivo `inventory.json` agora guarda tudo o que foi coletado, pacote
por pacote, e a avaliação da aula 16 pode rodar sobre ele para todas as máquinas de uma vez em vez de
uma.

**Esta é a metade medida do inventário**, e ela tem de se repetir: o software de um notebook muda toda
semana, e um inventário de um mês atrás descreve um escritório que não existe mais. Agentes existem
para que ele rode o tempo todo; o script é a mesma ideia rodada à mão.
