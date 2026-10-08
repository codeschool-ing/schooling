---
title: O pipeline de consulta, com o piso como componente
version: 2
---

A aula 10 precisou de um `if` depois da cadeia para recusar sem chamar o modelo. No Haystack o lugar
natural dessa decisão é um componente próprio, e um componente pode declarar mais de uma saída e
preencher só uma delas a cada execução:

```schooling-example
{
  "language": "python",
  "file": "hs_floor.py",
  "parts": [
    {
      "code": "from answer import REFUSAL\nfrom haystack import Document, component",
      "note": "A frase de recusa é a da aula 7."
    },
    {
      "code": "@component\nclass Floor:\n    \"\"\"Pass on the documents that reach lesson 6's floor, or the refusal if none does.\"\"\"",
      "note": "O `@component` transforma uma classe num componente do Haystack: algo com um método `run` e saídas declaradas."
    },
    {
      "code": "    def __init__(self, floor: float = 0.5):\n        self.floor = floor",
      "note": "O piso é um parâmetro, então entra no arquivo do pipeline junto com o resto."
    },
    {
      "code": "    @component.output_types(documents=list[Document], refusal=str)\n    def run(self, documents: list[Document]):\n        kept = [d for d in documents if d.score >= self.floor]\n        return {\"documents\": kept} if kept else {\"refusal\": REFUSAL}",
      "note": "Duas saídas declaradas, e cada execução preenche só uma delas. Um componente ligado a `documents` só roda quando saem documentos; quando sai a recusa, nada depois roda e o modelo nunca é chamado."
    }
  ]
}
```

O resto do pipeline são peças do próprio Haystack, com o filtro da aula 6 e o prompt da aula 7:

```schooling-example
{
  "language": "python",
  "file": "hs_ask.py",
  "parts": [
    {
      "code": "import sys\n\nfrom answer import SYSTEM\nfrom haystack import Pipeline\nfrom haystack.components.builders import ChatPromptBuilder\nfrom haystack.components.embedders import OpenAITextEmbedder\nfrom haystack.components.generators.chat import OpenAIChatGenerator\nfrom haystack.components.retrievers.in_memory import InMemoryEmbeddingRetriever\nfrom haystack.dataclasses import ChatMessage\nfrom haystack.document_stores.in_memory import InMemoryDocumentStore\nfrom hs_floor import Floor",
      "note": "As instruções da aula 7, e o gerador de embeddings de texto, o recuperador, o montador de prompt e o gerador de chat do Haystack."
    },
    {
      "code": "store = InMemoryDocumentStore.load_from_disk(\"store.json\")\npublic = {\"operator\": \"AND\", \"conditions\": [\n    {\"field\": \"meta.status\", \"operator\": \"==\", \"value\": \"current\"},\n    {\"field\": \"meta.audience\", \"operator\": \"==\", \"value\": \"public\"}]}\nsources = (\"{% for d in documents %}[{{ loop.index }}] {{ d.meta.title }} (updated {{ d.meta.updated }})\\n\"\n           \"{{ d.content }}\\n\\n{% endfor %}Question: {{ question }}\")",
      "note": "O armazenamento que o programa de indexação salvou. O filtro da aula 6 escrito na sintaxe do próprio Haystack, um campo, um operador e um valor. O prompt é um template Jinja que numera as fontes como a aula 7 faz."
    },
    {
      "code": "rag = Pipeline()\nrag.add_component(\"embed\", OpenAITextEmbedder(model=\"all-minilm\"))\nrag.add_component(\"retrieve\", InMemoryEmbeddingRetriever(store, top_k=3, filters=public))\nrag.add_component(\"floor\", Floor(0.5))\nrag.add_component(\"prompt\", ChatPromptBuilder(template=[ChatMessage.from_system(SYSTEM),\n                                                        ChatMessage.from_user(sources)],\n                                              required_variables=[\"documents\", \"question\"]))\nrag.add_component(\"generate\", OpenAIChatGenerator(model=\"llama3.2:3b\", generation_kwargs={\"temperature\": 0}))\nrag.connect(\"embed.embedding\", \"retrieve.query_embedding\")\nrag.connect(\"retrieve\", \"floor\")\nrag.connect(\"floor.documents\", \"prompt.documents\")\nrag.connect(\"prompt\", \"generate\")",
      "note": "Cinco componentes e quatro ligações. Só o `floor.documents` chega ao prompt, então o caminho da recusa termina no piso."
    },
    {
      "code": "if __name__ == \"__main__\":\n    question = sys.argv[1]\n    out = rag.run({\"embed\": {\"text\": question}, \"prompt\": {\"question\": question}},\n                  include_outputs_from={\"retrieve\"})\n    print(out[\"generate\"][\"replies\"][0].text if \"generate\" in out else out[\"floor\"][\"refusal\"])\n    for d in out[\"retrieve\"][\"documents\"]:\n        print(f\"  {d.score:.3f}  {d.meta['id']}\")",
      "note": "A pergunta entra duas vezes, para virar embedding e para ser escrita no prompt. O `include_outputs_from` guarda o que o recuperador devolveu, para que as notas possam ser impressas mesmo quando o modelo não é chamado."
    }
  ]
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O pipeline de consulta como um grafo: embed, retrieve, floor, prompt e generate, ligados da esquerda para a direita. A pergunta entra duas vezes, em embed e em prompt. Do floor, documents segue para prompt, e a recusa sai para baixo sem chegar ao modelo; generate produz a resposta.\"><defs><marker id=\"rg-73a4bd\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 5 L0 10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"26\" y=\"130\" width=\"104\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"78.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">embed</text><rect x=\"160\" y=\"130\" width=\"104\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"212.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">retrieve</text><rect x=\"294\" y=\"130\" width=\"104\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"346.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">floor</text><rect x=\"428\" y=\"130\" width=\"104\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">prompt</text><rect x=\"562\" y=\"130\" width=\"104\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"614.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">generate</text><path d=\"M130 153.0 L158 153.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-73a4bd)\"></path><path d=\"M264 153.0 L292 153.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-73a4bd)\"></path><path d=\"M398 153.0 L426 153.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-73a4bd)\"></path><path d=\"M532 153.0 L560 153.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-73a4bd)\"></path><text x=\"26\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">a pergunta</text><path d=\"M78.0 58 L480.0 58\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M78.0 58 L78.0 128\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-73a4bd)\"></path><path d=\"M480.0 58 L480.0 128\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-73a4bd)\"></path><path d=\"M346.0 176 L346.0 236\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-73a4bd)\"></path><text x=\"356.0\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a recusa, sem chamar o modelo</text><text x=\"356.0\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">refusal</text><text x=\"413.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">documents</text><path d=\"M614.0 176 L614.0 236\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-73a4bd)\"></path><text x=\"614.0\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a resposta</text></svg>", "caption": "O hs_ask.py como o Haystack o guarda: cinco componentes com nome e as ligações entre eles. O piso tem duas saídas, e uma execução preenche uma; quando é a recusa, prompt e generate nunca rodam."}
```

