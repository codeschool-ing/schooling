---
title: Três profundidades, contra o treino do zero
version: 1
---

Há três lugares de costume para traçar a linha entre o que fica congelado e o que aprende. **Só a
cabeça** é a extração de características da aula 13. **Último bloco** deixa aprender também a
camada logo abaixo da cabeça, começando dos pesos que o `base.pt` lhe deu. **Tudo** deixa todas as
camadas aprenderem, e os pesos pré-treinados viram só um ponto de partida. A cabeça nova começa de
pesos aleatórios nas três, porque a antiga respondia a outra pergunta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 330\" role=\"img\" aria-label=\"Uma grade de quatro linhas e quatro camadas. As camadas são Conv2d de 1 para 16, Conv2d de 16 para 32, Linear de 512 para 64 e Linear de 64 para 5. Do zero: as quatro aprendem a partir de pesos aleatórios, 37.957 parâmetros. Cabeça: as três camadas do corpo vêm do base.pt e ficam congeladas, a cabeça nova aprende, 325 parâmetros. Último bloco: as duas convoluções ficam congeladas, a camada de 512 para 64 aprende a partir dos pesos do base.pt e a cabeça nova a partir de pesos aleatórios, 33.157 parâmetros. Tudo: as três camadas do corpo aprendem a partir dos pesos do base.pt e a cabeça nova a partir de pesos aleatórios, 37.957 parâmetros.\"><text x=\"186.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Conv2d</text><text x=\"186.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">1→16</text><text x=\"288.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Conv2d</text><text x=\"288.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">16→32</text><text x=\"390.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Linear</text><text x=\"390.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">512→64</text><text x=\"492.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Linear</text><text x=\"492.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">64→5</text><text x=\"492.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cabeça nova</text><text x=\"600\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">treina</text><text x=\"124\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">do zero</text><rect x=\"140\" y=\"76\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><rect x=\"242\" y=\"76\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><rect x=\"344\" y=\"76\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><rect x=\"446\" y=\"76\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"600\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">37,957</text><text x=\"124\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">cabeça</text><rect x=\"140\" y=\"122\" width=\"92\" height=\"36\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"242\" y=\"122\" width=\"92\" height=\"36\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"344\" y=\"122\" width=\"92\" height=\"36\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"446\" y=\"122\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"600\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">325</text><text x=\"124\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">último bloco</text><rect x=\"140\" y=\"168\" width=\"92\" height=\"36\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"242\" y=\"168\" width=\"92\" height=\"36\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"344\" y=\"168\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><rect x=\"446\" y=\"168\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"600\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">33,157</text><text x=\"124\" y=\"232\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">tudo</text><rect x=\"140\" y=\"214\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><rect x=\"242\" y=\"214\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><rect x=\"344\" y=\"214\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><rect x=\"446\" y=\"214\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"600\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">37,957</text><rect x=\"40\" y=\"270\" width=\"30\" height=\"18\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"80\" y=\"279\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">mantida do base.pt, congelada</text><rect x=\"330\" y=\"270\" width=\"30\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"370\" y=\"279\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">aprende a partir do base.pt</text><rect x=\"40\" y=\"300\" width=\"30\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"80\" y=\"309\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">aprende a partir de pesos aleatórios</text></svg>", "caption": "As quatro camadas que têm parâmetros, nos quatro começos do depths.py. Caixas cheias aprendem; as tracejadas ficam com os pesos do base.pt."}
```

Quanto mais do corpo aprende, mais a rede consegue se adaptar à tarefa nova, e mais parâmetros ela
tem de ajustar com as mesmas poucas imagens. Qual efeito ganha depende do doador e de quantos dados
novos existem, então isso se mede em vez de se discutir. O programa treina as três profundidades e
a referência do zero nos dígitos de 5 a 9, com 2, 10 e 50 imagens de treino de cada um. Salve como
`~/dl/depths.py`:

```schooling-example
{
  "language": "python",
  "file": "depths.py",
  "parts": [
    {
      "code": "\"\"\"depths: base.pt fine-tuned on the digits 5 to 9 at three depths, against scratch.\"\"\"\nimport torch\nimport torch.nn as nn\n\nimport cnn\nimport loop\nimport tdigits\n\n(x, y), (xv, yv), _ = tdigits.load(images=True)\nkeep = yv >= 5\nval = xv[keep], yv[keep] - 5",
      "note": "A tarefa do `transfer.py` da aula 13: os cinco dígitos que o `base.pt` nunca viu, rotulados de 0 a 4 ao subtrair 5, avaliados em todo 5 a 9 da divisão de validação."
    },
    {
      "code": "LEARNS = {\"head\": [8], \"last block\": [6, 8], \"everything\": [0, 2, 6, 8]}\n\n\ndef start(depth):\n    model = cnn.make_cnn(5)\n    if depth == \"scratch\":\n        return model\n    model.load_state_dict(torch.load(\"base.pt\"))\n    model[8] = nn.Linear(64, 5)\n    for i, layer in enumerate(model):\n        for p in layer.parameters():\n            p.requires_grad = i in LEARNS[depth]\n    return model",
      "note": "As posições das camadas que aprendem em cada profundidade: 0 e 2 são as convoluções, 6 é a camada de 512 para 64 e 8 a cabeça. Todo começo pré-treinado ganha uma cabeça nova, e toda camada fora da lista fica congelada. `scratch` é a mesma rede com pesos aleatórios e nada congelado."
    },
    {
      "code": "for per_class in (2, 10, 50):\n    idx = torch.cat([torch.nonzero(y == d).flatten()[:per_class] for d in range(5, 10)])\n    train = x[idx], y[idx] - 5\n    print(f\"{per_class} per class, {len(idx)} training images\")\n    for depth in (\"scratch\", \"head\", \"last block\", \"everything\"):\n        accs = []\n        for seed in (0, 1, 2):\n            torch.manual_seed(seed)\n            model = start(depth)\n            params = [p for p in model.parameters() if p.requires_grad]\n            opt = torch.optim.Adam(params, lr=1e-3)\n            history = loop.fit(model, opt, train, val, epochs=100, seed=seed, every=1000)\n            accs.append(history[-1][3])\n        print(f\"  {depth:10s} trains {sum(p.numel() for p in params):5d} parameters, val acc \"\n              + \"  \".join(f\"{a:.3f}\" for a in accs))",
      "note": "As 2, 10 e 50 primeiras imagens de treino de cada dígito novo; 2 e 10 são os dois tamanhos que a aula 13 usou. Cada começo é treinado três vezes com três sementes, pelo Adam a 1e-3 por 100 épocas, e o otimizador recebe só os parâmetros que aprendem."
    }
  ]
}
```

```
PENDING depths
```

## O que a tabela diz

**As linhas que a aula 13 já rodou saem iguais.** Do zero e só a cabeça, com 2 e 10 por classe, são
as mesmas imagens, sementes e receita do `transfer.py` da aula 13, e repetem os números dela até o
último dígito: 0,944, 0,933 e 0,933 do zero com 10 por classe, 0,683, 0,689 e 0,672 para a cabeça.
O que a tabela traz de novo são as linhas com fine-tuning.

**Deixar o corpo aprender compensa.** Com 10 por classe, a cabeça sozinha chegou de 0,672 a 0,689,
o último bloco de 0,894 a 0,911 e tudo de 0,917 a 0,933. Com 50 por classe, a cabeça fica bem
atrás, de 0,789 a 0,806, e as outras duas empatam: de 0,967 a 0,978 para o último bloco, de 0,967 a
0,972 para tudo. Descongelar a camada de 512 para 64 fez a maior parte do trabalho, o que bate com
o que a aula 13 encontrou: 25 das 64 unidades dela ficavam caladas em todo 5 a 9, e uma camada que
pode aprender pode deixar de ficar calada.

**E nada disso supera o treino do zero.** Com 10 por classe, tudo marcou de 0,917 a 0,933 contra
0,933 a 0,944 do zero; com 50 por classe, marcou de 0,967 a 0,972 contra 0,972 a 0,983. O único
tamanho em que alguma profundidade com fine-tuning saiu na frente é o menor: com 2 imagens por
classe, tudo marcou 0,850, 0,900 e 0,872, e o do zero 0,850, 0,833 e 0,828. Isso é um empate e duas
vitórias com dez imagens de treino e três sementes, o que é um indício e não uma conclusão; a aula
18 mede quanto se pode confiar em três sementes.

## Por quê, e o que isso quer dizer fora deste laboratório

Este é o resultado da aula 13 de novo, visto do outro lado. **O `base.pt` foi treinado com 528
imagens de cinco dígitos, o que não é muito mais do que a tarefa nova tem**, e uma CNN pequena
aprende dígitos 8 por 8 com 50 exemplos bem sozinha. Um doador tão pequeno tem pouco a dar, então o
melhor que o fine-tuning faz com ele é se afastar dele, e o começo que se afasta mais, tudo, termina
mais perto do treino do zero.

O caso que este laboratório não consegue mostrar é um doador treinado com muito mais dados do que
você tem, como os pesos do ImageNet da aula 13. Ali é a referência que se move: uma rede treinada do
zero com algumas centenas de fotografias fica fraca, e é por isso que o fine-tuning é por onde
começa a maior parte do trabalho com imagens. **A receita é a mesma nos dois casos**:

1. Treine a referência do zero. É uma execução, e é a única coisa que diz se o empréstimo compensou.
2. Treine só a cabeça. É o mais barato, e se ficar perto do melhor, pare aí.
3. Descongele o último bloco, depois tudo, e fique com a profundidade só se a nota de validação
   disser que ela mereceu os parâmetros a mais.

Quanto menos dados novos existem, mais vale tentar as profundidades congeladas, porque cada
parâmetro que aprende é ajustado a essas poucas imagens. Quanto mais as imagens novas diferem das do
doador, mais fundo o corte tem de ir, porque as características perto da cabeça pertencem à tarefa
antiga.
