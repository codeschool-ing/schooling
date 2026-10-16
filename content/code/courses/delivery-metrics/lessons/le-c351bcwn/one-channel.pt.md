---
title: Um canal, e atualizações no relógio
version: 1
---

Um incidente gera muita conversa, e o pior lugar para essa conversa é em toda parte: mensagens diretas, três canais de chat, uma ligação, um corredor. A informação dita num lugar não chega a quem está nos outros; duas pessoas tentam a mesma correção; uma decisão tomada numa ligação não chega a quem está prestes a fazer o contrário.

## Um incidente, um canal

**Cada incidente ganha um canal próprio**, criado quando é declarado e nomeado a partir dele, e tudo o que quem está respondendo diz é dito ali. O canal vira o registro do incidente sem que ninguém precise montar um: a linha do tempo do escriba, na aula 14, é escrita a partir dele. Uma ligação de voz ou vídeo serve para ganhar velocidade, mas cada decisão tomada na ligação é escrita no canal em até um minuto, pelo escriba.

Quem não está respondendo fica fora do canal do incidente. Essas pessoas precisam de informação, não da investigação, e as perguntas delas no canal de trabalho interrompem quem está consertando. É para isso que existe o líder de comunicação.

## Atualizações no relógio

O líder de comunicação publica atualizações **num ritmo fixo definido pela severidade**, tenha algo mudado ou não: a cada 30 minutos num SEV1, a cada hora num SEV2, na escala do time de Billing. "Sem mudança, ainda investigando, próxima atualização às 18h30" é uma atualização útil. Ela faz as pessoas pararem de perguntar, e prova que alguém está cuidando disso.

Cada atualização responde quatro perguntas, na mesma ordem toda vez:

1. **O que está acontecendo**, nos termos dos usuários: "Algumas lojas estão sendo cobradas duas vezes pela assinatura mensal."
2. **Quem é afetado**, com a precisão que se tem: "Lojas cobradas desde as 17h20 de hoje; cerca de 140 até agora."
3. **O que estamos fazendo**: "Estamos fazendo rollback da versão desta tarde."
4. **Quando sai a próxima atualização**: "Próxima atualização às 18h30, ou antes se isso mudar."

O que as atualizações deixam de fora é especulação sobre a causa. "Achamos que foi a nova lógica de retentativa" numa mensagem ao time de suporte vira, uma hora depois, o que o suporte diz às lojas, e pode estar errado. **A causa pertence ao postmortem**, na aula 15.

## Os públicos

| quem | do que precisa | onde |
|---|---|---|
| quem responde | tudo | o canal do incidente |
| suporte | o que dizer aos usuários, e quando vai estar consertado | um canal de suporte, ou uma mensagem fixada |
| liderança | severidade, impacto, e se precisa agir | uma mensagem curta no mesmo ritmo |
| usuários | que sabemos, o que é afetado, quando esperar notícias | a página de status, e mensagens às lojas afetadas |

Uma pessoa escrevendo para os quatro, a partir dos mesmos fatos, é como os quatro se mantêm coerentes.
