---
title: Clientes e permissões
version: 1
---

Todo filtro até aqui foi sobre relevância: um idioma errado dá uma resposta pior. Um tipo de filtro
trata de outra coisa. Quando um sistema guarda os dados de vários clientes, os seus **tenants**, o
filtro de cliente é o que mantém os documentos de um fora dos resultados de outro. Um filtro de
idioma esquecido é uma busca ruim. **Um filtro de cliente esquecido é um vazamento de dados**, e ele
parece exatamente uma busca funcionando, porque os resultados são relevantes. Só que são de outra
pessoa.

## O filtro não pode vir da requisição

O desenho tentador é o que as seções anteriores usaram: a função de busca recebe um filtro, e quem
a chama passa `shop = 'folio'`. Isso põe a fronteira em cada chamador. Um endpoint que esquece, um
cliente que manda `shop = 'marginalia'` no lugar, e a fronteira some. Duas regras decorrem disso:

- o cliente vem da sessão, nunca do corpo da requisição. O servidor sabe quem entrou; um valor de
  filtro mandado pelo cliente é uma alegação, e um cliente pode alegar qualquer coisa;
- o lugar que garante isso deve ser um só, abaixo de todas as consultas, para que uma consulta
  escrita sem ele falhe em vez de vazar.

O PostgreSQL tem esse lugar embutido: a **segurança em nível de linha** (row-level security). Uma
política numa tabela é uma condição que o PostgreSQL acrescenta a toda consulta sobre ela, para todo
papel a que a política se aplica. Aqui uma segunda loja, a Folio, divide a tabela `articles` com a
Marginalia:

```schooling-example
{
  "language": "python",
  "file": "shops.py",
  "parts": [
    {
      "code": "import psycopg\nfrom pgvector.psycopg import register_vector\nfrom minilm import embed\nfrom store import help, D\n\nfolio = [(\"f01\", \"Returning a book to Folio\", \"Post it back within 30 days with the slip from the parcel.\"),\n         (\"f02\", \"Folio delivery times\", \"Orders leave our shop in two working days.\"),\n         (\"f03\", \"Your Folio account\", \"Change your password from the account page.\")]\nF = embed([title + \". \" + body for _, title, body in folio])",
      "note": "Uma segunda loja, a Folio, com três artigos próprios, transformados em vetores com o mesmo modelo."
    },
    {
      "code": "with psycopg.connect(autocommit=True) as conn:\n    conn.execute(\"CREATE EXTENSION IF NOT EXISTS vector\")\n    register_vector(conn)\n    conn.execute(\"\"\"CREATE TABLE articles (id text PRIMARY KEY, shop text NOT NULL,\n                    title text, embedding vector(384))\"\"\")\n    for h, v in zip(help, D):\n        conn.execute(\"INSERT INTO articles VALUES (%s, 'marginalia', %s, %s)\", (h[\"id\"], h[\"title\"], v))\n    for (id, title, _), v in zip(folio, F):\n        conn.execute(\"INSERT INTO articles VALUES (%s, 'folio', %s, %s)\", (id, title, v))",
      "note": "Uma tabela para as duas lojas, com uma coluna `shop` que toda linha precisa preencher."
    }
  ]
}
```

```sql
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
CREATE POLICY one_shop ON articles USING (shop = current_setting('app.shop'));
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'helpdesk') THEN
    CREATE ROLE helpdesk;
  END IF;
END $$;
GRANT SELECT ON articles TO helpdesk;
```

A política compara a loja de cada linha com a configuração `app.shop`, que a aplicação define uma
vez por conexão a partir da sessão de quem entrou. A busca em si não tem `WHERE` nenhum:

