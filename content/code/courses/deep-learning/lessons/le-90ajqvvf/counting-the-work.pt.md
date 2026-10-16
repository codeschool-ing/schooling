---
title: Contando o trabalho
version: 1
---

Um modelo é descrito pelo número de parâmetros, então o número de parâmetros é o primeiro palpite comum
sobre quanto custa treiná-lo. **A contagem de parâmetros mede memória, não trabalho.** O que ocupa o
tempo de um processador é aritmética, e um parâmetro pode entrar numa multiplicação por exemplo ou em
centenas delas.

O PyTorch consegue contar a aritmética por você. O programa abaixo a conta para o MLP da aula 9 e para a
CNN da aula 11, por exemplo, só para a passada para a frente e para um passo de treino inteiro, e depois
cronometra um passo de treino de cada uma. Ele precisa, ao lado, do `digits.py` da aula 1, do
`tdigits.py` e do `mlp.py` da aula 9 e do `cnn.py` da aula 11. Salve-o como `~/dl/work.py`:

```schooling-example
{
  "language": "python",
  "file": "work.py",
  "parts": [
    {
      "code": "\"\"\"work: parameters, arithmetic per example, and time, for lesson 9's MLP and lesson 11's CNN.\"\"\"\nimport time\n\nimport torch\nimport torch.nn.functional as F\nfrom torch.utils.flop_counter import FlopCounterMode\n\nimport cnn\nimport tdigits\nfrom mlp import make_mlp",
      "note": "`FlopCounterMode` é o contador do próprio PyTorch: enquanto está ativo, ele soma as operações de ponto flutuante de cada produto de matrizes e cada convolução que rodam. Ele conta uma multiplicação e uma adição como duas."
    },
    {
      "code": "def flops(step):\n    \"\"\"Floating-point operations PyTorch counts while `step` runs.\"\"\"\n    with FlopCounterMode(display=False) as counter:\n        step()\n    return counter.get_total_flops()\n\n\ndef ms_per_batch(model, x, y, repeat=20):\n    \"\"\"The fastest of `repeat` training steps on one batch, in milliseconds.\"\"\"\n    best = float(\"inf\")\n    for _ in range(repeat):\n        start = time.perf_counter()\n        F.cross_entropy(model(x), y).backward()\n        best = min(best, time.perf_counter() - start)\n    return best * 1000",
      "note": "A mais rápida de vinte execuções, porque qualquer outra coisa rodando na máquina só pode deixar um passo mais lento, nunca mais rápido. Um passo aqui é a passada para a frente, a perda e a passada para trás; a atualização do otimizador fica de fora, porque é uma subtração por parâmetro."
    },
    {
      "code": "measured = {}\nfor name, make, images in ((\"MLP\", make_mlp, False), (\"CNN\", cnn.make_cnn, True)):\n    torch.manual_seed(0)\n    model = make()\n    (x, y), _, _ = tdigits.load(images=images)\n    xb, yb = x[:32], y[:32]\n    n = sum(p.numel() for p in model.parameters())\n    forward = flops(lambda: model(xb)) / 32\n    train = flops(lambda: F.cross_entropy(model(xb), yb).backward()) / 32\n    ms = ms_per_batch(model, xb, yb)\n    print(f\"{name}: {n} parameters\")\n    print(f\"  forward {forward:,.0f} FLOPs per example, {forward / n:.1f} per parameter\")\n    print(f\"  training step {train:,.0f} per example, {train / forward:.2f} times the forward, {train / n:.1f} per parameter\")\n    print(f\"  30 epochs of 1,077 images: {30 * 1077 * train / 1e9:.2f} GFLOPs\")\n    print(f\"  {ms:.2f} ms per batch of 32, {32 * train / ms / 1e6:.2f} GFLOP/s\")\n    measured[name] = (train, ms)\n\n(mlp_flops, mlp_ms), (cnn_flops, cnn_ms) = measured[\"MLP\"], measured[\"CNN\"]\nprint(f\"CNN against MLP: {cnn_flops / mlp_flops:.0f} times the arithmetic, {cnn_ms / mlp_ms:.1f} times the time\")",
      "note": "As duas redes recebem o mesmo lote de 32 dígitos, achatado para o MLP e como grades de 1 por 8 por 8 para a CNN. Cada contagem é dividida por 32 para dar um custo por exemplo. As duas últimas linhas dividem a aritmética e o tempo da CNN pelos do MLP."
    }
  ]
}
```

