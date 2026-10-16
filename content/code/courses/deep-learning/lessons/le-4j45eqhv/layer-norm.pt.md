---
title: Normalização por camada, no outro eixo
version: 1
---

A normalização por camada costuma ser descrita como batch norm para lotes pequenos. **Ela fica mais
clara vista como a mesma aritmética no outro eixo.** O batch norm pega um atributo e o normaliza
através dos exemplos de um lote. O layer norm pega um exemplo e o normaliza através dos próprios
atributos. A média e a variância que ele usa saem de uma única linha, então as outras linhas nunca
entram.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 290\" role=\"img\" aria-label=\"Duas cópias de um lote desenhado como grade, quatro exemplos em linhas por seis atributos em colunas. À esquerda, batch norm: uma coluna destacada, ou seja, cada atributo é normalizado com estatísticas tiradas coluna abaixo, através dos exemplos. À direita, layer norm: uma linha destacada, ou seja, cada exemplo é normalizado com estatísticas tiradas ao longo da própria linha, através dos atributos.\"><text x=\"192\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" fill=\"var(--paper)\" font-weight=\"600\">batch norm</text><text x=\"192\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">atributos →</text><text x=\"76\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">exemplos</text><rect x=\"84\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"120\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"156\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"192\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"228\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"264\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"84\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"120\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"156\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"192\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"228\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"264\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"84\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"120\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"156\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"192\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"228\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"264\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"84\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"120\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"156\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"192\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"228\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"264\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"192\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">uma média e variância por atributo,</text><text x=\"192\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">sobre o lote</text><text x=\"508\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" fill=\"var(--paper)\" font-weight=\"600\">layer norm</text><text x=\"508\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">atributos →</text><text x=\"392\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">exemplos</text><rect x=\"400\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"436\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"472\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"508\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"544\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"580\" y=\"70\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"400\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"436\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"472\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"508\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"544\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"580\" y=\"100\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"400\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"436\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"472\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"508\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"544\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"580\" y=\"130\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"400\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"436\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"472\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"508\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"544\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"580\" y=\"160\" width=\"36\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"508\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">uma média e variância por exemplo,</text><text x=\"508\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">sobre os atributos</text></svg>", "caption": "A mesma aritmética nos dois eixos de um lote. O batch norm precisa dos outros exemplos; o layer norm só precisa daquele que tem à frente.", "same": ["batch norm", "layer norm"]}
```

Jimmy Ba, Jamie Kiros e Geoffrey Hinton a propuseram em 2016. A classe é o batch norm com o eixo
virado, e sem as partes que só existiam por causa do lote. Salve como `~/dl/layernorm.py`:

```schooling-example
{
  "language": "python",
  "file": "layernorm.py",
  "parts": [
    {
      "code": "\"\"\"layernorm: layer normalisation, the same arithmetic along the other axis.\"\"\"\nimport numpy as np\n\n\nclass LayerNorm:\n    \"\"\"Each example to mean 0 and variance 1 over its own features, then gamma and beta.\"\"\"\n    params = (\"gamma\", \"beta\")\n\n    def __init__(self, n, eps=1e-5):\n        self.gamma = np.ones(n, dtype=np.float32)\n        self.beta = np.zeros(n, dtype=np.float32)\n        self.dgamma = np.zeros_like(self.gamma)\n        self.dbeta = np.zeros_like(self.beta)\n        self.eps = eps",
      "note": "Os mesmos `gamma` e `beta`, um por atributo. O que falta é a questão: nada de estatísticas acumuladas, nada de momentum e nenhuma flag `training`, porque nada aqui depende do lote."
    },
    {
      "code": "    def forward(self, x):\n        mean = x.mean(axis=1, keepdims=True)\n        var = x.var(axis=1, keepdims=True)\n        self.std = np.sqrt(var + self.eps)\n        self.xhat = (x - mean) / self.std\n        return self.gamma * self.xhat + self.beta",
      "note": "`axis=1` onde o `BatchNorm` tem `axis=0`: a média e a variância de cada linha, sobre os próprios atributos. `keepdims=True` as mantém como coluna, para que sejam subtraídas de cada atributo da própria linha."
    },
    {
      "code": "    def backward(self, grad):\n        self.dgamma[...] = (grad * self.xhat).sum(axis=0)\n        self.dbeta[...] = grad.sum(axis=0)\n        g = grad * self.gamma\n        return (g - g.mean(axis=1, keepdims=True)\n                - self.xhat * (g * self.xhat).mean(axis=1, keepdims=True)) / self.std",
      "note": "O backward do `BatchNorm` com o eixo virado: os termos extras agora correm ao longo de uma linha, porque os atributos de uma linha dividiram uma média e uma variância. `gamma` e `beta` continuam somando sobre o lote, já que todo exemplo os usou."
    }
  ]
}
```

O `checknorm.py` da seção de batch norm recebe a camada e o eixo como argumentos, então a mesma
verificação roda nesta pela linha de comando:

```
ana@vm:~/dl$ python -c "from checknorm import check; from layernorm import LayerNorm; check(LayerNorm(5), axis=1)"
x     mean [3.08 3.26 1.25 2.94 3.73 2.28 2.75 3.74]  std [0.77 1.95 1.69 1.32 1.44 0.9  1.04 1.48]
xhat  mean [0. 0. 0. 0. 0. 0. 0. 0.]  std [1. 1. 1. 1. 1. 1. 1. 1.]
relative error of the input gradient: 1.6e-10
```

Cada uma das oito linhas tem agora média 0 e desvio-padrão 1, e o backward concorda com a inclinação
medida com erro de 1,6e-10. **A diferença que importa aparece quando um exemplo está sozinho.** Salve
como `~/dl/alone.py`:

```schooling-example
{
  "language": "python",
  "file": "alone.py",
  "parts": [
    {
      "code": "\"\"\"alone: one image's features, normalised inside a batch of four and on their own.\"\"\"\nimport numpy as np\n\nimport digits\nfrom batchnorm import BatchNorm\nfrom layernorm import LayerNorm\n\n_, (x, _), _ = digits.load()\nh = x[:4] @ np.random.default_rng(0).normal(0, 0.5, (64, 6))\nprint(\"first image's six features:\", np.round(h[0], 2))",
      "note": "Quatro imagens de validação por uma camada aleatória de seis unidades: seis atributos cada, o tipo de coisa que uma camada de normalização recebe."
    },
    {
      "code": "for layer in (BatchNorm(6), LayerNorm(6)):\n    in_batch = layer.forward(h)[0]\n    alone = layer.forward(h[:1])[0]\n    print(f\"\\n{type(layer).__name__}\")\n    print(\"  in a batch of four:\", np.round(in_batch, 2) + 0)\n    print(\"  on its own:        \", np.round(alone, 2) + 0)",
      "note": "A saída da primeira imagem duas vezes em cada camada: uma com as outras três imagens ao lado, e uma sozinha. As duas camadas estão no comportamento de treino, que para o `LayerNorm` é o único que existe."
    }
  ]
}
```

```
ana@vm:~/dl$ python alone.py
first image's six features: [ 2.16  2.48 -0.03 -2.   -3.61  0.23]

