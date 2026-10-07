---
title: Um playbook que pergunta antes
version: 1
---

Aqui está um playbook para o melhor alerta da aula 4, *login aceito a partir de um endereço que tentou
muitas contas*. É um programa Python curto, porque a lógica de um playbook é a mesma, rode ele no editor
visual de um produto ou num arquivo. Salve-o na pasta pessoal do root como `playbook.py`; ele precisa do
laboratório no ar, porque a única ação dele é no `fw`.

```schooling-example
{"language": "python", "file": "playbook.py", "parts": [{"code": "# playbook.py DB ADDRESS [--approve NAME]\n# For the alert \"login accepted from an address that tried many accounts\":\n# gather the facts, propose what to do, and act only when a named person approves.\nimport ipaddress, json, sqlite3, subprocess, sys, datetime as dt\n\nNEVER_BLOCK = {\"203.0.113.11\", \"203.0.113.17\", \"203.0.113.23\", \"203.0.113.31\",\n               \"203.0.113.41\",                  # staff, working from home\n               \"203.0.113.150\"}                 # the backup provider\nOURS = [ipaddress.ip_network(n) for n in (\"198.51.100.0/24\", \"192.168.20.0/24\", \"192.168.99.0/24\")]\ndb_path, address = sys.argv[1], sys.argv[2]\napprover = sys.argv[sys.argv.index(\"--approve\") + 1] if \"--approve\" in sys.argv else None", "note": "Duas listas mantidas por uma pessoa: endereços que uma máquina nunca pode bloquear, e as redes da própria empresa. O nome de quem aprova é um argumento, para que toda ação carregue um."}, {"code": "# 1. enrich: what else did this address do this week?\ndb = sqlite3.connect(db_path)\nfailures, accounts = db.execute(\n    \"SELECT count(*), count(DISTINCT user) FROM logs WHERE src_ip = ? AND action = 'failure'\",\n    (address,)).fetchone()\nlogins = db.execute(\n    \"SELECT timestamp, host, user, method FROM logs WHERE src_ip = ? AND action = 'success'\",\n    (address,)).fetchall()\nprint(f\"{address}: {failures} failed logins over {accounts} accounts, {len(logins)} accepted\")\nfor when, host, user, method in logins:", "note": "Enriquecimento: as perguntas que um analista faz primeiro, respondidas pelo SIEM antes de alguém abri-lo. Quanto esse endereço tentou, e onde conseguiu entrar?"}, {"code": "\n# 2. guard: some addresses are never blocked by a machine, whatever the alert says\nreasons = []\nif address in NEVER_BLOCK:\n    reasons.append(\"on the never-block list\")\nif any(ipaddress.ip_address(address) in net for net in OURS):", "note": "A proteção roda antes de qualquer decisão. Bloquear um parceiro, um fornecedor ou a própria rede é o jeito clássico de a automação causar a parada que deveria evitar."}, {"code": "\n# 3. propose\nactions = [] if reasons else [f\"block {address} at fw\"]\nfor user, host in sorted({(user, host) for _, host, user, _ in logins}):\n    actions.append(f\"disable {user} on {host} and reset the password (a person does this)\")\nticket = {\"opened\": dt.datetime.now(dt.timezone.utc).isoformat(timespec=\"seconds\"),\n          \"alert\": \"login accepted after many accounts tried\", \"address\": address,\n          \"failures\": failures, \"accounts_tried\": accounts,\n          \"accepted\": [list(row) for row in logins], \"not_automated\": reasons,\n          \"proposed\": actions, \"approved_by\": approver}\nfor a in actions:\n    print(\"  proposed:\", a)\nfor r in reasons:\n    print(f\"  refused to block: {address} is {r}\")", "note": "A proposta. Bloquear um endereço é reversível e estreito, então a máquina pode fazê-lo. Desativar uma conta mexe no trabalho de uma pessoa, então o playbook só diz, e uma pessoa faz."}, {"code": "# 4. act, only what was approved and only what a machine may do\nif approver and not reasons:\n    subprocess.run([\"ip\", \"netns\", \"exec\", \"fw\", \"nft\", \"insert\", \"rule\", \"ip\", \"fw\", \"forward\",\n                    \"ip\", \"saddr\", address, \"drop\", \"comment\", f'\"playbook, approved by {approver}\"'],\n                   check=True)\n    print(f\"  done: {address} blocked at fw, approved by {approver}\")", "note": "A única ação, tomada só com quem aprova nomeado e nenhuma proteção contra. O comentário da regra diz quem aprovou, então o próprio firewall registra a decisão."}, {"code": "with open(f\"ticket-{address}.json\", \"w\") as f:\n    json.dump(ticket, f, indent=2)\nprint(f\"  ticket written: ticket-{address}.json\")", "note": "Toda execução deixa um chamado, tendo agido ou não: o que se sabia, o que foi proposto, quem aprovou."}]}
```

