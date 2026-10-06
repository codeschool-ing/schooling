---
title: O filtro vai dentro da busca
version: 1
---

O `access.search` põe os públicos do papel no `WHERE` da consulta, então o PostgreSQL só ordena as
linhas que o leitor pode ver:

```schooling-example
{
  "language": "python",
  "file": "access.py",
  "parts": [
    {
      "code": "def connect():\n    \"\"\"The assistant's own connection: a role that can only SELECT, and only what the policy lets through.\"\"\"\n    conn = psycopg.connect(user=\"assistant\", autocommit=True)\n    register_vector(conn)\n    return conn",
      "note": "O assistente se conecta com um papel próprio no banco, `assistant`, que pode ler a tabela e mais nada."
    },
    {
      "code": "def search(conn, role, question, k=3, only=None):\n    \"\"\"Lesson 6's search with the role's audiences in the WHERE, inside a transaction that also tells\n    the database whose search it is, so its policy applies the same limit a second time. ONLY, a\n    narrowing the reader asked for, is intersected with what the role allows and can never add to it.\"\"\"\n    allowed = [a for a in audiences(role) if only is None or a in only]\n    q = embed(question)[0]\n    with conn.transaction():\n        conn.execute(\"SELECT set_config('rag.audiences', %s, true)\", (\",\".join(allowed),))\n        return conn.execute(\n            \"SELECT id, path, text, audience, 1 - (embedding <=> %s) FROM chunks\"\n            \" WHERE status = 'current' AND audience = ANY(%s)\"\n            \" ORDER BY embedding <=> %s LIMIT %s\", (q, allowed, q, k)).fetchall()",
      "note": "Os públicos do papel vão para o `WHERE`, então a busca só ordena o que o leitor pode ver. A mesma lista é definida para a transação como `rag.audiences`, que a política do banco lê na próxima seção; o `true` faz a configuração acabar com a transação, para não vazar para a próxima requisição na mesma conexão."
    }
  ]
}
```

A alternativa tentadora é buscar como antes e tirar depois o que o leitor não pode ver. É fácil de
acrescentar a um pipeline que já funciona, e está errada de dois jeitos de uma vez:

```
ana@lab:~/rag$ python after.py agent "When does an order get held for manual fraud review?"
the three nearest, for anybody:
  0.644  finance  Refund controls and chargebacks > Automatic holds
  0.586  staff    Customer support handbook > Suspected fraud
  0.516  public   Returns and refunds policy > Damaged, faulty and wrong items
then dropped for agent: 2 of 3 left
```

**Sobraram duas de três.** O pedaço do financeiro era o melhor casamento, então ocupou um lugar entre
os três primeiros e depois foi jogado fora, e o atendente recebe duas fontes onde o filtro dentro da
consulta deu três. Numa pergunta que casa forte com os documentos do financeiro, os três primeiros
podem ser todos jogados fora, e o atendente fica sem nada, enquanto o mesmo atendente com o filtro no
`WHERE` teria três seções do manual. Buscar mais para compensar é adivinhar quantas vão ser
descartadas.

O segundo jeito é pior. **Entre a busca e o descarte, o texto proibido está na memória do programa**, e
toda linha de código no meio do caminho pode vazá-lo: uma linha de registro que imprime as fontes, um
cache indexado pela pergunta, um trace mandado a um serviço de observabilidade, uma mensagem de
exceção que inclui a linha. O filtro dentro da consulta quer dizer que o texto que o leitor não pode
ver nunca é lido do banco para ele.

A aula 6 fez o mesmo argumento para o filtro de `status`, por qualidade: um pedaço substituído
descartado depois da busca custa um lugar. Com permissões, o argumento é sobre quem viu o quê.
