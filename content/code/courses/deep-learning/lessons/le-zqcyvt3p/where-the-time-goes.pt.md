---
title: Para onde vai o tempo, e a placa que espera
version: 1
---

Uma época de treino são dois tipos de tempo, revezando. **Esperar**: o programa pediu um lote ao
carregador e não pode seguir até ele chegar. **Calcular**: o passo para a frente, a perda, o passo
para trás e o passo do otimizador. Um programa que só mede a época vê a soma e não sabe qual metade
consertar. Salve isto como `~/dl/waiting.py`, que cronometra as duas separadas:

```schooling-example
{
  "language": "python",
  "file": "waiting.py",
  "parts": [
    {
      "code": "\"\"\"waiting: training on the warped digits, each epoch split into waiting for a batch and computing on it.\"\"\"\nimport time\n\nimport torch\nimport torch.nn as nn\nimport torch.nn.functional as F\nfrom torch.utils.data import DataLoader\n\nfrom dset import Digits\nfrom warp import Warp"
    },
    {
      "code": "def one_epoch(model, opt, loader):\n    wait = compute = 0.0\n    start = time.perf_counter()\n    for xb, yb in loader:\n        got = time.perf_counter()\n        loss = F.cross_entropy(model(xb), yb)\n        opt.zero_grad()\n        loss.backward()\n        opt.step()\n        done = time.perf_counter()\n        wait += got - start\n        compute += done - got\n        start = done\n    return wait, compute",
      "note": "Três relógios por lote. Do fim do último passo até o momento em que o `for` entrega um lote é espera; dali até o fim do `opt.step()` é cálculo. Os dois somados dão a época."
    },
    {
      "code": "if __name__ == \"__main__\":\n    torch.manual_seed(0)\n    train = Digits(\"train\", transform=Warp())\n    for workers in (0, 2):\n        model = nn.Sequential(nn.Flatten(), nn.Linear(1024, 256), nn.ReLU(), nn.Linear(256, 10))\n        opt = torch.optim.SGD(model.parameters(), lr=0.05)\n        loader = DataLoader(train, batch_size=32, shuffle=True, num_workers=workers,\n                            persistent_workers=workers > 0)\n        for e in (1, 2):\n            wait, compute = one_epoch(model, opt, loader)\n            print(f\"workers {workers}  epoch {e}  waiting {wait:.2f} s  computing {compute:.2f} s  \"\n                  f\"waiting share {wait / (wait + compute):.0%}\")",
      "note": "Uma rede densa para as imagens 32x32: o `nn.Flatten` transforma cada imagem 1x32x32 numa linha de 1.024, depois vem uma camada oculta de 256 unidades. Duas épocas sem workers, depois duas com dois workers."
    }
  ]
}
```

```
PENDING waiting
```

**Sem workers, 38% da segunda época foi gasto esperando**: 0,87 segundo de espera contra 1,42 de
cálculo. Os 0,87 são o entortamento, feito no processo principal entre os passos, e ficam perto dos
0,84 segundo que o `workers.py` levou para ler uma época sem modelo nenhum. **Com dois workers, a
espera caiu para 0,13 segundo, 8% da época**, porque os workers montaram os próximos lotes enquanto o
passo rodava, e o programa encontrou a maioria deles pronta quando pediu. O cálculo quase não se
mexeu, 1,42 segundo contra 1,49, então o ganho inteiro está do lado da espera.

A coluna do cálculo é grande aqui porque o modelo roda nos mesmos quatro processadores que todo o
resto, workers incluídos. A fração é uma propriedade de um programa numa máquina, e o jeito rápido de
saber onde o seu está é pôr esses dois relógios nele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 236\" role=\"img\" aria-label=\"Duas linhas do tempo de uma época de treino na mesma escala. Sem workers, o processo principal alterna entre esperar 29 ms por cada lote e calcular por 29 ms. Com dois workers, a espera por lote cai para 6 ms, enquanto o cálculo leva 29 ms.\"><text x=\"118\" y=\"54\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">sem workers</text><rect x=\"130\" y=\"40\" width=\"550\" height=\"28\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130.0\" y=\"43\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"221.7\" y=\"43\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"313.3\" y=\"43\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"405.0\" y=\"43\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"496.7\" y=\"43\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"588.3\" y=\"43\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"680\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">29 + 29</text><text x=\"625\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ms por lote</text><text x=\"118\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">dois workers</text><rect x=\"130\" y=\"110\" width=\"550\" height=\"28\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130.0\" y=\"113\" width=\"16.8\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"148.3\" y=\"113\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"240.0\" y=\"113\" width=\"16.8\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"258.3\" y=\"113\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"350.0\" y=\"113\" width=\"16.8\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"368.3\" y=\"113\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"460.0\" y=\"113\" width=\"16.8\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"478.3\" y=\"113\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"570.0\" y=\"113\" width=\"16.8\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"588.3\" y=\"113\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"680\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6 + 29</text><text x=\"632\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ms por lote</text><rect x=\"130\" y=\"189\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"152\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">esperando um lote</text><rect x=\"330\" y=\"189\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"352\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">calculando</text><text x=\"130\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">os mesmos 34 lotes, média por lote; o tempo corre para a direita</text></svg>", "caption": "Para onde vai o tempo de uma época, a partir da segunda época de cada execução do waiting.py. O âmbar é o processador esperando o carregador; com workers, os lotes são montados enquanto o passo roda."}
```

## Numa placa de vídeo

Numa placa, a coluna do cálculo é a que encolhe. O passo roda num hardware feito exatamente para
esses produtos de matrizes, enquanto o entortamento continua rodando no processador, imagem por
imagem, como rodou aqui. **A espera não encolhe junto.** Sem workers, a placa calcula por alguns
milissegundos e depois fica parada pelo tempo que o processador leva para entortar as próximas 32
imagens. Com workers, o passo agora é curto demais para esconder muito da montagem atrás dele, então
a espera por lote volta a crescer. Seja qual for a placa, uma época não pode levar menos tempo do
que o carregador sozinho levou no `workers.py`.

É essa a situação que o título desta aula descreve, e ela é comum: uma placa cara, comprada para
treinar mais rápido, sem fazer nada na maior parte de cada segundo porque o processador não consegue
alimentá-la. O conserto está do lado do carregador, não da placa: mais workers enquanto houver
processadores livres, uma transformação mais barata, ou a parte da transformação que não é aleatória
feita uma vez e guardada.

## Vendo isso numa placa

Numa máquina com placa NVIDIA, o driver traz uma ferramenta que mostra o quanto a placa está
ocupada. **Este curso não tem placa, então os comandos abaixo não foram executados para ele**:

```
nvidia-smi
nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv -l 1
```

O primeiro imprime uma tabela com cada placa, a sua memória e os processos que a usam; o segundo
imprime uma linha por segundo com os dois números pedidos. `utilization.gpu` é a fração do último
período de amostragem em que a placa estava rodando qualquer coisa. Um treino que a mantém perto de
100% está calculando a maior parte do tempo; um que fica em 30 ou 40% está esperando por algo a
maior parte do tempo, e o carregador é o primeiro suspeito. O número não diz o quanto a placa é bem
usada enquanto roda, só com que frequência ela roda, e os dois relógios do `waiting.py` é que dizem
por quê.