BatchNorm
  in a batch of four: [ 0.03  0.84 -0.24  0.49 -1.41 -0.05]
  on its own:         [0. 0. 0. 0. 0. 0.]

LayerNorm
  in a batch of four: [ 1.06  1.21  0.04 -0.87 -1.62  0.17]
  on its own:         [ 1.06  1.21  0.04 -0.87 -1.62  0.17]
```

**O batch norm dá à primeira imagem uma saída diferente conforme a companhia**, e sozinha dá zeros, a
falha da seção anterior. O layer norm dá os mesmos seis números nos dois casos, então não precisa de
médias acumuladas, nem de modo, nem de lote. Na rede de dez camadas desta aula ele estabiliza menos
que o batch norm:

```
ana@vm:~/dl$ python deep.py layer
normalisation: layer, 43,530 parameters
val accuracy  epoch:    1      5     10     15     20
rate 0.03              0.664  0.925  0.939  0.950  0.956   train loss 0.013
rate 0.1               0.436  0.797  0.803  0.914  0.975   train loss 0.035
rate 0.3               0.106  0.419  0.800  0.833  0.903   train loss 0.316
rate 1.0               0.097  0.106  0.100  0.100  0.111   train loss 2.310
```

Ele treina em 0,1 e 0,3, onde a rede sem normalização não treinava, e termina em 0,975 e 0,903. Em
1,0 falha, onde o batch norm chegou a 0,961. **Para uma pilha de camadas totalmente conectadas sobre
imagens, o batch norm é a escolha mais forte. O layer norm é o que continua funcionando onde um lote
não é uma coisa sensata de medir**, e modelos de sequência são esse caso por três motivos:

- os exemplos de um lote são frases de tamanhos diferentes, completadas até a maior, então as
  estatísticas de um atributo no lote misturariam palavras reais com preenchimento;
- um modelo que escreve texto produz um token por vez para um usuário, o que é um lote de um a cada
  passo;
- a mesma camada normaliza o vetor de cada palavra do mesmo jeito no treino e no uso, então não há
  modo para esquecer.

O bloco transformer da aula 15 tem um layer norm junto de cada uma das suas duas partes, a
atenção e a rede feed-forward.
Muitos modelos de linguagem recentes usam uma variante chamada RMSNorm, que não subtrai a média e
divide só pela raiz da média dos quadrados.
