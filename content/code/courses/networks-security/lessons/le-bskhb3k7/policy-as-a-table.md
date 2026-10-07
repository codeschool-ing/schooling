---
title: The policy as a table, the rules as its output
version: 1
---

The policy lives on `admin`, in a text file anybody can review in a pull request. In your lab this
lesson starts from `sudo bash nslab.sh reset`, with the company's policy loaded on `fw` by
`nft -f baseline.nft`; write `policy.txt` and `segment.py` in `/root` on `admin`, as they are printed
below.

```
root@admin:~# cat policy.txt
# host   address        role    accepts     on port   from roles
app      192.168.20.10  app     http        8080      proxy
db       192.168.20.30  db      postgres    5432      app
www      192.0.2.80     proxy   -           -         -
admin    192.168.99.10  admin   -           -         -
*        -              -       ssh         22        admin
```

Each server row names the role the machine plays, what it accepts, on which port, and from which
roles. The last row applies to every host: SSH from the `admin` role. Nothing names an address in the
*from* column. **A role becomes addresses only when the rules are generated.** A new application server
added to the table with the role `app` therefore gets the database's permission at the next generation,
and nobody edits the database's rules.

The generator is a short Python program:

```schooling-example
{"language": "python", "file": "segment.py", "parts": [{"code": "import sys\n\nrows = [l.split() for l in open(\"policy.txt\") if l.strip() and not l.startswith(\"#\")]", "note": "Every non-comment line of the policy, split into its six columns."}, {"code": "address = {r[2]: [] for r in rows if r[2] != \"-\"}\nfor r in rows:\n    if r[2] != \"-\":\n        address[r[2]].append(r[1])", "note": "Role to addresses: the one place where names become numbers. Two machines with one role would both be listed under it."}, {"code": "host = sys.argv[1]\nmine = [r for r in rows if r[0] in (host, \"*\") and r[3] != \"-\"]", "note": "The rows that describe what this host accepts: its own, and the ones that apply to every host."}, {"code": "print(\"flush ruleset\\ntable inet host {\\n  chain input {\")\nprint(\"    type filter hook input priority filter; policy drop;\")\nprint(\"    ct state established,related accept\\n    iifname \\\"lo\\\" accept\")", "note": "The fixed part of every host's rules: drop by default, replies and loopback allowed. Lesson 5's deny by default, on every machine."}, {"code": "for _, _, _, service, port, sources in mine:\n    peers = \", \".join(a for role in sources.split(\",\") for a in address[role])\n    print(f\"    ip saddr {{ {peers} }} tcp dport {port} accept comment \\\"{service} from {sources}\\\"\")\nprint(\"  }\\n}\")", "note": "One accept per service, from the addresses of the roles allowed, with the policy's own words as the comment. The generated rule says why it exists."}]}
```

For `db`:

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

The same rules lesson 19 wrote by hand for `db`, now derived. For `app`, the accept lines only:

```
root@admin:~# python3 segment.py app | grep accept
    ct state established,related accept
    iifname "lo" accept
    ip saddr { 192.0.2.80 } tcp dport 8080 accept comment "http from proxy"
    ip saddr { 192.168.99.10 } tcp dport 22 accept comment "ssh from admin"
```

The application accepts HTTP from the proxy role and SSH from the admin role. Each file is copied to its
server and loaded, four accept lines on each. In the lab the copying is one line on your own computer,
the job a configuration management tool does in a real company:

```sh
for h in app db; do sudo bash nslab.sh exec admin root "python3 segment.py $h" | sudo tee /lab/$h/root/segment.nft >/dev/null; done
```

```
root@db:~# nft -f segment.nft && nft list chain inet host input | grep -c accept
4
root@app:~# nft -f segment.nft && nft list chain inet host input | grep -c accept
4
```