O filtro é escrito na sintaxe do Haystack, e não no dicionário do LangChain: uma lista de condições,
cada uma com um campo, um operador e um valor, unidas por `AND`. As notas aqui são **similaridades, em
que maior é melhor**, como as da aula 6 e ao contrário das distâncias do `PGVector` na aula 10. O
armazenamento calcula um produto escalar por padrão, que é igual à similaridade de cosseno para
vetores de comprimento 1, e o Ollama devolve os vetores do
all-minilm com comprimento 1.

```
ana@vm:~/rag$ python hs_ask.py "How many days do I have to return a printed book?"
According to sources [1] and [2], you have 30 days from delivery to return a printed book in the condition you received it.

However, source [3] states that you have 7 days from delivery to withdraw from a purchase without giving a reason, as the consumer protection law guarantees. This period is extended to 30 days for printed books by our returns and refunds policy, as stated in sources [1] and [2]. 

Since source [3] is outdated (updated 2026-01-05) and source [1] and [2] are more recent (updated 2026-02-02), we prefer the more recent sources. Therefore, you have 30 days from delivery to return a printed book.
  0.787  returns-policy
  0.787  returns-policy
  0.733  terms-of-sale
```

A resposta está certa, 30 dias da política atual, e carrega a duplicata da seção anterior. **As duas
primeiras fontes são o mesmo pedaço com a mesma nota, 0,787**: a cópia com o dono antigo e a cópia
com o novo, as duas atuais, as duas públicas, e as duas devolvidas. O modelo citou a frase às duas,
*sources [1] and [2]*, e um dos três lugares do prompt foi gasto com uma frase que ele já tinha. A
aula 12 conta quanto custa esse tipo de desperdício, e o elimina.

A terceira fonte são os termos de venda, e o modelo tirou deles algo que nenhuma fonte diz. Chamou-os
de *outdated* porque a data deles é anterior, que é a instrução da aula 7 aplicada onde ela não cabe:
os termos estão em vigor, e os sete dias deles são o mínimo legal que a política estende para trinta.
O número sobreviveu ao raciocínio, desta vez.

```
ana@vm:~/rag$ python hs_ask.py "Can I pay with cryptocurrency?"
I could not find that in our documents.
  0.306  payments-and-invoices
  0.243  terms-of-sale
  0.234  gift-cards
```

A melhor fonte teve 0,306, abaixo do piso, então o componente do piso mandou a recusa e o montador de
prompt e o gerador nunca rodaram. As três notas são impressas da saída do recuperador, que a execução
foi instruída a guardar com `include_outputs_from`; sem isso, a execução de um pipeline devolve só as
saídas que nenhum outro componente consumiu.
