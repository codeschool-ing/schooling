---
title: Respondendo a um pedido, do começo ao fim
version: 1
---

O **artigo 19** fixa os prazos para confirmação e acesso. A resposta pode ser dada em **formato
simplificado, imediatamente**; ou por meio de **declaração clara e completa** — com a origem dos
dados, os critérios usados e a finalidade, observados os segredos comercial e industrial — **em até
15 dias** contados do requerimento. Quando o tratamento se apoia em consentimento ou em contrato, a
pessoa pode pedir também uma cópia eletrônica integral, num formato que permita usá-la em outro lugar
(§3º), que é a ponte para a portabilidade.

Para os outros direitos, a lei não fixa número de dias: o artigo 18, §4º pede providência, ou uma
explicação de por que não há, e a ANPD pode regulamentar o resto. A Ipê faz o que a maioria dos
controladores faz e responde **todo** tipo de pedido nos mesmos 15 dias, porque um prazo só é um
prazo de que as pessoas se lembram.

## Quem responde

Os pedidos chegam ao encarregado, e no laboratório o encarregado é o Davi. Ele precisa ler tudo
sobre um cliente e não mudar nada, o que nenhum dos papéis por função da aula 2 dá a ninguém:

```sql
-- The DPO answers data subjects' requests: he may read what is about a
-- customer, and change nothing.
CREATE ROLE privacy_officer NOLOGIN;
GRANT privacy_officer TO davi;
SET ROLE ipe_owner;
GRANT USAGE ON SCHEMA sales, health, support, gov TO privacy_officer;
GRANT SELECT ON ALL TABLES IN SCHEMA sales, health, support, gov TO privacy_officer;
CREATE POLICY privacy_officer_reads_all ON sales.customers
  FOR SELECT TO privacy_officer USING (true);
CREATE POLICY privacy_officer_reads_all ON support.tickets
  FOR SELECT TO privacy_officer USING (true);
```

```
ana@lab:~/gov$ psql -f privacy-role.sql
CREATE ROLE
GRANT ROLE
SET
GRANT
GRANT
CREATE POLICY
CREATE POLICY
```

O Davi também ganha uma entrada no `~/.pg_service.conf` da Ana, no mesmo formato das que a aula 2 escreveu e a aula 3 fez conferir o certificado, para o `psql service=davi` conectar como ele:

```ini
[davi]
host=db.ipe.example
port=5433
dbname=ipe
user=davi
sslmode=verify-full
```

As duas policies importam. `sales.customers` e `support.tickets` têm segurança por linha desde a aula
2, e um papel com `SELECT` e sem policy lê **zero linhas** sem erro nenhum — a exportação abaixo
teria voltado com um cliente vazio e ninguém teria notado.

O CPF está cifrado (aulas 4 e 5). Um pedido de acesso é um dos poucos motivos para decifrá-lo, então
o encarregado ganha uma policy no OpenBao que permite exatamente isso e um token que dura uma hora:

```hcl
# The DPO decrypts a CPF to include it in a data subject's export.
path "transit/decrypt/ipe-cpf" {
  capabilities = ["update"]
}
```

```
ana@lab:~/gov$ bao policy write dpo dpo.hcl
Success! Uploaded policy: dpo
ana@lab:~/gov$ bao token create -policy=dpo -ttl=1h -field=token > dpo.token && wc -c dpo.token
26 dpo.token
```

## A exportação

```python
"""Everything Ipê holds about one customer, as JSON, for a data subject's
request under article 18 of the LGPD. Which tables to read comes from
gov.column_class: a table with a customer_id is about somebody directly, and
a table with an order_id and no customer_id is about them through an order."""
import base64, json, os, ssl, subprocess, sys, urllib.request

ID = int(sys.argv[1])
TLS = ssl.create_default_context(cafile=os.environ["BAO_CACERT"])

def psql(sql):
    out = subprocess.run(["psql", "service=davi", "-X", "-q", "-At", "-c", sql],
                         capture_output=True, text=True, check=True).stdout
    return json.loads(out) if out.strip() else None

def decrypt(ct):
    req = urllib.request.Request(os.environ["BAO_ADDR"] + "/v1/transit/decrypt/ipe-cpf",
                                 data=json.dumps({"ciphertext": ct}).encode(), method="POST",
                                 headers={"X-Vault-Token": open("dpo.token").read().strip()})
    with urllib.request.urlopen(req, context=TLS) as r:
        return base64.b64decode(json.load(r)["data"]["plaintext"]).decode()

def tables_with(column, without=None):
    no = (f"AND NOT EXISTS (SELECT 1 FROM gov.column_class d WHERE d.table_schema = c.table_schema "
          f"AND d.table_name = c.table_name AND d.column_name = '{without}')") if without else ""
    return psql("SELECT json_agg(DISTINCT c.table_schema || '.' || c.table_name) "
                f"FROM gov.column_class c WHERE c.column_name = '{column}' {no}") or []

where = {t: f"customer_id = {ID}" for t in tables_with("customer_id")}
for t in tables_with("order_id", without="customer_id"):
    where[t] = f"order_id IN (SELECT order_id FROM sales.orders WHERE customer_id = {ID})"

export = {"customer_id": ID, "generated_for": "LGPD art. 18, II", "tables": {}}
for t in sorted(where):
    rows = psql(f"SELECT json_agg(t) FROM {t} t WHERE {where[t]}") or []
    for r in rows:
        r.pop("cpf_hmac", None)
        if r.get("cpf_ct"):
            r["cpf"] = decrypt(r.pop("cpf_ct"))
    export["tables"][t] = rows
json.dump(export, sys.stdout, ensure_ascii=False, indent=1)
print()
```

