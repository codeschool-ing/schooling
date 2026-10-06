---
title: As peças do LangChain, e o que elas decidem
version: 1
---

A aula 9 montou o pipeline com o SDK do provedor, um driver de banco e umas cem linhas de Python.
**LangChain** e **LlamaIndex** são as duas bibliotecas mais conhecidas que empacotam esses mesmos
passos como peças de formato comum: um carregador, um divisor, um cliente de embeddings, um
armazenamento vetorial, um recuperador, um modelo de prompt, um cliente de modelo. Trocar um
armazenamento ou um provedor por outro vira então a mudança de uma linha, e é isso que elas vendem
antes de tudo.

Esta aula monta o pipeline de novo com cada uma delas e faz uma pergunta a cada peça: **o que ela
decidiu que as aulas 4 a 8 decidiram medindo?** Um framework nunca deixa um valor vazio. Um padrão
escolhido por alguém que nunca viu os seus documentos continua sendo uma decisão, e ela é tomada sem
ninguém perceber. As versões estão fixadas no laboratório (`langchain-core` 1.6.6, `llama-index-core`
0.14.25), e as duas bibliotecas mudam depressa, então os nomes desta página vão mudar. As perguntas
é que ficam.

## O divisor

O divisor mais usado do LangChain é o `RecursiveCharacterTextSplitter`. Ele tenta cortar numa linha
em branco, depois numa quebra de linha, depois num espaço, e só então dentro de uma palavra, de modo
que um pedaço termina na maior fronteira que o mantém abaixo do tamanho. É a preferência da aula 4
pela estrutura, sem os títulos. Aqui ele está sem nada configurado, e depois com um tamanho escolhido
para bater com a aula 4:

```
ana@lab:~/rag$ python lc_split.py | head -n 20
{'chunk_size': 4000, 'chunk_overlap': 200, 'length_function': <built-in function len>}
 14 chunks, 491 words on average
132 chunks,  54 words on average
---
id: affiliate-api
title: Affiliate API reference
audience: developers
owner: platform
updated: 2026-02-10
version: 2.3
status: current
---

# Affiliate API reference

The affiliate API lets partner sites look up books, build tracked links and read their commission
reports. This is version 2.3 of the reference.

## Base URL and authentication
```

A primeira linha é a assinatura da classe base: **4.000 por padrão, e medidos com `len`, ou seja, em
caracteres**, não em palavras nem em tokens. Nos treze documentos da Marginalia isso dá 14 pedaços
de 491 palavras em média, um documento ou quase um documento por pedaço. A aula 4 mediu para onde vai
essa ponta da escala: a linha de 240 palavras achou tudo e mandou 768 tokens por pergunta, e
documentos inteiros são o "por que não colocar tudo no prompt" da aula 1 com passos a mais. Com 400
caracteres os pedaços têm 54 palavras em média, perto das 60 que a aula 4 escolheu.

O pedaço impresso mostra a outra coisa que o divisor não sabe: **front matter**. O bloco entre as
linhas `---` é texto para ele, então o id, o público e o status do documento são cortados, recebem
embedding e são buscados como se fossem prosa. A aula 5 os guardou em colunas porque a aula 6 filtra
por eles. O `langchain-text-splitters` também tem um `MarkdownHeaderTextSplitter`, que corta nos
títulos e guarda cada título como metadado, o caminho de títulos da aula 5. Nenhum dos dois divisores
lê um bloco de front matter.

## O cliente de embeddings

O `OpenAIEmbeddings` do `langchain-openai` é a metade de embeddings do SDK do provedor, embrulhada.
Apontado para o modelo do laboratório, ele falha na primeira chamada:

```
ana@lab:~/rag$ python lc_embed.py
BadRequestError Error code: 400 - {'error': {'message': "'input' must be a string or a non-empty array of strings.", 'type': 'invalid_request_error', 'param': None, 'code': 'invalid_value'}}
384 dimensions
```

O provedor recusou a requisição como malformada: `'input' must be a string`. Com as configurações
padrão, **o `OpenAIEmbeddings` não manda texto**. Ele codifica cada texto com o tiktoken e manda os
números dos tokens, para poder dividir um texto mais longo do que o modelo aceita e tirar a média dos
pedaços. A API da própria OpenAI aceita uma lista de números de tokens. O labembed, o substituto do
laboratório, só aceita strings, e o mesmo pode valer para qualquer provedor que apenas imite o
formato da OpenAI. `check_embedding_ctx_length=False` desliga esse comportamento, e a mesma chamada
devolve 384 números.

Duas lições num erro só. Um padrão pode pressupor um provedor específico até numa classe cujo
propósito é deixar você trocar de provedor. E a metade silenciosa desse padrão é pior que a barulhenta:
contra um provedor que aceita números de tokens, um texto maior que o limite do modelo é dividido e
tem a média tirada sem aviso nenhum, e esse vetor médio representa um pedaço que ninguém escolheu. Os
tamanhos da aula 4 mantêm todo pedaço muito abaixo do limite de qualquer modelo, então a configuração
certa aqui é a que manda o que você escreveu.
