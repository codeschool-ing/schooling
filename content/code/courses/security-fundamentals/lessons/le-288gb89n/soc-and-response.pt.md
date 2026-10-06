---
title: SOC e resposta a incidentes
version: 1
---

O **centro de operações de segurança (SOC)** é onde as aulas 10 e 11 viram emprego. Ele coleta logs da
organização inteira, roda regras de detecção sobre eles, e tem gente olhando os alertas que saem, muitas
vezes o tempo todo, em turnos.

### O trabalho

| tarefa | o que quer dizer | onde você a viu |
|---|---|---|
| **triagem** | olhar um alerta, decidir se é real, quão grave, e o que acontece a seguir | os quatro resultados da aula 11, decididos por uma pessoa |
| **investigação** | seguir um alerta real de volta: qual conta, qual máquina, o que mais ele tocou | o log da aula 4, lido como uma história |
| **engenharia de detecção** | escrever e ajustar regras, cortar falsos positivos, fechar falhas achadas em exercícios | os limites da aula 11; o ciclo roxo da aula 10 |
| **resposta a incidentes** | conter, erradicar, recuperar, e escrever o que aconteceu | a restauração da aula 12; os três dias úteis da aula 17 |

### Um dia

O turno de um analista de SOC de primeira linha é quase todo triagem: uma fila de alertas, cada um fechado
como inofensivo com uma nota dizendo por quê, ou escalado para um analista mais experiente. A habilidade
que se constrói é julgamento sob volume, e a conta de taxa de base da aula 11 é o motivo de ser difícil:
quase toda a fila é ruído, e o alerta real tem a mesma cara do resto. Analistas que escrevem boas notas
sobre o que fecharam e por quê são os que têm as escaladas levadas a sério.

Muitos SOCs organizam as pessoas em **níveis** (*tiers*): o nível 1 faz triagem, o nível 2 investiga o que
o nível 1 escala, o nível 3 caça o que nenhum alerta pegou e constrói detecções. Os nomes variam; a ideia
de profundidade crescente não.

### O que pede de você

Paciência com trabalho repetitivo, curiosidade pelo alerta que é diferente, e redes, sistemas operacionais
e logs o bastante para ler o que uma máquina estava fazendo. É o primeiro emprego mais comum em segurança,
porque as organizações precisam de muitos analistas e o trabalho ensina a área inteira: toda técnica de
ataque acaba aparecendo na fila de alguém.

A **resposta a incidentes** é a ponta mais sênior da mesma família. Quando algo real acontece, quem
responde lidera a contenção e a recuperação, coordena com gestão, jurídico e comunicação, e conduz a
reunião de lições aprendidas depois. O `soc-response` cobre o SOC e o ciclo inteiro de resposta, da
preparação ao relatório pós-incidente.
