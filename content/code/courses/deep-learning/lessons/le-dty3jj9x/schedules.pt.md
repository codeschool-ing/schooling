---
title: "Agendamentos: mudar a taxa conforme o treino anda"
version: 1
---

Uma taxa fixa é um meio-termo. No começo os pesos estão longe de qualquer coisa boa, e passos grandes
os levam até lá depressa. No fim do treino os mesmos passos os deixam tremendo em volta do mínimo,
porque o ruído de lote da primeira seção não encolhe perto do fundo. **Um agendamento é uma função da época
para uma taxa**, e o laço define `opt.lr` a partir dela antes de cada época. Salve como
`~/dl/schedules.py`:

```schooling-example
{
  "language": "python",
  "file": "schedules.py",
  "parts": [
    {
      "code": "\"\"\"schedules: three ways to change the learning rate as the epochs go by, and a run with each.\"\"\"\nimport math\n\nimport numpy as np\n\nimport digits\nimport optim\nfrom fit import fit\nfrom tinynet import Linear, ReLU, Net\n\nEPOCHS, TOP = 20, 0.1",
      "note": "Vinte épocas, e uma taxa máxima de 0,1 para o Adam: a taxa em que o Adam da varredura já tinha caído de 0,969 para 0,894."
    },
    {
      "code": "def constant(epoch):\n    return TOP\n\n\ndef step_decay(epoch):\n    \"\"\"The top rate for 8 epochs, a tenth of it for the next 8, a hundredth after.\"\"\"\n    return TOP * 0.1 ** ((epoch - 1) // 8)",
      "note": "Um agendamento é uma função da época para uma taxa. O decaimento em degraus divide a taxa por dez em épocas fixas, aqui depois da 8 e depois da 16."
    },
    {
      "code": "def cosine(epoch, start=1, length=EPOCHS):\n    \"\"\"Half a cosine wave, from the top rate down towards zero.\"\"\"\n    return TOP * 0.5 * (1 + math.cos(math.pi * (epoch - start) / length))",
      "note": "O decaimento cosseno desliza da taxa máxima para perto de zero ao longo de meia onda de cosseno: devagar no começo, mais rápido no meio, devagar de novo no fim."
    },
    {
      "code": "def warmup_cosine(epoch, warm=3):\n    \"\"\"A straight climb for `warm` epochs, then the cosine over what is left.\"\"\"\n    if epoch <= warm:\n        return TOP * epoch / warm\n    return cosine(epoch, start=warm, length=EPOCHS - warm + 1)",
      "note": "O aquecimento sobe de um terço da taxa até ela inteira em três épocas, e então passa a vez ao cosseno. Os primeiros passos de uma rede nova são os maiores e os menos confiáveis, e o aquecimento os mantém pequenos."
    },
    {
      "code": "SCHEDULES = [constant, step_decay, cosine, warmup_cosine]\nprint(\"epoch\" + \"\".join(f\"{s.__name__:>15}\" for s in SCHEDULES))\nfor epoch in range(1, EPOCHS + 1):\n    print(f\"{epoch:5d}\" + \"\".join(f\"{s(epoch):15.5f}\" for s in SCHEDULES))",
      "note": "Os quatro agendamentos como números, uma linha por época."
    },
    {
      "code": "train, val, _ = digits.load()\nfor schedule in SCHEDULES:\n    rng = np.random.default_rng(0)\n    net = Net(Linear(64, 32, rng), ReLU(), Linear(32, 10, rng))\n    opt = optim.Adam(net.params(), lr=TOP)\n    for epoch in range(1, EPOCHS + 1):\n        opt.lr = schedule(epoch)\n        history = fit(net, opt, train, val, epochs=1, seed=epoch, every=100)\n    val_loss, val_acc = history[-1][2:]\n    print(f\"Adam at {TOP} with {schedule.__name__:<14} val loss {val_loss:.4f}  val acc {val_acc:.3f}\")",
      "note": "A mesma rede e a mesma semente quatro vezes. Antes de cada época o agendamento define `opt.lr`, e o `fit` roda aquela época; `seed=epoch` dá a cada época um embaralhamento diferente, como uma chamada longa do `fit` daria."
    }
  ]
}
```

