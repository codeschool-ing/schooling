---
title: O LlamaIndex, e para onde ele manda as coisas
version: 2
---

O LlamaIndex começa pela outra ponta. O LangChain nasceu como um jeito de encadear chamadas a um
modelo, e a recuperação é uma das coisas que ele encadeia; **o LlamaIndex nasceu como um jeito de pôr
documentos na frente de um modelo**, e o objeto central dele é o índice. Três linhas carregam uma
pasta, geram os embeddings e respondem perguntas sobre ela, e é exatamente por isso que vale abrir
cada uma dessas linhas.

## Para onde vão as requisições

Antes do primeiro índice, uma verificação que não custa nada. O `env.sh` define `OPENAI_BASE_URL`, a
variável que o SDK `openai` lê, e todo programa das aulas 1 a 9 chegou ao Ollama por ela.

```schooling-example
{
  "language": "python",
  "file": "li_where.py",
  "parts": [
    {
      "code": "import os\n\nfrom llama_index.embeddings.openai import OpenAIEmbedding\nfrom llama_index.llms.openai import OpenAI\n\nprint(\"OPENAI_BASE_URL is\", os.environ[\"OPENAI_BASE_URL\"])\nprint(\"OpenAIEmbedding will call\", OpenAIEmbedding(model_name=\"all-minilm\").api_base)\ntry:\n    OpenAI(model=\"llama3.2:3b\").metadata\nexcept ValueError as e:\n    print(\"OpenAI(model='llama3.2:3b'):\", str(e).split(\".\")[0])",
      "note": "Para onde as duas classes OpenAI do LlamaIndex vão mandar as requisições, e o que acontece quando o nome do modelo é um que a OpenAI nunca publicou."
    }
  ]
}
```
```
ana@vm:~/rag$ python li_where.py
OPENAI_BASE_URL is http://localhost:11434/v1
OpenAIEmbedding will call https://api.openai.com/v1
OpenAI(model='llama3.2:3b'): Unknown model 'llama3
```

**Os clientes OpenAI do LlamaIndex não leem `OPENAI_BASE_URL`.** Eles leem `OPENAI_API_BASE`, o nome
que o SDK usava antes da versão 1, e sem nenhuma das duas voltam para o endereço público da OpenAI.
Construído só com o nome de um modelo, o cliente de embeddings mandaria cada pedaço do acervo para
`api.openai.com`. Aqui a chave é a palavra `ollama`, e a OpenAI a recusaria. No notebook de um desenvolvedor com uma chave real da OpenAI em `OPENAI_API_KEY` ela dá
certo, e uma equipe que tinha configurado outro provedor, talvez por um motivo escrito num contrato,
mandou seus documentos para um que ninguém escolheu.

A correção é passar o endereço à mão para cada cliente, e conferir para onde um cliente aponta antes
de lhe entregar qualquer coisa privada. A última linha é a outra surpresa: `OpenAI(model="llama3.2:3b")`
é recusado, porque a classe guarda uma tabela dos nomes de modelo da OpenAI para achar a janela de
contexto de cada um. Para qualquer outro modelo atrás de uma API no estilo da OpenAI, o LlamaIndex tem
um pacote separado com uma classe que recebe a janela como parâmetro:

```schooling-example
{
  "language": "python",
  "file": "li_setup.py",
  "parts": [
    {
      "code": "import os\n\nfrom llama_index.core import Settings, SimpleDirectoryReader\nfrom llama_index.embeddings.openai import OpenAIEmbedding\nfrom llama_index.llms.openai_like import OpenAILike",
      "note": "O `OpenAILike` vem de um pacote próprio, o `llama-index-llms-openai-like`, feito para servidores que falam o formato da OpenAI com outros modelos."
    },
    {
      "code": "BASE = os.environ[\"OPENAI_BASE_URL\"]\nSettings.embed_model = OpenAIEmbedding(model_name=\"all-minilm\", api_base=BASE)\nSettings.llm = OpenAILike(model=\"llama3.2:3b\", api_base=BASE, is_chat_model=True, context_window=4096, temperature=0)\ndocs = SimpleDirectoryReader(\"data/docs\").load_data()",
      "note": "O endereço passado à mão aos dois clientes, porque nenhum lê o `OPENAI_BASE_URL`. O `context_window` é o que o `OpenAI` teria procurado na sua tabela de nomes de modelos. O `Settings` é global: todo índice e motor construído depois disto usa esses dois clientes."
    }
  ]
}
```

## Os padrões, de ponta a ponta