O script não lista tabelas. Ele pergunta ao `gov.column_class` quais tabelas têm `customer_id`, e
quais têm `order_id` e não têm `customer_id` — itens de pedido e pagamentos são sobre um cliente por
meio de um pedido, e uma exportação que procurava só `customer_id` os perdeu na primeira execução.
Uma tabela criada no ano que vem e classificada como a aula 6 exige entra na exportação sem ninguém
editar este arquivo. O hash com chave é removido, porque não significa nada para a pessoa, e o CPF é
decifrado.

```
ana@lab:~/gov$ python3 export_subject.py 112 > subject-112.json && wc -c subject-112.json
3226 subject-112.json
ana@lab:~/gov$ python3 -c "import json; d = json.load(open('subject-112.json')); print({t: len(r) for t, r in d['tables'].items()})"
{'health.prescriptions': 3, 'sales.consent_events': 1, 'sales.customers': 1, 'sales.deliveries': 0, 'sales.order_items': 4, 'sales.orders': 3, 'sales.payments': 3, 'sales.returns': 0, 'support.tickets': 1}
ana@lab:~/gov$ python3 -c "import json; d = json.load(open('subject-112.json')); print(json.dumps(d['tables']['sales.customers'][0], ensure_ascii=False, indent=1))"
{
 "customer_id": 112,
 "full_name": "Sérgio Moura Fernandes",
 "email": "sergio.moura@example.net",
 "birth_date": "1982-07-16",
 "sex": "M",
 "cep": "30193-173",
 "city": "Belo Horizonte",
 "state": "MG",
 "created_at": "2020-01-02T10:44:08-03:00",
 "marketing_opt_in": true,
 "consent_at": "2020-01-02T07:23:03-03:00",
 "cpf": "610.041.257-87"
}
```

Nove tabelas, 3.226 bytes, para o cliente 112: os três pedidos dele e seus quatro itens, três
pagamentos, três receitas, um chamado de suporte, um evento de consentimento, e a linha do cliente com
o CPF em claro. Duas tabelas voltaram vazias e estão no arquivo mesmo assim — "você não tem
devoluções" faz parte de uma resposta completa.

## Controlando o relógio

```sql
-- Every request a data subject makes, with the date the answer is due.
SET ROLE ipe_owner;
CREATE TABLE gov.subject_requests (
  request_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id integer     NOT NULL,
  kind        text        NOT NULL
              CHECK (kind IN ('confirm', 'access', 'correct', 'delete', 'port',
                              'revoke-consent', 'sharing-info')),
  received_on date        NOT NULL,
  due_on      date        GENERATED ALWAYS AS (received_on + 15) STORED,
  answered_on date,
  answer      text
);
INSERT INTO gov.column_class VALUES
 ('gov','subject_requests','request_id','personal','one person''s request'),
 ('gov','subject_requests','customer_id','personal','whose'),
 ('gov','subject_requests','kind','personal','what they asked for'),
 ('gov','subject_requests','received_on','personal','when'),
 ('gov','subject_requests','due_on','none','arithmetic on the date'),
 ('gov','subject_requests','answered_on','personal','when we answered'),
 ('gov','subject_requests','answer','personal','what we did');
GRANT SELECT, INSERT, UPDATE (answered_on, answer) ON gov.subject_requests TO privacy_officer;
INSERT INTO gov.subject_requests (customer_id, kind, received_on, answered_on, answer) VALUES
  (112, 'access', '2026-06-02', '2026-06-09', 'export sent, subject-112.json'),
  (3,  'delete',  '2026-06-20', NULL, NULL),
  (47, 'access',  '2026-06-10', NULL, NULL),
  (88, 'correct', '2026-06-25', NULL, NULL);
```

```sql
-- On the lab's today, 1 July 2026: what is open, and what is late.
SELECT request_id, customer_id, kind, received_on, due_on,
       CASE WHEN due_on < DATE '2026-07-01' THEN 'LATE' ELSE 'open' END AS state
FROM gov.subject_requests
WHERE answered_on IS NULL
ORDER BY due_on;
```

```
ana@lab:~/gov$ psql -f requests.sql
SET
CREATE TABLE
INSERT 0 7
GRANT
INSERT 0 4
ana@lab:~/gov$ psql service=davi -f due.sql
 request_id | customer_id |  kind   | received_on |   due_on   | state 
------------+-------------+---------+-------------+------------+-------
          3 |          47 | access  | 2026-06-10  | 2026-06-25 | LATE
          2 |           3 | delete  | 2026-06-20  | 2026-07-05 | open
          4 |          88 | correct | 2026-06-25  | 2026-07-10 | open
(3 rows)
```

A data de vencimento é uma **coluna gerada**, então não pode discordar da data em que o pedido
chegou. O pedido 1 foi respondido em sete dias. O pedido 3 foi recebido em 10 de junho e ninguém o
respondeu; em 1º de julho ele está seis dias atrasado. **Um prazo que mora na agenda de alguém é
perdido na semana em que essa pessoa está de férias**; um que mora numa tabela pode ser conferido por
uma consulta toda manhã, e foi essa consulta que achou este.
