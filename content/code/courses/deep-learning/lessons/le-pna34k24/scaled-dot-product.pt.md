---
title: Atenção por produto escalar escalado, à mão
version: 1
---

O artigo de 2017 que apresentou o transformer, "Attention Is All You Need", de Ashish Vaswani e sete colegas, quase todos do Google,
escreve o mecanismo inteiro numa fórmula só:

```
attention(Q, K, V) = softmax(Q @ K.T / sqrt(d)) @ V
```

**Todo token é uma consulta e todo token é uma chave, então todas as buscas da seção anterior acontecem
num único produto de matrizes.** `Q @ K.T` é uma tabela com uma linha por consulta e uma coluna por
chave. A softmax corre ao longo de cada linha, e multiplicar por `V` mistura os valores com os pesos de
cada linha. `d` é a largura de uma consulta. O programa faz isso para quatro tokens, à mão e depois com a
função do PyTorch. Salve como `~/dl/attention.py`:

```schooling-example
{
  "language": "python",
  "file": "attention.py",
  "parts": [
    {
      "code": "\"\"\"attention: scaled dot-product attention by hand on four tokens, then against PyTorch's.\"\"\"\nimport math\n\nimport torch\nimport torch.nn.functional as F\n\ntorch.set_printoptions(precision=3, sci_mode=False)\ntorch.manual_seed(0)\nd = 8\nq, k, v = torch.randn(4, d), torch.randn(4, d), torch.randn(4, d)",
      "note": "Quatro tokens, já projetados: uma consulta, uma chave e um valor de 8 números para cada. Aleatórios, para que nada na aritmética dependa de uma escolha feliz."
    },
    {
      "code": "scores = q @ k.T / math.sqrt(d)\nprint(\"scores, one row per query, one column per key\\n\", scores)\nweights = torch.softmax(scores, dim=-1)\nprint(\"weights, each row sums to 1\\n\", weights)\nout = weights @ v\nprint(\"output\", tuple(out.shape), \" first row\", out[0, :4])",
      "note": "O mecanismo inteiro em três linhas. `q @ k.T` dá nota a toda consulta contra toda chave de uma vez, uma tabela de 4 por 4. A softmax corre ao longo de cada linha, então os pesos de cada token somam 1, e `weights @ v` mistura os valores com eles."
    },
    {
      "code": "ref = F.scaled_dot_product_attention(q[None], k[None], v[None])[0]\nprint(\"largest difference from PyTorch's:\", f\"{(out - ref).abs().max().item():.1e}\")",
      "note": "A função do próprio PyTorch, recebendo os mesmos tensores com um eixo de lote acrescentado na frente. Ela também divide pela raiz quadrada de `d`, por padrão."
    },
    {
      "code": "print(\"\\n   d   spread of q.k   spread / sqrt(d)   largest weight raw   scaled\")\nfor d in (4, 64, 512):\n    q, k = torch.randn(2000, 16, d), torch.randn(2000, 16, d)\n    raw = (q[:, :1] @ k.transpose(1, 2))[:, 0]\n    top_raw = torch.softmax(raw, dim=-1).max(dim=-1).values.mean()\n    top_scaled = torch.softmax(raw / math.sqrt(d), dim=-1).max(dim=-1).values.mean()\n    print(f\"{d:4d}   {raw.std():12.2f}   {raw.std() / math.sqrt(d):16.2f}   {top_raw:18.3f}   {top_scaled:6.3f}\")",
      "note": "Por que a divisão. Para três larguras, 2.000 consultas aleatórias recebem nota contra 16 chaves aleatórias cada. A dispersão das notas cruas, quanto o maior peso leva sem a divisão e quanto leva com ela."
    }
  ]
}
```

```
ana@vm:~/dl$ python attention.py
scores, one row per query, one column per key
 tensor([[-0.005,  1.806, -0.139, -1.336],
        [ 0.164,  0.193, -0.249,  0.338],
        [ 0.488, -2.487, -0.098,  0.802],
        [ 0.239,  1.360, -0.446, -0.815]])
weights, each row sums to 1
 tensor([[0.121, 0.741, 0.106, 0.032],
        [0.258, 0.265, 0.171, 0.307],
        [0.336, 0.017, 0.187, 0.460],
        [0.203, 0.623, 0.102, 0.071]])
output (4, 8)  first row tensor([-1.294, -0.149, -0.370, -0.216])
largest difference from PyTorch's: 1.2e-07
```

Leia as tabelas linha por linha. **A linha 1 é a consulta do primeiro token contra as quatro chaves.** Ela teve nota 1,806 contra a chave 2 e menos de 0,5 contra as outras, então a softmax deu à chave 2 um
peso de 0,741, e a saída do primeiro token é quase toda o valor 2. A linha 2 é quase plana, 0,258,
0,265, 0,171 e 0,307: essa consulta não combina com nenhuma chave muito mais do que com as outras, e a
sua saída fica perto da média simples dos quatro valores. Cada linha da saída é um vetor novo de 8 para
o seu token, montado com os valores de todos os tokens, inclusive o dele.

A versão escrita à mão concorda com a `F.scaled_dot_product_attention` até 1,2e-07, que é arredondamento
de float32. **Para quatro tokens os pesos são uma tabela de 4 por 4; para n tokens, de n por n**, então
uma sequência duas vezes mais longa tem quatro vezes mais pesos a calcular. A aula 16 volta ao que isso
custa quando os tokens são um texto.

```
   d   spread of q.k   spread / sqrt(d)   largest weight raw   scaled
   4           2.01               1.00                0.421    0.234
  64           7.95               0.99                0.844    0.246
 512          22.59               1.00                0.948    0.246
```

**A divisão por √d existe por causa da última tabela.** O produto escalar de dois vetores de `d` números
aleatórios, cada um com dispersão 1, tem dispersão de cerca de √d. O programa mediu 2,01, 7,95 e 22,59
para as larguras 4, 64 e 512, cujas raízes quadradas são 2, 8 e 22,6. Divididas por √d, as dispersões
foram 1,00, 0,99 e 1,00.

Sem a divisão, uma consulta larga produz notas grandes, e notas grandes fazem uma softmax aguda, como a
linha ×20 da seção anterior. Na largura 512, o maior de 16 pesos levou 0,948 em média, **antes de
qualquer treino ter decidido qual chave o merecia.** Um peso tão perto de 1 também devolve muito pouco
gradiente: a inclinação de um peso `w` da softmax em relação à sua própria nota é `w * (1 - w)`, que dá
0,049 em 0,948 contra 0,185 em 0,246. Com a divisão, o maior peso foi 0,246 nas larguras 64 e 512, e
0,234 na largura 4: o ponto de partida deixa de depender da largura do modelo.
