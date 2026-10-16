---
title: Taxas de aprendizado, e até onde os pesos andam
version: 1
---

A aula 5 chamou a taxa de aprendizado de o ajuste que mais importa, e no fine-tuning ela ganha um
segundo trabalho. Do zero, a taxa só decide quão rápido a rede chega a algum lugar útil. **A partir
de pesos pré-treinados, ela também decide quanto a rede pode se afastar de onde começou**, e o ponto
de partida é justamente o que você pegou emprestado. Uma taxa certa para pesos aleatórios pode
levar uma camada pré-treinada para longe do que ela sabia nas primeiras épocas.

Essa distância se mede. O programa abaixo faz fine-tuning de tudo, com 10 imagens por classe, em
três taxas únicas e uma vez com duas: um corpo lento e uma cabeça mais rápida, postos pelos grupos
de parâmetros da primeira seção. Ao lado de cada acurácia ele mostra quanto a primeira convolução
andou, como fração do tamanho dela no `base.pt`. Salve como `~/dl/rates.py`:

```schooling-example
{
  "language": "python",
  "file": "rates.py",
  "parts": [
    {
      "code": "\"\"\"rates: fine-tuning all of base.pt at three learning rates, and with two at once.\"\"\"\nimport torch\nimport torch.nn as nn\n\nimport cnn\nimport loop\nimport tdigits\n\n(x, y), (xv, yv), _ = tdigits.load(images=True)\nkeep = yv >= 5\nval = xv[keep], yv[keep] - 5\nidx = torch.cat([torch.nonzero(y == d).flatten()[:10] for d in range(5, 10)])\ntrain = x[idx], y[idx] - 5\n\nbase = cnn.make_cnn(5)\nbase.load_state_dict(torch.load(\"base.pt\"))",
      "note": "Dez imagens de cada dígito novo, o tamanho do meio do `depths.py`, e uma cópia intocada do `base.pt` guardada para medir contra ela."
    },
    {
      "code": "def moved(model):\n    \"\"\"How far the first convolution went from base.pt, as a fraction of its size.\"\"\"\n    w0, w = base[0].weight, model[0].weight\n    return ((w - w0).norm() / w0.norm()).item()",
      "note": "A distância entre os pesos da primeira camada agora e no `base.pt`, dividida pelo tamanho dos pesos no `base.pt`. 0,10 quer dizer que os filtros mudaram um décimo do próprio tamanho."
    },
    {
      "code": "SETUPS = {\n    \"one rate, 1e-2\": lambda m: [{\"params\": m.parameters(), \"lr\": 1e-2}],\n    \"one rate, 1e-3\": lambda m: [{\"params\": m.parameters(), \"lr\": 1e-3}],\n    \"one rate, 1e-4\": lambda m: [{\"params\": m.parameters(), \"lr\": 1e-4}],\n    \"body 1e-4, head 1e-3\": lambda m: [{\"params\": m[:8].parameters(), \"lr\": 1e-4},\n                                       {\"params\": m[8].parameters(), \"lr\": 1e-3}],\n}",
      "note": "Quatro otimizadores para a mesma rede, toda ela aprendendo. Os três primeiros usam uma taxa para todas as camadas; o último dá ao corpo uma taxa dez vezes menor que a da cabeça nova."
    },
    {
      "code": "for name, groups in SETUPS.items():\n    results = []\n    for seed in (0, 1, 2):\n        torch.manual_seed(seed)\n        model = cnn.make_cnn(5)\n        model.load_state_dict(torch.load(\"base.pt\"))\n        model[8] = nn.Linear(64, 5)\n        opt = torch.optim.Adam(groups(model))\n        history = loop.fit(model, opt, train, val, epochs=100, seed=seed, every=1000)\n        results.append(f\"{history[-1][3]:.3f} ({moved(model):.2f})\")\n    print(f\"{name:21s} val acc (first layer moved)  \" + \"  \".join(results))",
      "note": "Três sementes por configuração, como antes. Cada resultado é a acurácia de validação em 5 a 9 e, entre parênteses, quanto a primeira camada andou."
    }
  ]
}
```

```
PENDING rates
```

## Lendo os dois números juntos

**A taxa define a distância.** A 1e-4 a primeira camada andou de 0,03 a 0,04 do próprio tamanho, a
1e-3 de 0,16 a 0,18, e a 1e-2 de 0,32 a 0,40: a 1e-2 os filtros mudaram cerca de um terço do
próprio tamanho. A configuração com dois grupos, corpo a 1e-4 e cabeça a 1e-3, moveu o corpo tão
pouco quanto 1e-4, 0,04, porque essa é a taxa que o grupo dele recebeu.

**Nesta tarefa, andar longe deu a melhor nota.** A 1e-2 chegou de 0,922 a 0,950, a linha mais alta,
empatada com o treino do zero do `depths.py`. O corpo lento marcou menos, de 0,828 a 0,844, abaixo
de tudo a 1e-3 e abaixo também do último bloco do `depths.py`. É o resultado da seção anterior de
outra forma: o `base.pt` tem pouco a dar aos dígitos de 5 a 9, então quanto menos o corpo fica preso
a ele, melhor vai a tarefa nova.

O que uma taxa alta custa não está nesta tabela, porque a tabela só pergunta pela tarefa nova. A
próxima seção pergunta pela antiga.

## Por que o fine-tuning costuma ser mais lento

Na prática o fine-tuning usa taxas menores que o treino do zero, e muitas vezes menores ainda para
as camadas perto da entrada, e o motivo é a metade da troca que o doador deste laboratório não
consegue mostrar. **Com um corpo que vale a pena manter, cada passo para longe dele joga fora algo
que custou muito mais dados para aprender do que os que você está usando no fine-tuning.** As
primeiras camadas, com as características mais gerais, recebem a menor taxa; as camadas perto da
cabeça, mais; a cabeça nova, que começa do nada, a maior. Treinar cada profundidade com a própria
taxa se chama discriminative fine-tuning, e é exatamente a lista de grupos que o `rates.py` montou,
com mais entradas.

Dois hábitos menores vêm do mesmo raciocínio:

- **Uma cabeça nova começa aleatória, então os primeiros gradientes dela são grandes e
  arbitrários**, e eles voltam para um corpo que estava bem. Treinar só a cabeça por algumas épocas
  antes e só depois descongelar, ou começar com o warm-up da aula 5, impede que esses primeiros
  passos desfaçam o corpo.
- **Escolha a taxa pela validação, como sempre**, mas leia a distância também. Uma taxa que vence na
  tarefa nova movendo o corpo um terço do tamanho dele está dizendo que os pesos pré-treinados não
  faziam muita coisa, e é bom saber disso antes de pagar por um doador maior.
