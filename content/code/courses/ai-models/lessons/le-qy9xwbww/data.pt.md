---
title: Quem guarda o e-mail
version: 1
---

A seção 07 da aula 2 perguntou para onde vai o e-mail. Pelo OpenRouter ele vai ao OpenRouter e
depois ao provedor que o roteamento escolheu, e provedores diferem no que guardam. O objeto
`provider` tem um campo para isso, e o padrão dele merece ser lido devagar:

```
# OpenRouterTeam/docs@3e840a21 guides/routing/provider-selection.mdx
1192: - `allow`: (default) allow providers which store user data non-transiently and may train
      on it
1193: - `deny`: use only providers which do not collect user data
1195: Some model providers may log prompts, so we display them with a **Data Policy** tag on
      model pages. This is not a definitive source of third party data policies, but
      represents our best knowledge.
```

**Por padrão, um provedor que guarda o que recebe e pode treinar com isso é permitido.** A marcação
que o OpenRouter mostra, pela própria descrição dele, não é definitiva. Para a Lantern Books, cujos
e-mails trazem nomes e endereços de clientes, `"deny"` é o ajuste de onde partir. O substituto marca
o `standin-east` como um provedor que guarda dados:

```
ana@desk:~/desk$ python lab/or_sort.py '{"provider": {"data_collection": "deny"}}'
other  model=standin/large provider=standin-west cost=$0.000168
```

```
ana@desk:~/desk$ python lab/or_sort.py '{"models": ["standin/small"], "provider": {"data_collection": "deny"}}'
503: No allowed providers are available for the selected model. standin/small at standin-east: stores data
```

A primeira requisição pulou o `standin-east` e foi servida pelo `standin-west`. A segunda pediu um
modelo cujo único provedor guarda dados, e **a requisição falhou em vez de mandar o e-mail para lá**,
que é o comportamento a querer: um ajuste de privacidade que caísse em silêncio no provedor que devia
excluir não seria ajuste nenhum.

A mesma documentação lista controles mais estritos ao lado: `zdr`, para usar só endpoints com
retenção zero de dados, `only` e `ignore`, para nomear provedores, e `quantizations`, para recusar um
host que sirva o modelo numa precisão menor que a avaliada. Cada um é uma linha na requisição, e
cada um transforma uma pergunta das aulas 2 e 10 em algo que um programa garante em vez de uma
pessoa lembrar.
