---
title: LlamaIndex, and where it sends things
version: 2
---

LlamaIndex starts from the other end. LangChain began as a way to chain calls to a model, and
retrieval is one of the things it chains; **LlamaIndex began as a way to put documents in front of a
model**, and its central object is the index. Three lines load a folder, embed it and answer
questions about it, which is exactly why every one of those lines is worth opening.

## Where the requests go

Before the first index, a check that costs nothing. `env.sh` sets `OPENAI_BASE_URL`, the variable
the `openai` SDK reads, and every program in lessons 1 to 9 reached Ollama through it.

```schooling-example
{
  "language": "python",
  "file": "li_where.py",
  "parts": [
    {
      "code": "import os\n\nfrom llama_index.embeddings.openai import OpenAIEmbedding\nfrom llama_index.llms.openai import OpenAI\n\nprint(\"OPENAI_BASE_URL is\", os.environ[\"OPENAI_BASE_URL\"])\nprint(\"OpenAIEmbedding will call\", OpenAIEmbedding(model_name=\"all-minilm\").api_base)\ntry:\n    OpenAI(model=\"llama3.2:3b\").metadata\nexcept ValueError as e:\n    print(\"OpenAI(model='llama3.2:3b'):\", str(e).split(\".\")[0])",
      "note": "Where LlamaIndex's two OpenAI classes will send their requests, and what happens when the model's name is one OpenAI never published."
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

**LlamaIndex's OpenAI clients do not read `OPENAI_BASE_URL`.** They read `OPENAI_API_BASE`, the
name the SDK used before its version 1, and with neither set they fall back to OpenAI's public
address. Built with nothing but a model name, the embedding client would send every chunk of the
corpus to `api.openai.com`. Here the key is the word `ollama`, and OpenAI would refuse it. On a
developer's laptop with a real OpenAI key in `OPENAI_API_KEY` it succeeds, and a team that had
configured a different provider, perhaps for a reason written into a contract, has sent its
documents to one nobody chose.

The fix is to pass the address to each client by hand, and to check where a client points before it
is given anything private. The last line is the other surprise: `OpenAI(model="llama3.2:3b")` is
refused, because the class keeps a table of OpenAI's model names to look up each one's context
window. For any other model behind an OpenAI-style API, LlamaIndex has a separate package with a
class that takes the window as a parameter:

```schooling-example
{
  "language": "python",
  "file": "li_setup.py",
  "parts": [
    {
      "code": "import os\n\nfrom llama_index.core import Settings, SimpleDirectoryReader\nfrom llama_index.embeddings.openai import OpenAIEmbedding\nfrom llama_index.llms.openai_like import OpenAILike",
      "note": "`OpenAILike` comes from a package of its own, `llama-index-llms-openai-like`, made for servers that speak OpenAI's format with other models."
    },
    {
      "code": "BASE = os.environ[\"OPENAI_BASE_URL\"]\nSettings.embed_model = OpenAIEmbedding(model_name=\"all-minilm\", api_base=BASE)\nSettings.llm = OpenAILike(model=\"llama3.2:3b\", api_base=BASE, is_chat_model=True, context_window=4096, temperature=0)\ndocs = SimpleDirectoryReader(\"data/docs\").load_data()",
      "note": "The address passed to both clients by hand, because neither reads `OPENAI_BASE_URL`. `context_window` is what `OpenAI` would have looked up in its table of model names. `Settings` is global: every index and engine built after this uses these two clients."
    }
  ]
}
```

## The defaults, end to end

```schooling-example
{
  "language": "python",
  "file": "li_ask.py",
  "parts": [
    {
      "code": "import sys\n\nfrom li_setup import docs\nfrom llama_index.core import VectorStoreIndex\nfrom llama_index.core.prompts.chat_prompts import CHAT_TEXT_QA_PROMPT\n\nindex = VectorStoreIndex.from_documents(docs)\nnodes = list(index.docstore.docs.values())\nprint(len(docs), \"documents,\", len(nodes), \"nodes,\",\n      round(sum(len(n.get_content().split()) for n in nodes) / len(nodes)), \"words on average\")\nprint(\"the system prompt it sends:\")\nprint(CHAT_TEXT_QA_PROMPT.message_templates[0].content)\nprint()\nengine = index.as_query_engine(similarity_top_k=3)\nfor question in sys.argv[1:]:\n    print(\">\", question)\n    print(engine.query(question).response)",
      "note": "An index built from the documents with every default LlamaIndex has, the system prompt it will send, and the answers to the questions on the command line."
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

**14 nodes of 500 words on average**: the default splitter cuts at 1,024 tokens with 200 of overlap,
which on this corpus is a document per node again. A node is LlamaIndex's word for a chunk with its
metadata.

Then the system prompt, which is the part nobody reads. Its first rule is **"Never directly
reference the given context in your answer."** That is the opposite of lesson 7, where every
sentence had to name its source so that it could be checked. The prompt was written for a reply
that reads smoothly, which is a reasonable goal for a demonstration and the wrong one for a support
assistant whose answers have to be traceable.

The second reply shows why it matters. The index holds every document, the superseded 2025 policy
among them, because nothing filtered it out. This time the reply says thirty days, which is the
current policy's number, and nothing in it says which document it came from. The 2025 policy's
fourteen days, had they reached the top, would have been written with the same confidence and the
same absence of a source, and nobody reading the reply could tell the two apart.

## Citations, the LlamaIndex way

LlamaIndex has a query engine whose prompt asks for numbered citations:

```schooling-example
{
  "language": "python",
  "file": "li_cite.py",
  "parts": [
    {
      "code": "import sys\n\nfrom li_setup import docs\nfrom llama_index.core import VectorStoreIndex\nfrom llama_index.core.query_engine import CitationQueryEngine\n\nengine = CitationQueryEngine.from_args(VectorStoreIndex.from_documents(docs), similarity_top_k=3)\nreply = engine.query(sys.argv[1])\nprint(reply.response)\nfor node in reply.source_nodes:\n    print(\" \", \" \".join(node.node.get_content().split())[:64])",
      "note": "LlamaIndex's citation engine, which cuts the retrieved text into numbered sources and asks the model to cite them, and the first words of each source it built."
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

The prompt labels each source `Source 1:`, `Source 2:` and asks the model to cite them by number,
and llama3.2:3b used both labels at once, *Source 1 [1]*. A program parsing the reply has to know
that this prompt and this model write it that way. Three nodes were retrieved and **four sources were sent**, because this engine cuts the retrieved
nodes again, into pieces of 512 tokens by default, before numbering them. A citation therefore
points at a piece of up to 512 tokens and not at the chunk the search found. The size can be set
with `citation_chunk_size`; leaving it unset is choosing 512.
