---
title: O enquadramento, três meses depois
version: 1
---

O enquadramento da aula 1 foi escrito antes de qualquer código: a decisão, a linha, o momento, o alvo, o
que um erro custa, o que o modelo precisa vencer, como vai ser testado. Vinte e uma aulas depois a Ana tem
um modelo que vence as regras, um corte definido pelos custos, uma auditoria de justiça, um arquivo, um
endereço e três meses de evidência. O enquadramento ganha as suas últimas linhas, e são elas que mantêm as
outras verdadeiras:

| | Feira em Casa, churn |
|---|---|
| no dia 1º do mês | o `monthly.py` pontua o retrato com o modelo nomeado e guarda o arquivo; o `inputs.py` roda nas mesmas linhas |
| um alarme de entrada | um valor nunca visto no treino, uma coluna de repente vazia, um índice de estabilidade acima de 0,25 que ninguém sabe explicar |
| um mês depois | `labels.py` e `where.py` nas respostas: AUC, chance média contra o que aconteceu, prometido contra entregue, a razão por plano, cidade e faixa de idade |
| um alarme de resultado | um grupo cuja razão fica claramente longe de 1 por dois meses, ou valor entregue abaixo da metade do prometido |
| reajuste | a cada trimestre em tudo o que tem resposta, e antes quando um alarme tem uma causa que os dados conseguem consertar |
| troca de modelo | só depois de o novo vencer o antigo num mês com que nenhum dos dois aprendeu, e com o arquivo antigo guardado |
| quem é avisado | a equipe de retenção, quando um alarme tem uma causa que as colunas não descrevem |

Nenhuma das linhas é engenhosa. Cada uma é a resposta a algo que aconteceu nesta aula ou numa das vinte e
uma anteriores, e cada uma é barata agora e cara de acrescentar depois da primeira vez em que fez falta.

**A última linha é aquela para onde este curso vinha indo.** Um modelo é um resumo de como o mundo se
comportou enquanto os dados dele eram coletados. Ele não tem como saber que um concorrente abriu, que um
preço subiu, que um plano foi lançado; ele só consegue, quando as respostas chegam, mostrar que algo que
ele não sabia aconteceu, e com quem. As pessoas que tocam o negócio sabem as coisas que ele não sabe. O
que o curso deu a você é a metade que transforma o conhecimento delas e a evidência do modelo numa
decisão só: o enquadramento que diz o que está sendo decidido, o teste que diz se o modelo ajuda e as
conferências que dizem, todo mês, se ele ainda ajuda.

Dois cursos seguem daqui. **`deep-learning`** é o curso construído sobre este: modelos para imagens,
texto e sequências, em que as features são aprendidas em vez de escritas, e tudo da aula 1 à aula 4
continua valendo sem mudança. **`ml-mlops`** é a maquinaria em volta desta aula: a rodada mensal num
horário marcado, modelos num registro em vez de numa pasta, alarmes que chamam alguém e o reajuste como um
pipeline em vez de uma tarde.