```schooling-example
{
  "language": "python",
  "file": "li_ask.py",
  "parts": [
    {
      "code": "import sys\n\nfrom li_setup import docs\nfrom llama_index.core import VectorStoreIndex\nfrom llama_index.core.prompts.chat_prompts import CHAT_TEXT_QA_PROMPT\n\nindex = VectorStoreIndex.from_documents(docs)\nnodes = list(index.docstore.docs.values())\nprint(len(docs), \"documents,\", len(nodes), \"nodes,\",\n      round(sum(len(n.get_content().split()) for n in nodes) / len(nodes)), \"words on average\")\nprint(\"the system prompt it sends:\")\nprint(CHAT_TEXT_QA_PROMPT.message_templates[0].content)\nprint()\nengine = index.as_query_engine(similarity_top_k=3)\nfor question in sys.argv[1:]:\n    print(\">\", question)\n    print(engine.query(question).response)",
      "note": "Um índice construído a partir dos documentos com todos os padrões que o LlamaIndex tem, o prompt de sistema que ele vai mandar, e as respostas às perguntas da linha de comando."
    }
  ]
}
```
```
ana@vm:~/rag$ python li_ask.py "How long is a gift card valid?" "How many days do I have to return a printed book?"
13 documents, 14 nodes, 500 words on average
the system prompt it sends:
You are an expert Q&A system that is trusted around the world.
Always answer the query using the provided context information, and not prior knowledge.
Some rules to follow:
1. Never directly reference the given context in your answer.
2. Avoid statements like 'Based on the context, ...' or 'The context information ...' or anything along those lines.

> How long is a gift card valid?
A gift card is valid for two years from the day it was bought.
> How many days do I have to return a printed book?
You have 30 days from delivery to return a printed book.
```

**14 nós de 500 palavras em média**: o divisor padrão corta em 1.024 tokens com 200 de sobreposição,
o que neste acervo é de novo um documento por nó. Nó é a palavra do LlamaIndex para um pedaço com seus
metadados.

Depois o prompt de sistema, que é a parte que ninguém lê. A primeira regra dele é **"Never directly
reference the given context in your answer."**, nunca fazer referência direta ao contexto dado. É o
oposto da aula 7, em que toda frase tinha de nomear sua fonte para poder ser conferida. O prompt foi
escrito para uma resposta que se lê com fluidez, um objetivo razoável para uma demonstração e o
errado para um assistente de atendimento cujas respostas precisam ser rastreáveis.

A segunda resposta mostra por que isso importa. O índice guarda todos os documentos, a política
substituída de 2025 entre eles, porque nada a filtrou. Desta vez a resposta diz trinta dias, que é o
número da política atual, e nada nela diz de que documento ele veio. Os catorze dias da política de
2025, se tivessem chegado ao topo, teriam sido escritos com a mesma confiança e a mesma falta de
fonte, e ninguém lendo a resposta conseguiria distinguir uma da outra.

## Citações, do jeito do LlamaIndex

O LlamaIndex tem um motor de consulta cujo prompt pede citações numeradas:

```schooling-example
{
  "language": "python",
  "file": "li_cite.py",
  "parts": [
    {
      "code": "import sys\n\nfrom li_setup import docs\nfrom llama_index.core import VectorStoreIndex\nfrom llama_index.core.query_engine import CitationQueryEngine\n\nengine = CitationQueryEngine.from_args(VectorStoreIndex.from_documents(docs), similarity_top_k=3)\nreply = engine.query(sys.argv[1])\nprint(reply.response)\nfor node in reply.source_nodes:\n    print(\" \", \" \".join(node.node.get_content().split())[:64])",
      "note": "O motor de citações do LlamaIndex, que corta o texto recuperado em fontes numeradas e pede ao modelo que as cite, e as primeiras palavras de cada fonte que ele montou."
    }
  ]
}
```
```
ana@vm:~/rag$ python li_cite.py "How long is a gift card valid?"
According to Source 1 [1], a gift card is valid for two years from the day it was bought.
  Source 1: --- id: gift-cards title: Gift card terms audience: pu
  Source 2: --- id: payments-and-invoices title: Payments, invoice
  Source 3: ## Gift cards Gift cards are sold in values from 10 to
  Source 4: ## Items that cannot be returned The following cannot 
```

O prompt rotula cada fonte como `Source 1:`, `Source 2:` e pede ao modelo que as cite pelo número, e
o llama3.2:3b usou os dois rótulos de uma vez, *Source 1 [1]*. Um programa que lê a resposta precisa
saber que este prompt e este modelo escrevem desse jeito. Foram
recuperados três nós e **mandadas quatro fontes**, porque esse motor corta de novo os nós recuperados,
em pedaços de 512 tokens por padrão, antes de numerá-los. Uma citação aponta, portanto, para um pedaço
de até 512 tokens, e não para o pedaço que a busca achou. O tamanho pode ser definido com
`citation_chunk_size`; deixá-lo de fora é escolher 512.
