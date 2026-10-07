---
title: Requisições de serviço e níveis de serviço
version: 1
---

Nem tudo o que os usuários pedem é falha. Uma recepcionista que precisa de uma conta, um gestor de clínica que quer um relatório exportado, um fisioterapeuta que esqueceu a senha: essas são **requisições de serviço**, que o ITIL define como um pedido de um usuário por algo que faz parte normal do serviço. Elas são tratadas numa prática separada, o **gerenciamento de requisições de serviço**, com passos predefinidos, muitas vezes totalmente automatizados, e nunca deveriam ser registradas como incidentes. Uma central de atendimento que trata troca de senha como incidente acaba com estatísticas de incidentes que não dizem nada sobre falhas.

## Combinando o que o serviço oferece

O **gerenciamento de nível de serviço** define metas claras e mensuráveis para o serviço e confere se são cumpridas. As metas ficam num **acordo de nível de serviço**, ou SLA: um acordo documentado entre o provedor e o cliente que diz o que o serviço vai fazer e quão bem. Para o aplicativo Agenda, um SLA com a rede de clínicas poderia dizer:

| medida | meta |
|---|---|
| disponibilidade do agendamento, das 7h às 21h | 99,5% das horas de cada mês |
| incidentes de prioridade 1 | atendidos em 15 minutos, resolvidos em 4 horas |
| incidentes de prioridade 3 | resolvidos em 2 dias úteis |
| contas novas de usuário | criadas em 1 dia útil após o pedido |

Atrás do SLA ficam dois outros acordos que o cliente nunca vê. Um **acordo de nível operacional** (OLA) é entre partes da mesma organização — o time Agenda e o time de infraestrutura, por exemplo — e compromete cada uma com a parte da meta que controla. Um **contrato de apoio** é com um fornecedor de fora, como o provedor de hospedagem ou o gateway de SMS. Um SLA prometendo 99,5% de disponibilidade em cima de um contrato de hospedagem que garante 99% é uma promessa que o provedor não consegue cumprir, e vale conferir antes de assinar.

## Medindo o que os usuários sentem

Uma fraqueza conhecida dos SLAs é o **efeito melancia**: verde por fora, vermelho por dentro. Toda meta é cumprida — incidentes fechados no prazo, disponibilidade acima da linha — enquanto os usuários estão insatisfeitos, porque as metas medem o que era fácil de medir. O agendamento pode estar tecnicamente disponível levando vinte segundos por tela. Um bom gerenciamento de nível de serviço pergunta aos usuários com regularidade e acrescenta metas para o que eles de fato vivem. Um arquiteto pode ajudar desenhando sistemas que medem a experiência diretamente, como o tempo de resposta de um agendamento real, em vez do tempo de atividade de um servidor.
