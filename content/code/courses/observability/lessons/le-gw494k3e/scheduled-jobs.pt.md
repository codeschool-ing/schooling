---
title: Tarefas agendadas: trabalho que ninguém pediu
version: 1
---

O relatório não tem pai, e isso está certo, não é uma lacuna. **Uma tarefa iniciada por um
temporizador não tem quem a chamou**: o cron, um `CronJob` do Kubernetes ou um agendador na nuvem a
inicia, e nenhum deles é um span. Então o rastro de uma tarefa agendada começa na tarefa, e três
hábitos a impedem de virar uma ilha:

- **Dê ao span raiz o nome da tarefa**, `nightly report`, para que toda execução dela seja uma
  operação em todo backend, a regra da última seção da aula 2.
- **Faça links para o trabalho em que ela mexe**, como o relatório faz, quando esse trabalho tem
  rastros próprios.
- **Registre o que faz desta execução esta execução** como atributos: a janela que ela cobriu,
  quantos itens, quantos falharam. O relatório define `report.orders` e `report.paid` no seu span, e
  é isso que permite achar *o relatório não contou nada terça passada* buscando em vez de lendo
  logs.

O caso oposto também existe: uma tarefa **que é** iniciada por algo com rastro, uma esteira de
implantação rodando uma migração ou um serviço lançando um processo trabalhador. Aí o contexto do pai
precisa chegar a um processo novo, e não há cabeçalho para levá-lo. O OpenTelemetry acrescentou uma
convenção para isso: o pai define as variáveis de ambiente `TRACEPARENT` e `TRACESTATE` para o
filho, no mesmo formato dos cabeçalhos, e o filho extrai do seu ambiente como um servidor extrai de
uma requisição. É recente, e poucas ferramentas a leem sozinhas por enquanto, então um script lançado
assim pode precisar das duas linhas escritas à mão.

O que o rastro de uma tarefa agendada não consegue é dizer **que a tarefa não rodou**. Um rastro só
existe para trabalho que aconteceu; a noite em que o agendador falhou não deixa span nenhum. Essa
pergunta é de uma métrica, *tempo desde a última execução bem-sucedida*, e de um alerta sobre ela,
que as aulas 5 e 16 constroem.
