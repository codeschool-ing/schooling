---
title: Dizendo o quanto você tem certeza
version: 1
---

**Uma estimativa de risco é um julgamento, não uma medição, e o leitor tem direito ao número e a
quanto confiar nele.** Engenheiros costumam errar aqui em uma de duas direções: recusam-se a dar um
número porque não têm certeza, ou dão um único número confiante que não conseguem defender.

## Dê uma faixa e diga em que ela se apoia

"Duas a quatro vezes por ano" é mais útil do que "três vezes por ano" e muito mais útil do que "não
dá para prever isso". Uma faixa faz três coisas que um número único não faz:

- **mostra a incerteza**, para que quem decide possa planejar para o extremo alto se o custo de errar
  for grande;
- **provoca a pergunta certa**, "o que nos levaria ao extremo alto?", em vez de um ataque ao próprio
  número;
- **sobrevive ao erro**: se o evento acontecer uma vez no ano que vem, a estimativa não foi
  desmentida, e quem a escreveu não perde a credibilidade.

A aula 9 de `process-management` ensina estimativas de três pontos (otimista, provável, pessimista)
para esforço. O mesmo hábito serve para risco: um valor baixo, um provável e um alto, cada um com
uma frase de raciocínio.

## Separe o que é medido do que é julgado

Nas tabelas de Lívia, cada linha é de um de dois tipos, e o documento diz qual:

| medido | julgado |
|---|---|
| 9.000 checkouts por noite de sexta | duas a quatro paradas totais por ano |
| 2% falham | cerca de trinta minutos até alguém intervir |
| 60% dos clientes que falharam voltam | que a réplica elimina o problema "para o crescimento previsível" |

**Misturar os dois sem rótulo é o que faz uma estimativa cuidadosa ser descartada.** Um leitor que
encontra um julgamento apresentado como fato vai tratar todo número do documento como julgamento.

## Diga o que mudaria sua opinião, e quanto custa descobrir

A frase mais forte de uma estimativa incerta é a que diz como torná-la menos incerta:

> Não sabemos quão perto do limite uma sexta normal de maio vai ficar, porque o volume cresce com
> a sazonalidade. Duas semanas medindo as conexões por serviço, que não custam nada além de um
> dashboard, diriam se abril é urgente ou se o trabalho pode esperar até junho.

É uma terceira opção ao lado de "aprovar" e "rejeitar": **pagar um valor pequeno e conhecido para
reduzir a incerteza antes da decisão grande.** Quem decide gosta dela, porque em geral é barata e
permite decidir com informação melhor. Ela só é honesta quando a informação realmente mudaria a
decisão. Medir algo cuja resposta não mudaria nada é atraso com uma planilha anexada.

## Palavras de confiança, e o que elas significam

Palavras como "provável" e "provavelmente" são lidas de formas muito diferentes por pessoas
diferentes. Estudos sobre como os leitores as interpretam, a começar pelo trabalho de Sherman Kent
para a CIA nos anos 1960, viram a mesma expressão ser entendida como qualquer coisa entre uma chance
pequena e uma quase certeza. Kent propôs associar porcentagens aproximadas às palavras, e muitas
equipes de inteligência e de risco hoje fazem isso. Esta é a versão que a Marola usa nos documentos
de incidente e de risco:

| palavra | aproximadamente |
|---|---|
| quase certo | acima de 90% |
| provável | 60 a 90% |
| chances iguais | 40 a 60% |
| improvável | 10 a 40% |
| remoto | abaixo de 10% |

Seja qual for a escala usada, **defina-a uma vez e use-a com consistência**: "provável" deveria
significar a mesma coisa no registro de riscos de março e no relatório de incidente de maio.
