---
title: Pôr por escrito, e decidir não usar
version: 1
---

Um modelo dura mais que o analista que o construiu, e é usado por pessoas que nunca leram o código
dele. **Para que ele serve, e para que não serve, tem de viajar junto.** A forma usual é um documento
curto, muitas vezes chamado de **model card**, o cartão do modelo. Para o modelo de churn da Panela ele
diria:

| | |
|---|---|
| **propósito** | ordenar os clientes ativos nos últimos 60 dias pela chance de nenhum pedido nos próximos 90, para escolher quem recebe uma oferta de retenção |
| **não serve para** | nenhuma decisão que tire algo de um cliente, como o clube de fidelidade; crédito; preço |
| **dado** | pedidos e clientes até 30 de junho de 2025; treinado em 31 de dezembro de 2024, testado em 30 de junho de 2025 |
| **entradas** | atraso relativo, contagem relativa de pedidos, tempo de casa, canal, plano; a região não é entrada |
| **desempenho** | no limiar de 0,2: precisão 59,2%, revocação 67,9% |
| **por grupo** | alarmes falsos entre quem fica, por região, de 6,2% a 10,3%; a revocação do Norte se apoia em 17 pessoas |
| **limites conhecidos** | a taxa de retenção da oferta é suposta, não medida; o Norte é 4% do dado |
| **responsável** | quem retreina, quem audita, e quem responde perguntas sobre ele |

A linha "não serve para" é a que teria barrado o clube. É o viés de implantação da aula 18, evitado
numa frase.

## A pessoa do outro lado

**No Brasil a LGPD dá às pessoas um direito sobre decisões assim.** O artigo 20 diz que o titular pode
pedir a revisão de decisões tomadas unicamente com base em tratamento automatizado dos dados dele que
afetem seus interesses, incluindo as que definem seu perfil de consumo. Ele também tem direito a
informações claras sobre os critérios e os procedimentos usados, respeitados os segredos comercial e
industrial da empresa. Uma nota de churn que deixasse alguém fora de um clube seria uma decisão dessas,
e a Panela teria de conseguir explicá-la e revisá-la. O texto já exigiu que essa revisão fosse feita
por uma pessoa; a exigência caiu em 2019, então se uma pessoa olha agora é escolha da empresa.

Ainda há um argumento para manter uma pessoa no circuito sempre que a decisão de um modelo fecha uma
porta. Não para revisar toda marcação, o que ninguém faria por muito tempo, mas para manter **um
caminho pelo qual um cliente, ou um funcionário que veja algo estranho, possa pedir o olhar de
alguém**.

## Decidir não usar

**Às vezes o resultado certo de uma auditoria é o modelo não ser usado.** O clube é um bom exemplo. Um
clube de fidelidade premia clientes por serem fiéis, e o próprio histórico de pedidos do cliente diz
isso diretamente: um cliente que pediu a cada quinzena durante um ano é fiel. Prever a fidelidade com
um modelo de churn acrescenta um passo que só pode acrescentar erros. O desenho melhor é modelo
nenhum.

Três perguntas valem antes de qualquer modelo entrar numa decisão que afeta pessoas.

1. **É preciso uma previsão**, ou o fato já está no dado?
2. **Quem sai machucado por cada tipo de erro**, e a auditoria foi feita para esse erro?
3. **Essa decisão poderia ser explicada** à pessoa que ela afeta, numa frase que ela aceitaria?

Um modelo que falha na primeira pergunta é desnecessário. Um que falha na segunda não está pronto. Um
que falha na terceira não deveria tomar a decisão sozinho.
