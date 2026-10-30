---
title: O que o iOS permite em segundo plano
version: 1
---

**Um app de iPhone não continua rodando quando sai da tela.** Essa é a crença a largar primeiro,
porque ela vem dos computadores, onde um programa numa janela que você não vê continua sendo um
programa rodando. No iOS, um app que vai para o segundo plano é suspenso em segundos: ainda na
memória, sem usar processador nenhum, e sujeito a ser tirado da memória de vez quando outro app
precisar do espaço. A fase da cena da aula 2 é a última chance de o app salvar antes disso.

O que quer que rode depois roda porque o sistema **dá** tempo ao app, e dá esse tempo nos termos dele.
Esta aula trata de pedir bem. Nada nela que toca o sistema foi executado: é o framework
`BackgroundTasks` da Apple e o modificador `backgroundTask` do SwiftUI, escritos a partir da
documentação da Apple lida em 30 de outubro de 2026. As duas decisões que o app toma, quando pedir e o
que fazer quando o tempo acaba, são Swift puro, e as seções 06 e 07 as rodam.

## As formas de ganhar tempo

O artigo da Apple *Choosing Background Strategies for Your App* as lista. As que importam para um
planner de estudos:

| do que o app precisa | o que pedir | quanto tempo, segundo a documentação |
|---|---|---|
| terminar algo que a pessoa começou, como salvar | `beginBackgroundTask` ao ir para o segundo plano | um tempo limitado; o handler de expiração diz quando acabou |
| atualizar os dados de vez em quando | uma `BGAppRefreshTask` | até 30 segundos, quando o sistema escolher |
| manutenção pesada, melhor de madrugada no carregador | uma `BGProcessingTask` | minutos, quando o sistema escolher |
| um envio ou download que pode ser longo | um `URLSession` de segundo plano | a transferência continua enquanto o app está suspenso |
| um trabalho que a pessoa começa e acompanha, como uma exportação | uma `BGContinuedProcessingTask`, do iOS 26 em diante | ela continua, com o progresso mostrado à pessoa |
| novidades do servidor em horários irregulares | um push de segundo plano | até 30 segundos, com limite de frequência |

**"Quando o sistema escolher" é a expressão a levar a sério.** Um app pede uma atualização não antes de
uma data; a documentação de `earliestBeginDate` diz que o sistema não garante abrir a tarefa nessa
data, só que ela não começa antes. O guia de desenvolvimento da Apple acrescenta que a demora entre
agendar uma tarefa e ela abrir pode ser de muitas horas. O sistema pesa bateria, rede, com que
frequência a pessoa abre o app e a hora do dia, e o app não tem voz nisso.

## O que isso quer dizer para o planner

O planner tem dois trabalhos que gostaria de ver feitos enquanto não está na tela. **Enviar as sessões
acrescentadas offline**, para o servidor tê-las antes de a pessoa abrir o app em outro aparelho. E
**atualizar o plano**, para o app abrir com os dados desta manhã e não com os de ontem à noite. Nenhum
dos dois é urgente ao segundo, os dois são pequenos, e os dois são exatamente para o que serve uma
tarefa de atualização. A seção 03 pede uma; a seção 06 decide quando; a seção 07 faz o trabalho
sobreviver a ser cortado depois dos 30 segundos dele, ou depois de três.
