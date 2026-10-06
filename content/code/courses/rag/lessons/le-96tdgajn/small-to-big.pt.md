---
title: Buscar pequeno, devolver grande
version: 1
---

A tabela da seção anterior mostrou a tensão numa linha: pedaços pequenos são precisos para buscar e
perdem o contexto, pedaços grandes guardam o contexto e são vagos para buscar. A **recuperação do
pequeno para o grande** se recusa a escolher. Ela indexa unidades pequenas, para a busca ser precisa, e
devolve a unidade maior de onde cada uma veio, para o prompt ter o contexto.

O `small_to_big.py` indexa cada frase de cada seção separadamente, e lembra a que seção cada frase
pertence. Uma pergunta é comparada com as frases; as seções das frases que melhor combinam, três
diferentes, vão para o prompt:

```schooling-example
{
  "language": "python",
  "file": "small_to_big.py",
  "parts": [
    {
      "code": "import json\n\nimport tiktoken\nfrom chunking import load, sections, sentences\nfrom minilm import embed\n\nenc = tiktoken.get_encoding(\"cl100k_base\")\nquestions = [q for q in map(json.loads, open(\"data/eval.jsonl\")) if q[\"facts\"]]\nnorm = lambda t: \" \".join(t.split())",
      "note": "As 26 perguntas com resposta do conjunto de teste, e a codificação que conta os tokens do prompt."
    },
    {
      "code": "# Index sentences, but remember which section each came from.\nparents, small = [], []\nfor _, body in load().values():\n    for path, text in sections(body):\n        parents.append(text)\n        small += [(s, len(parents) - 1) for s in sentences(text)]\nv = embed([s for s, _ in small])",
      "note": "Cada seção é um pai, guardado inteiro. Cada frase dela vira uma unidade pequena, guardada com o número do pai, e só as unidades pequenas viram embedding."
    },
    {
      "code": "found, tokens = 0, 0\nfor q in questions:\n    scores = v @ embed(q[\"question\"])[0]\n    keep = []\n    for i in scores.argsort()[::-1]:\n        if small[i][1] not in keep:\n            keep.append(small[i][1])\n        if len(keep) == 3:\n            break\n    context = [parents[p] for p in keep]\n    found += any(f in norm(t) for t in context for f in q[\"facts\"])\n    tokens += len(enc.encode(\"\\n\".join(context)))\nprint(f\"sentences indexed: {len(small)}, sections returned: 3 per question\")\nprint(f\"found: {found}/{len(questions)}  tokens: {tokens / len(questions):.0f}\")",
      "note": "As frases são ordenadas contra a pergunta, e seus pais recolhidos nessa ordem até haver três diferentes. Essas três seções são o contexto."
    }
  ]
}
```

```
ana@lab:~/rag$ python small_to_big.py
sentences indexed: 319, sections returned: 3 per question
found: 24/26  tokens: 272
```

**24 de 26 achadas, por 272 tokens por pergunta.** É uma a menos que buscar seções inteiras, por um
pouco mais de tokens. Neste corpus o pequeno-para-grande não venceu a busca simples por seções, e o
motivo está no material: as seções da Marginalia são curtas e tratam de uma coisa cada, então o vetor
de uma seção já é preciso. A abordagem vale a pena em documentos com seções longas que cobrem várias
coisas, onde o vetor de uma seção é a média de todas elas e uma frase é um alvo muito mais nítido.

## Variações da ideia

O pai não precisa ser uma seção. Escolhas comuns:

- **da frase para a janela**: devolver a frase que combinou com duas ou três frases de cada lado, uma
  janela de contexto cortada em volta do acerto em vez de um pai fixo;
- **do pedaço para a seção**: indexar pedaços estruturados de 60 palavras, devolver a seção a que
  pertencem;
- **do pedaço para o documento**: para documentos curtos, devolver o documento inteiro. Os artigos da
  central de ajuda têm quarenta palavras cada, e devolver o artigo inteiro é devolver o pedaço.

O LlamaIndex chama a primeira de *sentence window* e a segunda de *auto-merging*; a aula 10 encontra os
dois nomes.

## O que custa

Unidades pequenas querem dizer muitos vetores: 319 frases contra 92 seções, três vezes e meia o índice.
E o pai tem de ser guardado e consultado, então o índice precisa de uma coluna dizendo a que pai cada
unidade pertence, que a aula 5 fornece com o caminho de títulos. O contexto devolvido também tem
tamanho menos previsível, porque um pai tem o tamanho que tem; uma seção de 300 palavras volta inteira
por menor que seja a frase que combinou.

## A decisão de corte, resumida

Para documentos com boa estrutura, corte por ela: seções, e parágrafos juntados dentro delas, com o
caminho de títulos guardado ao lado de cada pedaço. Meça dois ou três tamanhos contra o seu próprio
conjunto de teste e escolha aquele em que a contagem de achadas para de subir. Para texto sem
estrutura, pedaços de tamanho fixo com 10 a 20 por cento de sobreposição, ou cortes semânticos com
limite de tamanho. Recorra ao pequeno-para-grande quando as seções forem longas e misturadas. E seja
qual for a escolha, guarde os números que a justificaram, porque o corpus vai mudar e a escolha vai
precisar ser feita de novo.
