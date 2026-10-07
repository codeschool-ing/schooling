---
title: Um substituto que o banco consegue buscar
version: 1
---

Para achar um cliente pelo CPF, o banco precisa de uma coluna em que o mesmo CPF dê sempre o mesmo
valor — para poder ser indexada e comparada — e da qual ninguém consiga voltar ao CPF. Uma
cifração com nonce aleatório falha no primeiro teste; um hash simples falha no segundo, porque um
CPF tem só onze dígitos e todos eles podem passar pelo hash numa tarde.

**Um hash com chave — um HMAC — passa nos dois**, desde que a chave esteja onde ninguém a leia. O
motor transit do OpenBao calcula HMACs com uma chave que nunca sai dele:

```
ana@lab:~/gov$ bao write -f transit/keys/ipe-cpf-index
Key                       Value
---                       -----
allow_plaintext_backup    false
auto_rotate_period        0s
deletion_allowed          false
derived                   false
exportable                false
imported_key              false
keys                      map[1:1791344084]
latest_version            1
min_available_version     0
min_decryption_version    1
min_encryption_version    0
name                      ipe-cpf-index
soft_deleted              false
supports_decryption       true
supports_derivation       true
supports_encryption       true
supports_signing          false
type                      aes256-gcm96
ana@lab:~/gov$ bao write -field=hmac transit/hmac/ipe-cpf-index input=$(printf '372.874.168-09' | base64); echo
vault:v1:l1jDUSj8dorJ9bd8Knbe/1D+8q/tjs/3hyLEVtJ/qBg=
ana@lab:~/gov$ bao write -field=hmac transit/hmac/ipe-cpf-index input=$(printf '372.874.168-09' | base64); echo
vault:v1:l1jDUSj8dorJ9bd8Knbe/1D+8q/tjs/3hyLEVtJ/qBg=
```

O mesmo CPF, duas vezes, o mesmo HMAC. Sem `ipe-cpf-index` — que não é exportável — ninguém o
calcula, então a coluna pode ficar no banco, nos backups e nas exportações sem ser um dicionário de
CPFs. O `v1` é a versão da chave, como na aula 4.

A coluna é preenchida do mesmo jeito que a aula 4 cifrou os CPFs, por um script que chama o OpenBao
em lotes:

```python
"""Give every customer a searchable stand-in for the CPF: an HMAC made by
OpenBao with a key nobody can read. Equal CPFs give equal HMACs, so the
database can find a customer by CPF without holding one."""
import base64, csv, io, json, os, ssl, subprocess, urllib.request

TLS = ssl.create_default_context(cafile=os.environ["BAO_CACERT"])
TOKEN = open(os.path.expanduser("~/.vault-token")).read().strip()

def psql(sql):
    return subprocess.run(["psql", "-X", "-q", "-f", "-"], input=sql,
                          capture_output=True, text=True, check=True).stdout

def hmac(values):
    body = json.dumps({"batch_input": [
        {"input": base64.b64encode(v.encode()).decode()} for v in values]})
    req = urllib.request.Request(os.environ["BAO_ADDR"] + "/v1/transit/hmac/ipe-cpf-index",
                                 data=body.encode(), method="POST",
                                 headers={"X-Vault-Token": TOKEN})
    with urllib.request.urlopen(req, context=TLS) as r:
        return [b["hmac"] for b in json.load(r)["data"]["batch_results"]]

rows = list(csv.reader(io.StringIO(psql(
    "SET ROLE ipe_owner;\n"
    "COPY (SELECT customer_id, cpf FROM sales.customers ORDER BY 1) TO STDOUT (FORMAT csv);"))))
pairs = []
for i in range(0, len(rows), 250):
    chunk = rows[i:i + 250]
    pairs += zip([c for c, _ in chunk], hmac([cpf for _, cpf in chunk]))
values = ",\n".join(f"({c}, '{h}')" for c, h in pairs)
psql("SET ROLE ipe_owner;\n"
     "UPDATE sales.customers c SET cpf_hmac = v.h\n"
     f"FROM (VALUES {values}) AS v(id, h) WHERE c.customer_id = v.id;")
print(len(pairs), "CPFs indexed")
```

```
ana@lab:~/gov$ psql -f index.sql
SET
ALTER TABLE
ana@lab:~/gov$ python3 index_cpf.py
6012 CPFs indexed
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "CREATE UNIQUE INDEX ON sales.customers (cpf_hmac)"
SET
ERROR:  could not create unique index "customers_cpf_hmac_idx"
DETAIL:  Key (cpf_hmac)=(vault:v1:Eii5YuOYAXbl+hlcEt0CdNwT9j9dVb47y8q6vKayXRY=) is duplicated.
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT count(*) AS cpfs_twice FROM (SELECT cpf_hmac FROM sales.customers GROUP BY cpf_hmac HAVING count(*) > 1) d"
SET
 cpfs_twice 
------------
         12
(1 row)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "CREATE INDEX ON sales.customers (cpf_hmac)"
SET
CREATE INDEX
```

**O índice único foi recusado**, e isso é um achado, não um bug do script. Doze HMACs aparecem duas
vezes, o que quer dizer que doze CPFs aparecem duas vezes: a mesma pessoa cadastrada como dois
clientes. A aula 9 mede a qualidade dos dados e acha esses doze por outro lado; aqui eles chegaram
porque um índice fez a pergunta que ninguém tinha feito antes. O índice é criado sem `UNIQUE`, e os
duplicados vão para a lista da aula 9.

## Por que um HMAC e não um token de cofre

Os dois deixariam o banco achar um cliente. A diferença está no que precisa ser chamado, e quando:

| | token aleatório e cofre | hash com chave (HMAC) |
|---|---|---|
| mesma entrada, mesma saída | só consultando o cofre | sim, calculando |
| quem guarda o mapeamento | o cofre, uma tabela que precisa ser protegida | ninguém: não há mapeamento, só uma chave |
| achar um cliente por um CPF ditado ao telefone | pedir ao cofre o token do CPF, depois buscar | calcular o HMAC, depois buscar |
| ter o CPF de volta | destokenizar | impossível a partir do HMAC — decifra-se o `cpf_ct` |

O HMAC é um **substituto de mão única**: perfeito para buscar e juntar, inútil para ler. É por isso
que o CPF acaba com duas colunas, cada uma com um trabalho, e é por isso que a próxima seção pode
apagar a terceira.
