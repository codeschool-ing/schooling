---
title: Workers, e a leitura em paralelo
version: 1
---

Com o padrão `num_workers=0`, o carregador monta cada lote dentro do próprio processo do programa de
treino: o programa pede um lote, espera enquanto 32 imagens são entortadas uma depois da outra, e só
então segue com o passo. **`num_workers=n` inicia n processos extras que montam lotes por conta
própria**, cada um um lote inteiro por vez, e os mandam de volta ao processo principal. Enquanto o
modelo trabalha num lote, os workers já estão entortando os próximos.

Quantos workers fazem sentido depende de quantos processadores existem. O laboratório tem quatro:

```
PENDING workers
```

Salve isto como `~/dl/workers.py`. Ele lê o conjunto de treino entortado três vezes com cada
configuração e não treina nada, então o que ele mede é só o carregador:

```schooling-example
{
  "language": "python",
  "file": "workers.py",
  "parts": [
    {
      "code": "\"\"\"workers: three epochs of reading the warped digits, with 0, 2 and 4 worker processes.\"\"\"\nimport time\n\nfrom torch.utils.data import DataLoader\n\nfrom dset import Digits\nfrom warp import Warp",
      "note": "Nenhum modelo: este programa mede só o carregador, que é o mínimo que uma época pode durar."
    },
    {
      "code": "if __name__ == \"__main__\":\n    train = Digits(\"train\", transform=Warp())\n    fastest = {}\n    for workers in (0, 2, 4):\n        loader = DataLoader(train, batch_size=32, shuffle=True, num_workers=workers,\n                            persistent_workers=workers > 0)",
      "note": "O `num_workers` é o número de processos extras que leem itens e montam lotes. `persistent_workers=True` os mantém vivos entre épocas; sem isso, eles são iniciados de novo a cada época. A proteção `if __name__` importa onde os workers são iniciados do zero, e não copiados do programa em execução, como no macOS e no Windows."
    },
    {
      "code": "        times = []\n        for epoch in range(3):\n            start = time.perf_counter()\n            for xb, yb in loader:\n                pass\n            times.append(time.perf_counter() - start)\n        fastest[workers] = min(times)\n        print(f\"num_workers={workers}  epochs \" + \"  \".join(f\"{t:.2f} s\" for t in times)\n              + f\"   fastest {fastest[0] / fastest[workers]:.1f}x the speed of 0 workers\")",
      "note": "Três épocas cada, todo lote recebido e jogado fora. A comparação usa a época mais rápida de cada configuração, a menos perturbada pelo que mais a máquina estivesse fazendo."
    }
  ]
}
```

```
PENDING workers
```

**Dois workers leem uma época 2,1 vezes mais rápido que nenhum, e quatro workers 2,6 vezes**: de
0,84 segundo no melhor caso para 0,39 e para 0,32. Quatro workers não são quatro vezes mais rápidos,
porque a máquina tem quatro processadores e o processo principal também precisa de um deles, para
receber os lotes. Passado o número de processadores livres, um worker extra só se reveza com os
outros. São os tempos desta máquina no momento da execução; nos seus, os segundos vão ser outros, e
o formato, mais workers mais rápido até os processadores acabarem, é o que esperar.

**A primeira época é a mais lenta de cada linha**, e com workers ela também inclui iniciar os
processos e entregar a cada um uma cópia do dataset. `persistent_workers=True` os mantém vivos depois disso; sem
ele, toda época pagaria a partida de novo, o que é um custo real quando as épocas são curtas.

**O carregador sozinho é um piso.** Uma época de treino não pode ser mais curta que o tempo de
montar os seus lotes, por mais rápido que seja o modelo, então esse número é o primeiro a conhecer em
qualquer configuração de treino. E numa máquina sem placa de vídeo, os workers disputam com o modelo
os mesmos processadores, o que a próxima seção mede.

## Cada worker é uma cópia

Um worker é um processo separado, com a sua própria cópia do dataset e da transformação dentro dele.
O PyTorch semeia de um jeito diferente, em cada worker, os geradores aleatórios que conhece: o dele,
o módulo `random` do Python e o gerador global do NumPy. É por isso que o `Warp`, que sorteia com
`torch.rand`, não precisou de nada. **Um objeto gerador seu é outra história**: ele é copiado para
cada worker no estado em que estava, e todo worker passa a sortear os mesmos números. Salve como
`~/dl/twins.py`:

```schooling-example
{
  "language": "python",
  "file": "twins.py",
  "parts": [
    {
      "code": "\"\"\"twins: a transform holding a NumPy generator, read by two workers, before and after reseeding them.\"\"\"\nimport numpy as np\nimport torch\nfrom torch.utils.data import DataLoader, get_worker_info\n\nfrom dset import Digits\n\n\nclass Jitter:\n    def __init__(self):\n        self.rng = np.random.default_rng(0)\n\n    def __call__(self, img):\n        return img + torch.from_numpy(self.rng.normal(0, 0.1, img.shape).astype(np.float32))",
      "note": "Uma transformação que soma ruído sorteado pelo seu próprio gerador do NumPy, criado uma vez no `__init__`. Num processo só, não há nada de errado com ela."
    },
    {
      "code": "def reseed(worker_id):\n    info = get_worker_info()\n    info.dataset.transform.rng = np.random.default_rng(info.seed)",
      "note": "Uma `worker_init_fn` roda uma vez dentro de cada worker quando ele começa. O `get_worker_info()` dá a cópia do dataset daquele worker e uma semente que o PyTorch escolheu para ele, diferente em cada worker."
    },
    {
      "code": "if __name__ == \"__main__\":\n    torch.manual_seed(0)\n    clean = Digits(\"train\")\n    for init in (None, reseed):\n        loader = DataLoader(Digits(\"train\", transform=Jitter()), batch_size=4,\n                            num_workers=2, worker_init_fn=init)\n        batches = iter(loader)\n        first, second = next(batches)[0], next(batches)[0]\n        noise0 = first - clean.x[0:4]\n        noise1 = second - clean.x[4:8]\n        print(f\"worker_init_fn={getattr(init, '__name__', None)}\")\n        print(\"  batch 0, from worker 0, noise begins\", [round(v, 4) for v in noise0[0, :3].tolist()])\n        print(\"  batch 1, from worker 1, noise begins\", [round(v, 4) for v in noise1[0, :3].tolist()])\n        print(\"  the same noise:\", torch.allclose(noise0, noise1, atol=1e-6))",
      "note": "Sem embaralhar, o lote 0 é montado pelo worker 0 e o lote 1 pelo worker 1. Subtrair as imagens limpas deixa o ruído que cada worker somou, comparado com e sem o `reseed`."
    }
  ]
}
```

```
PENDING twins
```

Sem ajuda, o ruído do lote 0 e o do lote 1 começam com os mesmos três números: dois workers, uma
sequência só de ruído, e um aumento de dados que se repete entre os lotes. Nada falha e nada avisa.
O `reseed`, passado como `worker_init_fn`, dá à cópia de cada worker um gerador próprio, a partir da
semente que o PyTorch escolheu para aquele worker, e os dois lotes se separam.
