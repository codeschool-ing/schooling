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
      "note": "The device is chosen once, at the top. The model moves before the optimiser is made, so the optimiser holds the parameters where they will live. Pinned memory is asked for only when there is a card to copy to."
    },
    {
      "code": "for xb, yb in loader:\n    xb, yb = xb.to(device, non_blocking=True), yb.to(device, non_blocking=True)\n    loss = F.cross_entropy(model(xb), yb)\n    opt.zero_grad()\n    loss.backward()\n    opt.step()\nprint(\"device:\", device, \" batch on\", xb.device, \" pinned:\", xb.is_pinned(),\n      \" model on\", next(model.parameters()).device, \" last loss %.4f\" % loss.item())",
      "note": "Each batch is moved as it arrives, and the result is assigned back. `non_blocking=True` lets a copy from pinned memory to the card run while the processor goes on to the next line; on the processor it changes nothing."
    },
    {
      "code": "x = torch.zeros(3)\nx.to(torch.float64)\nprint(\"tensor after x.to(float64), result not kept:\", x.dtype)\nlayer = torch.nn.Linear(3, 2)\nlayer.to(torch.float64)\nprint(\"module after layer.to(float64), result not kept:\", layer.weight.dtype)",
      "note": "`.to` behaves differently on the two things it is called on. A dtype stands in for a device here, because this machine has only one device and the rule is the same."
    }
  ]
}
```
