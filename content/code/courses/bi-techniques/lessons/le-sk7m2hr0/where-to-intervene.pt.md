---
title: Onde uma correção pode entrar
version: 1
---

Um modelo fica numa cadeia: o dado é coletado, entradas são construídas a partir dele, um modelo é
ajustado, um limiar transforma notas em marcações, e uma decisão age sobre as marcações. **Uma correção
pode entrar em qualquer elo**, e cada um tem um preço diferente.

| elo | como fica uma correção ali | na Panela |
|---|---|---|
| **dado** | coletar o que falta, ou mais de um grupo escasso | mais histórico do Norte, que só o tempo dá |
| **entradas** | construir entradas que querem dizer a mesma coisa para todo grupo | medir a recência contra o ritmo do próprio cliente |
| **modelo** | dar mais peso ao grupo escasso, ou ajustar com uma restrição de justiça | pesar mais os clientes do Norte no treino |
| **limiar** | um limiar diferente por grupo | um limiar mais alto para o Norte |
| **decisão** | mudar o que a marcação faz | deixar o clube usar o histórico de pedidos, não uma nota de churn |
| **uso** | não usar o modelo nesta decisão | manter a nota de churn só para ofertas |

A ordem da tabela é uma ordem aproximada de preferência, e o raciocínio por trás é simples. **Uma
correção perto da causa conserta o modelo para toda decisão que ele serve**; uma correção perto do fim
conserta uma decisão e deixa a causa no lugar para a próxima pessoa que reusar o modelo. Quando a aula
18 achou que a causa era uma medição, as entradas viraram o primeiro lugar a olhar.

Essa preferência não é regra. Às vezes a causa não se alcança: o dado de que um grupo precisa não
existe, ou vai levar um ano para ser coletado. Aí uma correção mais abaixo na cadeia, aplicada às
claras e documentada, é melhor que esperar. E às vezes a resposta honesta está na última linha: a
decisão não deveria se apoiar neste modelo.

Toda correção tem de ser checada do mesmo jeito que o problema foi achado, **rodando a auditoria de
novo**. Uma correção que não passou por auditoria é uma esperança.
