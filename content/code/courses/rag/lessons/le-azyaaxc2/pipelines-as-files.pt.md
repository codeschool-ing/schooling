---
title: Um pipeline escrito como arquivo
version: 1
---

Como cada componente declara seus parâmetros e cada ligação tem nome, um pipeline do Haystack pode
ser escrito em YAML e carregado de volta. O `hs_dump.py` importa o pipeline do `hs_ask.py` e imprime
`rag.dumps()`:

```
ana@lab:~/rag$ python hs_dump.py > rag.yaml; wc -l rag.yaml
114 rag.yaml
```

O primeiro componente, como ficou escrito:

```
ana@lab:~/rag$ head -n 18 rag.yaml
components:
  embed:
    init_parameters:
      api_base_url: null
      api_key:
        env_vars:
        - OPENAI_API_KEY
        strict: true
        type: env_var
      dimensions: null
      http_client_kwargs: null
      max_retries: null
      model: lab-minilm
      organization: null
      prefix: ''
      suffix: ''
      timeout: null
    type: haystack.components.embedders.openai_text_embedder.OpenAITextEmbedder
```

**A chave não está no arquivo.** O `api_key` é escrito como o nome da variável de ambiente de onde
lê-la, `OPENAI_API_KEY`, e `strict: true` quer dizer que uma variável ausente é um erro, e não uma
chamada anônima silenciosa. O Haystack guarda segredos num tipo próprio por esse motivo, e um segredo
criado a partir de uma chave literal não pode ser escrito: serializá-lo é recusado. Um arquivo que
descreve um pipeline pode então ser commitado, revisado e comparado sem vazar nada.

Todo outro parâmetro também é escrito, inclusive os que ninguém definiu: `api_base_url: null` diz que
o endereço vem do ambiente, e `max_retries: null`, que vale o padrão do próprio SDK. Quem revisa este
arquivo vê os padrões, exatamente o que a aula 10 teve de cavar para achar.

```
ana@lab:~/rag$ grep -n -A 11 "      filters:" rag.yaml
89:      filters:
90-        conditions:
91-        - field: meta.status
92-          operator: ==
93-          value: current
94-        - field: meta.audience
95-          operator: ==
96-          value: public
97-        operator: AND
98-      return_embedding: false
99-      scale_score: false
100-      top_k: 3
ana@lab:~/rag$ sed -n "/^connections:/,\$p" rag.yaml
connections:
- receiver: retrieve.query_embedding
  sender: embed.embedding
- receiver: floor.documents
  sender: retrieve.documents
- receiver: prompt.documents
  sender: floor.documents
- receiver: generate.messages
  sender: prompt.prompt
max_runs_per_component: 100
metadata: {}
```

O filtro da aula 6, o `top_k` de 3 e as quatro ligações, legíveis por qualquer pessoa que saiba o que
é um recuperador. Mudar o `top_k` ou o piso é um diff de uma linha num pull request, e o teste da aula
8 pode rodar contra o arquivo que o pull request muda.

## O que o arquivo não é

**Não é o índice.** O armazenamento é escrito como suas configurações, nunca como seus documentos;
este armazenamento vive na memória e foi salvo em `store.json` à parte pelo programa de indexação. Um
armazenamento num banco de dados seria escrito como sua conexão, e os pedaços ficam no banco.
Carregar o YAML dá o mesmo pipeline sobre o que o armazenamento tiver naquele momento.

**É código.** Cada componente é escrito com o caminho de importação da sua classe, `hs_floor.Floor`
entre eles, e carregar o arquivo importa e constrói toda classe que ele nomeia. Então um arquivo de
pipeline é tratado como um programa: carregado só do repositório da própria equipe, revisado como
qualquer outra mudança, e nunca aceito de um usuário, de um upload ou de uma requisição. O mesmo vale
para qualquer sistema que constrói objetos a partir de um arquivo que os nomeia.