```
ana@vm:~/dl$ python schedules.py
epoch       constant     step_decay         cosine  warmup_cosine
    1        0.10000        0.10000        0.10000        0.03333
    2        0.10000        0.10000        0.09938        0.06667
    3        0.10000        0.10000        0.09755        0.10000
    4        0.10000        0.10000        0.09455        0.09924
    5        0.10000        0.10000        0.09045        0.09698
    6        0.10000        0.10000        0.08536        0.09330
    7        0.10000        0.10000        0.07939        0.08830
    8        0.10000        0.10000        0.07270        0.08214
    9        0.10000        0.01000        0.06545        0.07500
   10        0.10000        0.01000        0.05782        0.06710
   11        0.10000        0.01000        0.05000        0.05868
   12        0.10000        0.01000        0.04218        0.05000
   13        0.10000        0.01000        0.03455        0.04132
   14        0.10000        0.01000        0.02730        0.03290
   15        0.10000        0.01000        0.02061        0.02500
   16        0.10000        0.01000        0.01464        0.01786
   17        0.10000        0.00100        0.00955        0.01170
   18        0.10000        0.00100        0.00545        0.00670
   19        0.10000        0.00100        0.00245        0.00302
   20        0.10000        0.00100        0.00062        0.00076
Adam at 0.1 with constant       val loss 0.2262  val acc 0.950
Adam at 0.1 with step_decay     val loss 0.0681  val acc 0.978
Adam at 0.1 with cosine         val loss 0.1713  val acc 0.953
Adam at 0.1 with warmup_cosine  val loss 0.0966  val acc 0.964
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"A taxa de aprendizado de quatro agendamentos ao longo de 20 épocas, de 0 a 0,1. O constante fica em 0,1. O decaimento em degraus mantém 0,1 por 8 épocas, cai para 0,01 por 8 e para 0,001 nas últimas 4. O cosseno começa em 0,1 e desce em curva até perto de zero na época 20. O aquecimento com cosseno sobe em linha reta de 0,033 a 0,1 nas três primeiras épocas, depois segue o seu próprio cosseno até perto de zero.\"><path d=\"M80 240 L560 240\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 240 L80 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"70\" y=\"135.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.05</text><text x=\"70\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.1</text><text x=\"80.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"181.05263157894737\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"307.36842105263156\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><text x=\"433.6842105263158\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">15</text><text x=\"560.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><text x=\"320.0\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">época</text><text x=\"88\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">taxa de aprendizado</text><path d=\"M80.0 30.0 L105.3 30.0 L130.5 30.0 L155.8 30.0 L181.1 30.0 L206.3 30.0 L231.6 30.0 L256.8 30.0 L282.1 30.0 L307.4 30.0 L332.6 30.0 L357.9 30.0 L383.2 30.0 L408.4 30.0 L433.7 30.0 L458.9 30.0 L484.2 30.0 L509.5 30.0 L534.7 30.0 L560.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2.2\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M580 50 L606 50\" stroke=\"var(--paper-dim)\" stroke-width=\"2.2\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"612\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">constant</text><path d=\"M80.0 30.0 L80.0 30.0 L105.3 30.0 L130.5 30.0 L155.8 30.0 L181.1 30.0 L206.3 30.0 L231.6 30.0 L256.8 30.0 L269.5 30.0 L269.5 219.0 L282.1 219.0 L307.4 219.0 L332.6 219.0 L357.9 219.0 L383.2 219.0 L408.4 219.0 L433.7 219.0 L458.9 219.0 L471.6 219.0 L471.6 237.9 L484.2 237.9 L509.5 237.9 L534.7 237.9 L560.0 237.9\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M580 76 L606 76\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"612\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">step_decay</text><path d=\"M80.0 30.0 L105.3 31.3 L130.5 35.1 L155.8 41.4 L181.1 50.1 L206.3 60.7 L231.6 73.3 L256.8 87.3 L282.1 102.6 L307.4 118.6 L332.6 135.0 L357.9 151.4 L383.2 167.4 L408.4 182.7 L433.7 196.7 L458.9 209.3 L484.2 219.9 L509.5 228.6 L534.7 234.9 L560.0 238.7\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M580 102 L606 102\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"612\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cosine</text><path d=\"M80.0 170.0 L105.3 100.0 L130.5 30.0 L155.8 31.6 L181.1 36.3 L206.3 44.1 L231.6 54.6 L256.8 67.5 L282.1 82.5 L307.4 99.1 L332.6 116.8 L357.9 135.0 L383.2 153.2 L408.4 170.9 L433.7 187.5 L458.9 202.5 L484.2 215.4 L509.5 225.9 L534.7 233.7 L560.0 238.4\" stroke=\"var(--paper)\" stroke-width=\"2.2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M580 128 L606 128\" stroke=\"var(--paper)\" stroke-width=\"2.2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"612\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">warmup_cosine</text></svg>", "caption": "Os quatro agendamentos do `schedules.py`, desenhados a partir da tabela que ele imprimiu."}
```

