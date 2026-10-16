---
title: Que erro, para que pergunta
version: 1
---

A aula 10 terminou com uma tabela de métricas de classificação e a pergunta que cada uma responde. A
tabela de regressão é mais curta, e vale o mesmo hábito: nomeie a pergunta primeiro, depois escolha o
número.

| pergunta | métrica | na Feira em Casa, melhor modelo |
|---|---|---|
| quantos minutos de erro, numa entrega típica? | **MAE** | 5,02, `boost_absolute` |
| quão ruins são os piores erros? | **RMSE**, ao lado do MAE | 14,3, os três parecidos |
| quão longe, como parte da entrega? | **MAPE** | 8,7%, mas ele gosta de prever baixo |
| melhor que a média, e por quanto? | **R²** | 0,397, a reta; negativo é alarme |
| atrasado ou adiantado, e com que frequência? | **viés** e **parte atrasada** | +2,89 min, atrasa 50,5% |
| com que frequência a promessa é cumprida? | **parte atrasada** num **quantil** escolhido | 13,7% no quantil 0,9 |

Três hábitos seguem, e espelham os da aula 10.

**Ajuste com a perda que a decisão pede.** A métrica com que um modelo é ajustado é aquela em que ele é
bom. Um modelo ajustado por erro quadrático e julgado pelo MAE está sendo julgado por algo que não
tentou fazer, e o mesmo vale para um modelo de mediana a quem se pede promessas. Escolha o alvo
primeiro: a mediana para "típico", a média para "em média, ao longo de muitos", um quantil alto para
"uma promessa".

**Relate a direção do erro, sempre.** Dois números ao lado do MAE: o viés e a parte do lado caro.
Nenhum custa uma linha de raciocínio para calcular, e são os dois que o MAE esconde.

**Olhe os erros, não só a média deles.** O histograma da seção do RMSE mostrou um morro e uma cauda ao
mesmo tempo, e nenhum número-resumo mostra os dois. A aula 22 continua olhando para eles, mês a mês,
conforme chegam rótulos novos.

Na Feira em Casa a decisão agora está escrita. O aplicativo mostra o quantil 0,9 como promessa. O
`boost_absolute` fica na ferramenta de planejamento, onde a equipe de logística quer o tempo típico
para montar rotas. Os dois modelos respondem duas perguntas, e ninguém precisa fingir que um número
serve para as duas.