```schooling-example
{
  "language": "python",
  "file": "tenant_search.py",
  "parts": [
    {
      "code": "import sys\nimport psycopg\nfrom pgvector.psycopg import register_vector\nfrom minilm import embed\n\nshop = sys.argv[1] if len(sys.argv) > 1 else None\nwith psycopg.connect() as conn:\n    register_vector(conn)\n    conn.execute(\"SET ROLE helpdesk\")\n    if shop:\n        conn.execute(\"SELECT set_config('app.shop', %s, false)\", (shop,))",
      "note": "Conectar, assumir o papel `helpdesk` e, se uma loja foi informada, registrá-la na configuração `app.shop` desta conexão."
    },
    {
      "code": "    rows = conn.execute(\"\"\"SELECT id, title FROM articles\n                           ORDER BY embedding <=> %s LIMIT 3\"\"\",\n                        (embed(\"how do I return a book\")[0],)).fetchall()\n    for id, title in rows:\n        print(id, title)",
      "note": "A busca não tem `WHERE`. Quais linhas ela pode ver é assunto da política."
    }
  ]
}
```

```
ana@lab:~/emb$ python shops.py
ana@lab:~/emb$ psql -f policy.sql
ALTER TABLE
CREATE POLICY
DO
GRANT
ana@lab:~/emb$ python tenant_search.py marginalia
h14 How to return a book
h33 Refunds for e-books
h17 Items that cannot be returned
ana@lab:~/emb$ python tenant_search.py folio
f01 Returning a book to Folio
f03 Your Folio account
f02 Folio delivery times
ana@lab:~/emb$ python tenant_search.py
Traceback (most recent call last):
  File "/home/ana/emb/tenant_search.py", line 12, in <module>
    rows = conn.execute("""SELECT id, title FROM articles
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/emb/lib/python3.11/site-packages/psycopg/connection.py", line 304, in execute
    raise ex.with_traceback(None)
psycopg.errors.UndefinedObject: unrecognized configuration parameter "app.shop"
```

**A mesma consulta, sem filtro nenhum, devolveu só os artigos da Marginalia para a Marginalia e só
os da Folio para a Folio.** A busca da Folio devolveu os três artigos da Folio, inclusive dois que
não têm nada a ver com devolução, porque são tudo o que ela consegue ver. E sem loja definida, a
consulta **falhou** com um erro em vez de devolver tudo. Essa é a propriedade que vale ter: uma
conexão que esqueceu de dizer quem é não recebe nada.

Dois cuidados sobre a demonstração. `ana` é dona da tabela e é a superusuária do banco, e as duas
coisas pulam a segurança em nível de linha, por isso a busca roda como `helpdesk`, um papel só com
`SELECT`. E a política é uma condição que o PostgreSQL aplica às linhas que o plano produz, então
numa tabela grande com índice HNSW ela se comporta como qualquer outro filtro da seção de
pós-filtragem: um cliente pequeno numa tabela grande recebe menos de k linhas. As soluções de lá
valem aqui também.

## Uma coleção, ou uma por cliente

A segurança em nível de linha é um jeito de traçar a fronteira dentro de uma tabela compartilhada.
O outro é não compartilhar: **uma coleção, tabela ou índice por cliente**, para que uma consulta da
Folio não alcance os vetores da Marginalia porque eles estão em outro lugar. Cada um tem o seu
lugar:

| | compartilhada, com filtro de cliente | uma por cliente |
|---|---|---|
| os resultados de um cliente pequeno | podem ser cortados pela pós-filtragem | buscados no próprio índice, sem filtro para cortá-los |
| muitos clientes pequenos | um índice para construir e manter | milhares de índices, cada um com seu custo fixo |
| um filtro esquecido | vaza, a menos que o banco garanta o filtro | não tem como vazar entre clientes |
| apagar um cliente | um delete sobre muitas linhas | descartar uma coleção |

Os bancos vetoriais dão nome à segunda opção nos seus próprios termos: o Qdrant documenta tanto um
campo de payload por cliente quanto uma coleção por cliente, o Pinecone tem namespaces dentro de um
índice, o Chroma tem tenants e databases acima das coleções, e a aula 14 viu o Supabase recomendar a
segurança em nível de linha para o mesmo fim. Nenhuma dessas opções hospedadas foi executada aqui.

Seja qual for a escolha, o teste é o mesmo de toda esta aula: escreva a consulta que deveria não
devolver nada, uma busca de um cliente por uma frase que só aparece nos documentos de outro, e
confira que ela não devolve.
