---
title: "O bloco: atenção, um MLP e dois atalhos"
version: 1
---

A atenção move informação entre tokens, e é só isso que ela faz. Cada saída é uma média ponderada de
valores, então sozinha ela consegue misturar o que os tokens carregam, mas não transformá-lo muito.
**Um bloco transformer junta a atenção a um MLP pequeno que trabalha em cada token separadamente.** As
duas metades ficam envolvidas em dois recursos que este curso já viu: uma layer norm antes de cada metade
(aula 8) e uma conexão residual em volta dela (aula 12). Em código, um bloco são duas linhas:

```
x = x + attention(norm1(x))
x = x + mlp(norm2(x))
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 230\" role=\"img\" aria-label=\"Um bloco transformer desenhado da esquerda para a direita. Os tokens passam por uma layer norm e pela atenção, e a entrada é somada de volta em volta das duas. Depois uma segunda layer norm e um MLP de 32 a 128 e de volta a 32, e a entrada dessa metade é somada de volta em volta dele. A atenção tem 4.224 parâmetros e move informação entre tokens; o MLP tem 8.352 e trabalha em cada token sozinho.\"><text x=\"6\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tokens entram</text><path d=\"M20 130 L70 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M62.6 133.1 L70 130 L62.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"70\" y=\"108\" width=\"80\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">layer norm</text><path d=\"M150 130 L180 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M172.6 133.1 L180 130 L172.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"180\" y=\"100\" width=\"110\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"235\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">atenção</text><text x=\"235\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">4 cabeças</text><text x=\"235\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">4.224</text><text x=\"235\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">entre tokens</text><path d=\"M290 130 L322 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M314.6 133.1 L322 130 L314.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"334\" cy=\"130\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><text x=\"334\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">+</text><path d=\"M55 130 L55 60 L334 60 L334 118\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M334 108 L334 118\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M330.9 110.6 L334 118 L337.1 110.6\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M346 130 L376 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M368.6 133.1 L376 130 L368.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"376\" y=\"108\" width=\"80\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"416\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">layer norm</text><path d=\"M456 130 L486 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M478.6 133.1 L486 130 L478.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"486\" y=\"100\" width=\"110\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"541\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">MLP</text><text x=\"541\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">32 → 128 → 32</text><text x=\"541\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">8.352</text><text x=\"541\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cada token sozinho</text><path d=\"M596 130 L628 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M620.6 133.1 L628 130 L620.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"640\" cy=\"130\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><text x=\"640\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">+</text><path d=\"M362 130 L362 60 L640 60 L640 118\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M640 108 L640 118\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M636.9 110.6 L640 118 L643.1 110.6\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M652 130 L690 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M682.6 133.1 L690 130 L682.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"668\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tokens saem</text></svg>", "caption": "Um bloco com a layer norm primeiro: a atenção deixa os tokens trocarem informação, o MLP trabalha em cada um sozinho, e cada metade soma de volta a sua entrada.", "same": ["layer norm", "MLP"]}
```

Um transformer é esse bloco empilhado: a saída de um é a entrada do seguinte, com o mesmo formato até o
topo. O PyTorch o tem como `nn.TransformerEncoderLayer`. O programa monta um e depois refaz a passada
para a frente com as peças dele, para mostrar que as duas linhas são tudo o que há. Salve como
`~/dl/block.py`:

