---
title: Três jeitos de medir um erro
version: 1
---

Todo erro de previsão é um número por semana: o que foi previsto menos o que aconteceu. **Uma medida
de precisão de previsão é um jeito de transformar essa coluna de erros num número só**, e as três de
uso diário fazem escolhas diferentes sobre como.

| medida | a conta | em que unidade | o que ela realça |
|---|---|---|---|
| **MAE**, erro absoluto médio | tira a média dos erros depois de jogar fora os sinais | pedidos | o erro típico |
| **RMSE**, raiz do erro quadrático médio | eleva os erros ao quadrado, tira a média, tira a raiz | pedidos | os erros grandes |
| **MAPE**, erro percentual absoluto médio | divide cada erro pelo que aconteceu, depois tira a média | por cento | o erro relativo ao tamanho |

E mais uma que não é medida de precisão mas deveria sempre ser impressa ao lado delas:

- o **viés**, a média dos erros *com* sinal. Uma previsão cujos erros têm média zero fica alta tantas
  vezes quanto baixa. Uma com viés grande erra na mesma direção semana após semana, que é o erro
  mais fácil de corrigir que uma previsão pode cometer.

As quatro em cinco semanas, pequenas o bastante para conferir à mão:

```schooling-example
{"language": "python", "file": "errors.py", "parts": [{"code": "actual = [8796, 8753, 8812, 8422, 8458]\nforecast = [8659, 8844, 8587, 8653, 8181]", "note": "Cinco semanas do começo de 2025 e as previsões do Holt-Winters da aula 3 para elas, digitadas para que a conta fique visível."}, {"code": "errors = [f - a for f, a in zip(forecast, actual)]", "note": "Um erro é previsão menos real: positivo quer dizer que a previsão ficou alta demais."}, {"code": "mae = sum(abs(e) for e in errors) / len(errors)\nrmse = (sum(e * e for e in errors) / len(errors)) ** 0.5\nmape = sum(abs(e) / a for e, a in zip(errors, actual)) / len(errors) * 100\nbias = sum(errors) / len(errors)", "note": "As três medidas e o viés, cada uma uma linha de aritmética."}, {"code": "print(\"errors:\", errors)\nprint(f\"MAE  {mae:7.1f} orders\")\nprint(f\"RMSE {rmse:7.1f} orders\")\nprint(f\"MAPE {mape:7.2f} %\")\nprint(f\"bias {bias:7.1f} orders\")"}], "output": "errors: [-137, 91, -225, 231, -277]\nMAE    192.2 orders\nRMSE   203.8 orders\nMAPE    2.23 %\nbias   -63.4 orders"}
```

O MAE de 192,2 diz que a semana típica errou por uns duzentos pedidos. O RMSE é um pouco maior,
203,8, porque elevar ao quadrado dá ao maior erro, 277, mais peso que ao menor, 91. O MAPE diz que
os erros foram cerca de 2,2 por cento das semanas em que erraram. E o viés de −63,4 diz que a
previsão ficou um pouco baixa no saldo, embora com cinco semanas isso seja uma pista e não um
achado.

**O RMSE nunca é menor que o MAE**, e a distância entre os dois é informação. Quando todo erro tem
mais ou menos o mesmo tamanho eles ficam quase iguais; quando uma semana erra feio e o resto fica
perto, o RMSE se afasta. A próxima seção é um caso em que essa distância muda qual modelo vence.
