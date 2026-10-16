---
title: LoRA, uma correção pequena ao lado de pesos congelados
version: 1
---

Fazer fine-tuning de uma camada troca a matriz de pesos `W` por `W + ΔW`, em que `ΔW` é o que o
treino somou. Na camada de 512 para 64 do `base.pt`, `ΔW` tem 32.768 números, tantos quanto o
próprio `W`. **LoRA, sigla de low-rank adaptation, aposta que a mudança de que uma tarefa nova
precisa é bem mais simples que a matriz que ela muda.** Ela escreve a mudança como o produto de duas
matrizes finas, `ΔW = B A`, com `A` de `r` linhas por 512 e `B` de 64 linhas por `r`. O rank `r` é pequeno,
então as duas juntas guardam `r × (512 + 64)` números: 2.304 com rank 4, contra 32.768.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 270\" role=\"img\" aria-label=\"Um diagrama da camada adaptada. A entrada, 512 números, segue por dois caminhos. Em cima, pelo peso congelado W de 64 por 512 do base.pt, 32.768 números. Embaixo, por A, 4 por 512, 2.048 números, e depois B, 64 por 4, 256 números, que começa em zero; A e B aprendem. Os dois resultados são somados e dão a saída, 64 números.\"><text x=\"50\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">entrada</text><text x=\"50\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">512 números</text><rect x=\"160\" y=\"34\" width=\"220\" height=\"64\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"270\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">W  64 × 512</text><text x=\"270\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">32,768</text><text x=\"270\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">congelado, do base.pt</text><rect x=\"160\" y=\"160\" width=\"100\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"210\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">A  4 × 512</text><text x=\"210\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">2,048</text><rect x=\"280\" y=\"160\" width=\"100\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"330\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">B  64 × 4</text><text x=\"330\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">256</text><text x=\"270\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">aprendem</text><text x=\"330\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">começa em zero</text><path d=\"M260 188 L280 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M272.6 191.1 L280 188 L272.6 184.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 129 L120 129\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M120 66 L120 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M120 66 L160 66\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M152.6 69.1 L160 66 L152.6 62.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M120 188 L160 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M152.6 191.1 L160 188 L152.6 184.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"450\" cy=\"129\" r=\"14\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"450\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--paper)\">+</text><path d=\"M380 66 L450 66\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M450 66 L450 115\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M446.9 107.6 L450 115 L453.1 107.6\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M380 188 L450 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M450 188 L450 143\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M453.1 150.4 L450 143 L446.9 150.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M464 129 L530 129\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M522.6 132.1 L530 129 L522.6 125.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"580\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">saída</text><text x=\"580\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">64 números</text></svg>", "caption": "A camada congelada e o adaptador ao lado dela, com rank 4. Só A e B aprendem."}
```

Três detalhes fazem isso funcionar. **`W` fica congelado**, então, faça o treino o que fizer, a
camada original continua lá embaixo. **`B` começa em zero**, então `B A` é zero e a rede adaptada
começa exatamente onde o `base.pt` estava, sem nenhum solavanco aleatório. E a entrada passa por `A`
e `B` ao lado de `W` em vez de por uma matriz remontada, o que limita o custo do adaptador ao
tamanho pequeno dele. A ideia inteira cabe numa classe. Salve como `~/dl/lora.py`:

```schooling-example
{
  "language": "python",
  "file": "lora.py",
  "parts": [
    {
      "code": "\"\"\"lora: a low-rank adapter beside a frozen nn.Linear.\"\"\"\nimport torch\nimport torch.nn as nn\n\n\nclass LoRA(nn.Module):\n    def __init__(self, base, rank, alpha):\n        super().__init__()\n        self.base = base\n        for p in base.parameters():\n            p.requires_grad = False\n        self.A = nn.Parameter(torch.randn(rank, base.in_features) / base.in_features ** 0.5)\n        self.B = nn.Parameter(torch.zeros(base.out_features, rank))\n        self.scale = alpha / rank",
      "note": "A camada embrulhada fica como está, congelada. `A` é `rank` por entradas, aleatória; `B` é saídas por `rank`, toda zero. O produto delas é uma correção do tamanho da matriz de pesos inteira, e enquanto `B` é zero a correção é zero, então a camada embrulhada começa calculando exatamente o que a original calculava. `alpha / rank` dá a escala da correção."
    },
    {
      "code": "    def forward(self, x):\n        return self.base(x) + (x @ self.A.T @ self.B.T) * self.scale",
      "note": "A entrada passa pela camada congelada como antes, e por `A` e depois `B` ao lado dela: desce para `rank` números e volta ao tamanho da saída. Os dois resultados são somados."
    },
    {
      "code": "    def merged(self):\n        \"\"\"A plain nn.Linear that computes the same thing, with the adapter folded in.\"\"\"\n        out = nn.Linear(self.base.in_features, self.base.out_features)\n        with torch.no_grad():\n            out.weight.copy_(self.base.weight + self.scale * self.B @ self.A)\n            out.bias.copy_(self.base.bias)\n        return out",
      "note": "`B @ A` é uma matriz do mesmo formato que o peso congelado, então pode ser somada a ele uma vez, depois do treino. O resultado é uma camada comum, sem adaptador e sem trabalho a mais por predição."
    }
  ]
}
```

O experimento põe o adaptador na camada de 512 para 64, a que fez a maior parte do trabalho no
`depths.py`, congela todo o resto do `base.pt` e o treina com uma cabeça nova, nos ranks 1, 4 e 16.
Depois confere as duas promessas da classe: que o adaptador se dobra numa camada comum, e que
tirá-lo devolve a rede antiga. Salve como `~/dl/adapt.py`, ao lado do `lora.py`:

```schooling-example
{
  "language": "python",
  "file": "adapt.py",
  "parts": [
    {
      "code": "\"\"\"adapt: base.pt frozen whole, a LoRA adapter on its 512-to-64 layer, a new head.\"\"\"\nimport torch\nimport torch.nn as nn\n\nimport cnn\nimport loop\nimport tdigits\nfrom lora import LoRA\n\n(x, y), (xv, yv), _ = tdigits.load(images=True)\nnew_val = xv[yv >= 5], yv[yv >= 5] - 5\nold_val = xv[yv < 5], yv[yv < 5]",
      "note": "Os mesmos dois conjuntos de validação do `forget.py`, e a classe `LoRA` do `lora.py`, que precisa estar em `~/dl` ao lado deste arquivo."
    },
    {
      "code": "def adapted(rank):\n    model = cnn.make_cnn(5)\n    model.load_state_dict(torch.load(\"base.pt\"))\n    for p in model.parameters():\n        p.requires_grad = False\n    old_head = model[8]\n    model[6] = LoRA(model[6], rank, alpha=rank)\n    model[8] = nn.Linear(64, 5)\n    return model, old_head",
      "note": "Tudo no `base.pt` fica congelado, a camada de 512 para 64 inclusive. O adaptador é posto em volta dessa camada, e uma cabeça nova toma o lugar da antiga, que é guardada para depois. Com `alpha` igual ao rank, a escala é 1."
    },
    {
      "code": "for per_class in (10, 50):\n    idx = torch.cat([torch.nonzero(y == d).flatten()[:per_class] for d in range(5, 10)])\n    train = x[idx], y[idx] - 5\n    print(f\"{per_class} per class\")\n    for rank in (1, 4, 16):\n        accs = []\n        for seed in (0, 1, 2):\n            torch.manual_seed(seed)\n            model, old_head = adapted(rank)\n            params = [p for p in model.parameters() if p.requires_grad]\n            opt = torch.optim.Adam(params, lr=1e-3)\n            history = loop.fit(model, opt, train, new_val, epochs=100, seed=seed, every=1000)\n            accs.append(history[-1][3])\n        print(f\"  rank {rank:2d} trains {sum(p.numel() for p in params):4d} parameters, val acc \"\n              + \"  \".join(f\"{a:.3f}\" for a in accs))",
      "note": "A receita do `depths.py`, com 10 e 50 imagens por classe, três sementes, Adam a 1e-3 por 100 épocas, e três ranks. O que aprende é `A`, `B` e a cabeça nova."
    },
    {
      "code": "adapter = model[6]\nmodel.eval()\nfeatures = model[:6](new_val[0])\nmerged = adapter.merged()\nprint(\"merged layer against adapter, largest difference:\",\n      (merged(features) - adapter(features)).abs().max().item())",
      "note": "O último modelo treinado, rank 16 com 50 imagens por classe e semente 2. O adaptador dele é dobrado numa camada comum, e as duas recebem as mesmas entradas: os 512 números por imagem de validação que chegam a essa camada."
    },
    {
      "code": "old = nn.Sequential(*model[:6], adapter, model[7], old_head)\nprint(\"0 to 4 with the adapter on:  \", f\"{loop.evaluate(old, *old_val)[1]:.3f}\")\nold[6] = adapter.base\nprint(\"0 to 4 with the adapter off: \", f\"{loop.evaluate(old, *old_val)[1]:.3f}\")",
      "note": "A tarefa antiga, como o `forget.py` mediu: o corpo com a cabeça do `base.pt` por cima. Primeiro com o adaptador no lugar, depois com o adaptador tirado e a camada congelada que ele embrulhava de volta."
    }
  ]
}
```

```
ana@vm:~/dl$ python adapt.py
10 per class
  rank  1 trains  901 parameters, val acc 0.772  0.872  0.778
  rank  4 trains 2629 parameters, val acc 0.867  0.917  0.894
  rank 16 trains 9541 parameters, val acc 0.906  0.906  0.911
