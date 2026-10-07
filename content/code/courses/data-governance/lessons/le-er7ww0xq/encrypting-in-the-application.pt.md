---
title: O CPF, cifrado antes de chegar ao banco
version: 1
---

A aula 3 terminou com uma promessa: substituir a coluna cuja chave viajava na consulta. As peças
estão no lugar — uma chave que o banco nunca vê, um site que pode cifrar e não decifrar, um suporte
que pode decifrar e não cifrar.

Primeiro, a tentativa antiga sai, e uma coluna para texto cifrado entra no lugar:

```sql
-- Lesson 3's first attempt goes, and a column for ciphertext the
-- database receives and cannot read takes its place.
SET ROLE ipe_owner;
ALTER TABLE sales.customers DROP COLUMN cpf_enc;
ALTER TABLE sales.customers ADD COLUMN cpf_ct text;
```

```
ana@lab:~/gov$ psql -f column.sql
SET
ALTER TABLE
ALTER TABLE
```

Depois, o trabalho que o site faz para todo cliente novo, feito uma vez para todos eles. Num
sistema real isso acontece no código da aplicação, no cadastro; aqui um script faz o papel do site,
com o token do site:

```schooling-example
{
  "language": "python",
  "file": "encrypt_cpf.py",
  "parts": [
    {
      "code": "\"\"\"Encrypt every customer's CPF with the website's key, in batches, and\nwrite the ciphertexts back. The database never sees the key: it receives\nciphertext, which it stores and cannot read.\"\"\"\nimport base64, csv, io, json, os, ssl, subprocess, urllib.request\n\n",
      "note": "A biblioteca padrão e mais nada, para o script rodar em qualquer máquina com Python 3."
    },
    {
      "code": "ADDR = os.environ[\"BAO_ADDR\"]\nTOKEN = open(\"site-app.token\").read().strip()\nTLS = ssl.create_default_context(cafile=os.environ[\"BAO_CACERT\"])\n\n",
      "note": "**O token do site, não o da Ana.** Ele carrega a política `site-app`, então este script cifra e não conseguiria decifrar um CPF sequer se tentasse. O arquivo da CA é o do laboratório, então a conexão ao OpenBao é conferida como a do PostgreSQL."
    },
    {
      "code": "def psql(sql):\n    return subprocess.run([\"psql\", \"-X\", \"-q\", \"-f\", \"-\"], input=sql,\n                          capture_output=True, text=True, check=True).stdout\n\n",
      "note": "Todo comando vai ao psql pela entrada padrão, com o login da própria Ana."
    },
    {
      "code": "def encrypt(values):\n    body = json.dumps({\"batch_input\": [\n        {\"plaintext\": base64.b64encode(v.encode()).decode()} for v in values]})\n    req = urllib.request.Request(f\"{ADDR}/v1/transit/encrypt/ipe-cpf\",\n                                 data=body.encode(), method=\"POST\",\n                                 headers={\"X-Vault-Token\": TOKEN})\n    with urllib.request.urlopen(req, context=TLS) as r:\n        return [b[\"ciphertext\"] for b in json.load(r)[\"data\"][\"batch_results\"]]\n\n",
      "note": "**Uma requisição cifra muitos valores.** `batch_input` recebe uma lista, cada texto claro em base64, e a resposta mantém a ordem, então o n-ésimo texto cifrado é do n-ésimo CPF. A chave nunca aparece: a requisição a nomeia, `ipe-cpf`, e o OpenBao a usa."
    },
    {
      "code": "rows = list(csv.reader(io.StringIO(psql(\n    \"SET ROLE ipe_owner;\\n\"\n    \"COPY (SELECT customer_id, cpf FROM sales.customers ORDER BY 1) TO STDOUT (FORMAT csv);\"))))\n",
      "note": "Os CPFs saem do banco uma vez, na ordem do id, em CSV."
    },
    {
      "code": "pairs = []\nfor i in range(0, len(rows), 250):\n    chunk = rows[i:i + 250]\n    pairs += zip([c for c, _ in chunk], encrypt([cpf for _, cpf in chunk]))\n",
      "note": "**Lotes de 250**, para que nenhuma requisição seja grande: 6.012 CPFs levam 25 delas."
    },
    {
      "code": "values = \",\\n\".join(f\"({c}, '{ct}')\" for c, ct in pairs)\npsql(\"SET ROLE ipe_owner;\\n\"\n     \"UPDATE sales.customers c SET cpf_ct = v.ct\\n\"\n     f\"FROM (VALUES {values}) AS v(id, ct) WHERE c.customer_id = v.id;\")\nprint(len(pairs), \"CPFs encrypted by\", ADDR)\n",
      "note": "**O que volta é texto cifrado.** Um `UPDATE` junta os pares pelo id; o banco guarda textos `vault:v2:…` e não tem nada que os transforme de volta em CPFs."
    }
  ]
}
```

```
ana@lab:~/gov$ python3 encrypt_cpf.py
6012 CPFs encrypted by https://bao.ipe.example:8200
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT customer_id, left(cpf_ct, 40) AS cpf_ct FROM sales.customers ORDER BY 1 LIMIT 3"
SET
 customer_id |                  cpf_ct                  
-------------+------------------------------------------
           1 | vault:v2:6imxF0NlF2vTZrptkc/KgEt/Yzg8I2d
           2 | vault:v2:iBJqvllnAsO0445cFowNVOjzf5eT6Eg
           3 | vault:v2:OMTRBdV/vcaK9v/U8B85snk9yKKrLjM
(3 rows)

ana@lab:~/gov$ BAO_TOKEN=$(cat support.token) bao write -field=plaintext transit/decrypt/ipe-cpf ciphertext=vault:v2:6imxF0NlF2vTZrptkc/KgEt/Yzg8I2djETTPEwRvNVaJ/bi00tSlxyuu | base64 -d; echo
372.874.168-09
```

Todo CPF tem agora um texto cifrado `vault:v2:` ao lado, feito com a versão 2 de `ipe-cpf` porque
ela é a mais recente. O suporte consegue transformar um de volta em CPF; o site, que escreveu os
6.012, não consegue ler nenhum.

## O que mudou, e o que não mudou

**O banco agora guarda um valor que não consegue ler.** Um dump de `sales.customers` leva texto
cifrado em `cpf_ct`; uma réplica também, um `SELECT *` descuidado de um papel com concessão demais
também, e o log do servidor também, se um comando mencionar a coluna. Nenhum deles leva a chave,
porque a chave nunca chegou perto do banco.

**A coluna `cpf` em claro continua lá**, e isso é deliberado, por mais uma aula. O suporte acha um
cliente pelo CPF quando ele liga, e o banco não consegue buscar texto cifrado: duas cifrações do
mesmo CPF são textos diferentes. Apagar o texto claro exige uma segunda coluna que *consiga* ser
buscada sem ser legível, e é isso que a aula 5 chama de **token**. Até lá, as concessões da aula 2
são o que mantém a coluna em claro longe dos analistas.

**E o código do site agora faz parte da proteção.** Ele tem um token que pode cifrar; se ele
registrasse cada CPF no log antes de cifrá-lo, o arranjo inteiro vazaria pelo próprio log da
aplicação. Cifrar na aplicação muda a confiança do banco para a aplicação, que só é o lugar certo
se a aplicação for revisada com o mesmo cuidado que o banco foi.
