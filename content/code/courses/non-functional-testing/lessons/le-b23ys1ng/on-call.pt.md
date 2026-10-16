---
title: Plantão, runbooks e o postmortem
version: 1
---

Um alerta é uma mensagem para uma pessoa, e a pessoa tem de existir, estar alcançável, saber o que
fazer e ter permissão para fazer. **A regra é a parte barata; a escala é a cara.**

## Um runbook para cada acionamento

A anotação `runbook_url` aponta para uma página que todo alerta deveria ter antes de poder acionar
alguém. Um runbook é escrito para a pessoa que acabou de ser acordada e nunca viu esse alerta antes,
e responde a quatro perguntas, nesta ordem:

1. **O que este alerta quer dizer para os clientes?** "Mais de 2% das requisições à bilheteria
   estão falhando. Algumas pessoas não conseguem reservar."
2. **Como eu confirmo?** A consulta do `expr`, o painel, `jq 'select(.level == "error")'` sobre o
   log, os últimos resultados da sonda sintética.
3. **O que eu tento primeiro?** As causas conhecidas, a mais provável primeiro, cada uma com o
   comando que a confere: a página de status do provedor de pagamento, o último deploy e como
   revertê-lo, as conexões do banco de dados.
4. **Para quem eu ligo quando isso não resolver?** Um nome ou uma escala, não "o time de backend".

Um acionamento cujo runbook não diz nada útil deveria ser um chamado até alguém escrever um. Um
runbook cujos passos podem ser seguidos sem julgamento deveria virar um script, e aí, muitas vezes,
o alerta pode rodá-lo e não acionar ninguém.

## Escalas e escalonamento

Plantão é uma escala: uma pessoa de cada vez é a primeira a ser acionada, por uma semana ou coisa
assim, e depois passa adiante. Três hábitos o mantêm humano o bastante para durar.

- **Um titular e um reserva.** O serviço de plantão liga para o titular; se ninguém confirmar em,
  digamos, dez minutos, liga para o reserva, e depois para um gestor. Essa cadeia é a *política de
  escalonamento*, e é o que PagerDuty e Opsgenie guardam para você.
- **Passagens de turno por escrito.** O que disparou na semana, o que foi feito, o que continua em
  aberto. A próxima pessoa começa com o contexto em vez de redescobri-lo às 03:00.
- **Acionamentos contados e pagos.** Uma escala que aciona as suas pessoas toda noite é uma escala
  que as perde. A contagem de acionamentos por turno é uma métrica como qualquer outra, com um
  limite.

A frase da aula 1 dizia *chega a quem está de plantão*, não *é enviado*. **Um alerta que dispara
para um Alertmanager que ninguém roda, ou para um telefone que ninguém atende, não chegou a
ninguém**, e o único jeito de saber que a cadeia funciona de ponta a ponta é testá-la: um
acionamento deliberado, num horário fixo, que alguém tem de confirmar.

## O postmortem, sem culpados

Depois de um incidente vem um relato escrito dele, o **postmortem**. Ele conta o que aconteceu, na
ordem e com horários, e como foi detectado e quanto isso levou. Depois diz o que foi feito e qual
foi o impacto para os clientes. Por último vem o que vai mudar para não acontecer de novo, cada
mudança com um dono e uma data.

**Ele é escrito sem culpados**, e isso é uma regra de trabalho, não uma gentileza. A pergunta nunca
é quem errou, e sim por que o sistema deixou uma pessoa razoável errar: por que um deploy com um
cliente de pagamento quebrado passou por todas as verificações, por que o alerta levou onze minutos
quando o requisito dizia cinco. Um postmortem que aponta um culpado ensina todo mundo a esconder o
próximo erro, e um erro escondido é um erro com que o sistema não aprende. O resultado quase sempre é
uma mudança no sistema: um teste, uma verificação no pipeline, um alerta com um limite melhor, um
passo de runbook.

É também de onde vêm os testes deste curso numa equipe que já está rodando há um tempo. Um defeito
que só apareceu com usuários reais vira, depois do postmortem, um teste de carga com o tráfego que o
causou, uma sonda que percorre o caminho que quebrou, uma regra com um teste de unidade. A produção
ensina o que testar em seguida.

## O que os quatro terços têm em comum

Este curso teve quatro assuntos, e a aula 1 disse que cada um tinha as suas ferramentas e o seu
jeito de dizer *passou*. Eles também compartilham um movimento, o que a aula 1 fez primeiro:
**transformar o adjetivo num número, ou numa lista com nome, antes de medir qualquer coisa.**

| terço | o adjetivo | no que este curso o transformou | o que disse *reprovou* |
|---|---|---|---|
| desempenho, aulas 1 a 11 | rápido | um percentil, um limite, uma carga, para uma operação | os limites do teste de carga, e o orçamento de desempenho no pipeline |
| acessibilidade, aulas 12 a 15 | acessível | WCAG 2.2 AA, os critérios pelo nome | os achados do axe, e as verificações de teclado e leitor de tela que uma ferramenta não consegue fazer |
| segurança, aulas 16 a 21 | seguro | os riscos da OWASP, conferidos na sua própria aplicação, e nenhum achado alto deixado aberto | o relatório do scanner, lido por uma pessoa, e o teste de que um cliente não consegue ler a reserva de outro |
| operabilidade, aulas 22 a 24 | vamos saber quando quebrar | uma razão de erro, uma janela e um tempo para chegar a uma pessoa | uma regra com teste de unidade, e um alerta que chega |

Em toda linha a ferramenta foi a parte fácil. O trabalho foi decidir, antes de rodá-la, qual
resultado queria dizer *reprovou*, escrever isso onde a próxima pessoa conseguisse achar, e fazer uma
máquina segurar isso no lugar: um limite num script do k6, uma verificação do axe no pipeline, um
teste do `promtool` ao lado da regra. **Um requisito não funcional que ninguém escreveu é um
desejo**, e cada terço deste curso tratou de fazer essa escrita.
