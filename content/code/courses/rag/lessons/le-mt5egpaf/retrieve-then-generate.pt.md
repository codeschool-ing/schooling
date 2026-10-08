---
title: Recuperar, depois gerar
version: 2
---

**Geração aumentada por recuperação**, RAG na sigla em inglês, é o nome do arranjo a que a seção
anterior chegou: antes de o modelo responder, uma busca encontra os trechos com mais chance de conter a
resposta, e só eles entram no prompt. O modelo é o mesmo. O que muda é que ele lê três páginas
relevantes em vez de nenhuma, ou em vez de todas.

O nome veio de um artigo de 2020 de Lewis e outros, que treinava o buscador e o gerador juntos. Quase
ninguém faz isso hoje. Na prática, "RAG" quer dizer qualquer sistema em que uma busca roda primeiro e
um modelo escreve a partir dos resultados, e é isso que quer dizer neste curso.

## As duas metades

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 330\" role=\"img\" aria-label=\"Duas linhas. Uma vez, e de novo sempre que um documento muda: os documentos são cortados em pedaços, cada pedaço vira um embedding e os vetores são guardados num índice. Toda vez que alguém pergunta: a pergunta vai para a busca, que lê o índice e devolve os pedaços mais próximos; eles entram num prompt junto com a pergunta; o gerador lê o prompt e escreve uma resposta que cita suas fontes.\"><defs><marker id=\"rg-3e47fd\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 5 L0 10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">uma vez, e de novo sempre que um documento muda</text><rect x=\"20\" y=\"44\" width=\"160\" height=\"62\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">documentos</text><text x=\"100.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">regras, termos, manuais</text><path d=\"M180 75 L201 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-3e47fd)\"></path><rect x=\"205\" y=\"44\" width=\"160\" height=\"62\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"285.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">pedaços</text><text x=\"285.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pequenos o bastante</text><path d=\"M365 75 L386 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-3e47fd)\"></path><rect x=\"390\" y=\"44\" width=\"160\" height=\"62\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">embeddings</text><text x=\"470.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um vetor cada</text><path d=\"M550 75 L571 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-3e47fd)\"></path><rect x=\"575\" y=\"44\" width=\"160\" height=\"62\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"655.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">índice</text><text x=\"655.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vetores e texto</text><text x=\"20\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">toda vez que alguém pergunta</text><rect x=\"20\" y=\"170\" width=\"160\" height=\"62\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"193.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">pergunta</text><text x=\"100.0\" y=\"210.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o que foi perguntado</text><path d=\"M180 201 L201 201\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-3e47fd)\"></path><rect x=\"205\" y=\"170\" width=\"160\" height=\"62\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"285.0\" y=\"193.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">busca</text><text x=\"285.0\" y=\"210.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pedaços mais próximos</text><path d=\"M365 201 L386 201\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-3e47fd)\"></path><rect x=\"390\" y=\"170\" width=\"160\" height=\"62\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"193.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">prompt</text><text x=\"470.0\" y=\"210.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fontes + pergunta</text><path d=\"M550 201 L571 201\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-3e47fd)\"></path><rect x=\"575\" y=\"170\" width=\"160\" height=\"62\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"655.0\" y=\"193.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">gerador</text><text x=\"655.0\" y=\"210.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lê, depois escreve</text><path d=\"M655 106 L325 166\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#rg-3e47fd)\"></path><text x=\"470\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a busca lê o índice</text><path d=\"M655 232 L655 270\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-3e47fd)\"></path><rect x=\"370\" y=\"274\" width=\"380\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"560.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">uma resposta que cita suas fontes</text></svg>", "caption": "Recuperar, depois gerar. A linha de cima roda antes de alguém perguntar qualquer coisa; a de baixo roda a cada pergunta, e só os pedaços que a busca devolve chegam ao gerador.", "same": ["embeddings", "prompt"]}
```

A linha de cima é a **indexação**, e acontece antes de alguém perguntar qualquer coisa: os documentos
são cortados em pedaços, cada pedaço vira um vetor por um modelo de embeddings, e os vetores são
guardados com seu texto num índice. Ela roda de novo quando um documento muda, nunca quando chega uma
pergunta.

A linha de baixo é a **consulta**, e acontece a cada pergunta: a pergunta vira embedding com o mesmo
modelo, o índice devolve os pedaços cujos vetores estão mais perto, esses pedaços entram num prompt com
a pergunta, e o gerador escreve a resposta, citando os pedaços pelo número.

O `embeddings-vectors` construiu quase toda a linha de cima e a busca: embeddings, distância, bancos
vetoriais e seus índices. Este curso parte disso e gasta seu tempo com o que aquilo não responde. Como
cortar um documento para que o pedaço certo exista para ser encontrado é a aula 4. O que guardar ao
lado de cada vetor é a aula 5. Como buscar melhor que pelo mais próximo é a aula 6, e como fazer o
gerador usar e citar o que foi encontrado é a aula 7. Se alguma coisa disso funcionou é a aula 8.

## A menor versão que funciona

O `tiny_rag.py` é tudo isso em pouco mais de vinte linhas: seções cortadas nos títulos, embeddings em
memória, as três melhores pela similaridade de cosseno, e um prompt.

```schooling-example
{
  "language": "python",
  "file": "tiny_rag.py",
  "parts": [
    {
      "code": "import glob\nimport re\nimport sys\n\nfrom vectors import embed\nfrom openai import OpenAI",
      "note": "Três importações: `embed`, do `vectors.py` da instalação, e o cliente da OpenAI."
    },
    {
      "code": "# 1. Cut every document into its sections, at each \"## \" heading.\nsections = []\nfor path in sorted(glob.glob(\"data/docs/*.md\")):\n    doc = path.split(\"/\")[-1][:-3]\n    for part in re.split(r\"\\n(?=## )\", open(path).read())[1:]:\n        heading = part.splitlines()[0][3:]\n        sections.append((f\"{doc} > {heading}\", part))",
      "note": "A recuperação precisa de pedaços menores que um documento. O corte mais barato é em cada título `## `, e cada pedaço recebe o nome do documento e do título, para quem lê saber de onde ele veio. A aula 4 trata de fazer isso direito."
    },
    {
      "code": "# 2. Embed them once, and the question every time.\nvectors = embed([text for _, text in sections])\nquestion = sys.argv[1]\nscores = vectors @ embed(question)[0]",
      "note": "Cada seção vira um vetor uma vez só. A pergunta vira um a cada vez que é feita, e um produto de matrizes dá a similaridade de cosseno dela com todas, porque o `embed` devolve vetores de comprimento 1."
    },
    {
      "code": "# 3. Keep the best three.\nbest = scores.argsort()[::-1][:3]\nfor rank, i in enumerate(best, 1):\n    print(f\"[{rank}] {scores[i]:.3f}  {sections[i][0]}\")",
      "note": "As três seções mais parecidas, impressas com suas pontuações para que a escolha fique visível."
    },
    {
      "code": "# 4. Put only those in the prompt, numbered, and ask.\nsources = \"\".join(f\"[{rank}] {sections[i][0]}\\n{sections[i][1]}\\n\" for rank, i in enumerate(best, 1))\nreply = OpenAI().chat.completions.create(\n    model=\"llama3.2:3b\",\n    temperature=0,\n    messages=[\n        {\"role\": \"system\", \"content\": \"Answer from the sources and cite them by number.\"},\n        {\"role\": \"user\", \"content\": f\"{sources}Question: {question}\"},\n    ],\n)\nprint(reply.choices[0].message.content)",
      "note": "Só essas três entram no prompt, numeradas de `[1]` a `[3]`, seguidas da pergunta. O resto do corpus fica de fora."
    }
  ],
  "output": "ana@vm:~/rag$ python tiny_rag.py \"How many days do I have to return a printed book?\"\n[1] 0.810  returns-policy > The return window\n[2] 0.807  returns-policy-2025 > Returning a book\n[3] 0.744  returns-policy > Damaged, faulty and wrong items\nAccording to the provided sources, you have 30 days from delivery to return a printed book.\nana@vm:~/rag$ python tiny_rag.py \"How much is express delivery?\"\n[1] 0.698  shipping-and-delivery > Delivery options and costs\n[2] 0.544  shipping-and-delivery > Addresses\n[3] 0.463  shipping-and-delivery > Parcels that are late or lost\nAccording to [1], the cost of express delivery is 9.90."
}
```

**A pergunta sobre entrega expressa encontrou a seção certa em primeiro lugar**, com similaridade de
0,698 contra 0,544 da seguinte. É a recuperação funcionando: de todas as seções do corpus, a da tabela
de preços veio primeiro, sem que a pergunta precisasse bater palavra por palavra com a seção.

```
ana@vm:~/rag$ cat data/docs/*.md | grep -c "^## "
92
```

Noventa e duas seções, um título cada, e a busca pôs a certa em cima.

As duas respostas estão certas desta vez, e isso também vale ler devagar, por causa do que as deixou
certas.

A pergunta da expressa recebeu o preço, `9.90`, tirado da tabela da seção, com a citação `[1]`. A
pergunta da devolução recebeu trinta dias. **Olhe o que a busca pôs em segundo lugar para ela**: o
*Returning a book* da política de 2025, a regra que foi substituída, com 0,807 contra 0,810. Trata
exatamente do mesmo assunto, então marca quase exatamente o mesmo, e nada no pipeline sabe que uma das
duas está desatualizada. O modelo por acaso tirou a resposta da primeira fonte. Com as duas na ordem
inversa, ou com uma pergunta escrita de um jeito um pouco diferente, nada o teria impedido de tirar os
catorze dias da segunda, e a próxima seção mostra uma pergunta em que é isso que acontece.

O que importa aqui é a forma: **um sistema de recuperação é um buscador e um redator, e cada um pode
falhar enquanto o outro acerta.** Uma resposta certa construída sobre uma busca que também trouxe a
política errada é uma resposta certa por sorte. Separar as duas metades é a maior parte do trabalho
de fazer um bom sistema, e é por isso que a aula 8 mede as duas em separado.
