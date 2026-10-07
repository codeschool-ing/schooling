---
title: Só de inserção, como garantia
version: 1
---

A plataforma em que você estuda mantém um log de auditoria de toda ação administrativa, um fluxo de
eventos e um log de prática, e os três são **só de inserção**. O schema dela diz por quê num comentário
que vale citar: só de inserção como combinado é um comentário; só de inserção como gatilho é uma
garantia. A função que ela usa:

```sql
-- Raising rather than returning NULL: a BEFORE trigger that returns NULL
-- silently discards the row, and "the delete did nothing and said nothing" is
-- the failure mode this is here to prevent, not a milder version of it.
CREATE FUNCTION refuse_to_change_history() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION
        '% is append-only: % is refused. A correction is a new row, never an edit to an old one.',
        TG_TABLE_NAME, TG_OP
        USING ERRCODE = 'restrict_violation';
END;
$$;
```

Dois detalhes são iguais aos do laboratório, pelos mesmos motivos. Ela **levanta uma exceção** em vez
de devolver `NULL` — um gatilho `BEFORE` que devolve `NULL` descarta a operação em silêncio, e "o delete
não fez nada e não disse nada" é a falha que isto existe para impedir. E ela dá o motivo na mensagem:
**uma correção é uma linha nova**, nunca a edição de uma antiga.

## A brecha, e como foi achada

A primeira versão da plataforma tinha o gatilho por linha e não o de `TRUNCATE`. Uma migração
posterior explica como isso foi achado:

```sql
-- POSTGRES DOES NOT FIRE ROW TRIGGERS ON `TRUNCATE`. It is a separate event,
-- with its own trigger kind, and a statement that empties an append-only table
-- entirely was therefore the one edit the guard allowed. The strongest possible
-- change to history went through the gap left for the weakest.
--
-- It was found while writing `cmd/reset`, which needed to empty exactly these
-- tables — and could have done so without the schema noticing. A tool that gets
-- its way by walking through a hole in a guarantee teaches the next reader that
-- the guarantee is decorative.
```

Foi achado ao escrever uma ferramenta para esvaziar o banco de desenvolvimento, que precisava limpar
exatamente essas tabelas — e conseguiria fazer isso sem o schema notar. A correção foi o gatilho por
comando que o log de auditoria do laboratório tem. A ferramenta agora **desliga o gatilho pelo nome**,
dentro da sua transação, em código que qualquer pessoa consegue ler: esvaziar o histórico é legítimo
exatamente uma vez, antes de existir qualquer usuário, e fazer isso por uma brecha seria o mesmo ato sem
nada escrito.

## O que levar daqui

- **toda tabela só de inserção ganha os dois gatilhos.** Um por linha para `UPDATE` e `DELETE`, um por
  comando para `TRUNCATE`;
- **uma correção é uma linha nova** que aponta para o que corrige — o livro-razão da plataforma faz
  exatamente isso com reembolsos;
- **o caminho para contornar uma garantia é escrito.** Quando algo precisa legitimamente passar por
  cima dela, passa pelo nome, em código revisado, e deixa registro — nunca achando a brecha.
