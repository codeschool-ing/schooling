---
title: Os componentes do Haystack, e ids feitos de conteúdo
version: 2
---

O **Haystack**, da deepset, segue uma linha mais rígida que as duas bibliotecas da aula 10. Tudo é
um **componente**: uma classe com um método `run` cujas entradas e saídas são declaradas com seus
tipos. Um **pipeline** é um grafo de componentes com nome, e cada ligação entre dois deles é
conferida no momento em que é feita. O `requirements.txt` da aula 1 fixa o `haystack-ai` 3.3.0.

## Uma ligação que não encaixa

Ligar a saída do gerador de embeddings de texto direto no gerador de chat é um absurdo, já que um
vetor não é uma conversa, e o Haystack diz isso antes de qualquer coisa rodar:

```schooling-example
{
  "language": "python",
  "file": "hs_wrong.py",
  "parts": [
    {
      "code": "from haystack import Pipeline\nfrom haystack.components.embedders import OpenAITextEmbedder\nfrom haystack.components.generators.chat import OpenAIChatGenerator\n\np = Pipeline()\np.add_component(\"embed\", OpenAITextEmbedder(model=\"all-minilm\"))\np.add_component(\"generate\", OpenAIChatGenerator(model=\"llama3.2:3b\"))\ntry:\n    p.connect(\"embed.embedding\", \"generate.messages\")\nexcept Exception as e:\n    print(type(e).__name__ + \":\", \" \".join(str(e).split()))",
      "note": "Dois componentes cujos encaixes não combinam, o vetor do embedder nas mensagens do gerador, ligados mesmo assim para ver quem reclama e quando."
    }
  ]
}
```
```
ana@vm:~/rag$ python hs_wrong.py
PipelineConnectError: Cannot connect 'embed.embedding' with 'generate.messages': their declared input and output types do not match. 'embed': - embedding: list[float] 'generate': - messages: list[ChatMessage] | str (available)
```

O erro nomeia as duas pontas e os dois tipos: uma `list[float]` não pode ir onde se espera uma
`list[ChatMessage]`. O `|` do LangChain teria juntado os dois e falhado na primeira pergunta, com um
erro de dentro do cliente do modelo. Um pipeline que não pode ser montado é uma falha mais barata do
que um que quebra quando um cliente o usa.

## Indexação como pipeline

A indexação também é um pipeline: dividir, gerar embeddings, gravar. Primeiro os documentos, lidos
do jeito que o Haystack os quer pelo `hs_docs.py`:

```schooling-example
{
  "language": "python",
  "file": "hs_docs.py",
  "parts": [
    {
      "code": "import glob\n\nfrom haystack import Document\n\n\ndef document(path):\n    \"\"\"The text after the front matter, with the front matter as metadata.\"\"\"\n    _, head, body = open(path).read().split(\"---\\n\", 2)\n    return Document(content=body, meta=dict(line.split(\": \", 1) for line in head.splitlines()))\n\n\ndocs = [document(p) for p in sorted(glob.glob(\"data/docs/*.md\"))]",
      "note": "Cada documento como um `Document` do Haystack: o texto depois do front matter como conteúdo, e o front matter como metadados. Os programas desta aula importam `docs` daqui."
    }
  ]
}
```
Depois o programa de indexação. Ele carrega o acervo, carrega de novo, e depois muda um campo dos
metadados de um documento, o dono da política de devoluções, e carrega só esse documento:

```schooling-example
{
  "language": "python",
  "file": "hs_index.py",
  "parts": [
    {
      "code": "import sys\n\nfrom haystack import Pipeline\nfrom haystack.components.embedders import OpenAIDocumentEmbedder\nfrom haystack.components.preprocessors import DocumentSplitter\nfrom haystack.components.writers import DocumentWriter\nfrom haystack.document_stores.in_memory import InMemoryDocumentStore\nfrom haystack.document_stores.types import DuplicatePolicy\nfrom hs_docs import docs",
      "note": "Um pipeline, três componentes e um armazenamento que vive na memória. O `hs_docs.py` lê o front matter para os metadados, como o `lc_load.py` fazia na aula 10."
    },
    {
      "code": "store = InMemoryDocumentStore()\npolicy = DuplicatePolicy.OVERWRITE if \"--overwrite\" in sys.argv else DuplicatePolicy.NONE\nindexing = Pipeline()\nindexing.add_component(\"split\", DocumentSplitter(split_by=\"word\", split_length=60))\nindexing.add_component(\"embed\", OpenAIDocumentEmbedder(model=\"all-minilm\", progress_bar=False))\nindexing.add_component(\"write\", DocumentWriter(store, policy=policy))\nindexing.connect(\"split\", \"embed\")\nindexing.connect(\"embed\", \"write\")",
      "note": "Cada componente entra com um nome e depois é ligado pelo nome. O `connect` confere se o que um manda é o que o seguinte aceita. `DuplicatePolicy.NONE` deixa a decisão para o armazenamento, o que neste armazenamento quer dizer recusar uma duplicata."
    },
    {
      "code": "def load(documents):\n    try:\n        print(\"written:\", indexing.run({\"split\": {\"documents\": documents}})[\"write\"][\"documents_written\"])\n    except Exception as e:\n        print(type(e).__name__ + \":\", [line for line in str(e).splitlines() if line.startswith(\"Error:\")][0][:110])",
      "note": "Rodar o pipeline sobre alguns documentos e imprimir quantos pedaços foram escritos, ou a linha do próprio erro."
    },
    {
      "code": "load(docs)\nload(docs)\ndocs[7].meta[\"owner\"] = \"customer-service\"\nload(docs[7:8])\nprint(\"in the store:\", store.count_documents())\nstore.save_to_disk(\"store.json\")",
      "note": "Carregar tudo, carregar de novo, depois mudar um campo de metadados de um documento, o dono da política de devoluções, e carregar só esse documento. O armazenamento é salvo para o próximo programa."
    }
  ]
}
```

O divisor está em 60 palavras, o tamanho da aula 4; o padrão dele é 200 palavras sem sobreposição,
ao qual a seção de medição volta. O gerador de embeddings manda texto, como o Ollama espera, e lê o
endereço do provedor no `OPENAI_BASE_URL`, como o SDK `openai` sobre o qual é construído.

```
ana@vm:~/rag$ python hs_index.py
written: 110
PipelineRuntimeError: Error: ID '070820b895e5fb0107bb644c997975b17ee639273fdc05bbcd34657810edd9b8' already exists.
written: 14
in the store: 124
```

**A segunda carga foi recusada**: já existe um pedaço com aquele id. O Haystack dá a todo documento
um id quando ele é criado, um hash SHA-256 do conteúdo **e dos metadados**, de modo que o mesmo
pedaço sempre recebe o mesmo id, e com a política de duplicatas padrão este armazenamento se recusa
a gravá-lo duas vezes. É a ideia da aula 5, ids feitos do conteúdo, escolhida como padrão. O
armazenamento do LangChain, sem ids passados, dobrou.

Depois, a terceira linha. Um campo de metadados mudou num documento, e **14 pedaços foram gravados
como novos**, e o armazenamento foi de 110 para 124. Como os metadados fazem parte do hash, um pedaço
cujo texto não mudou mas cujo dono mudou tem outro id, então é gravado ao lado do antigo em vez de por
cima dele. Os 14 antigos continuam lá, com o dono antigo.

```
ana@vm:~/rag$ python hs_index.py --overwrite
written: 110
written: 110
written: 14
in the store: 124
```

Sobrescrever não ajuda. A política decide o que acontece quando um id já existe, e estes ids são
novos, então o resultado é o mesmo, 124. A aula 5 fazia o hash do caminho de títulos e do texto e de
mais nada, e atualizava os metadados no lugar; é por isso que uma mudança de status ou de público na
aula 5 tirava um pedaço da busca em vez de copiá-lo. No Haystack, o mesmo efeito exige um id montado
como a aula 5 monta, definido em cada documento antes de gravar, ou apagar antes os pedaços antigos do
documento. A próxima seção mostra o que a duplicata faz com uma resposta.