Rode-o no endereço da noite de quinta, sem aprovar nada:

```
root@soc:~# python3 playbook.py /home/ana/week/siem.db 203.0.113.66
203.0.113.66: 57 failed logins over 19 accounts, 2 accepted
  accepted 2026-09-17 05:33:07 UTC on gw: bruno by password
  accepted 2026-09-17 06:05:22 UTC on gw: bruno by publickey
  proposed: block 203.0.113.66 at fw
  proposed: disable bruno on gw and reset the password (a person does this)
  ticket written: ticket-203.0.113.66.json
```

Em menos de um segundo ele fez o que tomou uma seção da aula 4 à mão: **57 falhas em 19 contas, depois dois
logins bem-sucedidos como bruno**, o segundo com chave. Ele propõe duas coisas, e diz qual delas é tarefa de
uma pessoa. E escreveu o chamado:

```
root@soc:~# cat ticket-203.0.113.66.json
{
  "opened": "2026-10-07T08:06:52+00:00",
  "alert": "login accepted after many accounts tried",
  "address": "203.0.113.66",
  "failures": 57,
  "accounts_tried": 19,
  "accepted": [
    [
      "2026-09-17 05:33:07",
      "gw",
      "bruno",
      "password"
    ],
    [
      "2026-09-17 06:05:22",
      "gw",
      "bruno",
      "publickey"
    ]
  ],
  "not_automated": [],
  "proposed": [
    "block 203.0.113.66 at fw",
    "disable bruno on gw and reset the password (a person does this)"
  ],
  "approved_by": null
}
```

`"approved_by": null`: nada foi feito, e o chamado diz isso. Agora a ana lê a proposta, concorda e aprova
com o próprio nome:

```
root@soc:~# python3 playbook.py /home/ana/week/siem.db 203.0.113.66 --approve ana
203.0.113.66: 57 failed logins over 19 accounts, 2 accepted
  accepted 2026-09-17 05:33:07 UTC on gw: bruno by password
  accepted 2026-09-17 06:05:22 UTC on gw: bruno by publickey
  proposed: block 203.0.113.66 at fw
  proposed: disable bruno on gw and reset the password (a person does this)
  done: 203.0.113.66 blocked at fw, approved by ana
  ticket written: ticket-203.0.113.66.json
root@soc:~# ip netns exec fw nft list chain ip fw forward
table ip fw {
	chain forward {
		type filter hook forward priority filter; policy accept;
		ip saddr 203.0.113.66 drop comment "playbook, approved by ana"
		ct state new log prefix "fw-new " group 1
	}
}
root@soc:~# ip netns exec outside runuser -u ana -- ssh -o BatchMode=yes -o ConnectTimeout=3 ana@198.51.100.22 true
ssh: connect to host 198.51.100.22 port 22: Connection timed out
```

A regra fica em primeiro lugar na cadeia do `fw`, com o nome da ana no comentário, e uma conexão a partir
do endereço bloqueado agora estoura o tempo. O próprio firewall virou registro da decisão; quem listar as
regras dele descobre quem acrescentou esta e por quê.

Repare no que o playbook **não** fez. Ele não mexeu na conta do bruno. Isso continua como proposta no
chamado, para uma pessoa que consiga descobrir se o bruno, e não alguém usando a senha dele, também entrou
de casa naquela manhã, antes de decidir se interrompe o trabalho dele.
