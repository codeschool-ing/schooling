---
title: Escolhendo k
version: 1
---

Um k maior encontra mais respostas e repassa mais texto. Escolher k é escolher um ponto nessa troca,
e as duas metades dela podem ser medidas nas 24 perguntas do próprio curso.

A regra tentadora é *mais é mais seguro*: devolva dez e a certa com certeza está ali. A medida mostra
que isso compra muito pouco depois das primeiras, e custa a mesma quantidade toda vez.

```schooling-example
{
  "language": "python",
  "file": "recall_k.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nimport tiktoken\nfrom minilm import embed\nfrom wordllama import WordLlama\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nids = [h[\"id\"] for h in help]\ntexts = [h[\"title\"] + \". \" + h[\"body\"] for h in help]\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]",
      "note": "Leia os 40 artigos e as 24 perguntas, cada uma com os artigos que o curso decidiu que a respondem."
    },
    {
      "code": "wl = WordLlama.load()\nmodels = {\"minilm\": embed, \"wordllama\": lambda t: wl.embed(t, norm=True)}\nranks = {}\nfor name, f in models.items():\n    S = f([q[\"text\"] for q in queries]) @ f(texts).T\n    ranks[name] = np.argsort(-S, axis=1)",
      "note": "Dê nota a cada pergunta contra cada artigo com os dois modelos e guarde, para cada pergunta, os artigos em ordem da maior nota para a menor."
    },
    {
      "code": "def found(rank, k):\n    return sum(any(ids[j] in q[\"relevant\"] for j in r[:k])\n               for r, q in zip(rank, queries))",
      "note": "Uma pergunta conta como encontrada em `k` quando algum dos artigos certos está entre os `k` primeiros."
    },
    {
      "code": "enc = tiktoken.get_encoding(\"cl100k_base\")\ntokens = np.array([len(enc.encode(t)) for t in texts])\nprint(\" k  minilm  wordllama  tokens\")\nfor k in range(1, 11):\n    t = tokens[ranks[\"minilm\"][:, :k]].sum(axis=1).mean()\n    print(f\"{k:2}  {found(ranks['minilm'], k):3}/24  {found(ranks['wordllama'], k):6}/24  {t:6.0f}\")",
      "note": "A última coluna é o que custaria entregar os `k` primeiros artigos a um modelo de linguagem: os tokens deles em `cl100k_base`, na média das 24 perguntas."
    },
    {
      "code": "for r, q in zip(ranks[\"minilm\"], queries):\n    first = min(list(r).index(ids.index(a)) for a in q[\"relevant\"]) + 1\n    if first > 3:\n        print(f\"minilm puts the answer to {q['text']!r} at {first}\")",
      "note": "E as perguntas que o all-MiniLM-L6-v2 não responde no top 3: onde o primeiro artigo certo de fato caiu."
    }
  ],
  "output": "ana@lab:~/emb$ python recall_k.py\n k  minilm  wordllama  tokens\n 1   19/24      20/24      55\n 2   22/24      23/24     109\n 3   22/24      24/24     162\n 4   23/24      24/24     217\n 5   23/24      24/24     272\n 6   23/24      24/24     326\n 7   23/24      24/24     379\n 8   23/24      24/24     434\n 9   23/24      24/24     488\n10   23/24      24/24     544\nminilm puts the answer to 'send books to another country' at 4\nminilm puts the answer to 'my order came in pieces' at 12"
}
```

