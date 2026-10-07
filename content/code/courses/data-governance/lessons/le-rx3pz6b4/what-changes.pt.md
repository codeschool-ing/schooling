---
title: O que muda quando o dado é sensível
version: 1
---

Classificar uma coluna só vale o esforço se a classe mudar como ela é tratada. Na Ipê muda, e as
regras cabem numa tabela contra a qual um revisor confere um pull request:

| | `none` | `personal` | `identifying` | `sensitive` |
|---|---|---|---|---|
| **quem pode ler** | qualquer um com um cargo que precise da tabela | cargos que precisam (aula 2) | cargos que precisam, por máscaras onde der (aula 5) | só cargos nomeados, cada um com um motivo que o encarregado viu |
| **base legal** | nenhuma | artigo 7º (aula 7) | artigo 7º | **só o artigo 11** (aula 7) |
| **criptografia** | em trânsito e em repouso | em trânsito e em repouso | mais na aplicação, onde é buscado ou lido raramente (aulas 4 e 5) | mais na aplicação, ou num schema próprio com concessões próprias |
| **em exportações e análises** | livremente | pseudonimizado | nunca em claro | agregado com supressão (aula 5), ou nada |
| **retenção** | o que o negócio precisar | o período que a finalidade precisa (aula 10) | o período que a finalidade precisa | o período mais curto que a finalidade permitir |
| **avaliação** | nenhuma | no registro do tratamento | no registro do tratamento | um relatório de impacto à proteção de dados (aula 7) |

**Dado sensível estreita as bases legais.** O artigo 11 só permite tratar dado sensível com o
consentimento específico e destacado do titular, ou sem ele numa lista curta de casos — cumprimento
de obrigação legal, tutela da saúde por profissionais de saúde, exercício de direitos em processo,
prevenção à fraude e mais alguns. A aula 7 os percorre; o ponto aqui é que "o negócio acha útil", que
pode sustentar o tratamento de dado pessoal comum, não sustenta o de dado sensível.

**E dado sensível compartilhado por vantagem econômica é restrito.** O artigo 11, §4º veda a
comunicação ou o uso compartilhado de dado de saúde entre controladores com objetivo de obter
vantagem econômica, com exceções para prestação de serviços de saúde, de assistência farmacêutica e
de assistência à saúde no interesse do titular. Uma farmácia vendendo históricos de compra a uma
empresa de marketing é exatamente aquilo para que esse parágrafo existe.

## A tabela como ferramenta de revisão

O valor de escrever as regras assim é que cada célula pode ser conferida. Uma concessão aos analistas
em `health.prescriptions` contradiz uma célula. Um job de exportação que seleciona
`order_items.product_id` para um parceiro contradiz uma célula. Um revisor não precisa conhecer a
LGPD para ver a contradição — só a classe da coluna, que a seção 7 tornou algo que uma consulta
responde.
