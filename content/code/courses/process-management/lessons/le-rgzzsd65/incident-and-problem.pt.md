---
title: Incidentes e problemas
version: 1
---

A distinção do ITIL que mais rápido se paga é a que separa **incidente** de **problema**. Times que não a fazem acabam consertando a mesma falha toda semana ou investigando enquanto os usuários esperam.

## Um incidente é sobre restaurar o serviço

O ITIL define incidente como **uma interrupção não planejada de um serviço, ou uma redução da qualidade dele**. O agendamento para de funcionar numa clínica; o aplicativo leva vinte segundos para carregar a agenda; os lembretes param de ser enviados. O objetivo do gerenciamento de incidentes é **restaurar o serviço normal o mais rápido possível**, e para esse objetivo a causa é secundária. Reiniciar o serviço de lembretes, mandar o tráfego para outro servidor ou pedir às recepcionistas que agendem por telefone por uma hora são todas boas respostas a incidente, mesmo que nenhuma explique nada.

Cada incidente é registrado, classificado e recebe uma prioridade, que a próxima seção calcula. Um **incidente grave** — com impacto suficiente para precisar de procedimento próprio — ganha um coordenador dedicado e comunicação com os usuários afetados em intervalos definidos.

## Um problema é sobre a causa

Um problema é **uma causa, ou causa possível, de um ou mais incidentes**. Quando os lembretes param de ser enviados pela terceira segunda-feira seguida, os três incidentes foram resolvidos, e o problema continua lá. O **gerenciamento de problemas** o investiga: o que muda às segundas, que rotina roda nesse dia, por que ela falha. Ele trabalha num relógio diferente do gerenciamento de incidentes, e muitas vezes com outras pessoas, porque não se faz boa análise com o serviço fora do ar e todo mundo olhando.

Quando a causa é encontrada mas ainda não corrigida, o problema vira um **erro conhecido**, registrado com sua **solução de contorno**: os passos que restauram o serviço quando o incidente acontecer de novo. Um erro conhecido com uma boa solução de contorno transforma um incidente de duas horas num de cinco minutos enquanto a correção definitiva espera a vez no backlog.

## Por que a separação importa

Misturar os dois produz as duas falhas de uma vez. Um time que investiga durante o incidente deixa os usuários esperando enquanto lê logs. Um time que só restaura nunca pergunta por quê, então o incidente volta, e a central de atendimento aprende a aplicar o mesmo reinício toda segunda-feira sem ninguém registrar que o reinício é a solução de contorno de uma falha não explicada.

Para um arquiteto, os registros de problemas são o documento mais honesto que a organização tem sobre o sistema. Uma lista de erros conhecidos com soluções de contorno é uma lista de decisões de projeto que não aguentaram a produção, escrita por quem paga por elas.
