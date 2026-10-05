---
title: Benchmarks, e os seus próprios dados
version: 1
---

Um leaderboard responde *qual modelo vai bem, em média, em muitas tarefas que não são as suas*. A
pergunta que você tem é mais estreita: **qual modelo acha o artigo certo para as perguntas dos seus
clientes.** O único jeito de respondê-la é a medida que este curso vem rodando desde a aula 3, nas
24 perguntas que o curso anotou com os artigos que as respondem.

Aqui estão os dois modelos que o laboratório roda, lado a lado, com as perguntas que cada um errou
na posição 1:

```schooling-example
{
  "language": "python",
  "file": "bench.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\nfrom wordllama import WordLlama\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]\nids = [h[\"id\"] for h in help]\ndocs = [h[\"title\"] + \". \" + h[\"body\"] for h in help]\nwl = WordLlama.load()",
      "note": "Os artigos como título e corpo, as 24 perguntas e o WordLlama carregado ao lado do MiniLM."
    },
    {
      "code": "models = {\n    \"all-MiniLM-L6-v2\": embed,\n    \"WordLlama\": lambda texts: wl.embed(texts, norm=True),\n}",
      "note": "Cada modelo como uma função que leva uma lista de textos a vetores de comprimento 1."
    },
    {
      "code": "for name, f in models.items():\n    D, Q = f(docs), f([q[\"text\"] for q in queries])\n    top = np.argsort(-(Q @ D.T), axis=1)[:, :3]\n    first = [ids[t[0]] in q[\"relevant\"] for t, q in zip(top, queries)]\n    three = [any(ids[j] in q[\"relevant\"] for j in t) for t, q in zip(top, queries)]\n    wrong = [q[\"id\"] for q, ok in zip(queries, first) if not ok]\n    print(f\"{name:17} top 1: {sum(first)}/24  top 3: {sum(three)}/24  wrong at 1: {' '.join(wrong)}\")",
      "note": "Para cada modelo: transforme os dois lados em vetores, ordene os artigos para cada pergunta e conte as perguntas com um artigo relevante em primeiro e entre os 3 primeiros. Liste as erradas na posição 1."
    }
  ],
  "output": "ana@lab:~/emb$ python bench.py\nall-MiniLM-L6-v2  top 1: 19/24  top 3: 22/24  wrong at 1: q01 q08 q17 q19 q21\nWordLlama         top 1: 20/24  top 3: 24/24  wrong at 1: q02 q11 q13 q23"
}
```

## O que isso mostra

**O WordLlama pôs um artigo relevante em primeiro para 20 das 24 perguntas e entre os 3 primeiros
para todas as 24. O all-MiniLM-L6-v2 chegou a 19 e 22.** Nestas perguntas, o modelo estático, sem
transformer nenhum, foi pelo menos tão bem quanto o contextual. É um resultado real, e surpreendente
para quem tem na cabeça a imagem de que o maior e mais sofisticado sempre ganha.

## O que isso não mostra

Leia a última coluna antes da primeira. **Os dois modelos erraram perguntas diferentes.** O MiniLM
errou q01, q08, q17, q19 e q21; o WordLlama errou q02, q11, q13 e q23; nenhuma pergunta está nas
duas listas. Então a diferença de uma na posição 1 não é um modelo sendo melhor na mesma coisa. São
dois modelos com pontos cegos diferentes, e quatro ou cinco perguntas decidindo o placar.

Três limites decorrem disso, e cada um é um motivo para não generalizar:

- 24 perguntas é pouco. Uma pergunta vale uns quatro pontos do placar, e duas perguntas reescritas
  poderiam inverter a ordem na posição 1.
- Um domínio só. A central de ajuda de uma livraria tem artigos curtos, escritos de forma simples e
  num registro só. A aula 1 mostrou o WordLlama avaliando *the dog bit the man* ("o cachorro mordeu
  o homem") e *the man bit the dog* como o mesmo texto, e um corpus em que a ordem das palavras
  importa poderia inverter o resultado.
- Os artigos são curtos. Nenhum passa de 102 pedaços, então o limite do MiniLM nunca entrou em jogo,
  nem qualquer vantagem que um modelo contextual tenha em textos longos.

Então o resultado não é *o WordLlama é o melhor modelo*. É **nesta central de ajuda, com estas
perguntas, o modelo mais barato é bom o bastante**, e é nesse tipo de afirmação que a
escolha de um modelo deve se apoiar. A aula 10 acrescenta o lado do custo, e a próxima seção mede a
velocidade que faz isso importar.

## Montando o seu próprio conjunto

Vinte e quatro perguntas são um começo. O conjunto útil cresce com o uso real: as perguntas que os
clientes digitaram e que não acharam nada útil, cada uma anotada com o artigo que deveria tê-la
respondido. **Guarde o conjunto junto do código, rode-o sempre que o modelo, a divisão em trechos ou
o texto mudarem**, e compare modelos nele antes de compará-los em qualquer outra coisa. A aula 16
usa a mesma medida para escolher quantos resultados devolver.
