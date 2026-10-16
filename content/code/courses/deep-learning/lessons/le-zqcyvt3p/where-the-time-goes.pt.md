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
ana@vm:~/dl$ python waiting.py
workers 0  epoch 1  waiting 2.05 s  computing 0.09 s  waiting share 96%
workers 0  epoch 2  waiting 1.88 s  computing 0.12 s  waiting share 94%
workers 2  epoch 1  waiting 0.28 s  computing 1.38 s  waiting share 17%
workers 2  epoch 2  waiting 0.20 s  computing 1.51 s  waiting share 12%
```

**Sem workers, 94% da segunda época foi gasto esperando**: 1,88 segundo de espera contra 0,12 de
cálculo. Os 1,88 são o entortamento, feito no processo principal entre os passos, e ficam perto dos
1,97 segundo que o `workers.py` levou para ler uma época sem modelo nenhum. A rede em si é pequena o
bastante para que os seus 34 passos levem cerca de um décimo de segundo. **Esta máquina já está na
situação que o título da aula descreve**: a parte que aprende fica parada quase o tempo todo,
esperando a parte que prepara os dados.

**Com dois workers, a espera caiu para 0,20 segundo**, porque os workers montaram os próximos lotes
enquanto o passo rodava, e o programa encontrou a maioria deles pronta quando pediu. **E o cálculo
cresceu de 0,12 segundo para 1,51.** O passo não ganhou mais trabalho: ganhou menos processadores. O
PyTorch roda os produtos de matrizes do passo em threads espalhadas pelos quatro processadores, e
dois desses processadores agora estavam ocupados entortando imagens. Numa máquina sem placa de
vídeo, os workers e o modelo usam os mesmos quatro processadores, então a época foi de 2,00 segundos
para 1,71, e não para o 1,01 que o carregador sozinho conseguiu com dois workers.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 236\" role=\"img\" aria-label=\"Duas linhas do tempo de uma época de treino na mesma escala. Sem workers, o processo principal alterna entre esperar 55 ms por cada lote e calcular por 4 ms. Com dois workers, a espera por lote cai para 6 ms, enquanto o cálculo leva 44 ms.\"><text x=\"118\" y=\"54\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">sem workers</text><rect x=\"130\" y=\"40\" width=\"550\" height=\"28\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130.0\" y=\"43\" width=\"170.8\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"302.3\" y=\"43\" width=\"9.5\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"313.3\" y=\"43\" width=\"170.8\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"485.7\" y=\"43\" width=\"9.5\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"496.7\" y=\"43\" width=\"170.8\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"669.0\" y=\"43\" width=\"9.5\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"680\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">55 ms + 4 ms</text><text x=\"118\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">dois workers</text><rect x=\"130\" y=\"110\" width=\"550\" height=\"28\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130.0\" y=\"113\" width=\"16.8\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"148.3\" y=\"113\" width=\"136.9\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"286.8\" y=\"113\" width=\"16.8\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"305.1\" y=\"113\" width=\"136.9\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"443.5\" y=\"113\" width=\"16.8\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"461.8\" y=\"113\" width=\"136.9\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"600.2\" y=\"113\" width=\"16.8\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"618.6\" y=\"113\" width=\"59.9\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"680\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6 ms + 44 ms</text><rect x=\"130\" y=\"189\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"152\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">esperando um lote</text><rect x=\"330\" y=\"189\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"352\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">calculando</text><text x=\"130\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">os mesmos 34 lotes, média por lote; o tempo corre para a direita</text></svg>", "caption": "Para onde vai o tempo de uma época, a partir da segunda época de cada execução do waiting.py. Cada par de blocos é um lote: a espera por ele, depois o passo. Com workers, a espera quase some e o passo cresce, porque os workers e o passo dividem os quatro processadores."}
```

## Numa placa de vídeo

Numa placa, as duas metades se separam. O passo roda num hardware próprio, feito exatamente para
esses produtos de matrizes, e os workers deixam de tirar algo dele. **O que sobra é a espera.** Sem
workers, a placa calcula por um instante e depois fica parada enquanto o processador entorta as
próximas 32 imagens, o que aqui seria cerca de 94% de cada época. Com workers, a montagem acontece
por trás do passo, mas o passo agora é tão curto que esconde pouco dela. **Seja qual for a placa,
uma época não pode levar menos tempo que o carregador sozinho**: 1,01 segundo com dois workers e
0,56 com quatro, nesta máquina, pelo `workers.py`.

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
