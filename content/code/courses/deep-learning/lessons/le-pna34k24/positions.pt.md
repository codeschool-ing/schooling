---
title: "Posições: a atenção não enxerga ordem"
version: 1
---

É natural supor que a atenção lê uma sequência da esquerda para a direita, como fazia a LSTM da aula
14. **Ela não lê em ordem nenhuma.** Nada em `softmax(Q @ K.T / sqrt(d)) @ V` sabe qual linha é a
primeira: cada token é comparado com todos os outros, e a comparação é a mesma onde quer que os dois
estejam. Embaralhe os tokens e cada um encontra os mesmos outros com as mesmas notas. Salve como
`~/dl/positions.py`:

```schooling-example
{
  "language": "python",
  "file": "positions.py",
  "parts": [
    {
      "code": "\"\"\"positions: attention cannot see order until each token is told where it stands.\"\"\"\nimport math\n\nimport torch\nimport torch.nn as nn\n\ntorch.set_printoptions(precision=3, sci_mode=False)\ntorch.set_grad_enabled(False)\ntorch.manual_seed(0)\nd = 16\nmha = nn.MultiheadAttention(d, 4, batch_first=True)\nx = torch.randn(1, 5, d)\norder = torch.tensor([4, 2, 0, 3, 1])",
      "note": "Uma camada de atenção com 16 features e quatro cabeças, cinco tokens aleatórios e uma ordem para embaralhá-los."
    },
    {
      "code": "def attend(x):\n    return mha(x, x, x)[0]",
      "note": "Autoatenção: os mesmos tokens fornecem as consultas, as chaves e os valores."
    },
    {
      "code": "out, shuffled = attend(x), attend(x[:, order])\nprint(\"shuffle the input, and the output is the same rows shuffled:\", torch.allclose(shuffled, out[:, order], atol=1e-6))",
      "note": "A atenção sobre os tokens como estão e sobre os mesmos tokens embaralhados. Se a atenção enxergasse ordem, a segunda saída seria algo novo."
    },
    {
      "code": "def sinusoids(length, d):\n    \"\"\"The 2017 encoding: sines and cosines whose wavelength grows along the features.\"\"\"\n    pos = torch.arange(length).float()[:, None]\n    rate = torch.exp(-math.log(10000.0) * torch.arange(0, d, 2).float() / d)\n    pe = torch.zeros(length, d)\n    pe[:, 0::2], pe[:, 1::2] = torch.sin(pos * rate), torch.cos(pos * rate)\n    return pe",
      "note": "A codificação do artigo de 2017. Cada par de features é um seno e um cosseno da posição, e cada par gira no seu próprio ritmo, o primeiro mais depressa. Sem parâmetros: é calculada, para qualquer posição."
    },
    {
      "code": "pe = sinusoids(50, d)\nprint(\"positions 0 to 3, first four features\\n\", pe[:4, :4])\nprint(\"similarity of positions 0 and 3:\", round((pe[0] @ pe[3]).item(), 3),\n      \"  10 and 13:\", round((pe[10] @ pe[13]).item(), 3), \"  27 and 30:\", round((pe[27] @ pe[30]).item(), 3))",
      "note": "As primeiras linhas, e o produto escalar de três pares de posições, cada par a três de distância."
    },
    {
      "code": "placed = x + pe[:5]\nout, shuffled = attend(placed), attend(x[:, order] + pe[:5])\nprint(\"with positions added, still the same rows shuffled:\", torch.allclose(shuffled, out[:, order], atol=1e-6))",
      "note": "Cada token recebe o vetor da sua posição somado antes da atenção, e o embaralhamento é tentado de novo. Um token embaralhado agora carrega outra posição."
    },
    {
      "code": "learnt = nn.Embedding(50, d)\nprint(\"learnt positions:\", tuple(learnt.weight.shape))\ntry:\n    learnt(torch.arange(60))\nexcept IndexError as e:\n    print(\"a sequence of 60:\", type(e).__name__, e)",
      "note": "O outro jeito: uma tabela aprendida com uma linha por posição, treinada como qualquer embedding. Ela tem linhas para 50 posições, e uma sequência de 60 pede dez que não existem."
    }
  ]
}
```

```
ana@vm:~/dl$ python positions.py
shuffle the input, and the output is the same rows shuffled: True
positions 0 to 3, first four features
 tensor([[ 0.000,  1.000,  0.000,  1.000],
        [ 0.841,  0.540,  0.311,  0.950],
        [ 0.909, -0.416,  0.591,  0.807],
        [ 0.141, -0.990,  0.813,  0.583]])
similarity of positions 0 and 3: 5.543   10 and 13: 5.543   27 and 30: 5.543
with positions added, still the same rows shuffled: False
learnt positions: (50, 16)
a sequence of 60: IndexError index out of range in self
```

**A primeira linha é o problema.** Embaralhados numa nova ordem, os cinco tokens produziram exatamente
as mesmas cinco saídas, embaralhadas do mesmo jeito. Para a atenção, uma sequência é um conjunto: "o
cachorro mordeu o homem" e "o homem mordeu o cachorro" são as mesmas cinco palavras. Para a tarefa de
lembrar da aula 14 isso é fatal, porque "o primeiro símbolo" é uma posição, e um modelo que não enxerga
posições não tem como saber qual é.

A solução é somar, ao vetor de cada token, **um vetor que depende só de onde o token está.** O artigo de
2017 o calculava com senos e cossenos da posição em ritmos diferentes. A posição 0 começa com
`[0, 1, 0, 1]`, e cada linha seguinte gira cada par de features um pouco mais, o primeiro par mais
depressa. As três similaridades mostram a propriedade útil: as posições 0 e 3, 10 e 13, e 27 e 30 deram
todas 5,543. **O produto escalar de duas posições depende só da distância entre elas**, então "três
tokens atrás" parece igual em qualquer ponto da sequência, e a atenção pode aprendê-lo como uma regra
só.

Com as posições somadas, os tokens embaralhados deixam de dar a saída embaralhada: `False`. Um token
levado para outro lugar agora carrega outra posição, e é um vetor diferente.

O outro jeito é **uma tabela aprendida com uma linha por posição**, um `nn.Embedding` indexado pela
posição em vez do símbolo. O GPT-2 usava uma, com 1.024 linhas. Ela custa parâmetros e tem um limite
rígido: a tabela montada aqui tem 50 linhas, e uma sequência de 60 pediu posições que ela não tem, o que
levantou `IndexError`. Senoides podem ser calculadas para qualquer posição, mas um modelo treinado em
sequências de 50 continua nunca tendo visto como é a posição 60, então nenhuma das duas escolhas faz um
modelo funcionar além do comprimento de treino de graça.

Muitos modelos recentes usam um terceiro tipo, os embeddings de posição rotativos (RoPE), de Jianlin Su e
colegas, de 2021. Eles giram cada consulta e cada chave por um ângulo que cresce com a posição, de modo
que uma nota depende diretamente da distância entre dois tokens. Os modelos Llama o usam. Ele não é montado
nesta aula. O modelo do fim desta aula usa uma tabela aprendida de 50 linhas, já que 50 é a sequência
mais longa que a tarefa de lembrar pede.
