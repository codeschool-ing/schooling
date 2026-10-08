---
title: As peças do LangChain, e o que elas decidem
version: 2
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
ninguém perceber. As versões estão fixadas no `requirements.txt` da aula 1 (`langchain-core` 1.6.6,
`llama-index-core` 0.14.25), e as duas bibliotecas mudam depressa, então os nomes desta página vão mudar. As perguntas
é que ficam.

## O divisor

O divisor mais usado do LangChain é o `RecursiveCharacterTextSplitter`. Ele tenta cortar numa linha
em branco, depois numa quebra de linha, depois num espaço, e só então dentro de uma palavra, de modo
que um pedaço termina na maior fronteira que o mantém abaixo do tamanho. É a preferência da aula 4
pela estrutura, sem os títulos. Aqui ele está sem nada configurado, e depois com um tamanho escolhido
para bater com a aula 4:

```schooling-example
{
  "language": "python",
  "file": "lc_split.py",
  "parts": [
    {
      "code": "import glob\nimport inspect\n\nfrom langchain_text_splitters import RecursiveCharacterTextSplitter, TextSplitter\n\ndefaults = inspect.signature(TextSplitter.__init__).parameters\nprint({k: defaults[k].default for k in (\"chunk_size\", \"chunk_overlap\", \"length_function\")})\ntexts = [open(p).read() for p in sorted(glob.glob(\"data/docs/*.md\"))]\nfor splitter in (RecursiveCharacterTextSplitter(), RecursiveCharacterTextSplitter(chunk_size=400, chunk_overlap=50)):\n    chunks = splitter.create_documents(texts)\n    words = sum(len(c.page_content.split()) for c in chunks) / len(chunks)\n    print(f\"{len(chunks):3} chunks, {words:3.0f} words on average\")\nprint(chunks[0].page_content)",
      "note": "Os padrões do divisor, lidos da própria assinatura dele em vez da documentação, depois o corpus cortado com eles e com um tamanho menor, e o primeiro pedaço do corte menor impresso inteiro."
    }
  ]
}
```
```
ana@vm:~/rag$ python lc_split.py | head -n 20
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
essa ponta da escala: a linha de 240 palavras achou menos, 24 de 26, e mandou 768 tokens por pergunta, e
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
Apontado para o Ollama, ele falha na primeira chamada:

```schooling-example
{
  "language": "python",
  "file": "lc_embed.py",
  "parts": [
    {
      "code": "from langchain_openai import OpenAIEmbeddings\n\nquestion = \"How long is a gift card valid?\"\ntry:\n    OpenAIEmbeddings(model=\"all-minilm\").embed_query(question)\nexcept Exception as e:\n    print(type(e).__name__, e)\nplain = OpenAIEmbeddings(model=\"all-minilm\", check_embedding_ctx_length=False)\nprint(len(plain.embed_query(question)), \"dimensions\")",
      "note": "A mesma pergunta transformada em embedding duas vezes: uma com os padrões do LangChain, e outra com `check_embedding_ctx_length=False`, que faz a classe mandar o próprio texto."
    }
  ]
}
```
```
ana@vm:~/rag$ python lc_embed.py
BadRequestError Error code: 400 - {'error': {'message': 'invalid input type', 'type': 'invalid_request_error', 'param': None, 'code': None}}
384 dimensions
```

O Ollama recusou a requisição como malformada: `invalid input type`. Com as configurações padrão,
**o `OpenAIEmbeddings` não manda texto**. Ele codifica cada texto com o tiktoken e manda os números
dos tokens, para poder dividir um texto mais longo do que o modelo aceita e tirar a média dos
pedaços. Os números são do `cl100k_base`, a codificação da OpenAI, e não significariam nada para o
all-minilm mesmo que o Ollama os aceitasse. A API da própria OpenAI aceita uma lista de números de
tokens. A imitação dela que o Ollama faz só aceita strings, e o mesmo pode valer para qualquer
servidor que imite o formato da OpenAI. `check_embedding_ctx_length=False` desliga esse
comportamento, e a mesma chamada devolve 384 números.

Duas lições num erro só. Um padrão pode pressupor um provedor específico até numa classe cujo
propósito é deixar você trocar de provedor. E a metade silenciosa desse padrão é pior que a barulhenta:
contra um provedor que aceita números de tokens, um texto maior que o limite do modelo é dividido e
tem a média tirada sem aviso nenhum, e esse vetor médio representa um pedaço que ninguém escolheu. Os
tamanhos da aula 4 mantêm todo pedaço muito abaixo do limite de qualquer modelo, então a configuração
certa aqui é a que manda o que você escreveu.
