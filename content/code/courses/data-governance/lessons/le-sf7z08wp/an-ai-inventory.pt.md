---
title: Um inventário de sistemas de IA
version: 1
---

Toda obrigação do AI Act depende de duas perguntas: **que sistemas** a empresa constrói ou usa, e em
**que classe** está cada um? Nenhuma das duas se responde lendo a lei. As duas se respondem com um
inventário — o mesmo instrumento que a aula 6 construiu para colunas, um nível acima.

A Ipê tem quatro sistemas que usam aprendizado de máquina:

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

Cada linha é um pequeno argumento, e a coluna `why` é onde ele é feito:

- **`cv-screen`**, comprado de um fornecedor, classifica candidatos a vagas de farmacêutico em São
  Paulo e no armazém de Lisboa. Recrutamento está no **Anexo III, ponto 4(a)**: é **alto risco**, e a
  Ipê é a responsável pela implantação. E é a única linha em que **ninguém** responde por ele — foi
  comprado por quem contrata, e ninguém do lado de dados sabia que ele existia até o inventário
  perguntar.
- **`support-bot`** responde clientes no chat, incluindo as portuguesas. O artigo 50(1) exige que
  elas sejam informadas de que estão falando com um sistema de IA, e isso vale desde 2 de agosto de
  2026.
- **`fraud-score`** marca pedidos. O Anexo III, ponto 5(b), lista o score de crédito e **exclui
  expressamente** sistemas usados para detectar fraude financeira, então ele é de risco **mínimo** no
  AI Act. Isso não encerra a questão: ele toma decisões sobre pessoas, então valem o artigo 22 do
  GDPR e o artigo 20 da LGPD (seção 10).
- **`recommender`** sugere produtos. Nada no Anexo III; mínimo. A LGPD continua valendo para o que ele
  usa, e a aula 7 já decidiu que ele não pode usar categorias de saúde sem consentimento.

## O que o inventário achou

Um sistema de alto risco sem dono. As obrigações da Ipê como responsável pela implantação (artigo 26)
valem a partir de 2 de dezembro de 2027, e o que elas exigem leva mais tempo do que isso para montar:
usar conforme as instruções do fornecedor; **supervisão humana por pessoas com a competência e a
autoridade** para contrariá-lo; monitoramento; guardar os logs que ele produz por pelo menos seis
meses; avisar os representantes dos trabalhadores antes de usá-lo; e avisar os candidatos de que ele
é usado com eles. A Ipê também precisa de uma DPIA do GDPR para ele (seção 6), e isso já vale.

A consulta ordena por classe e torna o dono vazio impossível de não ver. Transformada numa verificação
que roda com as migrações — como o `unclassified.sql` da aula 6 —, **um sistema sem classe, ou um
sistema de alto risco sem dono, pararia o deploy**. A tabela é classificada como qualquer outra: a
coluna `owner` nomeia um funcionário, então é dado pessoal, e diz isso.
