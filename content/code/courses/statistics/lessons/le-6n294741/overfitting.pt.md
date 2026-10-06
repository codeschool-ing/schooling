---
title: Preditores demais
version: 1
---

Todo preditor acrescentado a uma regressão aumenta o R², ou na pior das hipóteses o deixa igual. Os mínimos quadrados sempre conseguem usar uma coluna extra para ajustar os dados um pouco melhor, mesmo uma coluna de puro ruído. Isso faz do R² um guia fraco para saber se um preditor pertence a um modelo.

## R² ajustado

O **R² ajustado** cobra uma penalidade por preditor:

**R² ajustado = 1 − (1 − R²) × (n − 1) ÷ (n − k − 1)**

em que *k* é o número de preditores. Um preditor que acrescenta menos que o seu custo o abaixa.

Aqui está o modelo de três preditores da Horta com colunas de números aleatórios acrescentadas, que por construção não têm nada a ver com os tempos de entrega:

| colunas de ruído acrescentadas | R² | R² ajustado |
|---|---|---|
| 0 | 0,9098 | 0,9075 |
| 5 | 0,9112 | 0,9048 |
| 10 | 0,9157 | 0,9053 |
| 20 | 0,9221 | 0,9035 |
| 30 | 0,9337 | 0,9082 |

O R² sobe sem parar. O R² ajustado na maior parte cai, mas com 30 colunas de ruído termina um pouco **acima** de onde começou: algumas dessas colunas aleatórias por acaso se alinham com os resíduos destas 120 entregas. O R² ajustado é uma correção, não uma garantia.

## Testando em dados que o modelo não viu

O teste honesto de um modelo é como ele prevê dados **novos**. Divida as entregas: ajuste cada modelo em 60, depois preveja as outras 60.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 300\" role=\"img\" data-fig=\"l19-overfit\" aria-label=\"Erro típico de previsão, em minutos, de dois modelos ajustados a 60 entregas e depois testados nas outras 60. Com distância, itens e chuva: 2,98 nas entregas em que foi ajustado e 3,38 em entregas novas. Com 30 colunas de ruído aleatório acrescentadas: 1,81 nas próprias entregas e 5,84 nas novas.\"><path d=\"M70.0 50.0 L70.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 250.0 L70.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 221.4 L580.0 221.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 221.4 L70.0 221.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"221.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M70.0 192.9 L580.0 192.9\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 192.9 L70.0 192.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"192.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M70.0 164.3 L580.0 164.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 164.3 L70.0 164.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"164.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><path d=\"M70.0 135.7 L580.0 135.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 135.7 L70.0 135.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"135.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M70.0 107.1 L580.0 107.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 107.1 L70.0 107.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"107.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M70.0 78.6 L580.0 78.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 78.6 L70.0 78.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"78.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M70.0 50.0 L580.0 50.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 50.0 L70.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><text x=\"70.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">erro típico (minutos)</text><path d=\"M126.1 250.0 L126.1 164.9 L192.4 164.9 L192.4 250.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"var(--phosphor-dim)\"></path><text x=\"159.2\" y=\"155.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2,98</text><path d=\"M202.6 250.0 L202.6 153.4 L268.9 153.4 L268.9 250.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"var(--amber)\"></path><text x=\"235.8\" y=\"144.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3,38</text><text x=\"197.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3 preditores reais</text><path d=\"M381.1 250.0 L381.1 198.4 L447.4 198.4 L447.4 250.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"var(--phosphor-dim)\"></path><text x=\"414.2\" y=\"189.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1,81</text><path d=\"M457.6 250.0 L457.6 83.3 L523.9 83.3 L523.9 250.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"var(--amber)\"></path><text x=\"490.8\" y=\"74.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5,84</text><text x=\"452.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">+ 30 de ruído</text><path d=\"M70.0 250.0 L580.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"330.0\" y=\"12.0\" width=\"12.0\" height=\"12.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"348.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">entregas do ajuste</text><rect x=\"470.0\" y=\"12.0\" width=\"12.0\" height=\"12.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"488.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">entregas novas</text></svg>", "caption": "O modelo recheado de ruído se ajusta melhor aos próprios dados e prevê dados novos muito pior. Ele aprendeu os acidentes de 60 entregas em particular."}
```

Com distância, itens e chuva, o erro típico é **2,98 minutos** nas 60 entregas usadas no ajuste e **3,38** nas novas: um pouco pior, como esperado. Com as 30 colunas de ruído, o modelo se ajusta muito melhor às suas 60, **1,81 minuto**, e o R² nelas é 0,969. Nas 60 novas o erro típico é **5,84** minutos, pior que só a distância. Ele decorou os acidentes de 60 entregas em particular e tirou deles as lições erradas.

Isso é **sobreajuste**, e é o problema central de todo modelo preditivo, de uma regressão com quatro colunas aos modelos do curso de aprendizado de máquina, que constrói seus métodos em torno dessa divisão.

## Regras práticas

- **Escolha os preditores por um motivo.** Cada um deve ter um papel plausível, decidido antes de olhar os resultados.
- **Mantenha o número de preditores pequeno em relação aos dados.** Uma regra prática comum pede pelo menos dez a vinte observações por preditor.
- **Julgue um modelo preditivo em dados em que ele não foi ajustado.**
- **Prefira o modelo mais simples quando dois preveem mais ou menos igual.** Ele é mais fácil de explicar, e menos provável de ter aprendido ruído.
