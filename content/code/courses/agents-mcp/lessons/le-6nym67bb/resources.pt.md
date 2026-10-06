---
title: Recursos
version: 1
---

Uma ferramenta é algo que o modelo pede para rodar. Um **recurso** é um dado que um hospedeiro pode ler: um documento, um registro, um arquivo, cada um com uma URI. A central de ajuda da Marginalia combina bem com isso: quarenta artigos que um hospedeiro pode mostrar a uma pessoa, anexar a uma conversa, ou dar ao modelo quando forem relevantes.

```
ana@lab:~/agents$ python try_server.py resources 2> server.log
template: help://{article_id} text/markdown
search_help: {"result": [{"title": "How to return a book", "uri": "help://h14"}, {"title": "Damaged books on arrival", "uri": "help://h12"}, {"title": "Wrong book in the par
help://h14 -> # How to return a book  You have 30 days from delivery to return a printed book in the condition you received it. Start 
help://h99 -> MCPError no help article h99
```

- **`help://{article_id}`** é um **modelo de recurso**: uma entrada na lista que vale por quarenta URIs. Um hospedeiro que quer mostrar a central de ajuda pode listar os modelos; a especificação também deixa um servidor listar recursos concretos, o que este não faz.
- **O `search_help` devolve URIs**, então a busca do modelo e a leitura do hospedeiro se encontram: o modelo acha `help://h14`, e o hospedeiro o lê (ou pergunta à pessoa, ou deixa o modelo ler, o que é decisão do hospedeiro).
- **Ler `help://h14`** devolveu o artigo em Markdown, com o `mimeType`.
- **Ler `help://h99`** falhou com o motivo, *"no help article h99"*. O `ResourceNotFoundError` é a exceção do SDK exatamente para isso; qualquer outra exceção teria sido uma queda, com o motivo guardado no servidor como nas ferramentas. A especificação dá a um recurso que não existe o código `-32602`.

O modelo de recurso importa também para a segurança. O `help_article` procura o id num dicionário montado a partir do arquivo; ele nunca monta um caminho com ele. Um handler de recurso que fizesse `open(f"help/{article_id}.md")` estaria a um `../` de ler qualquer arquivo que a ana consegue, que é a checagem do `read_handbook` da aula 7 de `ai-dev` em outro lugar. O SDK acrescenta a própria proteção para parâmetros de modelo (o `ResourceSecurity`, que recusa travessia por padrão), e o handler mais seguro ainda é um que nunca toca num caminho escolhido pelo cliente.
