---
title: Mudando uma tabela que ninguém pode parar de usar
version: 1
---

Esta é a seção que separa quem sabe SQL de quem pode ser confiado com um banco, e quase nunca é
ensinada.

A situação: `invoices` tem oitenta milhões de linhas, a aplicação lê e escreve nela constantemente, e
`status` precisa virar `NOT NULL`. A linha única é:

```sql
ALTER TABLE invoices ALTER COLUMN status SET NOT NULL;
```

Ela pega um lock `ACCESS EXCLUSIVE` e varre oitenta milhões de linhas. Tudo para por um ou dois
minutos. Rode isso às dez da manhã e você causou uma queda com um comando correto.

## O formato geral da resposta

Toda mudança segura de esquema numa tabela viva tem a mesma estrutura:

> **Faça a mudança em passos, cada um rápido, e cada um deixando o sistema funcionando — tanto para o
> código antigo quanto para o novo.**

Essa última cláusula é a que as pessoas perdem. Durante um deploy existem duas versões da aplicação
rodando ao mesmo tempo, por segundos ou por minutos. Todo estado intermediário tem que ser um em que
as duas conseguem viver.

## Tornar uma coluna `NOT NULL` sem a varredura

O truque é que o PostgreSQL confia num `CHECK` que ele já validou.

```sql
-- 1. acrescente a regra, NOT VALID: instantâneo, sem varredura, vale só para linhas novas
ALTER TABLE invoices
    ADD CONSTRAINT invoices_status_present CHECK (status IS NOT NULL) NOT VALID;

-- 2. preencha os nulos existentes, em lotes, no seu ritmo
UPDATE invoices SET status = 'draft' WHERE status IS NULL AND id BETWEEN 1 AND 100000;
-- … repita

-- 3. valide: varre, mas pega só um lock SHARE UPDATE EXCLUSIVE,
--    então leituras e escritas continuam
ALTER TABLE invoices VALIDATE CONSTRAINT invoices_status_present;

-- 4. agora SET NOT NULL é instantâneo, porque a prova já existe
ALTER TABLE invoices ALTER COLUMN status SET NOT NULL;
ALTER TABLE invoices DROP CONSTRAINT invoices_status_present;
```

Quatro comandos em vez de um, e em nenhum momento a tabela fica travada por mais que um instante.

**`NOT VALID` é a ideia central e ela generaliza.** Significa *"aplique esta regra de agora em
diante, e não confira o que já está aqui"* — que é exatamente o que você quer, porque as linhas novas
são as que você controla, e as antigas você conserta na sua velocidade. Chaves estrangeiras também
aceitam:

```sql
ALTER TABLE invoices ADD CONSTRAINT invoices_customer_fk
    FOREIGN KEY (customer_id) REFERENCES customers (id) NOT VALID;
ALTER TABLE invoices VALIDATE CONSTRAINT invoices_customer_fk;
```

## Renomear uma coluna, que não pode ser feito num passo de jeito nenhum

```sql
ALTER TABLE invoices RENAME COLUMN notes TO remarks;
```

Instantâneo, sem lock digno do nome, e **quebra toda cópia rodando da aplicação antiga**, que
continua selecionando `notes`. O comando é rápido e o deploy está quebrado.

O formato seguro é o padrão expandir-e-contrair, e leva três deploys:

1. **Expandir.** Acrescente `remarks`. Mude a aplicação para escrever nas **duas** colunas e ler
   `notes`. Deploy. Preencha `remarks` a partir de `notes`.
2. **Mover.** Mude a aplicação para ler `remarks`, ainda escrevendo nas duas. Deploy. Agora nada
   depende de ler a coluna antiga.
3. **Contrair.** Mude a aplicação para parar de escrever `notes`. Deploy. Depois derrube a coluna.

Lento, sem graça, e a única versão que nunca tem um momento em que um programa rodando está errado. O
mesmo formato cobre mudar o tipo de uma coluna, dividir uma coluna em duas, e mover uma coluna para
outra tabela.

## Acrescentar um índice sem bloquear escritas

A aula 9 é sobre quais índices acrescentar. A mecânica pertence aqui:

```sql
CREATE INDEX CONCURRENTLY invoices_customer_idx ON invoices (customer_id);
```

Um `CREATE INDEX` comum bloqueia escritas enquanto durar. `CONCURRENTLY` não — demora mais no total e
deixa a tabela continuar sendo escrita.

Duas coisas sobre ele que mordem:

- **Não pode rodar dentro de uma transação**, então uma ferramenta de migração que envolve tudo numa
  só tem que ser avisada para abrir exceção.
- **Pode falhar e deixar um índice inválido para trás**, que não é usado por consultas e não é óbvio.
  Confira depois de qualquer falha:

```sql
SELECT indexrelid::regclass FROM pg_index WHERE NOT indisvalid;
```

Derrube e recrie qualquer um que ele achar.

## A lista de conferência

Antes de qualquer migração contra uma tabela que importa:

1. **Qual das três velocidades é?** Catálogo, varredura ou reescrita.
2. **Que lock ela pega, e por quanto tempo?**
3. **Existe um estado intermediário em que o código antigo e o novo conseguem viver?** Se não, são
   três deploys, não um.
4. **Defina `lock_timeout`.** Para que um comando paciente não possa enfileirar a aplicação inteira
   atrás dele.
5. **Dá para desfazer?** `DROP COLUMN` não dá. `TRUNCATE` também não, uma vez comitado.

E a nota honesta sobre o último ponto: **boa parte disso é respondida para você por uma ferramenta de
migração**, que é a aula 11. Ferramentas sabem quais operações são perigosas e recusam ou reescrevem.
Saber do que elas estão te protegendo é o que te permite ler o aviso e decidir, em vez de acrescentar
a opção que o desliga.
