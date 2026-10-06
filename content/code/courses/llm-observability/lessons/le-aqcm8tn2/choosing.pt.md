---
title: Escolhendo entre os dois
version: 1
---

Os dois produtos se sobrepõem no que fazem e diferem em onde rodam e no que pedem de você. As
perguntas que decidem quase nunca são sobre funcionalidades.

| | Langfuse | LangSmith |
|---|---|---|
| licença | código aberto (MIT), com algumas funções corporativas sob licença separada | proprietário; o SDK é código aberto |
| onde roda | nas suas máquinas, ou na nuvem do Langfuse na UE ou nos EUA | na nuvem da LangChain nos EUA ou na UE; nas suas máquinas para clientes corporativos |
| como os spans chegam | OpenTelemetry (OTLP) ou o SDK próprio, que é construído sobre o OpenTelemetry | o SDK próprio; ingestão OpenTelemetry também |
| amarrado a um framework | não | não, embora seja mais próximo de LangChain e LangGraph |
| quanto custa rodar | seis contêineres para operar, fazer backup e atualizar | uma conta por trace, e um contrato sobre dados |

**Para onde os dados podem ir vem primeiro.** Todo trace leva o que os clientes digitaram, limpo ou não,
e a aula 2 mostrou que a limpeza nunca é completa. Para uma loja no Brasil sob a LGPD, mandar isso para
os servidores de outra empresa no exterior é uma transferência internacional que precisa de base legal
e de contrato, e a resposta de algumas organizações é simplesmente não. Se for não, a escolha está
feita: uma ferramenta auto-hospedada. Se for sim, os serviços hospedados poupam muito trabalho de
operação.

**Depois, quem vai rodar.** Seis contêineres, dois bancos e uma fila são um pequeno sistema de produção
por si só. Precisam de backups, atualizações, disco, e alguém que os conheça quando o worker atrasar.
Uma equipe sem essa capacidade é mais bem servida por um serviço hospedado com um bom contrato do que
por um auto-hospedado de que ninguém cuida.

**E mantenha a instrumentação portável.** O assistente desta aula mandou os mesmos spans para um
arquivo e para o Langfuse com duas variáveis de ambiente, porque escreve OpenTelemetry e a sua
convenção, e os nomes específicos da ferramenta são acrescentados num adaptador de onze linhas na
borda. Esse arranjo torna a escolha reversível. Uma aplicação que chama o SDK de um fornecedor em toda
função tomou uma decisão que vai pagar para desfazer.

A aula 13 do `observability` faz as mesmas perguntas a produtos comerciais de APM, e chega à mesma
ordem: dados primeiro, operação depois, funcionalidades por último. A aula 7 a aplica a mais duas
ferramentas, uma delas construída sobre outra ideia.
