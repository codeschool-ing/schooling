---
title: A exceção — bloqueios judiciais
version: 1
---

O cliente 4407 está processando a Ipê por causa do reembolso de um pedido de 2020. Esse pedido já
passou do prazo de retenção. Se o expurgo o apagasse na semana que vem, a Ipê estaria destruindo prova
num processo de que é parte, o que nenhuma regra de retenção justifica. A própria LGPD permite guardar
dados para o **exercício regular de direitos em processo judicial, administrativo ou arbitral** (artigo
7º, VI), e apagar os registros de uma disputa enquanto ela está na Justiça seria indefensável nesse
processo.

Um **bloqueio judicial** (*legal hold*) suspende o expurgo para os dados que ele cobre, enquanto o
processo durar:

```sql
-- Customer 4407 is in court over a refund from 2020. Nothing of theirs is
-- deleted until the case ends, whatever the retention rule says.
SET ROLE ipe_owner;
CREATE TABLE gov.legal_holds (
  customer_id integer NOT NULL,
  reason      text    NOT NULL,
  since       date    NOT NULL,
  released_on date
);
INSERT INTO gov.column_class VALUES
 ('gov','legal_holds','customer_id','personal','whose data is held'),
 ('gov','legal_holds','reason','personal','a dispute about a person'),
 ('gov','legal_holds','since','personal','when it began'),
 ('gov','legal_holds','released_on','personal','when it ended');
INSERT INTO gov.legal_holds VALUES
 (4407, 'lawsuit over the refund of order 105213, filed 2026-03-02', '2026-03-09', NULL);
```

Três propriedades fazem um bloqueio funcionar:

- **é dado, e não uma conversa.** Um advogado dizendo ao time de banco "não apaguem nada do 4407" por
  e-mail é um bloqueio que dura até o e-mail ser esquecido. Uma linha é lida pelo expurgo toda vez que
  ele roda;
- **tem começo e fim.** O `released_on` é preenchido quando o processo termina, e a partir da execução
  seguinte as regras de retenção voltam a valer. Um bloqueio que ninguém libera é retenção indefinida
  com outro nome;
- **é dado pessoal ele mesmo**, sobre uma pessoa numa disputa, e classificado como tal na mesma
  migração.

## O que o bloqueio cobre

Aqui, tudo sobre um cliente: os pedidos antigos, as receitas e os chamados dele. Bloqueios podem ser
mais estreitos — um pedido — ou mais amplos — todo registro de uma linha de produtos sob investigação
da autoridade sanitária. O formato da tabela segue o que os bloqueios precisam nomear; a regra de que o
expurgo a lê não muda.
