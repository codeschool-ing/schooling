---
title: Sentence windows and auto-merging
version: 2
---

Lesson 4 ended on a tension it could not resolve with one size: a small chunk matches a question
precisely and carries too little to answer it, a large chunk carries the answer and matches
vaguely. Its answer was **small-to-big**, search small pieces and send the larger piece each came
from. LlamaIndex has two ready-made versions of the idea, and they are the parts of it most worth
borrowing.

## The sentence window

```schooling-example
{
  "language": "python",
  "file": "li_window.py",
  "parts": [
    {
      "code": "import sys\n\nfrom li_setup import docs\nfrom llama_index.core import VectorStoreIndex\nfrom llama_index.core.node_parser import SentenceWindowNodeParser",
      "note": "The documents and clients from `li_setup.py`."
    },
    {
      "code": "nodes = SentenceWindowNodeParser.from_defaults(window_size=3).get_nodes_from_documents(docs)\nhit = VectorStoreIndex(nodes).as_retriever(similarity_top_k=1).retrieve(sys.argv[1])[0]\nprint(len(nodes), \"sentences indexed\")\nprint(\"matched:\", hit.node.get_content().strip())\nprint(\"window: \", \" \".join(hit.node.metadata[\"window\"].split()))",
      "note": "One node per sentence, each carrying the three sentences on either side in its metadata under `window`. The search compares the question with the sentence; the window is what would be sent to the model."
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

The sentence that matched, "Express delivery is not free at any order value", **is about express
delivery and does not hold its price**. The price, 9.90, is in the table three sentences earlier.
Searched alone, sentences match questions well and lose the facts around them; this is the row of
the next section's table where sentences alone find 21 of 26. The window puts the neighbours back.
A post-processor, `MetadataReplacementPostProcessor`, swaps each retrieved sentence for its window
before the prompt is built, so the search is precise and the model reads the paragraph.

The window has a cost the output shows. It is **counted in sentences, not bounded by the
document's structure**: this one starts inside the front matter and runs past the next heading.
Lesson 4's structured chunks never cross a heading, because the sections of a policy are where its
subjects change. Here a window can carry the end of one subject into the start of another.

## Auto-merging

```schooling-example
{
  "language": "python",
  "file": "li_merge.py",
  "parts": [
    {
      "code": "import sys\n\nfrom li_setup import docs\nfrom llama_index.core import StorageContext, VectorStoreIndex\nfrom llama_index.core.node_parser import HierarchicalNodeParser, get_leaf_nodes\nfrom llama_index.core.retrievers import AutoMergingRetriever",
      "note": "The documents and clients from `li_setup.py`."
    },
    {
      "code": "nodes = HierarchicalNodeParser.from_defaults().get_nodes_from_documents(docs)\nleaves = get_leaf_nodes(nodes)\nstorage = StorageContext.from_defaults()\nstorage.docstore.add_documents(nodes)\nindex = VectorStoreIndex(leaves, storage_context=storage)\nprint(len(nodes), \"nodes,\", len(leaves), \"of them leaves\")\nfor name, retriever in ((\"leaves\", index.as_retriever(similarity_top_k=6)),\n                        (\"merged\", AutoMergingRetriever(index.as_retriever(similarity_top_k=6), storage))):\n    found = retriever.retrieve(sys.argv[1])\n    print(f\"{name}: {len(found)} returned, {sum(len(n.node.get_content().split()) for n in found)} words\")",
      "note": "Three layers of nodes, of 2,048, 512 and 128 tokens, each a child of the one above. Only the leaves are embedded; the whole tree goes into the docstore so that a parent can be found from its children. The same search runs twice, once returning leaves and once letting the retriever merge them."
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

The parser builds a tree: 146 nodes, of which the 109 leaves of 128 tokens are what gets embedded.
The search returns six leaves. The auto-merging retriever then counts, for each parent, how many of
its children were returned, and **when more than half of them were, it returns the parent instead**.
It repeats the count one level up until nothing changes. Here the six leaves merged into their
parents, and the parents into theirs, until **one node of 497 words** was left: the whole document
on e-books and audiobooks, which is shorter than the tree's largest size of 2,048 tokens. Six pieces
of one document became that document, once and in order.

That is small-to-big decided at query time rather than at indexing time: a question that matches
one sentence of a section gets that sentence, and a question that matches most of a section gets
the section, or the document. The ratio is a setting of the retriever, and so are the
three sizes of the tree.
