---
title: O que roda em spot, e o que não roda
version: 1
---

A pergunta não é se uma aplicação é importante. Um serviço web de produção pode rodar quase todo em
spot e um banco de dados de teste não deve. **A pergunta é quanto custa uma interrupção**: se
qualquer instância pode sumir com dois minutos de aviso e o trabalho segue em outro lugar, spot é um
desconto; se uma instância sumir perde alguma coisa ou para tudo, é uma aposta que um dia vai perder.

## O que serve

- **Instâncias web e de API sem estado atrás de um load balancer.** Cada requisição é curta, a sessão
  mora num armazenamento compartilhado, e uma instância saindo do target group custa as requisições
  que ela atendia naquele momento, que o load balancer pode deixar terminar. Um grupo misto com base
  sob demanda, como na seção anterior, é a forma padrão.
- **Workers de fila.** Um worker interrompido no meio de uma mensagem nunca a apaga, então a mensagem
  volta a ficar visível e outro worker a pega. O custo de uma interrupção é uma mensagem processada
  duas vezes, que o consumidor já tem de tolerar de qualquer jeito (lição 21).
- **Jobs de lote que registram progresso.** Uma renderização, um treino ou um relatório que grava o
  progresso no S3 a cada poucos minutos perde no máximo esses minutos. Sem esses registros, o mesmo
  job perde tudo desde que começou, e um longo pode nunca terminar.
- **Runners de CI e agentes de build.** Um build interrompido roda de novo, e builds já são feitos
  para serem repetíveis.
- **Contêineres num cluster de instâncias.** O orquestrador move os contêineres de um nó perdido; o
  Fargate Spot (lição 9) e o provisionamento spot do Karpenter no EKS (lição 12) são essa ideia
  nesses serviços.

## O que não serve

- **Uma instância única guardando estado**: um servidor de banco de dados, um servidor de arquivos,
  uma instância cujo disco é a única cópia de alguma coisa. O instance store da lição 3 some na
  primeira interrupção.
- **Jobs longos que não conseguem registrar progresso**, porque quanto mais longo o job, mais provável
  uma interrupção cair dentro dele, e cada uma o recomeça.
- **Qualquer coisa cuja subida é mais longa que a vida esperada entre interrupções.** Uma aplicação
  que precisa de vinte minutos para aquecer os caches não ganha nada com uma instância que perde a
  cada hora.
- **O mínimo de que um serviço precisa para continuar no ar.** É para isso que serve a base sob
  demanda: se o serviço precisa de três instâncias para responder, três delas são sob demanda.

## Uma verificação antes de passar algo para spot

Três perguntas decidem, e cada uma tem uma resposta que dá para testar sem spot nenhum:

1. **Qualquer instância pode ser terminada agora sem perder dados?** Termine uma num grupo de teste e
   veja.
2. **O trabalho que ela fazia é feito mesmo assim?** Numa fila, a mensagem volta; numa requisição, o
   cliente tenta de novo; num job, ele retoma de um registro de progresso.
3. **O grupo sobrevive a perder várias de uma vez?** Uma interrupção é por pool, então um grupo de um
   tipo numa zona pode perder todas as instâncias spot juntas. Vários tipos e zonas, e uma base sob
   demanda, são a resposta.

**Uma carga que passa nas três já é do tipo que a lição 4 pediu**: instâncias substituídas, nunca
consertadas. O spot não pede outra arquitetura. Ele cobra menos pela que os grupos de auto scaling
já supõem, e cobra em interrupções por qualquer instância que era, em segredo, um bichinho de
estimação.
