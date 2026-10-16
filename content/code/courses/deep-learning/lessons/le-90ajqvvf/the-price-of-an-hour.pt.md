---
title: stub
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "bill.py",
  "parts": [
    {
      "code": "\"\"\"bill: what training costs, from a time and a price per hour that you look up yourself.\"\"\"\nimport sys\n\nPRICE_PER_HOUR = 2.50   # ILLUSTRATIVE, set in October 2026 for the arithmetic. Not a quote.\n\nseconds = float(sys.argv[1])\nhours = seconds / 3600\nprint(f\"this run: {seconds:.0f} s = {hours:.4f} h, {hours * PRICE_PER_HOUR:.4f} at {PRICE_PER_HOUR:.2f} an hour\")",
      "note": "O preço é uma variável no topo, sem moeda, porque é o único número aqui que você precisa fornecer. 2,50 por hora foi escolhido para deixar a conta legível, em outubro de 2026, e não é o que algum provedor cobra. O tempo de uma execução chega pela linha de comando."
    },
    {
      "code": "# A large language model, by the 6 x N x D rule. Every number below is an assumption.\nN = 7e9         # parameters\nD = 20 * N      # training tokens, about twenty per parameter\nPEAK = 1e15     # FLOP/s that a card's data sheet promises in bfloat16\nKEPT = 0.40     # the share of that peak a real training job sustains\n\nflops = 6 * N * D\ncard_hours = flops / (PEAK * KEPT) / 3600\nprint(f\"6 x N x D = {flops:.2e} FLOPs\")\nprint(f\"{card_hours:,.0f} card-hours, {card_hours * PRICE_PER_HOUR:,.0f} at {PRICE_PER_HOUR:.2f} an hour\")\nfor cards in (8, 256):\n    print(f\"  on {cards:3d} cards: {card_hours / cards / 24:5.1f} days\")",
      "note": "Quatro suposições, cada uma em sua linha para poder ser mudada. Vinte tokens por parâmetro é a proporção que um estudo de 2022 de Hoffmann e colegas achou o melhor uso de um orçamento fixo. Mil trilhões de operações por segundo é a ordem de grandeza que as fichas técnicas davam para placas grandes em bfloat16, e 40% disso é uma fração que treinos reais alcançam quando bem ajustados."
    }
  ]
}
```
