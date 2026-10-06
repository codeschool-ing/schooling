---
title: O banco garante
version: 1
---

O filtro do `access.search` depende de toda consulta lembrar dele. A consulta desta aula lembra, e a
próxima que alguém escrever, para um relatório, um script de depuração, uma função nova, pode não
lembrar. A aula 13 encontrou a mesma fraqueza na tabela de memória. A defesa é fazer o próprio banco
aplicar a regra, diga a consulta o que disser, com **segurança em nível de linha**:

```schooling-example
{
  "language": "sql",
  "file": "policy.sql",
  "parts": [
    {
      "code": "-- The assistant reads through a role of its own, and the database decides which rows that role sees.\n-- Run by the loader, which owns the table and is not limited by the policy.\nDO $$ BEGIN CREATE ROLE assistant LOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;",
      "note": "Um papel para o assistente, criado só se ainda não existir: papéis pertencem ao servidor PostgreSQL inteiro, e não a um banco."
    },
    {
      "code": "GRANT SELECT ON chunks TO assistant;\nALTER TABLE chunks ENABLE ROW LEVEL SECURITY;",
      "note": "Ele pode ler a tabela, e a tabela agora confere uma política a cada leitura."
    },
    {
      "code": "CREATE POLICY by_audience ON chunks FOR SELECT TO assistant\n    USING (audience = ANY (string_to_array(current_setting('rag.audiences', true), ',')));",
      "note": "A política: uma linha só é visível ao `assistant` se o público dela estiver na lista que a transação definiu. Sem lista definida, o `current_setting(..., true)` é nulo, a comparação nunca é verdadeira, e nenhuma linha aparece."
    }
  ]
}
```

O carregador, `ana` neste laboratório, é dono da tabela e não é limitado pela política; o assistente se
conecta como `assistant`, um papel que só lê, e toda leitura dele passa pela `by_audience`. Uma
consulta do assistente que esquece o `WHERE` por completo, contando todos os pedaços por público:

```
ana@lab:~/rag$ psql -q -f policy.sql
ana@lab:~/rag$ python asassistant.py
no rows
ana@lab:~/rag$ python asassistant.py public
[('public', 86)]
ana@lab:~/rag$ python asassistant.py public,staff
[('public', 86), ('staff', 22)]
```

**Sem públicos definidos, nenhuma linha.** Com `public`, os 86 pedaços públicos; com `public,staff`,
esses e os 22 pedaços de funcionários. Os pedaços do financeiro nunca aparecem, porque nada que o
assistente possa fazer naquela conexão os nomeia. Uma consulta sem filtro, que antes desta política
teria lido todas as linhas, agora lê só o que a transação foi informada de que o leitor pode ver.

Dois detalhes fazem o arranjo se sustentar.

- **Ele falha fechado.** Uma configuração ausente, um erro de digitação no nome da variável, um caminho
  do código que esqueceu de defini-la: cada um faz o `current_setting` devolver nulo, e nulo não casa
  com nada. Um sistema de permissões que abre diante de uma entrada inesperada tem uma lista de jeitos
  de contorná-lo; este não tem nenhum.
- **A configuração é por transação**, definida com `set_config(..., true)` a partir de um valor que o
  programa calculou da sessão. Uma configuração que sobrevivesse à requisição deixaria a próxima
  requisição numa conexão de pool herdar as permissões do leitor anterior, o tipo de defeito que só
  aparece sob carga.

A política não substitui o `WHERE`; o `access.search` mantém os dois. O `WHERE` deixa a consulta certa
e rápida, e a política deixa segura uma consulta que o esqueceu. A tabela de memória da aula 13 aceita
o mesmo tipo de política, com a conta no lugar do público.