As colunas do meio contam as perguntas que têm um artigo certo em algum lugar entre os k primeiros.
A aula 3 chamou a primeira e a terceira linhas de **recall@1** e **recall@3**; esta é a mesma medida
para todo k.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"Um gráfico de linhas de quantas das 24 perguntas encontram um artigo certo entre os k primeiros resultados, para k de 1 a 10. O all-MiniLM-L6-v2 encontra 19 em k=1, 22 em k=2 e 23 de k=4 em diante. O WordLlama encontra 20 em k=1 e 24 de k=3 em diante. As duas linhas ficam planas depois dos primeiros valores de k.\"><path d=\"M90 300 L680 300\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"300\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><path d=\"M90 235 L680 235\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"235\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">18</text><path d=\"M90 170 L680 170\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><path d=\"M90 105 L680 105\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"105\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">22</text><path d=\"M90 40 L680 40\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24</text><path d=\"M90 300 L680 300\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 300 L90 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"90\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"90\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">55</text><text x=\"155.6\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"155.6\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">109</text><text x=\"221.1\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"221.1\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">162</text><text x=\"286.7\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"286.7\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">217</text><text x=\"352.2\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><text x=\"352.2\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">272</text><text x=\"417.8\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><text x=\"417.8\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">326</text><text x=\"483.3\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">7</text><text x=\"483.3\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">379</text><text x=\"548.9\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><text x=\"548.9\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">434</text><text x=\"614.4\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">9</text><text x=\"614.4\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">488</text><text x=\"680\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"680\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">544</text><text x=\"385\" y=\"333\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">k, o número de artigos devolvidos</text><text x=\"90\" y=\"372\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">tokens repassados, top k do all-MiniLM-L6-v2</text><text x=\"20\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">perguntas encontradas (de 24)</text><path d=\"M90.0 170.0 L155.6 72.5 L221.1 40.0 L286.7 40.0 L352.2 40.0 L417.8 40.0 L483.3 40.0 L548.9 40.0 L614.4 40.0 L680.0 40.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><circle cx=\"90\" cy=\"170\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"155.6\" cy=\"72.5\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"221.1\" cy=\"40\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"286.7\" cy=\"40\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"352.2\" cy=\"40\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"417.8\" cy=\"40\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"483.3\" cy=\"40\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"548.9\" cy=\"40\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"614.4\" cy=\"40\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"680\" cy=\"40\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><path d=\"M90.0 202.5 L155.6 105.0 L221.1 105.0 L286.7 72.5 L352.2 72.5 L417.8 72.5 L483.3 72.5 L548.9 72.5 L614.4 72.5 L680.0 72.5\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"90\" cy=\"202.5\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"155.6\" cy=\"105\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"221.1\" cy=\"105\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"286.7\" cy=\"72.5\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"352.2\" cy=\"72.5\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"417.8\" cy=\"72.5\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"483.3\" cy=\"72.5\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"548.9\" cy=\"72.5\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"614.4\" cy=\"72.5\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"680\" cy=\"72.5\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><path d=\"M470 250 L500 250\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"485\" cy=\"250\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"508\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">all-MiniLM-L6-v2</text><path d=\"M470 274 L500 274\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><circle cx=\"485\" cy=\"274\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><text x=\"508\" y=\"274\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">WordLlama</text></svg>", "caption": "Quantas das 24 perguntas encontram um artigo certo nos k primeiros resultados. As duas curvas achatam em poucos passos, enquanto os tokens repassados, na linha abaixo do eixo, continuam crescendo a cada artigo.", "same": ["all-MiniLM-L6-v2", "WordLlama"]}
```

## A curva achata depressa

**O all-MiniLM-L6-v2 encontra 19 de 24 com k = 1, 22 com k = 2, e 23 de k = 4 em diante.** Ir de 4
para 10 não encontra mais nada. O WordLlama chega às 24 com k = 3 e fica lá. As duas curvas fazem
quase toda a subida nos dois ou três primeiros passos.

As duas últimas linhas da saída dizem por que a curva para onde para. *send books to another
country* (mandar livros para outro país) tem a resposta na posição 4, que é o passo de 22 para 23.
*my order came in pieces* (meu pedido veio em pedaços) tem a resposta na posição 12, além de
qualquer k do gráfico. Subir k até 10 não chega lá, e um k grande o bastante para chegar repassaria
doze artigos para cada pergunta para salvar uma. Essa é uma pergunta que o modelo erra, e k é a
ferramenta errada para ela. Um segundo modelo é a certa: o WordLlama tem as 24 com k = 3, e a seção
sobre reranqueamento põe os dois modelos para trabalhar juntos.

**A coluna de custo cresce em linha reta.** Os artigos são curtos, cerca de 55 tokens cada, então o
primeiro artigo custa 55 tokens, três custam 162 e dez custam 544. Cada um desses tokens é lido por
quem vier depois:

- um modelo de linguagem, no curso `rag`, paga por cada token de contexto e lê o ruído com o mesmo
  cuidado que a resposta. Dez artigos onde três bastariam são mais do que o triplo da conta pelas
  mesmas respostas, e sete chances a mais de citar o errado;
- uma pessoa, numa página de resultados, lê os primeiros e para. Uma tela tem espaço para um
  punhado de resultados, e pouca gente chega ao décimo;
- a próxima etapa da busca, como um reranqueador, gasta tempo por candidato.

## Um jeito de escolher

Escolha k pela sua própria curva, não pelo costume. Meça o encontrado-em-k em perguntas de resposta
conhecida, como `recall_k.py` faz, e fique com o menor k depois do qual a curva fica plana. Nesta
central de ajuda isso dá 4 para o all-MiniLM-L6-v2, ou 2 se a única pergunta ganha em k = 4 contar como ruído, e 3
para o WordLlama.

Dois cuidados mantêm esse número honesto. **24 perguntas é uma amostra pequena**: uma pergunta vale
cerca de quatro pontos do total, e o passo de 22 para 23 é uma pergunta. E a curva pertence ao
corpus e ao modelo juntos. Uma central de ajuda com 4.000 artigos tem mais quase-acertos disputando
cada lugar, então a curva dela sobe mais devagar, e a medida precisa ser feita de novo nela.
