---
title: Várias cabeças, pelos mesmos pesos
version: 1
---

Uma atenção dá a cada token um conjunto de pesos: um jeito de olhar para o resto da sequência. Um token
muitas vezes precisa de vários ao mesmo tempo. Um verbo pode precisar do seu sujeito, da palavra logo
antes dele e do fim da frase, e uma softmax só tem um total de 1 para dividir entre todos eles. **A
atenção de várias cabeças (*multi-head*) corta as features em grupos e roda uma atenção separada em cada
um.** Com 16 features e 4 cabeças, cada cabeça recebe 4 features da consulta, da chave e do valor,
calcula os seus próprios pesos, e os quatro resultados voltam a ficar lado a lado.

O programa escreve isso por extenso e compara com o `nn.MultiheadAttention`, usando os pesos da própria
camada. Salve como `~/dl/heads.py`:

```schooling-example
{
  "language": "python",
  "file": "heads.py",
  "parts": [
    {
      "code": "\"\"\"heads: four heads of attention written out, against nn.MultiheadAttention with the same weights.\"\"\"\nimport torch\nimport torch.nn as nn\nimport torch.nn.functional as F\n\ntorch.set_printoptions(precision=3, sci_mode=False)\ntorch.set_grad_enabled(False)\ntorch.manual_seed(0)\nd, heads = 16, 4\nmha = nn.MultiheadAttention(d, heads, batch_first=True)\none = nn.MultiheadAttention(d, 1, batch_first=True)\nprint(\"parameters, 4 heads:\", sum(p.numel() for p in mha.parameters()),\n      \" 1 head:\", sum(p.numel() for p in one.parameters()))\nprint(\"in_proj\", tuple(mha.in_proj_weight.shape), \" out_proj\", tuple(mha.out_proj.weight.shape))",
      "note": "Uma camada de quatro cabeças e uma de uma, ambas com largura 16. Nada aqui é treinado, então os gradientes ficam desligados. `in_proj_weight` são as matrizes de consulta, chave e valor empilhadas numa só; `out_proj` mistura as cabeças de volta."
    },
    {
      "code": "def split(t):\n    \"\"\"(batch, time, d) to (batch, head, time, d / heads): each head gets its own slice of the features.\"\"\"\n    return t.view(1, 5, heads, d // heads).transpose(1, 2)",
      "note": "Uma cabeça é uma fatia das features. O `view` corta as 16 em 4 grupos de 4, e o `transpose` põe o eixo das cabeças antes do tempo, para que cada cabeça vire um lote à parte com a sua própria atenção pequena."
    },
    {
      "code": "x = torch.randn(1, 5, d)\nq, k, v = F.linear(x, mha.in_proj_weight, mha.in_proj_bias).chunk(3, dim=-1)\nq, k, v = split(q), split(k), split(v)\nprint(\"q for all heads\", tuple(q.shape))",
      "note": "Cinco tokens pela projeção da própria camada, usando os pesos dela diretamente, e depois divididos nas quatro cabeças."
    },
    {
      "code": "weights = torch.softmax(q @ k.transpose(-2, -1) / (d // heads) ** 0.5, dim=-1)\njoined = (weights @ v).transpose(1, 2).reshape(1, 5, d)\nout = mha.out_proj(joined)",
      "note": "A atenção em todas as cabeças de uma vez, escalada pela raiz quadrada da largura da cabeça, 4, e não da camada. Os quatro resultados voltam a ficar lado a lado, de novo com 16 features, e o `out_proj` os mistura."
    },
    {
      "code": "ref, ref_weights = mha(x, x, x, average_attn_weights=False)\nprint(\"largest difference from nn.MultiheadAttention: output\", f\"{(out - ref).abs().max().item():.1e}\",\n      \" weights\", f\"{(weights - ref_weights).abs().max().item():.1e}\")\nfor h in range(heads):\n    print(f\"head {h}: where token 5 looks\", weights[0, h, 4])",
      "note": "A camada executada normalmente, pedindo os pesos de cada cabeça em separado, contra a versão escrita à mão. Depois, para onde o quinto token olha, cabeça por cabeça."
    }
  ]
}
```

```
ana@vm:~/dl$ python heads.py
parameters, 4 heads: 1088  1 head: 1088
in_proj (48, 16)  out_proj (16, 16)
q for all heads (1, 4, 5, 4)
largest difference from nn.MultiheadAttention: output 0.0e+00  weights 0.0e+00
head 0: where token 5 looks tensor([0.282, 0.175, 0.172, 0.127, 0.245])
head 1: where token 5 looks tensor([0.137, 0.103, 0.529, 0.163, 0.069])
head 2: where token 5 looks tensor([0.136, 0.201, 0.206, 0.248, 0.209])
head 3: where token 5 looks tensor([0.178, 0.105, 0.330, 0.263, 0.123])
```

**Quatro cabeças custam exatamente o que custa uma: 1.088 parâmetros.** As matrizes de consulta, chave e
valor são 16 por 16 de qualquer jeito que se corte, guardadas juntas numa matriz `(48, 16)`, e o
`out_proj` é a quarta, 16 por 16. Quatro matrizes de `d` por `d` e quatro vetores de viés de `d` dão
`4 * 16 * 16 + 4 * 16`, os 1.088 que o programa contou. Cabeças não acrescentam pesos. Elas dividem a
mesma projeção em pedaços independentes, cada um com a sua softmax.

A versão escrita por extenso concorda com a do PyTorch até `0.0e+00`, na saída e nos pesos, porque é a
mesma aritmética na mesma ordem. Cada cabeça escala pela raiz quadrada da sua própria largura, 4, já que
essa é a largura dos vetores que ela multiplica.

**As últimas quatro linhas mostram por que ter cabeças.** O quinto token, olhando a partir da mesma
entrada, põe 0,529 do seu peso no token 3 na cabeça 1, e espalha o peso entre 0,136 e 0,248 na cabeça 2.
Os pesos aqui são aleatórios, então esses padrões ainda não significam nada. Num modelo treinado, significam. Em 2019, Kevin Clark e
colegas leram as cabeças de um BERT treinado: algumas olhavam para o token anterior, outras para o
separador que encerra cada frase, e outras ligavam um verbo ao seu objeto.
