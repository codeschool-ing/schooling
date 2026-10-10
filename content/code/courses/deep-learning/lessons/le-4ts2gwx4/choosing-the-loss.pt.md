---
title: Escolhendo a perda, e por que a métrica é outro número
version: 1
---

**A perda decorre da pergunta que a saída responde, e a pergunta também fixa a última camada.** As duas
são escolhidas juntas, porque as perdas que funcionam melhor recebem as pontuações cruas e aplicam elas
mesmas a função que espreme.

| a saída responde | última camada | perda | no PyTorch (aula 9) |
| --- | --- | --- | --- |
| um número, ruído comum | uma saída linear, sem ativação | MSE | `nn.MSELoss` |
| um número, com outliers a ignorar | uma saída linear, sem ativação | Huber, ou MAE | `nn.HuberLoss`, `nn.L1Loss` |
| uma classe entre várias | um logit por classe, sem softmax no modelo | entropia cruzada, com o softmax dentro | `nn.CrossEntropyLoss` |
| sim ou não | um logit | entropia cruzada binária, com a sigmoid dentro | `nn.BCEWithLogitsLoss` |
| vários rótulos de sim ou não ao mesmo tempo | um logit por rótulo | entropia cruzada binária por rótulo | `nn.BCEWithLogitsLoss` |

## A métrica não é a perda

Uma perda precisa ser algo que a descida do gradiente consiga seguir: suave, com inclinação em todo
lugar. **A acurácia não tem inclinação útil.** Ela é um degrau, como o do perceptron da aula 1: uma
mudança pequena num peso não muda nenhuma previsão, então o gradiente dela é zero em quase todo lugar.
Por isso o treinamento segue uma perda, o modelo é julgado por uma métrica, e as duas podem discordar.
Salve como `~/dl/metric.py`:

```python
# metric.py: three models on the same five yes-or-no questions, scored two ways
import numpy as np

models = {                          # the probability each model gave the right answer
    "A": [0.60, 0.60, 0.60, 0.60, 0.40],
    "B": [0.99, 0.99, 0.99, 0.99, 0.001],
    "C": [0.90, 0.90, 0.45, 0.45, 0.45],
}
for name, p_right in models.items():
    p = np.array(p_right)
    print(f"model {name}  accuracy {(p > 0.5).mean():.1f}   cross-entropy {-np.log(p).mean():.3f}")
```

```
ana@vm:~/dl$ python metric.py
model A  accuracy 0.8   cross-entropy 0.592
model B  accuracy 0.8   cross-entropy 1.390
model C  accuracy 0.4   cross-entropy 0.521
```

A e B acertam quatro de cinco. **A perda de B é mais que o dobro da de A por causa de uma resposta**:
na quinta pergunta ele deu 0,001 à classe certa, e a entropia cruzada pune um erro confiante sem
limite. C tem a menor perda dos três e a menor acurácia, 0,4. Ele nunca erra feio, e erra muito.
Ordenados pela perda, a ordem é C, A, B; pela acurácia, C fica em último.

**Treine pela perda, escolha pela métrica.** A métrica é aquilo pelo que o problema é julgado: acurácia
nos dígitos, recall quando deixar passar um caso raro é o que dói, média de minutos de atraso nas
entregas. Quando dois modelos discordam no conjunto de validação, a métrica decide qual vai para
produção. A perda diz se o treinamento vai bem, e a aula 6 lê as curvas dela; uma perda de validação
que sobe enquanto a acurácia fica parada costuma ser um modelo ficando confiante e errado em poucas
imagens, que é o formato do modelo B.
