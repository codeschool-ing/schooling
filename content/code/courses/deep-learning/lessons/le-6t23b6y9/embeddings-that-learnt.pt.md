---
title: Embeddings que aprenderam alguma coisa
version: 1
---

Ninguém diz a um modelo que Monday e Friday são dias. **Ele recebe uma tarefa, adivinhar um token que
falta a partir dos tokens em volta.** A tabela de embeddings é ajustada por backpropagation como
qualquer outro peso. Tokens que vivem aparecendo na mesma companhia acabam com linhas parecidas,
porque linhas parecidas são o jeito mais barato de fazer os mesmos palpites sobre eles. Essa ideia, de
que uma palavra se conhece pelas palavras em volta dela, é mais antiga que as redes neurais; o word2vec
a tornou famosa em 2013.

O modelo abaixo é tão pequeno quanto essa ideia permite: uma tabela de embeddings de 500 linhas de 8,
uma média, e uma camada linear que dá nota aos 500 tokens. Salve-o como `~/dl/near.py`, ao lado do
`corpus.txt` e do `tok.json`:

```schooling-example
{
  "language": "python",
  "file": "near.py",
  "parts": [
    {
      "code": "\"\"\"near: a small model learns a vector per token from the corpus, and the neighbours that come out.\"\"\"\nfrom collections import Counter\n\nimport torch\nimport torch.nn as nn\nimport torch.nn.functional as F\nfrom tokenizers import Tokenizer\n\ntok = Tokenizer.from_file(\"tok.json\")\nids = tok.encode(open(\"corpus.txt\").read()).ids\nV, DIM, WINDOW = tok.get_vocab_size(), 8, 2\nx = torch.tensor([ids[i - WINDOW:i] + ids[i + 1:i + WINDOW + 1] for i in range(WINDOW, len(ids) - WINDOW)])\ny = torch.tensor(ids[WINDOW:len(ids) - WINDOW])\nprint(\"examples:\", len(y), \" context:\", tuple(x.shape))",
      "note": "Cada token, com os dois de cada lado como contexto. A tarefa do modelo é adivinhar o token do meio a partir desses quatro."
    },
    {
      "code": "class Guess(nn.Module):\n    def __init__(self):\n        super().__init__()\n        self.emb = nn.Embedding(V, DIM)\n        self.out = nn.Linear(DIM, V)\n\n    def forward(self, context):\n        return self.out(self.emb(context).mean(dim=1))",
      "note": "Consulta os quatro vetores do contexto, tira a média e dá uma nota a cada token do vocabulário com uma camada linear. A média joga a ordem fora de propósito: este modelo só aprende quais tokens andam juntos."
    },
    {
      "code": "seen = Counter(ids)\npieces = [tok.decode([i]) for i in range(V)]\nwords = [i for i, p in enumerate(pieces) if seen[i] >= 3 and p[:1] == \" \" and p[1:].isalpha() and len(p) > 3]",
      "note": "Os candidatos a vizinho: palavras inteiras, com o espaço da frente, vistas pelo menos três vezes. Sem isso, fragmentos e bytes que ninguém escreveu lotariam a lista."
    },
    {
      "code": "def nearest(model, word, k=3):\n    table = F.normalize(model.emb.weight.detach()[words], dim=1)\n    q = words.index(tok.encode(word).ids[0])\n    sims = table @ table[q]\n    sims[q] = -1\n    best = sims.topk(k)\n    return \"  \".join(f\"{pieces[words[j]].strip()} {s:.2f}\"\n                     for s, j in zip(best.values.tolist(), best.indices.tolist()))",
      "note": "Similaridade de cosseno: os dois vetores levados a comprimento 1, depois um produto escalar. 1 é a mesma direção e 0 é sem relação. A própria palavra fica de fora."
    },
    {
      "code": "QUERIES = [\" Monday\", \" baker\", \" pears\", \" red\", \" goat\"]\ntorch.manual_seed(0)\nmodel = Guess()\nprint(\"candidates:\", len(words))\nfor w in QUERIES:\n    print(f\"untrained {w.strip():7s}\", nearest(model, w))",
      "note": "Os vizinhos antes de qualquer treino, a partir de vetores aleatórios. É a referência que os treinados precisam superar."
    },
    {
      "code": "opt = torch.optim.Adam(model.parameters(), lr=0.01)\nfor epoch in range(1, 301):\n    loss = F.cross_entropy(model(x), y)\n    opt.zero_grad()\n    loss.backward()\n    opt.step()\n    if epoch % 100 == 0:\n        print(f\"epoch {epoch}: loss {loss.item():.3f}\")\nfor w in QUERIES:\n    print(f\"trained   {w.strip():7s}\", nearest(model, w))",
      "note": "Treino com o lote inteiro: todos os exemplos em cada passo, com o Adam da aula 5. Depois, as mesmas cinco perguntas de novo."
    }
  ]
}
```

```
PENDING near
```

Os 998 exemplos são os tokens do corpus menos os dois de cada ponta, e cada um tem quatro tokens de
contexto. Dos 500 tokens, 57 servem de candidatos: palavras inteiras vistas pelo menos três vezes.

## Antes: uma referência, não uma descoberta

**Leia primeiro o bloco sem treino, porque ele é a cara de um cosseno quando não quer dizer nada.**
` baker` fica a 0,89 de ` rains`, e ` Monday` a 0,82 de ` said`. Em oito dimensões, dois vetores
aleatórios caem perto um do outro com frequência suficiente para que o melhor de 56 quase sempre pareça
um acerto. Um número de similaridade sozinho não prova nada; ele precisa superar o que o acaso dá no
mesmo tamanho.

## Depois de 300 épocas

Cada época é um passo, com o corpus inteiro como lote. A perda cai de 3,270 na época 100 para 1,353
na época 300, e os vizinhos mudam:

| consulta | mais perto depois do treino | o padrão |
| --- | --- | --- |
| Monday | Saturday 0,81, Friday 0,79 | dias de feira |
| baker | potter 0,95, miller 0,94 | os ofícios |
| goat | dog 0,91, cat 0,88 | os animais |
| pears | sleeps 0,80, plums 0,76, cherries 0,70 | frutas, com um intruso na frente |
| red | all 0,86, sheep 0,83 | nada |

**Quatro das cinco saíram como categorias que o corpus nunca nomeou.** O modelo as achou porque essas
palavras ocupam as mesmas vagas: `On ___ the`, `the ___ sells`, `The ___ eats`. Os ofícios são os mais
nítidos, porque o corpus os cita mais: `baker` quinze vezes. `pears` achou duas outras frutas, atrás de
uma palavra que não tem nada a ver com fruta.

`red` falhou, e o corpus diz por quê. **Ela aparece três vezes, em três molduras diferentes**:
`apples are red,`, `cherries are red,` e `the wheel red.`. `Monday` aparece cinco vezes, quatro delas
logo depois de `on`, a vaga que todo outro dia da semana ocupa. Três exemplos que discordam sobre a
companhia de uma palavra não bastam para a linha dela assentar em lugar nenhum. A tabela de um modelo
de linguagem é treinada do mesmo jeito em bilhões de tokens, e essa é toda a diferença entre estes
vizinhos e os que um modelo de verdade dá.

Este modelo não serve para mais nada. Os palpites dele são só o pretexto: a tabela é o que se queria, e
um modelo de linguagem ganha a tabela dele como subproduto do mesmo tipo de palpite.
