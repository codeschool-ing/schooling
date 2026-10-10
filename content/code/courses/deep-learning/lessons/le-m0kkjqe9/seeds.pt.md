---
title: Sementes, e o que uma semente fixa
version: 1
---

Visto de fora, o treino parece determinístico: o mesmo programa, os mesmos dados, as mesmas
configurações. **Não é, porque três coisas nele são sorteadas**: os pesos iniciais, a ordem em que
as imagens são embaralhadas a cada época e, um nível acima, quais imagens foram para qual conjunto.
Mude qualquer uma delas e a acurácia final muda, sem nada no código que diga por quê.

Uma semente é o número de onde um gerador de números aleatórios parte. Comece-o do mesmo número e
ele produz de novo a mesma sequência, então tudo o que é sorteado dele é sorteado de novo. Três
linhas, rodadas duas vezes com a semente 0 e uma vez com a semente 1:

```
PENDING init
```

A mesma semente deu os mesmos três primeiros pesos, dígito por dígito, e a semente 1 deu outros.
**Depois de receber uma semente, o gerador não tem nada de aleatório.** Ele é uma sequência longa e
fixa, e a semente diz em que ponto dela começar.

## Uma execução, todas as escolhas num lugar só

Para comparar execuções, toda escolha que uma execução faz precisa ser um argumento, nunca uma linha
que alguém edita. Salve isto como `~/dl/exp.py`, ao lado do `digits.py` da aula 1 e do `tdigits.py`
e do `loop.py` da aula 9:

```schooling-example
{
  "language": "python",
  "file": "exp.py",
  "parts": [
    {
      "code": "\"\"\"exp: one training run on the digits, decided by a config and a seed and nothing else.\"\"\"\nimport torch\nfrom torch import nn\n\nimport loop\nimport tdigits",
      "note": "`tdigits.py` e `loop.py` são os da aula 9. Este arquivo não traz nenhuma ideia nova sobre treino; ele junta num lugar só toda escolha que uma execução faz, para que duas execuções se distingam pelos argumentos."
    },
    {
      "code": "def build(config):\n    h = config[\"hidden\"]\n    return nn.Sequential(nn.Linear(64, h), nn.ReLU(), nn.Linear(h, 10))",
      "note": "A rede da aula 9: uma camada oculta cuja largura vem da config."
    },
    {
      "code": "def run(config, seed):\n    \"\"\"Train one network; return the model and its final validation accuracy.\"\"\"\n    torch.manual_seed(seed)\n    train, val, _ = tdigits.load()\n    model = build(config)",
      "note": "`torch.manual_seed` reinicia o gerador de números aleatórios do PyTorch, e o `build` sorteia os pesos iniciais dele logo em seguida. Mesma semente, mesmos pesos iniciais. A divisão não é tocada: `tdigits.load()` usa a própria semente fixa, 0, então toda execução vê as mesmas 1.077 imagens de treino."
    },
    {
      "code": "    opt = torch.optim.SGD(model.parameters(), lr=config[\"lr\"], momentum=0.9)\n    history = loop.fit(model, opt, train, val, config[\"epochs\"],\n                       batch_size=config[\"batch_size\"], seed=seed, every=config[\"epochs\"] + 1)\n    return model, history[-1][3]",
      "note": "A mesma semente vai para o `loop.fit`, que a usa na ordem em que as imagens são embaralhadas a cada época. Um `every` maior que o número de épocas impede o `fit` de imprimir, e a última entrada de `history` guarda a acurácia de validação final."
    }
  ]
}
```

Cada uma das três coisas sorteadas tem a própria semente aqui, e vale saber qual é qual:

| coisa sorteada | fixada por |
| --- | --- |
| quais imagens são de treino, de validação e de teste | `digits.load(seed=0)`, dentro de `tdigits.load()`: nunca muda nesta aula |
| os pesos iniciais | `torch.manual_seed(seed)`, logo antes do `build` |
| a ordem dos lotes em cada época | o gerador que o `loop.fit` cria a partir de `seed` |

A divisão fica fixa de propósito. Variá-la também é uma pergunta justa, e ela responde outra coisa:
quanto o resultado depende de quais 360 imagens calharam de ficar de fora.

## Duas vezes com a mesma semente

Salve como `~/dl/seeds.py`:

```schooling-example
{
  "language": "python",
  "file": "seeds.py",
  "parts": [
    {
      "code": "\"\"\"seeds: the same seed twice, then another one.\"\"\"\nimport torch\n\nimport exp\n\nconfig = {\"hidden\": 32, \"lr\": 0.01, \"epochs\": 10, \"batch_size\": 32}\na, acc_a = exp.run(config, 0)\nb, acc_b = exp.run(config, 0)\nc, acc_c = exp.run(config, 1)",
      "note": "Três treinos completos de dez épocas: dois com semente 0 e um com semente 1. Todo o resto é idêntico."
    },
    {
      "code": "def same(m, n):\n    return all(torch.equal(p, q) for p, q in zip(m.parameters(), n.parameters()))\n\n\nprint(f\"seed 0  val acc {acc_a:.4f}\")\nprint(f\"seed 0  val acc {acc_b:.4f}  every weight equal to the first run's: {same(a, b)}\")\nprint(f\"seed 1  val acc {acc_c:.4f}  every weight equal to the first run's: {same(a, c)}\")",
      "note": "`torch.equal` só é verdadeiro quando dois tensores guardam os mesmos números até o último bit. Próximo não é igual aqui, de propósito."
    }
  ]
}
```

```
PENDING seeds
```

**A semente 0, duas vezes, deu a mesma rede até o último bit**, e não só a mesma acurácia. Dez
épocas de 34 lotes são 340 passos do otimizador, e depois de todos eles nenhum parâmetro diferia. A
semente 1 terminou em outro lugar, com outra acurácia.

É isso que uma semente compra, e é tudo o que ela compra: **a mesma execução, de novo, na mesma
máquina com as mesmas bibliotecas.** Ela não torna um resultado verdadeiro. A acurácia da semente 0
é um sorteio entre todas as acurácias que esta configuração consegue alcançar, e a próxima seção
mede o tamanho dessa faixa.