```schooling-example
{
  "language": "python",
  "file": "block.py",
  "parts": [
    {
      "code": "\"\"\"block: one transformer block written as two lines, against nn.TransformerEncoderLayer.\"\"\"\nimport torch\nimport torch.nn as nn\n\ntorch.set_grad_enabled(False)\ntorch.manual_seed(0)\nd = 32\nlayer = nn.TransformerEncoderLayer(d, nhead=4, dim_feedforward=4 * d, dropout=0.1,\n                                   activation=\"gelu\", batch_first=True, norm_first=True)\nlayer.eval()",
      "note": "O bloco do PyTorch, com largura 32, 4 cabeças, um MLP quatro vezes mais largo, GELU e o dropout padrão de 0,1. `norm_first=True` põe cada layer norm antes da sua subcamada, como fazem o GPT-2 e a maioria dos modelos posteriores. O `eval()` desliga o dropout."
    },
    {
      "code": "def mlp(x):\n    return layer.linear2(layer.activation(layer.linear1(x)))",
      "note": "O MLP, montado com as peças da própria camada: uma camada linear até 128, GELU, e uma camada linear de volta a 32. Ele vê um token de cada vez."
    },
    {
      "code": "def block(x):\n    n = layer.norm1(x)\n    x = x + layer.self_attn(n, n, n)[0]\n    return x + mlp(layer.norm2(x))",
      "note": "O bloco. Normaliza, aplica a atenção, soma a entrada de volta; normaliza, roda o MLP, soma de novo. As duas somas são conexões residuais."
    },
    {
      "code": "x = torch.randn(2, 7, d)\nprint(\"input\", tuple(x.shape), \" output\", tuple(layer(x).shape))\nprint(\"largest difference from the layer:\", f\"{(block(x) - layer(x)).abs().max().item():.1e}\")",
      "note": "Duas sequências de sete tokens pela camada e pelas duas linhas acima, comparadas."
    },
    {
      "code": "for name, part in ((\"attention\", layer.self_attn), (\"mlp\", nn.ModuleList([layer.linear1, layer.linear2])),\n                   (\"two layer norms\", nn.ModuleList([layer.norm1, layer.norm2]))):\n    print(f\"{name:16s} {sum(p.numel() for p in part.parameters()):6,d}\")\nprint(f\"{'the block':16s} {sum(p.numel() for p in layer.parameters()):6,d}\")\nprint(\"by hand:\", 4 * d * d + 4 * d, \"+\", 2 * 4 * d * d + 4 * d + d, \"+\", 4 * d)",
      "note": "Onde estão os parâmetros, contados nos tensores e depois à mão: quatro projeções de 32 por 32 com vieses, duas matrizes de 32 por 128 com vieses, e um gamma e um beta por feature em cada norm."
    },
    {
      "code": "big = nn.TransformerEncoderLayer(768, nhead=12, dim_feedforward=3072, batch_first=True)\nper_block = sum(p.numel() for p in big.parameters())\nprint(f\"one block 768 wide: {per_block:,} parameters\")\nprint(f\"twelve blocks, 50,257 tokens, 1,024 positions, a last norm: {12 * per_block + (50257 + 1024) * 768 + 2 * 768:,}\")",
      "note": "O mesmo bloco na largura publicada do GPT-2, 768, com 12 cabeças e um MLP de 3.072, montado na memória com pesos aleatórios. Depois o modelo inteiro: doze blocos, uma linha por token para os seus 50.257 tokens e as suas 1.024 posições, e uma última norm."
    }
  ]
}
```

```
ana@vm:~/dl$ python block.py
input (2, 7, 32)  output (2, 7, 32)
largest difference from the layer: 0.0e+00
attention         4,224
mlp               8,352
two layer norms     128
the block        12,704
by hand: 4224 + 8352 + 128
one block 768 wide: 7,087,872 parameters
twelve blocks, 50,257 tokens, 1,024 positions, a last norm: 124,439,808
```

**As duas linhas concordam com a camada até `0.0e+00`.** Nada mais acontece dentro dela, fora o dropout,
que a camada aplica depois da atenção e dentro do MLP durante o treino, a 0,1 por padrão. A aula 7 o
apresentou; o `eval()` o desliga, e é por isso que a comparação foi feita depois dele. O MLP é o da aula
9 com GELU, a ativação que a aula 1 citou, no lugar da ReLU, e quatro vezes mais largo que o bloco por
dentro, que é a proporção do artigo de 2017.

As contagens mostram onde um transformer guarda os seus pesos:

| parte | parâmetros | à mão |
| --- | --- | --- |
| atenção | 4.224 | quatro matrizes de 32 × 32 e os seus vieses |
| MLP | 8.352 | 32 × 128 e 128 × 32, com vieses |
| duas layer norms | 128 | um gamma e um beta para cada uma das 32 features, duas vezes |
| o bloco | 12.704 | |

**Dois terços do bloco são o MLP**, e essa proporção não depende da largura: a atenção cresce como 4·d² e
o MLP como 8·d². Na largura publicada do GPT-2, 768, o mesmo bloco tem 7.087.872 parâmetros. Doze
deles, com uma linha de 768 para cada um dos seus 50.257 tokens e 1.024 posições e uma última layer norm,
dão 124.439.808: o menor GPT-2, de 2019, que
a OpenAI anunciou primeiro como 117M e depois rebatizou de 124M. Isso é aritmética sobre formatos
montados na memória; nada foi baixado.

**Onde fica a norm é uma escolha com história.** O artigo de 2017 normalizava depois de cada soma, o que
o PyTorch mantém como padrão, `norm_first=False`. O GPT-2 levou a norm para o começo de cada metade, como
aqui, para que o caminho residual vá do primeiro bloco ao último sem nada nele além de somas. Ruibin
Xiong e colegas mostraram em 2020 que esse arranjo pode ser treinado sem o aquecimento (*warm-up*) de que
o original precisava, o aquecimento da aula 5. A maioria dos modelos desde então põe a norm primeiro.