50 per class
  rank  1 trains  901 parameters, val acc 0.889  0.900  0.900
  rank  4 trains 2629 parameters, val acc 0.967  0.967  0.972
  rank 16 trains 9541 parameters, val acc 0.967  0.967  0.972
merged layer against adapter, largest difference: 8.58306884765625e-06
0 to 4 with the adapter on:   0.950
0 to 4 with the adapter off:  0.989
```

## O que o adaptador comprou

**Com rank 4 o adaptador empatou com o último bloco usando cerca de um doze avos dos parâmetros
dele.** Treinou 2.629 parâmetros, os 2.304 de `A` e `B` mais os 325 da cabeça nova, enquanto
descongelar o último bloco treinou 33.157. Com 50 imagens por classe marcou 0,967, 0,967 e 0,972,
contra 0,967, 0,978 e 0,967 do último bloco no `depths.py`; com 10 por classe, de 0,867 a 0,917
contra 0,894 a 0,911. O rank 1 foi fino demais, de 0,889 a 0,900 com 50 por classe, e o rank 16 não
somou nada ao rank 4 ali.

Também não superou o treino do zero, e nem dava para esperar isso: ele adapta o mesmo doador
pequeno que todas as outras linhas desta aula.

**O adaptador se dobra.** A camada mesclada e o adaptador deram as mesmas saídas a menos de
8,6e-06, que é arredondamento de float32. Depois do treino, `B A` pode ser somado a `W` uma vez, e
a rede que vai para produção tem o formato comum do `cnn.make_cnn(5)`, sem adaptador nenhum e sem
nada a mais para calcular por predição.

**E ele pode ser tirado.** Com o adaptador no lugar, a tarefa antiga marcou 0,950: a camada
corrigida se afastou do que a cabeça do `base.pt` espera, como o fine-tuning fez na seção anterior.
Com o adaptador tirado e a camada congelada de volta, marcou 0,989, o número que o `base.pt` tinha na
aula 13. **Nada foi esquecido, porque nada foi sobrescrito.** Uma rede congelada pode carregar
vários adaptadores, um por tarefa, cada um num arquivo pequeno, trocados quando a tarefa deles é
pedida.

A conclusão da aula 13 continua valendo: o adaptador não acrescenta o que as camadas congeladas
abaixo dele nunca aprenderam. O LoRA decide quanto você treina e o que você mantém, não o que o
doador sabe.
