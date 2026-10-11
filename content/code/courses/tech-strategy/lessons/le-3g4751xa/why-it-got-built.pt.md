---
title: Por que foi construída mesmo assim
version: 1
---

A explicação fácil para o portal é que alguém tomou uma decisão ruim. **Ela não resiste aos fatos**:
vários engenheiros capazes trabalharam nele por meses, ele foi aprovado e foi mostrado à empresa
inteira. Um erro que muita gente comete junta tem uma causa no jeito como o trabalho foi escolhido, e
a mesma causa vai produzir o próximo portal se ninguém lhe der nome.

A autópsia encontrou três causas, e elas se reforçam.

## Construir aparece; não construir, não

Uma ferramenta construída tem demo, capturas de tela, um anúncio de lançamento e uma linha na
avaliação de alguém. Uma investigação curta que termina em "os times com pipeline não precisam disso"
não tem nada disso. É o resultado melhor, e parece que nada aconteceu.

Essa assimetria puxa todo time na direção de construir, e não é defeito de caráter de ninguém. O time
de Plataforma da época era julgado pelo que entregava, e um portal é uma entrega. **Descobrir que uma
ferramenta é desnecessária também é trabalho, e uma organização que não conta isso como trabalho vai
continuar recebendo ferramentas no lugar.** Helena Prates, a CTO, tirou essa conclusão da autópsia: a
partir dali, uma investigação que encerrava uma proposta era apresentada na revisão de engenharia
como qualquer lançamento.

## Ninguém perguntou a quem ia usar

Os requisitos do portal vieram do canal de chat da Plataforma, que é onde os pedidos chegavam.
"Que versão está em produção?" "Dá para fazer rollback do serviço de PDF de ingressos?" "Pode aprovar
este deploy?" Cada pedido era real, e juntos descreviam uma ferramenta que os responderia.

A falha está em quem perguntava. **O canal só ouvia os times que precisavam da ajuda da Plataforma
para fazer deploy**, que eram os times sem pipeline. Os 38 times cujos pipelines faziam deploy a cada
integração nunca perguntaram nada, e por isso ficaram invisíveis nos requisitos. A Plataforma
construiu para os usuários mais barulhentos e lançou para os silenciosos.

Perguntar teria sido barato. Uma conversa com cada um dos outros seis líderes de time, do tipo "como
vocês fazem deploy hoje e o que incomoda nisso?", teria mostrado numa tarde que a maioria dos times
não tinha nada a consertar no deploy. A aula 6 de `architect-communication` trata desse tipo de
escuta — achar a necessidade por trás de um pedido —, e a aula 7 do mesmo curso defende diagnosticar
antes de propor uma solução, que é exatamente o passo que o portal pulou.

## Resolveu o problema de quem construiu

Olhe o que o portal removeu. Os pedidos no chat pararam de interromper a Plataforma, as perguntas
sobre versões passaram a se responder sozinhas e as aprovações deixavam registro. **Todos esses
benefícios caíram no time de Plataforma.** Para os times sem pipeline o portal foi um ganho real;
para os outros, foi uma aba de navegador acrescentada a um deploy que não precisava de nenhuma.

O teste é curto de enunciar: a semana de quem fica mais fácil? Uma ferramenta que facilita sobretudo a semana de quem a constrói é um projeto de eficiência interna, e ainda assim pode valer a pena. Ela deve então ser dimensionada e justificada como tal, contra as horas de interrupção que poupa à Plataforma, em vez de lançada como produto para todo mundo.

| a pergunta | a resposta do portal | a resposta que o teria parado |
|---|---|---|
| quem pediu? | pedidos no canal da Plataforma | os times que mudariam o jeito de trabalhar |
| o que eles fazem hoje? | não se perguntou | 38 de 41 já fazem deploy a cada integração |
| a semana de quem fica mais fácil? | a da Plataforma | a dos usuários |
| o que nos faria parar? | nada escrito | uma data e um nível de uso |

## E nada dizia quando parar

O plano do projeto tinha uma data de lançamento. Não tinha nenhum ponto em que alguém perguntaria se
era o caso de continuar. A cada mês o portal estava mais perto de pronto, as horas já gastas
cresciam, e parar parecia mais desperdício do que terminar. É o custo afundado da autópsia agindo na
outra direção: ele manteve o projeto vivo antes do lançamento, como teria mantido o portal vivo
depois se a Rafaela tivesse deixado os R$ 165.000 entrarem na decisão.

**Um projeto sem data de decisão é decidido pelo embalo**, e o embalo sempre diz "quase pronto". A próxima seção trata dos quatro passos que teriam parado o portal enquanto ele ainda era uma proposta. A aula 18 dá a esse risco o nome que o pessoal de produto usa: o risco de ninguém querer o que está sendo construído.
