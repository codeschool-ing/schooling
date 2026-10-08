---
title: Janelas de frases e auto-merging
version: 2
---

A aula 4 terminou numa tensão que um tamanho só não resolvia: um pedaço pequeno casa com a pergunta
com precisão e leva pouco demais para respondê-la, um pedaço grande leva a resposta e casa de forma
vaga. A saída dela foi o **pequeno-para-grande**: buscar pedaços pequenos e mandar o pedaço maior de
onde cada um veio. O LlamaIndex tem duas versões prontas da ideia, e elas são as partes dele que mais
vale pegar emprestado.

## A janela de frases

```schooling-example
{
  "language": "python",
  "file": "li_window.py",
  "parts": [
    {
      "code": "import sys\n\nfrom li_setup import docs\nfrom llama_index.core import VectorStoreIndex\nfrom llama_index.core.node_parser import SentenceWindowNodeParser",
      "note": "Os documentos e os clientes do `li_setup.py`."
    },
    {
      "code": "nodes = SentenceWindowNodeParser.from_defaults(window_size=3).get_nodes_from_documents(docs)\nhit = VectorStoreIndex(nodes).as_retriever(similarity_top_k=1).retrieve(sys.argv[1])[0]\nprint(len(nodes), \"sentences indexed\")\nprint(\"matched:\", hit.node.get_content().strip())\nprint(\"window: \", \" \".join(hit.node.metadata[\"window\"].split()))",
      "note": "Um nó por frase, cada um levando as três frases de cada lado nos metadados, em `window`. A busca compara a pergunta com a frase; a janela é o que seria mandado ao modelo."
    }
  ]
}
```

```
ana@vm:~/rag$ python li_window.py "How much is express delivery?"
374 sentences indexed
matched: Express delivery is not free at any order value.
window:  --- id: shipping-and-delivery title: Shipping and delivery audience: public owner: operations updated: 2026-03-18 version: 6 status: current --- # Shipping and delivery Everything about how an order reaches you: the options at checkout, what they cost, how long they take, and what happens when a parcel goes missing. ## Delivery options and costs | option | time | cost | | --- | --- | --- | | standard | three to five working days | 4.90, free on orders over 40 | | express | next working day if ordered before 2 pm | 9.90 | | pickup point | three to five working days | 2.90, free on orders over 40 | | international | seven to fifteen working days | from 14.00, shown at checkout | The threshold of 40 is the value of the books in the order after any discount, with tax included and gift wrapping excluded. Express delivery is not free at any order value. Express orders placed after 2 pm, or on a Saturday, Sunday or public holiday, leave the warehouse on the next working day and arrive the working day after that. ## When an order leaves the warehouse Books in stock leave the warehouse within one working day. A book shown as Dispatched in 3 to 5 days is ordered from the publisher, and the whole order waits for it unless you choose Send what is ready at checkout.
```

A frase que casou, "Express delivery is not free at any order value", **fala da entrega expressa e
não traz o preço dela**. O preço, 9.90, está na tabela três frases antes. Buscadas sozinhas, as frases
casam bem com as perguntas e perdem os fatos em volta; é a linha da tabela da próxima seção em que as
frases sozinhas acham 21 de 26. A janela devolve os vizinhos. Um pós-processador, o
`MetadataReplacementPostProcessor`, troca cada frase recuperada pela sua janela antes de o prompt ser
montado, então a busca é precisa e o modelo lê o parágrafo.

A janela tem um custo que a saída mostra. Ela é **contada em frases, e não limitada pela estrutura do
documento**: esta começa dentro do front matter e passa do título seguinte. Os pedaços estruturados da
aula 4 nunca atravessam um título, porque as seções de uma política são onde os assuntos dela mudam.
Aqui uma janela pode levar o fim de um assunto para o começo de outro.

## Auto-merging

```schooling-example
{
  "language": "python",
  "file": "li_merge.py",
  "parts": [
    {
      "code": "import sys\n\nfrom li_setup import docs\nfrom llama_index.core import StorageContext, VectorStoreIndex\nfrom llama_index.core.node_parser import HierarchicalNodeParser, get_leaf_nodes\nfrom llama_index.core.retrievers import AutoMergingRetriever",
      "note": "Os documentos e os clientes do `li_setup.py`."
    },
    {
      "code": "nodes = HierarchicalNodeParser.from_defaults().get_nodes_from_documents(docs)\nleaves = get_leaf_nodes(nodes)\nstorage = StorageContext.from_defaults()\nstorage.docstore.add_documents(nodes)\nindex = VectorStoreIndex(leaves, storage_context=storage)\nprint(len(nodes), \"nodes,\", len(leaves), \"of them leaves\")\nfor name, retriever in ((\"leaves\", index.as_retriever(similarity_top_k=6)),\n                        (\"merged\", AutoMergingRetriever(index.as_retriever(similarity_top_k=6), storage))):\n    found = retriever.retrieve(sys.argv[1])\n    print(f\"{name}: {len(found)} returned, {sum(len(n.node.get_content().split()) for n in found)} words\")",
      "note": "Três camadas de nós, de 2.048, 512 e 128 tokens, cada uma filha da de cima. Só as folhas recebem embedding; a árvore inteira vai para o docstore para que um pai possa ser achado a partir dos filhos. A mesma busca roda duas vezes, uma devolvendo folhas e outra deixando o recuperador juntá-las."
    }
  ]
}
```

```
ana@vm:~/rag$ python li_merge.py "On how many devices can I read my e-books?"
146 nodes, 109 of them leaves
leaves: 6 returned, 434 words
merged: 1 returned, 497 words
```

O divisor monta uma árvore: 146 nós, dos quais as 109 folhas de 128 tokens são as que recebem
embedding. A busca devolve seis folhas. O recuperador de auto-merging conta então, para cada pai,
quantos filhos dele voltaram, e **quando mais da metade voltou, devolve o pai no lugar deles**. Ele
repete a contagem um nível acima até nada mudar. Aqui as seis folhas se juntaram nos pais, e os pais
nos deles, até sobrar **um nó de 497 palavras**: o documento inteiro sobre e-books e audiolivros, que
é mais curto que o maior tamanho da árvore, de 2.048 tokens. Seis pedaços de um documento viraram esse
documento, uma vez só e em ordem.

É o pequeno-para-grande decidido na hora da consulta, e não na hora da indexação: uma pergunta que
casa com uma frase de uma seção recebe essa frase, e uma pergunta que casa com a maior parte de uma
seção recebe a seção, ou o documento. A proporção é uma configuração do recuperador, e os três
tamanhos da árvore também.
