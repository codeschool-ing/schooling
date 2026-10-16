---
title: Se um modelo é mesmo a resposta
version: 1
---

**Nem toda pergunta que menciona dados precisa de um modelo.** Parte do trabalho mais útil de um
cientista de dados é a tarde gasta mostrando que uma regra, um relatório ou um telefonema responde à
pergunta melhor do que qualquer coisa que se pudesse treinar. Um modelo custa algo para construir,
mais para manter honesto, e mais ainda para explicar quando erra. Ele só paga esse custo sob certas
condições, e elas podem ser conferidas antes de qualquer ajuste.

## Cinco condições, e o que falha sem cada uma

**Uma decisão que muda por causa da resposta.** Se a equipe de retenção vai mandar o crédito às
mesmas pessoas diga o modelo o que disser, porque o orçamento é fixo e a lista é escolhida à mão, o
modelo não muda nada e não vale nada. Pergunte o que seria feito de diferente com uma previsão
perfeita. Se a resposta for "nada", pare.

**Um rótulo que existe e significa o que você pensa.** Para aprender quem cancela, os dados precisam
dizer quem cancelou. Na Feira em Casa dizem, em `churned`. Muitas empresas descobrem nesta etapa que
um cancelamento só é registrado quando alguém liga, e um assinante cujo cartão simplesmente para de
passar não aparece em lista nenhuma. Um modelo treinado nesse rótulo aprende a prever ligações.

**Entradas conhecidas no momento da decisão.** A seção 06 desta aula definiu o momento: o dia 1º. Um
modelo que precisa das reclamações da semana que vem para prever os cancelamentos deste mês não
consegue rodar no momento em que o crédito é enviado.

**Um padrão que uma regra ainda não capture.** Se todo mundo que pula três caixas seguidas cancela, e
mais ninguém, escreva essa frase no sistema e vá para casa. Um modelo vale a pena quando o sinal se
espalha por muitas colunas de jeitos que nenhuma pessoa escreveria, e a aula 2 é o teste: uma regra
prática, medida do mesmo jeito que o modelo será.

**Exemplos suficientes do que importa.** 248 cancelamentos em dezembro, 3.685 no arquivo todo. Dá
para aprender com isso. Uma empresa com quarenta cancelamentos por ano tem outro problema, que é ler
cada um deles.

## Um enquadramento de uma página

Antes de qualquer código, a Ana escreve isto e manda para quem pediu. Leva dez minutos e é a coisa
mais reaproveitável do projeto:

| | Feira em Casa, churn |
|---|---|
| a decisão | mandar um crédito de R$ 40, ou não, no começo de cada mês |
| uma linha | um assinante no primeiro dia de um mês |
| o momento | o dia 1º, antes de o crédito sair |
| o alvo | cancela durante aquele mês: `churned` = 1 |
| quanto custa um erro | um falso positivo R$ 40, um falso negativo R$ 104 que deixam de entrar |
| o que precisa superar | a melhor regra simples, e não mandar a ninguém (aula 2) |
| como será testado | em meses posteriores aos que ele aprendeu (aula 3) |

**O enquadramento é mais contrato que documento.** Quando alguém perguntar, três meses depois, por
que o modelo é "só 30% preciso", a resposta já está escrita: precisão nunca foi o objetivo, o valor
líquido da seção anterior era, e aqui está o que foi combinado.

## O que muda numa regressão

As mesmas quatro perguntas valem quando o alvo é uma quantidade. A equipe de logística da Feira em
Casa quer dizer a cada cliente quando a caixa chega: uma linha é uma entrega, o momento é quando a
rota é planejada, o alvo é `minutes`, e o custo de um erro depende da direção dele. Uma caixa
prometida para 40 minutos que chega em 30 não incomoda ninguém; uma que chega em 50 gera uma
reclamação. A aula 12 mede o erro de jeitos que distinguem esses dois casos, e a aula 5 ajusta o
primeiro modelo ao `deliveries.csv`.
