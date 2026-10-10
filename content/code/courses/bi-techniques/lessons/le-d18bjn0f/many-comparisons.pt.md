---
title: Vinte números, um alarme falso
version: 1
---

**O nível de significância de 5 por cento é uma promessa sobre uma comparação.** Se nada mudou, um
teste de uma métrica cruza a linha por acaso uma vez em vinte. Um relatório de teste raramente tem
uma comparação: tem a métrica primária, várias secundárias, as de proteção, e depois as mesmas
métricas quebradas por aparelho, região, visitantes novos e que voltam. Cada uma é mais uma chance.

```schooling-example
{"language": "python", "file": "many.py", "parts": [{"code": "for k in (1, 5, 10, 20, 50):\n    print(f\"{k:2} independent metrics, none really moved: \"\n          f\"chance of at least one 'significant' = {1 - 0.95 ** k:.0%}\")", "note": "Cada métrica tem 95% de chance de não dar alarme falso, então todas ficam quietas com probabilidade 0,95 elevado ao número delas."}], "output": " 1 independent metrics, none really moved: chance of at least one 'significant' = 5%\n 5 independent metrics, none really moved: chance of at least one 'significant' = 23%\n10 independent metrics, none really moved: chance of at least one 'significant' = 40%\n20 independent metrics, none really moved: chance of at least one 'significant' = 64%\n50 independent metrics, none really moved: chance of at least one 'significant' = 92%"}
```

**Com dez métricas que não se mexeram, a chance de pelo menos uma parecer significativa é 40%; com
vinte, 64%.** A conta supõe métricas independentes; as reais são correlacionadas, o que baixa um
pouco esses números, e não muda a forma. Olhe números o bastante e um deles vai cruzar a linha, e é o
que cruza que vai para o relatório.

Esse é o **problema das comparações múltiplas**, e é por isso que a aula 7 insistiu numa métrica
primária escolhida antes. Métricas secundárias e de proteção continuam valendo ser relatadas, como
descrições. **Uma métrica secundária que sai significativa é uma hipótese para o próximo teste, não um
achado deste.**
