---
title: Trilhas de auditoria
version: 1
---

Uma **trilha de auditoria** responde "quem fez o quê, em qual registro, e quando" depois do fato. O
OpenBao da aula 4 mantinha uma para cada uso de uma chave; o banco precisa da sua própria para mudanças
nos dados que importam às pessoas. Três decisões a moldam, e a do laboratório toma as três de
propósito:

```sql
-- Who changed which customer, and which columns. Not the values: the trail
-- would otherwise be a second copy of everything it watches.
SET ROLE ipe_owner;
CREATE TABLE gov.audit_log (
  audit_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  at          timestamptz NOT NULL DEFAULT now(),
  logged_in   name        NOT NULL,   -- the person who connected
  acting_as   name        NOT NULL,   -- the role they had set
  action      text        NOT NULL,
  rel         text        NOT NULL,
  row_key     text        NOT NULL,
  columns     text[]
);
INSERT INTO gov.column_class
SELECT 'gov', 'audit_log', c, 'personal', 'who did what to whose row'
FROM unnest(ARRAY['audit_id','at','logged_in','acting_as','action','rel','row_key','columns']) c;

CREATE FUNCTION gov.audit_customers() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog AS $$
BEGIN
  INSERT INTO gov.audit_log (logged_in, acting_as, action, rel, row_key, columns)
  SELECT session_user, current_user, TG_OP, TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
         OLD.customer_id::text,
         CASE WHEN TG_OP = 'UPDATE' THEN
           ARRAY(SELECT n.key FROM jsonb_each(to_jsonb(NEW)) n
                 JOIN jsonb_each(to_jsonb(OLD)) o USING (key)
                 WHERE n.value IS DISTINCT FROM o.value ORDER BY n.key)
         END;
  RETURN NULL;
END $$;
CREATE TRIGGER customers_audited AFTER UPDATE OR DELETE ON sales.customers
  FOR EACH ROW EXECUTE FUNCTION gov.audit_customers();

-- The trail itself: inserted into, never changed, never emptied.
CREATE FUNCTION gov.refuse() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION '% is append-only: % is refused', TG_TABLE_NAME, TG_OP;
END $$;
CREATE TRIGGER audit_log_is_append_only BEFORE UPDATE OR DELETE ON gov.audit_log
  FOR EACH ROW EXECUTE FUNCTION gov.refuse();
CREATE TRIGGER audit_log_is_not_emptied BEFORE TRUNCATE ON gov.audit_log
  FOR EACH STATEMENT EXECUTE FUNCTION gov.refuse();
```

```
ana@lab:~/gov$ psql -f audit.sql
SET
CREATE TABLE
INSERT 0 8
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE TRIGGER
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "UPDATE sales.customers SET city = 'Contagem', cep = '32010-000' WHERE customer_id = 112"
SET
UPDATE 1
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT logged_in, acting_as, action, rel, row_key, columns FROM gov.audit_log"
SET
 logged_in | acting_as | action |       rel       | row_key |  columns   
-----------+-----------+--------+-----------------+---------+------------
 ana       | ipe_owner | UPDATE | sales.customers | 112     | {cep,city}
(1 row)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "DELETE FROM gov.audit_log"
SET
ERROR:  audit_log is append-only: DELETE is refused
CONTEXT:  PL/pgSQL function gov.refuse() line 3 at RAISE
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "TRUNCATE gov.audit_log"
SET
ERROR:  audit_log is append-only: TRUNCATE is refused
CONTEXT:  PL/pgSQL function gov.refuse() line 3 at RAISE
```

**Quem.** A linha diz `logged_in = ana` e `acting_as = ipe_owner`. Os dois importam. Só `current_user`
diria `ipe_owner` para toda mudança que qualquer pessoa fizesse por esse papel, o que é o mesmo que
dizer ninguém — e é por isso que a aula 1 fez do `ipe_owner` um papel com que ninguém consegue logar,
alcançado só por `SET ROLE` a partir do login de uma pessoa. O `session_user` é a pessoa que conectou;
o par diz quem, e com que autoridade.

**O quê.** A trilha registra **que colunas** mudaram — `{cep,city}` — e não os valores. Uma trilha que
copiasse valores antigos e novos seria uma segunda cópia, permanente, de todo endereço, e-mail e nome
que ela já vigiou, sem prazo de retenção e sem caminho de eliminação. A pergunta que uma auditoria
responde é quase sempre "quem mudou isto, e quando", e o valor atual está na tabela.

**Onde.** A função é `SECURITY DEFINER`, então a trilha é escrita com os direitos do dono mesmo quando
a mudança foi feita por um papel que não pode ler `gov.audit_log`. Ela roda `AFTER` da mudança, então
registra só o que de fato aconteceu.

## Recusando ser mudada

Os dois últimos comandos foram recusados. O `DELETE` é barrado por um gatilho por linha, e o `TRUNCATE`
por um segundo gatilho, por comando, porque o PostgreSQL não dispara gatilhos por linha no `TRUNCATE`.
Uma trilha só com o primeiro tem uma brecha exatamente do tamanho do comando mais destrutivo que existe.
A próxima seção é sobre onde essa lição foi aprendida.

## O que um gatilho não consegue barrar

O dono de uma tabela consegue desligar os gatilhos dela, e o superusuário consegue tudo. Uma trilha
dentro do banco protege contra erros e contra papéis que não são o dono; não protege contra o dono.
Dois acréscimos fecham a maior parte dessa brecha: a extensão **`pgaudit`**, que escreve os comandos
no log do servidor, fora de qualquer tabela que um papel consiga mudar; e **enviar o log a outro
sistema** à medida que é escrito, para que mudar o passado signifique mudar uma máquina que o dono do
banco não alcança.
