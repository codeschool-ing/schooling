---
title: A política como tabela, as regras como sua saída
version: 1
---

A política fica em `admin`, em um arquivo de texto que qualquer um pode revisar em um pull request:

```
root@admin:~# cat policy.txt
# host   address        role    accepts     on port   from roles
app      192.168.20.10  app     http        8080      proxy
db       192.168.20.30  db      postgres    5432      app
www      192.0.2.80     proxy   -           -         -
admin    192.168.99.10  admin   -           -         -
*        -              -       ssh         22        admin
```

Cada linha de servidor diz o **papel** que a máquina cumpre, o que ela **aceita**, em qual **porta** e
de quais **papéis**. A última linha vale para todo host: SSH a partir do papel `admin`. Nada cita um
endereço na coluna *de*. Um papel é convertido em endereços quando as regras são geradas, então um novo
servidor de aplicação acrescentado à tabela com o papel `app` recebe a permissão do banco de dados na
próxima vez que as regras forem geradas, sem que ninguém edite as regras do banco de dados.

O gerador é um programa curto em Python:

```schooling-example
{"language": "python", "file": "segment.py", "parts": [{"code": "import sys\n\nrows = [l.split() for l in open(\"policy.txt\") if l.strip() and not l.startswith(\"#\")]", "note": "Cada linha da política que não é comentário, dividida nas suas seis colunas."}, {"code": "address = {r[2]: [] for r in rows if r[2] != \"-\"}\nfor r in rows:\n    if r[2] != \"-\":\n        address[r[2]].append(r[1])", "note": "De papel para endereços: o único lugar onde nomes viram números. Duas máquinas com um mesmo papel seriam as duas listadas sob ele."}, {"code": "host = sys.argv[1]\nmine = [r for r in rows if r[0] in (host, \"*\") and r[3] != \"-\"]", "note": "As linhas que descrevem o que este host aceita: as dele e as que valem para todo host."}, {"code": "print(\"flush ruleset\\ntable inet host {\\n  chain input {\")\nprint(\"    type filter hook input priority filter; policy drop;\")\nprint(\"    ct state established,related accept\\n    iifname \\\"lo\\\" accept\")", "note": "A parte fixa das regras de todo host: descartar por padrão, respostas e loopback permitidos. A negação por padrão da aula 5, em toda máquina."}, {"code": "for _, _, _, service, port, sources in mine:\n    peers = \", \".join(a for role in sources.split(\",\") for a in address[role])\n    print(f\"    ip saddr {{ {peers} }} tcp dport {port} accept comment \\\"{service} from {sources}\\\"\")\nprint(\"  }\\n}\")", "note": "Um aceite por serviço, a partir dos endereços dos papéis permitidos, com as próprias palavras da política como comentário. A regra gerada diz por que existe."}]}
```

Para `db`:

```
root@admin:~# python3 segment.py db
flush ruleset
table inet host {
  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    iifname "lo" accept
    ip saddr { 192.168.20.10 } tcp dport 5432 accept comment "postgres from app"
    ip saddr { 192.168.99.10 } tcp dport 22 accept comment "ssh from admin"
  }
}
```

As mesmas regras que a aula 19 escreveu à mão para `db`, agora derivadas. Para `app`, só as linhas de
aceite:

```
root@admin:~# python3 segment.py app | grep accept
    ct state established,related accept
    iifname "lo" accept
    ip saddr { 192.0.2.80 } tcp dport 8080 accept comment "http from proxy"
    ip saddr { 192.168.99.10 } tcp dport 22 accept comment "ssh from admin"
```

A aplicação aceita HTTP do papel de proxy e SSH do papel de administração. Cada arquivo é copiado para o
seu servidor e carregado, quatro linhas de aceite em cada um:

```
root@db:~# nft -f segment.nft && nft list chain inet host input | grep -c accept
4
root@app:~# nft -f segment.nft && nft list chain inet host input | grep -c accept
4
```
