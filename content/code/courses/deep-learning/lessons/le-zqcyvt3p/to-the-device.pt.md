---
title: to-the-device
version: 1
---

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
