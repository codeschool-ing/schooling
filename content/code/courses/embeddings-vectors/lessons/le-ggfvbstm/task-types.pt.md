---
title: Task types e busca assimétrica
version: 1
---

A imagem óbvia da busca é a de dois textos comparados de igual para igual: transforme a pergunta em
vetor, transforme o artigo em vetor, e quanto mais perto os dois vetores, melhor o resultado. Essa
imagem trata os dois lados como o mesmo tipo de texto. **Na busca, eles não são.** A pergunta é
curta, escrita por um cliente, e pergunta; o artigo é longo, escrito pela loja, e explica. *can I
pay in three parts* ("posso pagar em três vezes") e *Payment methods we accept* ("formas de
pagamento que aceitamos") quase não têm palavras em comum e não são paráfrases um do outro. Um é a
resposta do outro.

Um modelo pode ser treinado para essa diferença. Os pares de treino dele são perguntas e os trechos
que as respondem, e no treino ele fica sabendo de que lado do par cada texto está. Um modelo assim
transforma um texto em vetor **de um jeito diferente conforme ele seja uma consulta ou um
documento**, para que uma pergunta caia perto das respostas dela e não perto de outras perguntas
parecidas. Isso se chama busca **assimétrica**, e o `task_type` do Google é como você diz ao modelo
dele de que lado um texto está.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas linhas. Na indexação: cada artigo da central de ajuda vira vetor como documento, com o task type RETRIEVAL_DOCUMENT no Gemini ou o input type search_document no Cohere, e os vetores são guardados. Quando um cliente pergunta: a pergunta can I pay in three parts vira vetor como consulta, com RETRIEVAL_QUERY ou search_query, e é comparada com os vetores guardados para dar os três primeiros. Os dois tipos de vetor caem no mesmo espaço.\"><defs><marker id=\"sidespt-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sidespt-ah1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">na indexação</text><rect x=\"20\" y=\"44\" width=\"190\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"26\" y=\"50\" width=\"190\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"32\" y=\"56\" width=\"190\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"127\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Payment methods we accept</text><path d=\"M222 70 L262 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sidespt-ah0)\"></path><rect x=\"264\" y=\"48\" width=\"210\" height=\"44\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"369\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">RETRIEVAL_DOCUMENT</text><text x=\"369\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">search_document</text><path d=\"M474 70 L528 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sidespt-ah0)\"></path><rect x=\"530\" y=\"52\" width=\"120\" height=\"22\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"538\" y=\"58\" width=\"120\" height=\"22\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"546\" y=\"64\" width=\"120\" height=\"22\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"554\" y=\"70\" width=\"120\" height=\"22\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"614\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">vetores guardados</text><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">quando um cliente pergunta</text><rect x=\"20\" y=\"194\" width=\"190\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">can I pay in three parts</text><path d=\"M210 214 L262 214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sidespt-ah0)\"></path><rect x=\"264\" y=\"192\" width=\"210\" height=\"44\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"369\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">RETRIEVAL_QUERY</text><text x=\"369\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">search_query</text><path d=\"M474 214 L528 214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sidespt-ah0)\"></path><rect x=\"530\" y=\"196\" width=\"90\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">comparar</text><path d=\"M590 124 L590 194\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sidespt-ah1)\"></path><path d=\"M620 214 L642 214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sidespt-ah0)\"></path><rect x=\"644\" y=\"196\" width=\"70\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"679\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">3 primeiros</text><text x=\"700\" y=\"284\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um espaço, dois tipos de texto</text></svg>", "caption": "Os dois lados de uma busca são tipos diferentes de texto, e um modelo treinado para essa diferença recebe a informação de que lado cada texto está. Os rótulos entram nas duas pontas; os vetores ainda se encontram no mesmo espaço. O labembed aceita os rótulos e os ignora.", "same": ["Payment methods we accept", "can I pay in three parts"]}
```

## Os task types que o Google documenta

| `task_type` | use para |
|---|---|
| `RETRIEVAL_DOCUMENT` | os textos que você guarda e busca: artigos, trechos, páginas de produto |
| `RETRIEVAL_QUERY` | a pergunta para a qual se faz uma busca |
| `QUESTION_ANSWERING` | uma consulta quando os documentos são respostas a perguntas |
| `FACT_VERIFICATION` | uma consulta que é uma afirmação, contra documentos que a confirmam ou desmentem |
| `CODE_RETRIEVAL_QUERY` | uma pergunta em palavras, contra código transformado em vetor como documento |
| `SEMANTIC_SIMILARITY` | dois textos do mesmo tipo, comparados entre si |
| `CLASSIFICATION` | textos que vão ser atributos de um classificador, como na aula 4 |
| `CLUSTERING` | textos que vão ser agrupados, sem rótulos |

Os cinco primeiros são os dois lados de uma busca, um tipo de documento e quatro de consulta, e
com eles vem uma regra: **indexe com `RETRIEVAL_DOCUMENT`, busque com um dos tipos de consulta
e nunca indexe com um tipo de consulta.** Os três últimos são simétricos. Todo texto é do mesmo
tipo, então os dois lados recebem o mesmo task type.

O tipo com que um vetor foi feito é parte do que o vetor é, do mesmo jeito que a aula 1 fez do
modelo parte dos dados. Um documento indexado com `SEMANTIC_SIMILARITY` e buscado com
`RETRIEVAL_QUERY` é um descompasso que a API não vai acusar, porque cada chamada, sozinha, era
válida.

## O que o laboratório faz com isso

**Nada, e dá para ver que não faz nada.** Os dois modelos do laboratório são simétricos: nenhum foi
treinado com um lado de consulta e um lado de documento, então eles não têm um segundo jeito de
transformar um texto em vetor. O labembed confere o task type contra a lista do Google, registra e
transforma o texto do mesmo jeito, diga ele o que disser:

```schooling-example
{
  "language": "python",
  "file": "tasks.py",
  "parts": [
    {
      "code": "import os\nimport numpy as np\nfrom google import genai\nfrom google.genai import types\n\nclient = genai.Client(\n    api_key=os.environ[\"GEMINI_API_KEY\"],\n    http_options=types.HttpOptions(base_url=os.environ[\"GEMINI_BASE_URL\"]),\n)\ntext = \"can I pay in three parts\"",
      "note": "O mesmo cliente de `gemini.py`, e uma pergunta de cliente."
    },
    {
      "code": "def as_task(task):\n    r = client.models.embed_content(\n        model=\"lab-minilm\", contents=text,\n        config=types.EmbedContentConfig(task_type=task),\n    )\n    return np.array(r.embeddings[0].values, dtype=np.float32)",
      "note": "Transforma a mesma pergunta em vetor com um task type dado e devolve o vetor como array do NumPy."
    },
    {
      "code": "q = as_task(\"RETRIEVAL_QUERY\")\nfor task in [\"RETRIEVAL_DOCUMENT\", \"SEMANTIC_SIMILARITY\", \"CLASSIFICATION\"]:\n    d = as_task(task)\n    print(f\"{task:20} max difference from RETRIEVAL_QUERY: {np.abs(q - d).max()}\")",
      "note": "A pergunta como consulta, depois com outros três task types, e a maior diferença entre qualquer coordenada dos dois vetores."
    }
  ],
  "output": "ana@lab:~/emb$ python tasks.py\nRETRIEVAL_DOCUMENT   max difference from RETRIEVAL_QUERY: 0.0\nSEMANTIC_SIMILARITY  max difference from RETRIEVAL_QUERY: 0.0\nCLASSIFICATION       max difference from RETRIEVAL_QUERY: 0.0\nana@lab:~/emb$ jq -c '{inputs, task_type}' labembed.jsonl | tail -n 4\n{\"inputs\":1,\"task_type\":\"RETRIEVAL_QUERY\"}\n{\"inputs\":1,\"task_type\":\"RETRIEVAL_DOCUMENT\"}\n{\"inputs\":1,\"task_type\":\"SEMANTIC_SIMILARITY\"}\n{\"inputs\":1,\"task_type\":\"CLASSIFICATION\"}"
}
```

Os quatro vetores de *can I pay in three parts* são idênticos até o último bit, e o log mostra que o
servidor recebeu quatro task types diferentes. O gemini-embedding-001 é documentado como um modelo
que os transforma de jeitos diferentes; quanto, não foi medido aqui, porque nenhuma requisição
chegou ao Google, e nenhum número deste curso ocupa o lugar desse.

A consequência para o código que você escreve é o oposto do comportamento do laboratório. **Passe o
task type em todo lugar, mesmo onde hoje ele não faz diferença.** Um código que indexa com
`RETRIEVAL_DOCUMENT` e busca com `RETRIEVAL_QUERY` está certo contra um modelo simétrico e contra um
assimétrico. Trocar de modelo depois muda então um nome, e não cada ponto de chamada. O tipo inválido
da seção anterior, `SEARCH_QUERY`, é recusado com um 400 pelo mesmo motivo: um tipo que o modelo não
conhece é um erro que vale ouvir já na primeira requisição.
