---
title: O que é do arquiteto na operação
version: 1
---

O projeto de um arquiteto é julgado duas vezes: uma quando é construído, e por anos depois por quem o opera. Quase tudo o que torna um sistema agradável ou miserável de operar é decidido no projeto, e por isso as práticas do ITIL interessam ao arquiteto mesmo que ele raramente conduza alguma delas.

## Projetando para o gerenciamento de incidentes

Restaurar o serviço rápido depende de decisões tomadas muito antes do primeiro incidente:

- **O sistema consegue dizer que está quebrado?** Verificações de saúde, logs com significado e métricas do que os usuários vivem — o assunto do curso `observability` — decidem se um incidente é detectado pelo monitoramento ou por uma clínica ligando para a central de atendimento.
- **Dá para restaurá-lo sem correção?** Reverter um deploy, passar para um reserva, desligar uma funcionalidade com uma flag: cada uma é uma solução de contorno que precisa ser projetada.
- **Ele consegue falhar em partes?** Um sistema de agendamento em que uma falha nos lembretes por SMS também para os agendamentos transformou uma prioridade 4 numa prioridade 1.

## Projetando para a habilitação de mudanças

Uma mudança é barata e segura quando o sistema permite deploys pequenos, reversíveis e testados automaticamente. Uma arquitetura que só pode ser implantada como uma unidade, de madrugada, com uma migração de banco manual, força toda mudança para o caminho normal da quinta seção desta aula e torna o comitê de mudanças necessário. Projetar para deploys frequentes e independentes é projetar para mudanças padrão.

## Projetando para os níveis de serviço

Uma meta de disponibilidade é um requisito de arquitetura. **99,5%** da janela diária de agendamento de catorze horas num mês de trinta dias — 420 horas — permite **126 minutos** de indisponibilidade no mês; isso descarta um projeto com uma hora semanal de parada planejada. Antes de um SLA ser assinado, o arquiteto é quem consegue dizer se o sistema, a hospedagem e os fornecedores conseguem cumpri-lo, e quanto custaria cumprir um mais rígido.

## Prontidão operacional

Muitas organizações exigem uma revisão de **transição de serviço** ou de **prontidão operacional** antes de um sistema novo entrar no ar: existe runbook, os alertas estão definidos, quem está de plantão, quais são os erros conhecidos, como é feito o backup e a restauração. Um arquiteto que trata essa revisão como lista a cumprir no fim vai encontrá-la cheia de decisões de projeto tarde demais para mudar. Escrever as respostas como parte do projeto, desde a primeira iteração, é o equivalente operacional de pôr requisitos não funcionais na Definição de Pronto.
