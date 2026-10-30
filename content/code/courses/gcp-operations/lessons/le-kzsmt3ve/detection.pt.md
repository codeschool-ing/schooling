---
title: De um alerta a um incidente declarado
version: 1
---

**Um incidente é declarado, não descoberto.** Um alerta dispara, um cliente escreve, um colega repara num gráfico;
nada disso é um incidente ainda. Vira um quando alguém diz que é, em voz alta, no lugar onde o time trabalha, e
assume o papel de conduzi-lo. Declarar cedo custa uma mensagem e cinco minutos da atenção de alguém. Declarar
tarde custa a meia hora em que três pessoas investigaram a mesma coisa separadamente e ninguém avisou os clientes.
**Esta lição é sobre pessoas e processo**, e há pouco para rodar; a única parte prática é a linha do tempo,
montada a partir do log da lição 10 na terceira seção.

## De onde vêm os incidentes

A maioria dos incidentes é percebida de uma de quatro formas, e a ordem desta lista é a ordem de preferência:

1. **Um alerta sobre um sintoma**: a queima rápida da lição 13, o uptime check da lição 8.
2. **Uma pessoa olhando um painel** por outro motivo.
3. **Um cliente** escrevendo para o suporte.
4. **A fatura**, uma semana depois (lição 25).

Todo incidente percebido da terceira ou da quarta forma é uma pergunta para o postmortem: por que os alertas não
o pegaram? O incidente de pagamento da loja na lição 10 é um desses, e a terceira seção mostra por quê.

## Severidade, decidida num minuto

| severidade | o que significa para a loja | quem se envolve |
|---|---|---|
| SEV1 | o checkout caiu ou está cobrando errado | todo mundo, agora, e os clientes são avisados |
| SEV2 | o checkout funciona para a maioria, falha ou demora para alguns | quem está de plantão e mais uma pessoa |
| SEV3 | algo está degradado e ninguém está bloqueado | quem está de plantão, em horário comercial |

Escolha a mais alta na dúvida. **Baixar uma severidade depois é de graça; subir depois significa que as pessoas que
deviam estar lá desde o início entram numa conversa que já tem meia hora.**

## Os primeiros cinco minutos

1. Diga "estou declarando um incidente, SEV2, pagamentos com novas tentativas, eu sou o comandante" no canal do
   time.
2. Abra um documento com o horário e essa frase. Ele vira a linha do tempo.
3. Olhe o orçamento do SLO (lição 13): com que velocidade está queimando, e desde quando?
4. Pergunte o que mudou: o último release (o histórico de rollouts da lição 3), o último apply do Terraform (as
   versões do estado da lição 6), a última mudança de configuração.
5. Decida se o caminho mais rápido de volta é um rollback. Em geral, se algo mudou na última hora, é.

O quinto passo é o que os times pulam, em favor de entender a causa primeiro. **Restaurar o serviço vem antes de
entendê-lo**: um rollback (lição 3) leva minutos e não precisa de diagnóstico, e a causa pode ser achada depois,
com o serviço funcionando e o checkout de ninguém falhando enquanto isso.
