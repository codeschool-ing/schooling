---
title: A dispersão de uma configuração
version: 1
---

Uma execução sozinha responde *quanto esta semente obteve*. A pergunta que todo mundo de fato faz é
*quanto esta configuração obtém*, e **uma semente não consegue respondê-la, porque a semente também
mexe no resultado.** O jeito de ver quanto é não mudar nada além da semente. Salve como
`~/dl/spread.py`:

```schooling-example
{
  "language": "python",
  "file": "spread.py",
  "parts": [
    {
      "code": "\"\"\"spread: one configuration, five seeds.\"\"\"\nimport statistics\n\nimport exp\n\nconfig = {\"hidden\": 32, \"lr\": 0.01, \"epochs\": 10, \"batch_size\": 32}\naccs = []\nfor seed in range(5):\n    _, acc = exp.run(config, seed)\n    accs.append(acc)\n    print(f\"seed {seed}  val acc {acc:.4f}  ({round(acc * 360)} of 360)\")",
      "note": "A configuração do `seeds.py`, com as sementes de 0 a 4. A acurácia em 360 imagens anda em degraus de uma imagem, então o programa imprime a contagem ao lado."
    },
    {
      "code": "print(f\"min {min(accs):.4f}  max {max(accs):.4f}  mean {statistics.mean(accs):.4f}  \"\n      f\"sd {statistics.stdev(accs):.4f}\")",
      "note": "O intervalo, a média e o desvio padrão das cinco: o tamanho do ruído que uma configuração faz sozinha."
    }
  ]
}
```

```
PENDING spread
```

**Cinco execuções de uma mesma configuração caíram entre 0,9139 e 0,9250.** São de 329 a 333
imagens certas em 360: quatro imagens de diferença, e nenhuma causada por algo que alguém escolheu.
Três das cinco sementes empataram em 333, o que lembra o quanto esta medida é grossa. **A acurácia
em 360 imagens anda em degraus de 1/360, cerca de 0,0028**, então duas execuções que diferem por um
degrau diferem por uma imagem.

Dois números resumem a dispersão, e dizem coisas diferentes:

- **o intervalo**, do mínimo ao máximo, é o que uma execução sozinha poderia ter mostrado. Se você
  tivesse rodado só a semente 2, teria relatado 0,9139; só a semente 1, 0,9250.
- **o desvio padrão**, aqui 0,0053, é a distância típica de uma execução até a média. É a régua com
  que se mede a comparação de duas configurações, duas seções adiante.

Cinco sementes são uma amostra pequena, e o desvio padrão de cinco números também é grosseiro. Basta
para ver o tamanho do ruído, que é o que interessa aqui, e não basta para cravá-lo na terceira casa
decimal. Uma comparação publicada usaria mais sementes, e o custo é um treino a mais por semente.

## De onde vem a dispersão

Cada semente começa a rede num ponto diferente e entrega os lotes numa ordem diferente. A descida do
gradiente a partir desses pontos caminha para lugares diferentes, e uma rede que termina em outro
lugar classifica de outro jeito alguns dígitos de fronteira. **O conjunto de validação pequeno
transforma isso num número visível**: com 360 imagens, um punhado de casos de fronteira é um ponto
percentual inteiro.

A dispersão também não é uma propriedade fixa dos dados. Uma taxa de aprendizado mais alta, outro
tamanho de lote ou mais épocas podem alargá-la ou estreitá-la, então ela pertence a uma
configuração. É por isso que a comparação duas seções adiante roda cada configuração com várias
sementes, em vez de medir a dispersão uma vez e supor que ela vale para todas.
