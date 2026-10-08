---
title: Normalizar: um nome para cada coisa
version: 1
---

Três arquivos, três vocabulários. O SSH diz `from 203.0.113.66`, o firewall diz `SRC=203.0.113.66`, o
arquivo de fluxos tem uma coluna chamada `src`. Uma pergunta como "tudo o que este endereço fez" precisa
ser feita de três jeitos, e a hora do firewall não tem ano. A **normalização** escreve cada evento uma vez,
numa tabela, com um nome para cada coisa. Salve isto como `load.py`, na mesma pasta:

```schooling-example
{"language": "python", "file": "load.py", "parts": [{"code": "# load.py: read the week's three files into one table, every field named the same way\nimport csv, re, sqlite3, datetime as dt\n\nSP = dt.timezone(dt.timedelta(hours=-3))\ndb = sqlite3.connect(\"siem.db\")\ndb.execute(\"DROP TABLE IF EXISTS logs\")\ndb.execute(\"\"\"CREATE TABLE logs (timestamp TEXT, host TEXT, product TEXT, action TEXT,\n              detail TEXT, user TEXT, method TEXT, src_ip TEXT, dst_ip TEXT,\n              dst_port INTEGER, bytes INTEGER, raw TEXT)\"\"\")", "note": "Uma tabela, `logs`, com as mesmas colunas para toda fonte. O nome é o que o backend SQLite do Sigma espera."}, {"code": "def utc(when):\n    return when.astimezone(dt.timezone.utc).strftime(\"%Y-%m-%d %H:%M:%S\")", "note": "Toda hora é guardada em UTC, como a aula 2 pediu."}, {"code": "SSH = re.compile(r\"(?P<ts>\\S+) (?P<host>\\S+) sshd: (?:Accepted (?P<method>\\S+) for (?P<ok>\\S+)\"\n                 r\"|Failed password for (?P<bad>\\S+)|Invalid user (?P<unknown>\\S+)) from (?P<src>\\S+)\")\nrows = []\nfor line in open(\"auth.log\"):\n    m = SSH.match(line)\n    if not m:\n        continue\n    when = dt.datetime.strptime(m[\"ts\"], \"%Y-%m-%dT%H:%M:%S%z\")\n    action = \"success\" if m[\"ok\"] else \"failure\"\n    detail = \"unknown_user\" if m[\"unknown\"] else (\"wrong_password\" if m[\"bad\"] else None)\n    user = m[\"ok\"] or m[\"bad\"] or m[\"unknown\"]\n    rows.append((utc(when), m[\"host\"], \"sshd\", action, detail, user, m[\"method\"],\n                 m[\"src\"], None, 22, None, line.strip()))", "note": "Uma linha de SSH vira `success` ou `failure`, com a conta que ela citou e, numa falha, se essa conta existe. A expressão regular é o parser; uma linha que não casa é ignorada, e um SIEM de verdade contaria essas."}, {"code": "for line in open(\"fw.log\"):\n    # the firewall writes no year and no zone: both are assumed here, out loud\n    when = dt.datetime.strptime(\"2026 \" + line[:15], \"%Y %b %d %H:%M:%S\").replace(tzinfo=SP)\n    f = dict(p.split(\"=\", 1) for p in line.split() if \"=\" in p)\n    rows.append((utc(when), \"fw\", \"firewall\", \"connection\", None, None, None,\n                 f[\"SRC\"], f[\"DST\"], int(f[\"DPT\"]), None, line.strip()))", "note": "A linha do firewall não tem ano nem fuso, então os dois são fornecidos aqui, escritos onde qualquer pessoa que leia o código os vê."}, {"code": "for r in csv.DictReader(open(\"flows.csv\")):\n    when = dt.datetime.strptime(r[\"start\"], \"%Y-%m-%d %H:%M:%S\").replace(tzinfo=SP)\n    rows.append((utc(when), \"fw\", \"flow\", \"flow\", None, None, None,\n                 r[\"src\"], r[\"dst\"], int(r[\"dport\"]), int(r[\"bytes\"]), \",\".join(r.values())))", "note": "Uma linha de fluxo guarda os bytes, o único campo que nenhum dos dois logs tem."}, {"code": "db.executemany(\"INSERT INTO logs VALUES (?,?,?,?,?,?,?,?,?,?,?,?)\", rows)\ndb.commit()\nprint(len(rows), \"rows in siem.db\")"}]}
```

Rode-o e conte o que entrou:

```
ana@soc:~/week$ python3 load.py
382 rows in siem.db
ana@soc:~/week$ sqlite3 -header -column siem.db 'SELECT product, action, count(*) AS n FROM logs GROUP BY 1, 2'
product   action      n  
--------  ----------  ---
firewall  connection  191
flow      flow        8  
sshd      failure     150
sshd      success     33 
```

382 linhas de tabela a partir de 383 linhas de arquivo: o cabeçalho do CSV não é um evento. Uma linha,
com todos os campos, ao lado da linha de onde veio:

```
ana@soc:~/week$ sqlite3 -line siem.db "SELECT * FROM logs WHERE user = 'hr' LIMIT 1"
timestamp = 2026-09-17 05:11:39
     host = gw
  product = sshd
   action = failure
   detail = unknown_user
     user = hr
   method = 
   src_ip = 203.0.113.66
   dst_ip = 
 dst_port = 22
    bytes = 
      raw = 2026-09-17T02:11:39-0300 gw sshd: Invalid user hr from 203.0.113.66 port 37412
```

A linha crua fica guardada ao lado dos campos. **Nunca jogue o original fora**: o parser é código, código
tem defeitos, e o dia em que um campo se revela errado é o dia em que é preciso interpretar de novo.
Repare também em `detail = unknown_user`, que diz que a conta `hr` não existe no `gw`. Essa distinção,
entre uma senha errada e uma conta que não está lá, vem da aula 2, e a aula 9 depende dela.

A linha do firewall mostra a outra metade da normalização, a hora:

```
ana@soc:~/week$ sqlite3 siem.db "SELECT timestamp, raw FROM logs WHERE product = 'firewall' LIMIT 1"
2026-09-14 04:00:00|Sep 14 01:00:00 fw fw-new  IN=eth2 OUT=eth0 SRC=192.168.20.10 DST=203.0.113.150 PROTO=TCP SPT=43379 DPT=443
```

A linha diz `Sep 14 01:00:00`, horário local, sem ano; a tabela diz `2026-09-14 04:00:00`, em UTC. As duas
suposições, o ano e o fuso, estão escritas no `load.py`, onde quem lê as vê. Um SIEM faz a mesma coisa por
configuração em vez de código, e a configuração merece o mesmo escrutínio: **um fuso errado numa fonte
desloca cada um dos eventos dela em horas**, e nenhum alerta avisa.