```
ana@vm:~/dl$ python work.py
MLP: 2410 parameters
  forward 4,736 FLOPs per example, 2.0 per parameter
  training step 10,112 per example, 2.14 times the forward, 4.2 per parameter
  30 epochs of 1,077 images: 0.33 GFLOPs
  0.32 ms per batch of 32, 1.00 GFLOP/s
CNN: 38282 parameters
  forward 675,072 FLOPs per example, 17.6 per parameter
  training step 2,006,784 per example, 2.97 times the forward, 52.4 per parameter
  30 epochs of 1,077 images: 64.84 GFLOPs
  2.24 ms per batch of 32, 28.62 GFLOP/s
CNN against MLP: 198 times the arithmetic, 6.9 times the time
```

**O MLP faz 2,0 operações de ponto flutuante por parâmetro na passada para a frente.** Cada peso
multiplica uma entrada, e o produto é somado a uma soma: uma multiplicação e uma adição, uma vez por
exemplo. Os vieses são um punhado de adições, que o contador deixa de fora.

**A CNN faz 17,6 por parâmetro**, porque um peso de convolução não é usado uma vez só. Um filtro desliza
pelas 64 posições do mapa de 8 por 8, e o preenchimento mantém todo mapa em 8 por 8, então cada peso das
duas convoluções multiplica 64 vezes por imagem. A aula 11 viu que a CNN tem quase dezesseis vezes os
parâmetros do MLP. Em aritmética por passo de treino, ela faz 198 vezes mais.

## A passada para a frente, e a para trás pelo dobro

**Um passo de treino custa umas três passadas para a frente.** A passada para trás de uma camada
calcula dois produtos, cada um mais ou menos do tamanho do produto da ida: o gradiente da perda em
relação aos pesos da camada, e o gradiente em relação à entrada da camada, de que a camada de baixo
precisa. O passo da CNN dá 2,97 vezes a passada para a frente dela. O do MLP dá 2,14 vezes, porque a
primeira camada lê a imagem, e ninguém precisa de gradiente para a imagem, então o segundo produto dessa
camada é pulado.

Daí sai a regra usada para estimar quanto um modelo grande vai custar antes que alguém o treine. **O
treino leva umas 6 × N × D operações**: 2 por parâmetro na ida e 4 na volta, para N parâmetros e D
exemplos vistos. Num modelo de linguagem, D conta tokens, e cada peso é usado uma vez por token, que é o
caso para o qual a regra foi feita. O MLP fica abaixo dela, com 4,2 por parâmetro, pelo motivo que acabou
de ser dado. A CNN a quebra com 52,4 por parâmetro, porque uma convolução reusa os pesos de posição em
posição. A regra vale para camadas densas, e um modelo feito de outra coisa precisa ter a aritmética
contada.

## O tempo não acompanha a aritmética, neste tamanho

Os milissegundos são os da máquina do curso, e uma leitura de relógio muda com o que mais a máquina
estiver fazendo. Os seus vão ser diferentes, então **compare as razões.** A CNN fez 198 vezes a
aritmética do MLP e levou 6,9 vezes o tempo.

O motivo é o que acontece em volta da aritmética. Todo passo paga custos fixos, seja qual for o tamanho
das matrizes: o Python chama cada camada, o PyTorch confere formas, escolhe uma rotina e aloca as saídas.
**No MLP, quase o passo inteiro é esse custo fixo**, e é por isso que as operações por segundo dele saem
tão baixas perto das da CNN. A aritmética só prevê o tempo quando cada passo tem o bastante dela para
manter o processador ocupado: camadas maiores, imagens maiores, lotes maiores.

Uma placa de vídeo deixa isso mais nítido. A aritmética dela é muitas vezes mais rápida que a de um
processador e o custo fixo por passo não é, então um modelo tão pequeno quanto estes deixa a placa
esperando a maior parte do tempo. Isso não foi executado neste curso, que não tem placa de vídeo, mas é o
motivo pelo qual um modelo pequeno numa placa cara é dinheiro gasto com espera. A aula 10 mediu o outro
tipo de espera, a dos dados.
