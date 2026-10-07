---
title: Dois relógios para uma violação
version: 1
---

**Artigo 33** do GDPR: em caso de violação de dados pessoais, o controlador notifica a autoridade de
controle **sem demora injustificada e, sempre que possível, até 72 horas** depois de tomar
conhecimento dela — a menos que a violação **não seja suscetível de resultar em risco** para as
pessoas. Uma notificação depois das 72 horas traz os motivos do atraso. A informação ainda não
conhecida pode ser fornecida **por fases**. O **artigo 34** acrescenta as próprias pessoas, sem demora
injustificada, quando o risco para elas é **elevado**. E o artigo 33(5) pede que toda violação seja
documentada, notificada ou não.

A aula 7 pôs a regra brasileira ao lado: três dias úteis para a ANPD e para as pessoas, mais vinte
para completar, cinco anos de registro. Os formatos batem. Os relógios não, porque **72 horas são
horas** — sábado conta, feriado conta — e três dias úteis não.

## Calculando os dois

Uma violação que atinge as clientes de Lisboa é uma violação sob as duas leis, com os dois relógios
correndo do mesmo momento. A Ipê calcula os prazos no banco, e não num calendário:

```sql
-- Two deadlines for one incident: the GDPR's 72 hours, which run through
-- weekends and holidays, and the ANPD's three working days, which do not.
-- The twenty days to complete the information count from the notice.
SET ROLE ipe_owner;
CREATE TABLE gov.holidays (day date PRIMARY KEY, name text NOT NULL);
-- National holidays only. A state or city holiday where the company sits
-- is a row somebody has to add.
INSERT INTO gov.holidays VALUES
 ('2026-01-01', 'Confraternização Universal'), ('2026-04-21', 'Tiradentes'),
 ('2026-05-01', 'Dia do Trabalho'),            ('2026-09-07', 'Independência'),
 ('2026-10-12', 'Nossa Senhora Aparecida'),    ('2026-11-02', 'Finados'),
 ('2026-11-15', 'Proclamação da República'),   ('2026-11-20', 'Consciência Negra'),
 ('2026-12-25', 'Natal');
INSERT INTO gov.column_class VALUES
 ('gov','holidays','day','none','a date in the calendar'),
 ('gov','holidays','name','none','its name');

-- The n-th working day after the day something became known.
CREATE FUNCTION gov.working_day(known timestamptz, n integer) RETURNS date
LANGUAGE sql STABLE AS $$
  SELECT d::date
  FROM generate_series(known::date + 1, known::date + 60, interval '1 day') AS d
  WHERE extract(isodow FROM d) < 6
    AND d::date NOT IN (SELECT day FROM gov.holidays)
  ORDER BY d
  OFFSET n - 1 LIMIT 1
$$;

SELECT to_char(k, 'Dy DD Mon HH24:MI')                          AS known,
       to_char(k + interval '72 hours', 'Dy DD Mon HH24:MI')    AS gdpr_72h,
       to_char(gov.working_day(k, 3), 'Dy DD Mon')               AS anpd_3_working_days,
       to_char(gov.working_day(gov.working_day(k, 3), 20), 'Dy DD Mon') AS anpd_complete_20
FROM (VALUES (timestamptz '2026-04-17 18:00-03')) AS v(k);
```

```
ana@lab:~/gov$ psql -f clock.sql
SET
CREATE TABLE
INSERT 0 9
INSERT 0 2
CREATE FUNCTION
      known       |     gdpr_72h     | anpd_3_working_days | anpd_complete_20 
------------------+------------------+---------------------+------------------
 Fri 17 Apr 18:00 | Mon 20 Apr 18:00 | Thu 23 Apr          | Fri 22 May
(1 row)
```

A violação é conhecida numa **sexta à noite**, 17 de abril de 2026. A CNPD tem de saber até
**segunda às 18h**. O terceiro dia útil da ANPD pula o fim de semana e **Tiradentes**, na terça, 21 de
abril, e cai na **quinta, 23**. A informação fica completa até **22 de maio**, vinte dias úteis depois
da comunicação.

Duas coisas valem ser tiradas dessas quatro colunas:

- **O prazo europeu é o que obriga aqui, com três dias de vantagem.** Um time que planeja para "três
  dias" porque é o número que conhece do Brasil já perdeu o da CNPD quando manda o da ANPD. Quando um
  incidente está sob duas leis, o plano de resposta trabalha com o relógio mais cedo.
- **A tabela de feriados faz parte da regra.** Ela guarda só feriados nacionais, e o comentário diz
  isso. Uma violação conhecida na véspera de um feriado estadual de São Paulo ganha um dia a mais do
  que esta função dá, o que erra para o lado seguro; uma conhecida antes de um feriado que a tabela
  lista errado ganha um dia a menos do que a lei, o que não erra para o lado seguro. Um calendário que
  decide um prazo legal é dado que tem dono, com uma pessoa cujo trabalho é preencher o ano seguinte.

## Por que "sempre que possível" não é uma folga

As duas leis aceitam uma primeira comunicação que ainda não sabe tudo. Esse é o ponto: o relógio é
para **avisar**, e não para **terminar**. Uma primeira notificação na segunda que diz o que se sabe —
que sistemas, mais ou menos quantas pessoas, o que foi feito para conter — e diz com clareza o que
ainda não se sabe cumpre o artigo 33. Um relatório completo na quinta não cumpre, por melhor que seja.