As quatro execuções usam o Adam com taxa máxima de 0,1, que a varredura mostrou ser alta demais. **O
que o agendamento fez com essa taxa alta demais é o resultado**:

| agendamento | perda de validação | acurácia de validação |
| --- | --- | --- |
| constante | 0,2262 | 0,950 |
| decaimento em degraus | 0,0681 | 0,978 |
| cosseno | 0,1713 | 0,953 |
| aquecimento e depois cosseno | 0,0966 | 0,964 |

**O decaimento em degraus foi o melhor aqui, e o motivo está na tabela de taxas.** Ele passou oito
épocas em 0,1, oito em 0,01 e as últimas quatro em 0,001, e a varredura já tinha achado 0,01 entre as
melhores taxas do Adam. O cosseno ainda está em 0,05782 na época 10 e só cai abaixo de 0,01 nas
últimas quatro épocas, então passou a maior parte da execução alto demais. **O aquecimento ajudou o
cosseno**: a mesma curva com três primeiras épocas mais suaves terminou numa perda de validação de
0,0966 em vez de 0,1713.

Leia a linha constante contra a varredura. A configuração é a mesma, Adam em 0,1 por 20 épocas, e a
varredura imprimiu 0,894 onde esta imprime 0,950. A única mudança é o embaralhamento: o `sweep.py`
sorteou uma ordem de lotes por época a partir de um único gerador, e este laço dá a cada época a sua
própria semente. **Uma ordem diferente dos mesmos lotes mexeu a acurácia em 0,056**, e é por isso que
nenhuma linha desta tabela decide nada sozinha.

Qual agendamento usar é sobretudo convenção, e vale conhecer as convenções:

- **O decaimento em degraus** é o clássico. As ResNets originais foram treinadas em 0,1, dividida por
  dez duas vezes conforme o treino andava, e a aula 12 é sobre essas redes.
- **O cosseno** não tem nada a escolher além do comprimento, e é por isso que virou um padrão comum.
- **Aquecimento seguido de decaimento** é como transformers são treinados, porque os primeiros passos
  do Adam numa rede nova e profunda são os menos confiáveis. A aula 15 monta um.
- **Baixar a taxa quando a perda de validação para de melhorar** reage à execução em vez de seguir um
  plano. O PyTorch chama isso de `ReduceLROnPlateau`.

**Um agendamento não é um jeito de escapar de escolher a taxa.** O decaimento em degraus ganhou
porque as suas últimas épocas rodaram em taxas que a varredura já tinha achado boas. A taxa veio
primeiro, e o agendamento só decidiu quando usar cada uma.
