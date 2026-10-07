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

**Por padrão, um provedor que guarda o que recebe e pode treinar com isso é permitido.** A
etiqueta que o OpenRouter mostra é, pela própria descrição dele, não definitiva. Para a Lantern
Books, cujos e-mails trazem nomes e endereços de clientes, `"deny"` é o ajuste de onde partir, e é
mais um campo na requisição:

```
ana@desk:~/desk$ export OPENROUTER_BASE_URL=http://127.0.0.1:8500/v1 MODEL=llama3.2:3b
ana@desk:~/desk$ python or_sort.py '{"provider": {"data_collection": "deny"}}'
other model=llama3.2:3b provider=None
ana@desk:~/desk$ python relay.py show --body | grep -A2 '"provider"'
  "provider": {
    "data_collection": "deny"
  }
```

O que o campo muda acontece do lado do OpenRouter: um provedor que guarda dados é pulado, e se todo
provedor do modelo guarda dados, não sobra ninguém para quem mandar. Esse é o comportamento a
querer: um ajuste de privacidade que caísse quieto no provedor que devia excluir não seria ajuste
nenhum. E é o ajuste que um servidor que não o conhece ignora mais quieto de todos, como o Ollama
fez com o `provider` na seção 03, então **um campo de privacidade é conferido contra o serviço a que
é mandado**, nunca suposto pela requisição.

A mesma documentação lista controles mais estritos ao lado: `zdr`, para usar só endpoints com
retenção zero de dados, `only` e `ignore`, para nomear provedores, e `quantizations`, para recusar
um host que sirva o modelo numa precisão menor que a avaliada. Cada um é uma linha na requisição, e
cada um transforma uma pergunta das aulas 2 e 10 em algo que um programa garante em vez de uma
pessoa lembrar.
