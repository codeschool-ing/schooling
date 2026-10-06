---
title: Too many predictors
version: 1
---

Every predictor added to a regression raises R², or at worst leaves it the same. Least squares can always use an extra column to fit the data a little better, even a column of pure noise. That makes R² a poor guide to whether a predictor belongs in a model.

## Adjusted R²

**Adjusted R²** charges a penalty for each predictor:

**adjusted R² = 1 − (1 − R²) × (n − 1) ÷ (n − k − 1)**

where *k* is the number of predictors. A predictor that adds less than its cost lowers it.

Here is Horta's three-predictor model with columns of random numbers added, which by construction have nothing to do with delivery times:

| noise columns added | R² | adjusted R² |
|---|---|---|
| 0 | 0.9098 | 0.9075 |
| 5 | 0.9112 | 0.9048 |
| 10 | 0.9157 | 0.9053 |
| 20 | 0.9221 | 0.9035 |
| 30 | 0.9337 | 0.9082 |

R² climbs steadily. Adjusted R² mostly falls, but with 30 noise columns it ends slightly **above** where it started: some of those random columns happen to line up with the residuals of these 120 deliveries. Adjusted R² is a correction, not a guarantee.

## Testing on data the model has not seen

The honest test of a model is how it predicts **new** data. Split the deliveries: fit each model on 60, then predict the other 60.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 300\" role=\"img\" data-fig=\"l19-overfit\" aria-label=\"Typical prediction error, in minutes, for two models fitted to 60 deliveries and then tried on the other 60. With distance, items and rain: 2.98 on the deliveries it was fitted to and 3.38 on new ones. With 30 columns of random noise added: 1.81 on its own deliveries and 5.84 on new ones.\"><path d=\"M70.0 50.0 L70.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 250.0 L70.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 221.4 L580.0 221.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 221.4 L70.0 221.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"221.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M70.0 192.9 L580.0 192.9\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 192.9 L70.0 192.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"192.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M70.0 164.3 L580.0 164.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 164.3 L70.0 164.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"164.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><path d=\"M70.0 135.7 L580.0 135.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 135.7 L70.0 135.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"135.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M70.0 107.1 L580.0 107.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 107.1 L70.0 107.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"107.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M70.0 78.6 L580.0 78.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 78.6 L70.0 78.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"78.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M70.0 50.0 L580.0 50.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 50.0 L70.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><text x=\"70.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">typical error (minutes)</text><path d=\"M126.1 250.0 L126.1 164.9 L192.4 164.9 L192.4 250.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"var(--phosphor-dim)\"></path><text x=\"159.2\" y=\"155.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2.98</text><path d=\"M202.6 250.0 L202.6 153.4 L268.9 153.4 L268.9 250.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"var(--amber)\"></path><text x=\"235.8\" y=\"144.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3.38</text><text x=\"197.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3 real predictors</text><path d=\"M381.1 250.0 L381.1 198.4 L447.4 198.4 L447.4 250.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"var(--phosphor-dim)\"></path><text x=\"414.2\" y=\"189.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1.81</text><path d=\"M457.6 250.0 L457.6 83.3 L523.9 83.3 L523.9 250.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"var(--amber)\"></path><text x=\"490.8\" y=\"74.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5.84</text><text x=\"452.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">+ 30 of noise</text><path d=\"M70.0 250.0 L580.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"330.0\" y=\"12.0\" width=\"12.0\" height=\"12.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"348.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fitted deliveries</text><rect x=\"470.0\" y=\"12.0\" width=\"12.0\" height=\"12.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"488.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new deliveries</text></svg>", "caption": "The model stuffed with noise fits its own data better and predicts new data far worse. It has learnt the accidents of 60 particular deliveries."}
```

With distance, items and rain, the typical error is **2.98 minutes** on the 60 deliveries used for fitting and **3.38** on the new ones: a little worse, as expected. With the 30 noise columns added, the model fits its own 60 far better, **1.81 minutes**, and its R² on them is 0.969. On the new 60 its typical error is **5.84** minutes, worse than distance alone. It has memorised the accidents of 60 particular deliveries and learnt the wrong lessons from them.

This is **overfitting**, and it is the central problem of every predictive model, from a regression with four columns to the models of the machine-learning course, which builds its methods around this split.

## Practical rules

- **Choose predictors for a reason.** Each should have a plausible role, decided before looking at the results.
- **Keep the number of predictors small relative to the data.** A common rule of thumb asks for at least ten to twenty observations per predictor.
- **Judge a predictive model on data it was not fitted to.**
- **Prefer the simpler model when two predict about equally well.** It is easier to explain, and less likely to have learnt noise.
