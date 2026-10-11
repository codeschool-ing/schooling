---
title: "A LSTM: um estado da célula e três portas"
version: 1
---

A long short-term memory, LSTM, é de 1997, de Sepp Hochreiter e Jürgen Schmidhuber, e foi projetada
exatamente contra o produto da seção anterior. **Ela acrescenta um segundo estado, o estado da célula
`c`, e arruma as coisas para que o caminho do `c` de um passo ao do seguinte não tenha matriz de pesos nem
`tanh`.** O que muda o `c` é decidido por portas: vetores de números entre 0 e 1, calculados a partir da
entrada e da saída anterior, que multiplicam outros vetores elemento a elemento.

- a porta de esquecimento `f`, acrescentada por Felix Gers, Schmidhuber e Fred Cummins em 2000, multiplica o que o estado da célula já guarda;
- a porta de entrada `i` multiplica o candidato `g`, o que este passo propõe acrescentar;
- a porta de saída `o` decide quanto do estado da célula aparece como a saída `h`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 280\" role=\"img\" aria-label=\"Um passo de LSTM. Ao longo do topo corre o estado da célula, do c à esquerda ao novo c à direita. No caminho ele é multiplicado pela porta de esquecimento f e recebe o candidato g, multiplicado pela porta de entrada i: nenhuma matriz de pesos e nenhuma função de achatamento ficam nessa linha. Embaixo, a saída anterior h e a entrada x alimentam uma única multiplicação por pesos que produz as quatro portas. A nova saída h é a porta de saída o vezes tanh do novo estado da célula.\"><text x=\"30\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">c</text><path d=\"M45 50 L590 50\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M582.6 53.1 L590 50 L582.6 46.9\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"610\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--phosphor)\">c'</text><text x=\"320\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">estado da célula</text><circle cx=\"200\" cy=\"50\" r=\"14\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><text x=\"200\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--amber)\">×</text><circle cx=\"340\" cy=\"50\" r=\"14\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><text x=\"340\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--amber)\">+</text><rect x=\"110\" y=\"180\" width=\"360\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"290\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">[x, h] @ W + b</text><text x=\"30\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">x, h</text><path d=\"M62 202 L108 202\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M100.6 205.1 L108 202 L100.6 198.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"200\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">f = σ</text><text x=\"200\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">esquecer</text><path d=\"M200 180 L200 172\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M203.1 179.4 L200 172 L196.9 179.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"310\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">i = σ</text><text x=\"310\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">entrada</text><path d=\"M310 180 L310 172\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M313.1 179.4 L310 172 L306.9 179.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"370\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">g = tanh</text><text x=\"370\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">candidato</text><path d=\"M370 180 L370 172\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M373.1 179.4 L370 172 L366.9 179.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"450\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">o = σ</text><text x=\"450\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">saída</text><path d=\"M450 180 L450 172\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M453.1 179.4 L450 172 L446.9 179.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M200 132 L200 66\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M203.1 73.4 L200 66 L196.9 73.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"340\" cy=\"100\" r=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><text x=\"340\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">×</text><path d=\"M310 132 L332 109\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M329.2 116.5 L332 109 L324.7 112.2\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M370 132 L348 109\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M355.3 112.2 L348 109 L350.8 116.5\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M340 88 L340 66\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M343.1 73.4 L340 66 L336.9 73.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M520 50 L520 88\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M516.9 80.6 L520 88 L523.1 80.6\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"520\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">tanh</text><circle cx=\"520\" cy=\"140\" r=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><text x=\"520\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">×</text><path d=\"M520 110 L520 126\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M516.9 118.6 L520 126 L523.1 118.6\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M480 140 L506 140\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M498.6 143.1 L506 140 L498.6 136.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M520 152 L520 250\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M516.9 242.6 L520 250 L523.1 242.6\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"540\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">h'</text></svg>", "caption": "O estado da célula corre pelo topo, tocado só por uma multiplicação e uma soma. Tudo o que precisa de pesos acontece embaixo dele."}
```

O programa calcula um passo à mão e compara com a `nn.LSTM`. Salve como `~/dl/lstm_step.py`:

```schooling-example
{
  "language": "python",
  "file": "lstm_step.py",
  "parts": [
    {
      "code": "\"\"\"lstm_step: one step of nn.LSTM, gate by gate.\"\"\"\nimport torch\nimport torch.nn as nn\n\ntorch.manual_seed(0)\nlstm = nn.LSTM(input_size=3, hidden_size=5, batch_first=True)\nx = torch.randn(2, 1, 3)\nh0, c0 = torch.zeros(1, 2, 5), torch.randn(1, 2, 5)\nout, (h1, c1) = lstm(x, (h0, c0))",
      "note": "Uma LSTM carrega dois estados, `h` e o estado da célula `c`, e devolve os dois. O programa começa `c` com números aleatórios para que haja algo nele que as portas possam guardar ou esquecer."
    },
    {
      "code": "z = (x[:, 0] @ lstm.weight_ih_l0.T + h0[0] @ lstm.weight_hh_l0.T\n     + lstm.bias_ih_l0 + lstm.bias_hh_l0)\ni, f, g, o = z.chunk(4, dim=1)\ni, f, o = torch.sigmoid(i), torch.sigmoid(f), torch.sigmoid(o)\ng = torch.tanh(g)",
      "note": "A mesma soma da RNN, quatro vezes mais larga, cortada em quatro blocos de cinco. Três passam por uma sigmoid e viram portas entre 0 e 1: entrada `i`, esquecimento `f`, saída `o`. O quarto passa por `tanh` e é o candidato `g`, o que este passo propõe escrever."
    },
    {
      "code": "c = f * c0[0] + i * g\nh = o * torch.tanh(c)",
      "note": "As duas linhas pelas quais a LSTM existe. O novo estado da célula é o antigo multiplicado pela porta de esquecimento, mais o candidato multiplicado pela porta de entrada: nenhuma matriz e nenhum `tanh` ficam entre `c0` e `c`. A saída é uma vista dele, filtrada por uma porta."
    },
    {
      "code": "print(\"cell state equals nn.LSTM's:\", torch.allclose(c, c1[0], atol=1e-6))\nprint(\"output equals nn.LSTM's:\", torch.allclose(h, h1[0], atol=1e-6))\nprint(\"forget gate, sequence 0:\", f[0].detach().numpy().round(2))\nprint(\"parameters: RNN\", sum(p.numel() for p in nn.RNN(3, 5).parameters()),\n      \" LSTM\", sum(p.numel() for p in lstm.parameters()))"
    }
  ]
}
```

```
PENDING lstm-step
```

**Os dois estados batem com os do PyTorch**, então os quatro blocos estão na ordem `i, f, g, o`, que é a
ordem que o PyTorch documenta. As portas saem do mesmo tipo de soma que uma RNN calcula, quatro vezes mais
larga, e por isso a camada tem quatro vezes os parâmetros: 200 contra os 50 da RNN.

A linha que importa é `c = f * c0[0] + i * g`. Voltar um passo pelo estado da célula multiplica o
gradiente por `f`, e por mais nada. **Onde a porta de esquecimento fica perto de 1, o estado da célula
leva a informação e o gradiente dela por muitos passos.** Onde fica perto de 0, a célula esquece de
propósito, o que é igualmente útil quando uma frase termina ou o assunto muda.

A porta é uma sigmoid de uma soma aprendida, então não começa perto de 1. A porta de esquecimento que este
programa imprimiu vai de 0.22 a 0.61. O `bptt.py` da seção anterior recebe `lstm` como primeiro argumento
e, para uma LSTM, um número a somar ao viés da porta de esquecimento como segundo. Rode sem e com 3:

```
PENDING bptt-lstm
```

**Uma LSTM nova perde o gradiente quase tão rápido quanto a RNN**: 1.6e-11 a 49 passos. Com 3 somado ao
viés da porta de esquecimento, de modo que as portas comecem em torno da sigmoid de 3, que é 0,95, a
mesma camada ainda passa 2.9e-02 para 49 passos atrás, umas nove ordens de grandeza a mais. A célula não
lembra por padrão. É uma célula que *pode* aprender a lembrar, porque o caminho existe e o treino só
precisa abrir a porta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 330\" role=\"img\" aria-label=\"Um gráfico do tamanho do gradiente contra quantos passos para trás fica a entrada, de 0 a 49, em escala logarítmica de 10 à menos 14 até 10. A linha da RNN cai sem parar até cerca de 10 à menos 14 a 49 passos. A linha da LSTM nova cai quase tão rápido, até cerca de 10 à menos 11. A LSTM com 3 somado ao viés do esquecimento fica quase plana, entre 10 à menos 1 e 10 à menos 2, até o fim.\"><path d=\"M80 260 L600 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 260 L80 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 260.0 L600 260.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e-14</text><path d=\"M80 214.0 L600 214.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"214.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e-11</text><path d=\"M80 168.0 L600 168.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"168.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e-8</text><path d=\"M80 122.0 L600 122.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"122.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e-5</text><path d=\"M80 76.0 L600 76.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"76.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e-2</text><path d=\"M80 30.0 L600 30.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e1</text><text x=\"80.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"186.12244897959184\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><text x=\"292.2448979591837\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><text x=\"398.3673469387755\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">30</text><text x=\"504.48979591836735\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">40</text><text x=\"600.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">49</text><text x=\"340.0\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">passos para trás a partir da última saída</text><text x=\"80\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">gradiente (escala log)</text></svg>", "caption": "Os números que o `bptt.py` imprimiu, numa escala em que cada linha da grade vale mil vezes a de baixo."}
```

É por isso que é comum começar o viés do esquecimento em 1 em vez de 0, o que Jozefowicz, Zaremba e
Sutskever recomendaram em 2015 depois de comparar milhares de arquiteturas recorrentes. O modelo da
próxima seção faz isso.

**A GRU**, de 2014, é a simplificação mais conhecida da LSTM: duas portas em vez de três e nenhum estado
da célula separado, então três blocos de pesos em vez de quatro. O PyTorch a tem como `nn.GRU`, com a
mesma interface da `nn.RNN`. Ela não foi executada nesta aula. Chung e colegas compararam as duas em 2014
e as acharam próximas nas tarefas que testaram, e a GRU custa três quartos dos parâmetros.
