---
title: O LlamaIndex, e para onde ele manda as coisas
version: 1
---

O LlamaIndex começa pela outra ponta. O LangChain nasceu como um jeito de encadear chamadas a um
modelo, e a recuperação é uma das coisas que ele encadeia; **o LlamaIndex nasceu como um jeito de pôr
documentos na frente de um modelo**, e o objeto central dele é o índice. Três linhas carregam uma
pasta, geram os embeddings e respondem perguntas sobre ela, e é exatamente por isso que vale abrir
cada uma dessas linhas.

## Para onde vão as requisições

Antes do primeiro índice, uma verificação que não custa nada. O laboratório define `OPENAI_BASE_URL`,
a variável que o SDK `openai` lê, e todo programa das aulas 5 a 9 chegou ao labgen por ela.

```
ana@lab:~/rag$ python li_where.py
OPENAI_BASE_URL is http://127.0.0.1:8600/v1
OpenAIEmbedding will call https://api.openai.com/v1
OpenAI(model='extract-1'): Unknown model 'extract-1'
```

**Os clientes OpenAI do LlamaIndex não leem `OPENAI_BASE_URL`.** Eles leem `OPENAI_API_BASE`, o nome
que o SDK usava antes da versão 1, e sem nenhuma das duas voltam para o endereço público da OpenAI.
Construído só com o nome de um modelo, o cliente de embeddings mandaria cada pedaço do acervo para
`api.openai.com`. Neste laboratório essa requisição falha, porque nenhum provedor real está ao
alcance. No notebook de um desenvolvedor com uma chave real da OpenAI em `OPENAI_API_KEY` ela dá
certo, e uma equipe que tinha configurado outro provedor, talvez por um motivo escrito num contrato,
mandou seus documentos para um que ninguém escolheu.

A correção é passar o endereço à mão para cada cliente, e conferir para onde um cliente aponta antes
de lhe entregar qualquer coisa privada. A última linha é a outra surpresa: `OpenAI(model="extract-1")`
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
      "code": "BASE = os.environ[\"OPENAI_BASE_URL\"]\nSettings.embed_model = OpenAIEmbedding(model_name=\"lab-minilm\", api_base=BASE)\nSettings.llm = OpenAILike(model=\"extract-1\", api_base=BASE, is_chat_model=True, context_window=8192)\ndocs = SimpleDirectoryReader(\"data/docs\").load_data()",
      "note": "O endereço passado à mão aos dois clientes, porque nenhum lê o `OPENAI_BASE_URL`. O `context_window` é o que o `OpenAI` teria procurado na sua tabela de nomes de modelos. O `Settings` é global: todo índice e motor construído depois disto usa esses dois clientes."
    }
  ]
}
```

## Os padrões, de ponta a ponta

```
ana@lab:~/rag$ python li_ask.py "How long is a gift card valid?" "How many days do I have to return a printed book?"
13 documents, 14 nodes, 500 words on average
the system prompt it sends:
You are an expert Q&A system that is trusted around the world.
Always answer the query using the provided context information, and not prior knowledge.
Some rules to follow:
1. Never directly reference the given context in your answer.
2. Avoid statements like 'Based on the context, ...' or 'The context information ...' or anything along those lines.

> How long is a gift card valid?
A gift card is valid for two years from the day it was bought. Gift cards are valid for two years from purchase and cannot be exchanged for cash.
> How many days do I have to return a printed book?
You have 30 days from delivery to return a printed book in the condition you received it. You may return a printed book within 14 days of delivery if it is unread and in the condition in which you received it. A printed book with a fault from the printer, such as pages bound upside down or missing, can be returned for a refund or a replacement within 30 days, like any other return.
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
substituída de 2025 entre eles, porque nada a filtrou. A resposta põe os 30 dias atuais ao lado dos
14 dias antigos, e sem citação nada nela diz qual frase veio de qual política. O extract-1 copia
frases inteiras, então aqui as duas ainda podem ser achadas buscando nos documentos; um modelo que
segue aquele prompt é instruído a misturá-las em palavras próprias, e depois disso não podem mais.

## Citações, do jeito do LlamaIndex

O LlamaIndex tem um motor de consulta cujo prompt pede citações numeradas:

```
ana@lab:~/rag$ python li_cite.py "How long is a gift card valid?"
A gift card is valid for two years from the day it was bought. [1] Gift cards are valid for two years from purchase and cannot be exchanged for cash. [3]
  Source 1: --- id: gift-cards title: Gift card terms audience: pu
  Source 2: --- id: payments-and-invoices title: Payments, invoice
  Source 3: ## Gift cards Gift cards are sold in values from 10 to
  Source 4: ## Items that cannot be returned The following cannot 
```

O prompt rotula cada fonte como `Source 1:`, `Source 2:` e pede ao modelo que as cite pelo número; o
extract-1 lê esses rótulos como lê o `[1]` da aula 7. A resposta cita as fontes 1 e 3. Foram
recuperados três nós e **mandadas quatro fontes**, porque esse motor corta de novo os nós recuperados,
em pedaços de 512 tokens por padrão, antes de numerá-los. Uma citação aponta, portanto, para um pedaço
de até 512 tokens, e não para o pedaço que a busca achou. O tamanho pode ser definido com
`citation_chunk_size`; deixá-lo de fora é escolher 512.
