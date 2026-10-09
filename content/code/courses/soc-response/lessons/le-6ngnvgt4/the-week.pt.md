---
title: A semana que o SIEM vai ler
version: 1
---

Um SIEM só vale a pena se tiver o que ler, e os logs do próprio laboratório, da aula 1, cobrem poucos
minutos. O resto do curso lê uma **semana**: de segunda, 14, a domingo, 20 de setembro de 2026, na empresa
do laboratório, escrita por um programa curto para que todo leitor receba exatamente as mesmas linhas.
Crie uma pasta chamada `week` na sua pasta pessoal e salve isto nela como `week.py`:

```schooling-example
{"language": "python", "file": "week.py", "parts": [{"code": "# week.py: one week of logs from the company in the lab, 14 to 20 September 2026.\n# Ordinary days, plus one night somebody has to find. Same output on every run.\nimport random, datetime as dt\n\nrandom.seed(7)\nZ = dt.timezone(dt.timedelta(hours=-3))\nSTAFF = {\"ana\": \"203.0.113.11\", \"bruno\": \"203.0.113.17\", \"carla\": \"203.0.113.23\",\n         \"diego\": \"203.0.113.31\", \"helena\": \"203.0.113.41\"}\nKEYS = {\"ana\", \"diego\"}                      # who logs in with a key\nGUESSES = [\"root\", \"admin\", \"test\", \"oracle\", \"ubuntu\", \"user\", \"backup\", \"git\"]\nauth, fw, flows = [], [], []", "note": "O elenco: cinco pessoas e os endereços de casa de onde trabalham, quais duas entram com chave, e os nomes que estranhos na internet tentam. `random.seed(7)` faz toda execução sair igual."}, {"code": "def t(day, h, m, s=0):\n    return dt.datetime(2026, 9, day, h, m, s, tzinfo=Z)\n\n\ndef port():\n    return random.randint(32768, 60999)\n\n\ndef ssh(when, host, text):\n    auth.append((when, f\"{when:%Y-%m-%dT%H:%M:%S%z} {host} sshd: {text}\"))\n\n\ndef conn(when, inn, out, src, dst, dport):\n    fw.append((when, f\"{when:%b %e %H:%M:%S} fw fw-new  IN={inn} OUT={out} \"\n                     f\"SRC={src} DST={dst} PROTO=TCP SPT={port()} DPT={dport}\"))\n\n\ndef flow(when, src, dst, dport, seconds, nbytes):\n    flows.append((when, f\"{when:%Y-%m-%d %H:%M:%S},{seconds},{src},{dst},{dport},{nbytes}\"))\n\n\ndef attempt(when, src, name, known):\n    conn(when, \"eth0\", \"eth1\", src, \"198.51.100.22\", 22)\n    if known:\n        ssh(when, \"gw\", f\"Failed password for {name} from {src} port {port()} ssh2\")\n    else:\n        ssh(when, \"gw\", f\"Invalid user {name} from {src} port {port()}\")\n\n\ndef login(when, user, src, how):\n    conn(when, \"eth0\", \"eth1\", src, \"198.51.100.22\", 22)\n    ssh(when, \"gw\", f\"Accepted {how} for {user} from {src} port {port()} ssh2\")", "note": "Quatro escritores, um por tipo de linha, nos formatos da aula 1: `ssh` no formato do `ts`, `conn` como o do firewall (só os campos que o curso lê), e `flow` como uma linha de CSV."}, {"code": "for day in range(14, 21):\n    conn(t(day, 1, 0), \"eth2\", \"eth0\", \"192.168.20.10\", \"203.0.113.150\", 443)\n    flow(t(day, 1, 0), \"192.168.20.10\", \"203.0.113.150\", 443,\n         random.randint(500, 700), random.randint(330, 380) * 1_000_000)  # nightly backup\n    for n in range(random.randint(4, 8)):              # strangers trying common names\n        src = f\"203.0.113.{random.randint(100, 199)}\"\n        when = t(day, random.randint(0, 23), random.randint(0, 59), random.randint(0, 59))\n        for name in random.sample(GUESSES, random.randint(1, 3)):\n            when += dt.timedelta(seconds=random.randint(2, 9))\n            attempt(when, src, name, name == \"root\")\n    if dt.date(2026, 9, day).weekday() < 5:            # staff start work from home\n        for user, src in STAFF.items():\n            when = t(day, 8, random.randint(0, 59), random.randint(0, 59))\n            if user not in KEYS and random.random() < 0.15:   # a typo first\n                attempt(when, src, user, True)\n                when += dt.timedelta(seconds=random.randint(4, 12))\n            login(when, user, src, \"publickey\" if user in KEYS else \"password\")\n            if user == \"diego\":                         # IT: on to the file server\n                when += dt.timedelta(minutes=random.randint(2, 20))\n                conn(when, \"eth1\", \"eth2\", \"198.51.100.22\", \"192.168.20.10\", 22)\n                ssh(when, \"files\", f\"Accepted publickey for diego from 198.51.100.22 port {port()} ssh2\")", "note": "Um dia comum: o backup noturno para um provedor fixo à 01:00, um punhado de estranhos tentando nomes comuns, e nos dias úteis todo mundo entrando por volta das oito, de vez em quando depois de um erro de digitação. O Diego, que cuida da TI, segue para o servidor de arquivos."}, {"code": "# Thursday night\nnames = list(STAFF) + GUESSES + [\"finance\", \"hr\", \"scanner\", \"printer\", \"support\", \"dev\"]\nwhen = t(17, 2, 10)\nfor _ in range(3):\n    for name in names:\n        when += dt.timedelta(seconds=random.randint(5, 9))\n        attempt(when, \"203.0.113.66\", name, name in STAFF or name == \"root\")\nlogin(t(17, 2, 33, 7), \"bruno\", \"203.0.113.66\", \"password\")\nconn(t(17, 2, 35, 40), \"eth1\", \"eth2\", \"198.51.100.22\", \"192.168.20.10\", 22)\nssh(t(17, 2, 35, 40), \"files\", \"Accepted password for bruno from 198.51.100.22 port 40112 ssh2\")\nconn(t(17, 2, 41, 12), \"eth2\", \"eth0\", \"192.168.20.10\", \"203.0.113.200\", 443)\nflow(t(17, 2, 41, 12), \"192.168.20.10\", \"203.0.113.200\", 443, 1104, 612_408_119)\nlogin(t(17, 3, 5, 22), \"bruno\", \"203.0.113.66\", \"publickey\")", "note": "A noite que o resto do curso investiga. Você está lendo o gerador, então conhece a história; os exercícios pedem que você a encontre com as ferramentas, como faria sem gerador nenhum para ler."}, {"code": "for name, rows in ((\"auth.log\", auth), (\"fw.log\", fw), (\"flows.csv\", flows)):\n    with open(name, \"w\") as f:\n        if name == \"flows.csv\":\n            f.write(\"start,seconds,src,dst,dport,bytes\\n\")\n        f.writelines(line + \"\\n\" for _, line in sorted(rows))", "note": "Cada arquivo ordenado por tempo e escrito uma vez."}]}
```

