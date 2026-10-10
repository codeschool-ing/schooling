---
title: Extração de características, e quando emprestar não compensa
version: 1
---

A extração de características é o tipo mais barato de transferência. **Congele o corpo emprestado,
ponha uma cabeça nova nele e treine só a cabeça.** O corpo é usado como uma função fixa de imagens
para características, e a cabeça é um classificador linear pequeno por cima: algumas centenas de
parâmetros para aprender em vez de dezenas de milhares, e é por isso que dá para funcionar com
pouquíssimos exemplos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 250\" role=\"img\" aria-label=\"A CNN pequena desenhada como uma fileira de camadas. As quatro primeiras caixas, duas convoluções, o pooling e a camada linear de 512 para 64, ficam dentro de uma moldura tracejada que as marca como o corpo copiado do base.pt e congelado: aprendido nos dígitos de 0 a 4, 37.632 parâmetros nunca atualizados. A última caixa, uma camada linear de 64 para 5, é a cabeça nova, treinada com 50 imagens dos dígitos de 5 a 9: 325 parâmetros.\"><rect x=\"78\" y=\"40\" width=\"432\" height=\"120\" rx=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"294\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">corpo: copiado do base.pt, congelado</text><rect x=\"528\" y=\"40\" width=\"116\" height=\"120\" rx=\"8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"586\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">cabeça: nova, treinada</text><text x=\"34\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">entrada</text><text x=\"34\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1x8x8</text><rect x=\"88\" y=\"70\" width=\"96\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"136\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Conv2d</text><text x=\"136\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">1→16</text><path d=\"M60 100 L88 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80.6 103.1 L88 100 L80.6 96.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"194\" y=\"70\" width=\"96\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"242\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Conv2d</text><text x=\"242\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">16→32</text><path d=\"M180 100 L194 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M186.6 103.1 L194 100 L186.6 96.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"300\" y=\"70\" width=\"96\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"348\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">pool, flatten</text><text x=\"348\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">512</text><path d=\"M286 100 L300 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M292.6 103.1 L300 100 L292.6 96.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"406\" y=\"70\" width=\"96\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"454\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Linear</text><text x=\"454\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">512→64</text><path d=\"M392 100 L406 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M398.6 103.1 L406 100 L398.6 96.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M502 100 L538 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M530.6 103.1 L538 100 L530.6 96.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"538\" y=\"70\" width=\"96\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"586\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">Linear</text><text x=\"586\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">64→5</text><text x=\"294\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">aprendido nos dígitos de 0 a 4</text><text x=\"294\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">37.632 parâmetros, nunca atualizados</text><text x=\"586\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor-dim)\">aprende de 5 a 9</text><text x=\"586\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor-dim)\">com 50 imagens</text><text x=\"586\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor-dim)\">325 parâmetros</text></svg>", "caption": "O corpo é emprestado e fica como estava; só a cabeça aprende as classes novas.", "same": ["pool, flatten"]}
```

O programa abaixo tenta isso nos dígitos de 5 a 9 com 10 e depois com 50 imagens de treino, e o
compara com dois outros começos: a mesma rede treinada do zero, e um meio-termo que mantém do
`base.pt` só as duas convoluções e treina camadas lineares novas em cima delas. Salve como
`~/dl/transfer.py`, ao lado do `base.pt`:

```schooling-example
{
  "language": "python",
  "file": "transfer.py",
  "parts": [
    {
      "code": "\"\"\"transfer: the digits 5 to 9 from a few examples each, with and without base.pt.\"\"\"\nimport torch\nimport torch.nn as nn\n\nimport cnn\nimport loop\nimport tdigits\n\n(x, y), (xv, yv), _ = tdigits.load(images=True)\nkeep = yv >= 5\nval = xv[keep], yv[keep] - 5",
      "note": "A tarefa nova são os cinco dígitos que o `pretrain.py` nunca viu, avaliados contra todos os 5 a 9 da divisão de validação. Subtrair 5 deixa os rótulos de 0 a 4, que é o que uma cabeça de cinco saídas responde."
    },
    {
      "code": "def pretrained():\n    model = cnn.make_cnn(5)\n    model.load_state_dict(torch.load(\"base.pt\"))\n    for p in model.parameters():\n        p.requires_grad = False\n    return model",
      "note": "A rede como o `pretrain.py` a deixou, montada primeiro e depois preenchida pelo arquivo, com todo parâmetro congelado: `requires_grad = False` quer dizer que o backward não calcula gradiente para ele, e o otimizador não tem o que mover."
    },
    {
      "code": "def scratch():\n    return cnn.make_cnn(5)\n\n\ndef head_only():\n    model = pretrained()\n    model[8] = nn.Linear(64, 5)\n    return model\n\n\ndef convolutions_only():\n    model = pretrained()\n    model[6] = nn.Linear(512, 64)\n    model[8] = nn.Linear(64, 5)\n    return model",
      "note": "Três começos. `head_only` mantém o corpo inteiro e troca a camada 8, a última `Linear`. `convolutions_only` mantém as duas convoluções e troca as duas camadas lineares. Uma camada nova nasce com `requires_grad` ligado, então é ela a parte que aprende."
    },
    {
      "code": "with torch.no_grad():\n    hidden = pretrained()[:8](val[0])\nprint(\"the 64 units before base.pt's head: silent on every 5 to 9 in val:\",\n      int((hidden.max(dim=0).values == 0).sum()))",
      "note": "Fatiar um `Sequential` dá as camadas até a cabeça. Isto conta as unidades, das 64, cujo ReLU fica em zero para todos os dígitos novos: uma característica que nunca dispara é uma característica que a cabeça nova não consegue usar."
    },
    {
      "code": "for per_class in (2, 10):\n    few = torch.cat([torch.nonzero(y == d).flatten()[:per_class] for d in range(5, 10)])\n    train = x[few], y[few] - 5\n    print(f\"{len(few)} training images, {len(val[1])} validation images\")\n    for make in (scratch, head_only, convolutions_only):\n        accs = []\n        for seed in (0, 1, 2):\n            torch.manual_seed(seed)\n            model = make()\n            params = [p for p in model.parameters() if p.requires_grad]\n            opt = torch.optim.Adam(params, lr=1e-3)\n            history = loop.fit(model, opt, train, val, epochs=100, seed=seed, every=1000)\n            accs.append(history[-1][3])\n        print(f\"  {make.__name__:17s} trains {sum(p.numel() for p in params):5d} parameters,\"\n              \" val acc \" + \"  \".join(f\"{a:.3f}\" for a in accs))",
      "note": "As 2 primeiras e depois as 10 primeiras imagens de treino de cada dígito novo. Cada começo treina três vezes com três sementes, as mesmas 100 épocas e a mesma taxa, e o otimizador recebe só os parâmetros que ainda aprendem. `every=1000` deixa o `loop.fit` calado."
    }
  ]
}
```

```
PENDING transfer
```

## O resultado é a lição

**Emprestar o corpo inteiro perdeu, e por muito.** Com 50 imagens, treinar do zero chegou a 0,944,
0,933 e 0,933; a cabeça sobre o corpo congelado chegou a 0,683, 0,689 e 0,672. Com só 10 imagens a
ordem foi a mesma, de 0,828 a 0,850 contra de 0,600 a 0,667. Os 325 parâmetros treinaram bem; o
problema eram as características que eles receberam.

A primeira linha da saída diz por quê. **25 das 64 unidades antes da cabeça nunca disparam para
nenhum 5 a 9 da validação.** O pré-treino em 0 a 4 moldou essa camada em detectores daqueles cinco
dígitos, e um terço dela não tem nada a dizer sobre um 7. Essa é a regra geral sobre onde as
características moram: as camadas perto da entrada aprendem peças que qualquer dígito tem, e as
camadas perto da saída aprendem as respostas da tarefa antiga.

O começo do meio concorda. Manter só as convoluções e aprender de novo as camadas lineares recuperou
quase tudo: de 0,917 a 0,922 com 50 imagens, e com 10 imagens empatou com o do zero, de 0,833 a
0,856. **Mesmo assim não superou o treino do zero.** Aqui o motivo honesto é o tamanho do doador:
528 imagens de cinco dígitos é pouco mais que a tarefa nova, e uma CNN pequena aprende dígitos 8 por
8 com 50 exemplos bem o bastante sozinha. A transferência compensa quando a tarefa antiga é muito
maior e mais ampla que a nova, que é exatamente o caso da próxima seção.

O que levar desta execução para o seu trabalho:

- **Corte onde as características ainda são gerais.** Quanto mais funda a camada, mais ela pertence
  aos rótulos antigos. Com um doador grande, a última camada oculta costuma servir; com um estreito,
  corte antes.
- **Treine sempre a referência do zero também.** Custa uma execução a mais, e sem ela uma
  transferência que perdeu teria parecido um razoável 0,68.
- **Congelado quer dizer barato.** O começo só com a cabeça treinou 325 parâmetros; num corpo grande,
  a parte congelada pode até rodar uma vez só, as características ficarem guardadas, e só a cabeça
  treinar sobre elas.

A aula 17 parte do mesmo `base.pt` e deixa parte do corpo aprender também.
