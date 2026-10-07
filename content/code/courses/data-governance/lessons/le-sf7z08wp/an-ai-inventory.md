---
title: An inventory of AI systems
version: 1
---

Every obligation in the AI Act depends on two questions: **which systems** does the company build or
use, and **which class** is each one in? Neither is answered by reading the law. Both are answered by
an inventory — the same instrument lesson 6 built for columns, one level up.

Ipê has four systems that use machine learning:

```sql
-- Every AI system Ipê builds or uses, with the AI Act's class and the
-- reason for it written beside it.
SET ROLE ipe_owner;
CREATE TABLE gov.ai_systems (
  name         text PRIMARY KEY,
  purpose      text NOT NULL,
  ipe_is       text NOT NULL CHECK (ipe_is IN ('provider', 'deployer')),
  ai_act_class text NOT NULL
               CHECK (ai_act_class IN ('prohibited', 'high-risk', 'transparency', 'minimal')),
  why          text NOT NULL,
  personal     boolean NOT NULL,   -- does it process personal data?
  owner        text                -- who answers for it; NULL is a finding
);
INSERT INTO gov.column_class VALUES
 ('gov','ai_systems','name','none','a system'),
 ('gov','ai_systems','purpose','none','what it is for'),
 ('gov','ai_systems','ipe_is','none','Ipê''s role'),
 ('gov','ai_systems','ai_act_class','none','the class'),
 ('gov','ai_systems','why','none','the reasoning'),
 ('gov','ai_systems','personal','none','a yes or no about the system'),
 ('gov','ai_systems','owner','personal','an employee''s name');
INSERT INTO gov.ai_systems VALUES
 ('fraud-score', 'flags orders likely to be fraudulent', 'provider', 'minimal',
  'Annex III 5(b) excludes systems used to detect financial fraud', true, 'bruno'),
 ('support-bot', 'answers customers in the support chat', 'deployer', 'transparency',
  'art. 50(1): people must be told they are talking to an AI system', true, 'carla'),
 ('recommender', 'suggests products on the shop', 'provider', 'minimal',
  'no Annex III use; the LGPD still rules out health categories', true, 'ana'),
 ('cv-screen', 'ranks applicants for pharmacist jobs', 'deployer', 'high-risk',
  'Annex III 4(a): recruitment and selection of people', true, NULL);
```

```sql
-- What the inventory says, and what it says is missing.
SELECT name, ipe_is, ai_act_class, coalesce(owner, '-- nobody --') AS owner
FROM gov.ai_systems
ORDER BY array_position(ARRAY['prohibited','high-risk','transparency','minimal'], ai_act_class),
         name;
```

```
ana@lab:~/gov$ psql -f ai-systems.sql
SET
CREATE TABLE
INSERT 0 7
INSERT 0 4
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -f ai-review.sql
SET
    name     |  ipe_is  | ai_act_class |    owner     
-------------+----------+--------------+--------------
 cv-screen   | deployer | high-risk    | -- nobody --
 support-bot | deployer | transparency | carla
 fraud-score | provider | minimal      | bruno
 recommender | provider | minimal      | ana
(4 rows)
```

Each row is a small argument, and the `why` column is where it is made:

- **`cv-screen`**, bought from a vendor, ranks applicants for pharmacist jobs in São Paulo and in the
  Lisbon warehouse. Recruitment is in **Annex III, point 4(a)**: it is **high-risk**, and Ipê is its
  deployer. And it is the only row with **nobody** answering for it — it was bought by the people who
  hire, and nobody on the data side knew it existed until the inventory asked.
- **`support-bot`** answers customers in the chat, including Portuguese ones. Article 50(1) requires
  that they be told they are talking to an AI system, and that has applied since 2 August 2026.
- **`fraud-score`** flags orders. Annex III, point 5(b), lists credit scoring and **explicitly
  excludes** systems used to detect financial fraud, so it is **minimal** risk under the Act. That is
  not the end of it: it makes decisions about people, so GDPR article 22 and LGPD article 20 apply
  (section 10).
- **`recommender`** suggests products. Nothing in Annex III; minimal. The LGPD still applies to what it
  uses, and lesson 7 already decided it may not use health categories without consent.

## What the inventory found

One high-risk system with no owner. Its obligations as a deployer (article 26) apply from 2 December
2027, and they take longer than that to set up. They are: use according to the provider's
instructions; **human oversight by people with the competence and authority** to overrule it;
monitoring; keeping the logs it produces for at least six months; telling the workers'
representatives before using it; and telling the candidates it is used on them. Ipê also needs a
GDPR DPIA for it (section 6), and that applies already.

The query sorts by class and makes the empty owner impossible to miss. Turned into a check that runs
with the migrations — the way lesson 6's `unclassified.sql` does — **a system with no class, or a
high-risk system with no owner, would stop the deploy**. The table is classified like any other: its
`owner` column names an employee, so it is personal data, and it says so.
