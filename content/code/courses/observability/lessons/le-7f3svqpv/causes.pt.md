---
title: Fatores contribuintes, não uma causa raiz
version: 1
---

A expressão *causa raiz* promete que um incidente tem uma causa só lá no fundo, e que removê-la impede o
incidente. **Incidentes reais em sistemas que já são confiáveis raramente têm uma.** Eles acontecem
quando várias condições, cada uma inofensiva sozinha, se alinham na mesma tarde.

Os **cinco porquês** são o método clássico: perguntar por que a falha aconteceu, depois por que isso
aconteceu, cinco vezes. Aplicados ao incidente da aula 17:

1. Por que os checkouts falharam? O payments falhou uma cobrança em oito.
2. Por quê? A versão 1.4.2 do payments tinha um bug no tratamento das respostas da rede de cartões.
3. Por que ela chegou à produção? Os testes rodavam contra um mock que nunca responde com esse erro.
4. Por que ninguém percebeu durante minutos? A versão foi para todas as instâncias de uma vez.
5. Por quê? A esteira não tem etapa de canary para o payments.

É útil, porque continua perguntando depois da primeira resposta. A fraqueza é que ele percorre **uma**
cadeia e para em qualquer que seja a quinta resposta. Perguntado por outra pessoa, o mesmo incidente
poderia terminar em *o mock é mantido por outra equipe*, ou *ninguém é dono da lista de verificação de
lançamento*.

Um postmortem por isso lista **fatores contribuintes**: toda condição sem a qual o incidente não teria
acontecido, ou teria sido menor. Para o mesmo incidente:

| fator | tipo |
|---|---|
| o bug no tratamento de uma resposta de erro na 1.4.2 | gatilho |
| testes contra um mock que nunca devolve esse erro | defesa ausente |
| lançamento para todas as instâncias de uma vez, sem canary | defesa ausente |
| um alerta de queima rápida que precisa encher a janela de cinco minutos antes de acionar | detecção mais lenta |
| existia uma anotação de deploy, então *o que mudou?* teve resposta em segundos | defesa que funcionou |

A última linha importa tanto quanto as outras. **O que deu certo também é registrado**, porque é a parte
com mais chance de ser removida por alguém arrumando uma esteira sem saber que ela já ajudou.

Cada defesa ausente, e não o gatilho, é de onde vêm as ações. Corrigir o bug corrige este bug; uma etapa
de canary e um mock melhor pegam o próximo, seja ele qual for.
