---
title: O documento do postmortem
version: 1
---

A revisão é escrita num **documento de postmortem**, e ele é diferente do relatório do incidente da aula 20. O
relatório é para pessoas de fora da resposta, a gestão, clientes, às vezes um regulador, e ele explica. O
postmortem é para quem opera os sistemas, e ele muda coisas. As partes:

| parte | o que entra |
|---|---|
| **resumo** | três frases: o que aconteceu, o impacto, os fatores principais |
| **linha do tempo** | a da aula 12, corrigida pelo que a revisão aprendeu |
| **números** | os intervalos do `milestones.sql` |
| **o que deu certo** | detecção em um minuto; contenção em 33 minutos depois da declaração; evidência coletada antes de cada mudança |
| **fatores contribuintes** | escritos sem culpa, como na terceira seção |
| **ações** | a tabela da seção anterior, com donos e prazos |
| **perguntas em aberto** | o que ainda não se sabe, como quais arquivos estavam nos 612 MB |

**"O que deu certo" não é enfeite.** Uma revisão que lista só falhas ensina à equipe que a revisão é um
castigo, e esconde o que manter: a regra da quinta pegou o login em um minuto, e a próxima versão do SIEM não
pode perder isso por acidente.

O documento é escrito na mesma linguagem sem culpa da reunião, é compartilhado com todos que participaram antes
de ficar final, e é guardado com o registro do incidente. Um ano depois, quando alguém perguntar por que o `gw`
recusa senhas, a resposta é um link.