Rode-o, e olhe o que ele escreveu:

```
ana@soc:~/week$ python3 week.py
ana@soc:~/week$ wc -l auth.log fw.log flows.csv
  183 auth.log
  191 fw.log
    9 flows.csv
  383 total
ana@soc:~/week$ head -n 2 auth.log; head -n 2 fw.log; head -n 3 flows.csv
2026-09-14T06:31:52-0300 gw sshd: Invalid user backup from 203.0.113.179 port 47617
2026-09-14T06:31:59-0300 gw sshd: Invalid user git from 203.0.113.179 port 40908
Sep 14 01:00:00 fw fw-new  IN=eth2 OUT=eth0 SRC=192.168.20.10 DST=203.0.113.150 PROTO=TCP SPT=43379 DPT=443
Sep 14 06:31:52 fw fw-new  IN=eth0 OUT=eth1 SRC=203.0.113.179 DST=198.51.100.22 PROTO=TCP SPT=51955 DPT=22
start,seconds,src,dst,dport,bytes
2026-09-14 01:00:00,538,192.168.20.10,203.0.113.150,443,355000000
2026-09-15 01:00:00,652,192.168.20.10,203.0.113.150,443,361000000
```

Três arquivos, 383 linhas, em formatos que você já conhece: `auth.log` é o SSH do `gw` e do `files`,
`fw.log` é a linha do firewall para cada conexão nova, e `flows.csv` guarda um resumo por transferência
longa. Repare que a primeira linha do firewall, à 01:00 de segunda, é o backup saindo para
`203.0.113.150`, e o arquivo de fluxos o mostra toda noite com algo entre 340 e 370 MB. É assim que o
normal se parece aqui, e as aulas seguintes voltam a isso o tempo todo.

Você vai reencontrar esses arquivos nas aulas 5 a 15. Guarde a pasta; se perdê-la, rodar o `week.py` de
novo refaz cada arquivo de forma idêntica.
