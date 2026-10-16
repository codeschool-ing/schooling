---
title: Levando o modelo e os lotes para o dispositivo
version: 1
---

Numa máquina com placa de vídeo, os pesos do modelo e cada lote precisam estar na memória da placa
antes que ela possa calcular com eles. **O padrão é o mesmo em quase todo programa de treino**:
escolher o dispositivo uma vez, mover o modelo uma vez e mover cada lote quando ele chega. Salve
isto como `~/dl/todevice.py`; ele treina o MLP da aula 9 por uma época e roda nesta máquina, onde o
dispositivo é o processador:

```schooling-example
{
  "language": "python",
  "file": "todevice.py",
  "parts": [
    {
      "code": "\"\"\"todevice: the device pattern of a training program, run on a machine with no graphics card.\"\"\"\nimport torch\nimport torch.nn.functional as F\nfrom torch.utils.data import DataLoader\n\nfrom dset import Digits\nfrom mlp import make_mlp\n\ndevice = torch.device(\"cuda\" if torch.cuda.is_available() else \"cpu\")\ntorch.manual_seed(0)\nmodel = make_mlp().to(device)\nopt = torch.optim.SGD(model.parameters(), lr=0.1)\nloader = DataLoader(Digits(\"train\"), batch_size=32, shuffle=True,\n                    pin_memory=device.type == \"cuda\")",
      "note": "O dispositivo é escolhido uma vez, no topo. O modelo é movido antes de o otimizador ser criado, então o otimizador guarda os parâmetros onde eles vão morar. A memória fixada só é pedida quando existe uma placa para onde copiar."
    },
    {
      "code": "for xb, yb in loader:\n    xb, yb = xb.to(device, non_blocking=True), yb.to(device, non_blocking=True)\n    loss = F.cross_entropy(model(xb), yb)\n    opt.zero_grad()\n    loss.backward()\n    opt.step()\nprint(\"device:\", device, \" batch on\", xb.device, \" pinned:\", xb.is_pinned(),\n      \" model on\", next(model.parameters()).device, \" last loss %.4f\" % loss.item())",
      "note": "Cada lote é movido quando chega, e o resultado é atribuído de volta. `non_blocking=True` deixa uma cópia da memória fixada para a placa correr enquanto o processador segue para a próxima linha; no processador, não muda nada."
    },
    {
      "code": "x = torch.zeros(3)\nx.to(torch.float64)\nprint(\"tensor after x.to(float64), result not kept:\", x.dtype)\nlayer = torch.nn.Linear(3, 2)\nlayer.to(torch.float64)\nprint(\"module after layer.to(float64), result not kept:\", layer.weight.dtype)",
      "note": "O `.to` se comporta de um jeito diferente nas duas coisas em que é chamado. Aqui um dtype faz o papel de um dispositivo, porque esta máquina só tem um dispositivo e a regra é a mesma."
    }
  ]
}
```

```
PENDING todevice
```

## O modelo uma vez, os lotes toda vez

**O `.to` num módulo move o próprio módulo**; o `.to` num tensor devolve um tensor novo e deixa o
original onde estava. As duas últimas linhas mostram a diferença com um dtype no papel de um
dispositivo: o tensor continua `float32` depois de `x.to(float64)`, e a camada virou `float64`.
Então `model.to(device)` numa linha sozinho funciona, e `xb.to(device)` numa linha sozinho não deixa
nada de duradouro. Numa placa, a linha seguinte entrega ao modelo um lote que ainda está na memória
do processador, e o PyTorch para com um erro que nomeia dois dispositivos.

O modelo é movido antes de o otimizador ser criado. A documentação do PyTorch para o `Module.cuda`
pede essa ordem: ela avisa que a mudança torna os parâmetros objetos diferentes, e um otimizador
criado antes estaria segurando os antigos.

## Memória fixada e non_blocking

Uma cópia da memória do processador para a placa é mais rápida a partir de memória **fixada**
(*pinned*): páginas que o sistema operacional prometeu não mover, que a placa consegue ler
diretamente. `pin_memory=True` faz o carregador pôr cada lote lá. Nesta máquina não há placa para
onde copiar, e o PyTorch avisa:

```
PENDING pinned
```

O aviso e o `pinned: False` são o efeito inteiro. É por isso que o `todevice.py` pede a fixação com
`pin_memory=device.type == "cuda"`, que é `False` aqui e `True` numa placa.

`non_blocking=True` deixa o processador começar a cópia e seguir para a próxima linha sem esperar
que ela termine. Isso é seguro porque a placa executa o trabalho que recebe em ordem: o passo para a
frente entra na fila atrás da cópia e lê um lote completo. **O processador usa o tempo que ganhou
para pedir o próximo lote ao carregador**, que é a mesma sobreposição que os workers compraram, um
nível abaixo. No processador, os dois argumentos não mudam nada, e a execução acima treinou como
treinaria sem eles.

## O que muda numa placa

Nada no programa. Com uma placa e o seu driver, `torch.cuda.is_available()` responde `True`, o
dispositivo vira `cuda`, os 2.410 parâmetros do modelo vão para a memória da placa, a fixação é
pedida e cada lote é copiado quando chega. Essa execução não foi feita para este curso, que não tem
placa; o programa foi escrito para que o mesmo arquivo rode nos dois.
