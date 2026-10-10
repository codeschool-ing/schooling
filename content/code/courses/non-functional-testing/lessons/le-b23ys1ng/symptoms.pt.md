---
title: Alerte sobre o que o usuário sente
version: 1
---

Alguns defeitos só existem com usuários reais: o erro que precisa de uma conta específica, a
lentidão que precisa de mil pessoas ao mesmo tempo, o provedor de pagamento que falha às 21:00 de
uma sexta-feira. **Nenhum teste antes da versão teria conseguido pegá-los**, porque as condições não
existiam antes da versão. O monitoramento, das aulas 22 e 23, os torna visíveis. Um alerta faz
alguém olhar, e toda a dificuldade de alertar é fazer alguém olhar para as coisas certas e para mais
nada.

## Sintomas, não causas

Os primeiros alertas que uma equipe escreve costumam ser sobre causas: CPU acima de 90%, memória
acima de 80%, um disco com três quartos ocupados, uma fila com mais de mil itens. Cada um é sobre
uma máquina, e cada um dispara em noites em que todo cliente é atendido perfeitamente bem. **Um
processador a 95% que responde toda reserva a tempo é um processador fazendo o seu trabalho.** E a
queda que de fato acontece costuma ser uma para a qual ninguém escreveu uma causa: o provedor de
pagamento da aula 23, lento, com todas as máquinas ociosas.

Um sintoma é o que o usuário sente, e o RED da aula 22 já os lista:

| | um sintoma: acione alguém | uma causa: olhe de manhã, ou no painel |
|---|---|---|
| erros | mais de 2% das requisições respondidas com 5xx | o log de erros do provedor de pagamento tem linhas |
| duração | o percentil 95 da reserva acima de 500 ms | CPU acima de 90% |
| disponibilidade | a sonda sintética falhando a partir de duas regiões | um de três servidores reiniciou |

**Acione por sintomas, investigue com causas.** As métricas de causa continuam sendo coletadas,
desenhadas, e são o que a pessoa acionada abre em seguida, que é o trabalho do método USE. Elas só
não acordam ninguém sozinhas.

## SLOs, e queimar um orçamento

Um limite como 2% é mais fácil de defender quando vem de um acordo sobre o serviço. **Um objetivo
de nível de serviço**, um SLO, diz quão bom o serviço tem de ser num período: *99,5% das requisições
de reserva dão certo, medidas em 30 dias*. O 0,5% que sobra é o *orçamento de erro*, as falhas que o
serviço pode ter. Um mês de 300.000 requisições de reserva pode ter 1.500 delas falhando, e cada
falha gasta parte disso.

Isso transforma o alerta numa pergunta sobre velocidade. Uma razão de 1% gasta o orçamento duas
vezes mais rápido do que o SLO permite, o que o esgotaria em quinze dias: vale um chamado, não um
telefonema de madrugada. Uma razão de 2% o esgota em cerca de uma semana. Uma razão de 7,2% é uma
*taxa de queima* (*burn rate*) de 14,4, que gasta o orçamento de um mês inteiro em cerca de dois
dias; é a taxa que o SRE workbook do Google usa para o seu acionamento mais rápido. Alertar pela taxa
de queima em vez de uma razão fixa dá um motivo a cada limite, e deixa um vazamento lento e
constante abrir um chamado enquanto um rápido acorda alguém.

O requisito da aula 1 é a forma mais simples, 2% fixos, e é o que a próxima seção escreve. A versão
com SLO é a mesma regra com um número derivado em vez de escolhido.

## Esperando, e o orçamento de tempo

Uma razão que encosta em 2% numa coleta e volta é ruído. **O `for:` faz uma regra esperar** até a
condição se manter por um tempo declarado antes de disparar. Curto demais, e todo soluço aciona
alguém; longo demais, e o alerta chega depois que os clientes desistiram e escreveram reclamando.

A aula 1 deu ao alerta cinco minutos, contados a partir do momento em que a razão de erro passa de
2%. Esses cinco minutos são gastos em vários lugares, e cada um é uma configuração que alguém
escolheu:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l24-budget\" aria-label=\"Uma linha do tempo de cinco minutos, começando quando a razão de erro de cinco minutos passa de 2%. Alguns segundos vão na coleta e na avaliação da regra. Depois dois minutos de for, com o alerta pendente. Depois 30 segundos de group_wait do Alertmanager. Depois o serviço de plantão toca um telefone, mais alguns segundos. O resto, um pouco mais de dois minutos, é a margem para uma pessoa acordar e confirmar antes de acabarem os cinco minutos. Abaixo, a mesma linha com o for em cinco minutos: o for sozinho chega ao fim dos cinco minutos, e o aviso chega depois.\"><text x=\"60.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a razão passa de 2%</text><text x=\"660.0\" y=\"26.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">5 minutos</text><path d=\"M60.0 36.0 L60.0 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M660.0 36.0 L660.0 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"60.0\" y=\"56.0\" width=\"20.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><rect x=\"80.0\" y=\"56.0\" width=\"240.0\" height=\"34.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"200.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">for: 2m</text><rect x=\"320.0\" y=\"56.0\" width=\"60.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"350.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">group_wait</text><rect x=\"380.0\" y=\"56.0\" width=\"20.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><rect x=\"400.0\" y=\"56.0\" width=\"260.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"530.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">margem para acordar e confirmar</text><text x=\"70.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">coleta, avaliação</text><text x=\"390.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">telefone toca</text><rect x=\"60.0\" y=\"156.0\" width=\"20.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><rect x=\"80.0\" y=\"156.0\" width=\"580.0\" height=\"34.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"370.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">for: 5m</text><text x=\"668.0\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">depois</text><text x=\"360.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">com for: 5m o requisito quebra antes de alguém ser avisado</text></svg>", "caption": "Os cinco minutos da aula 1, gastos. Cada bloco é uma configuração que alguém escolheu."}
```

O Prometheus tem de coletar as falhas e avaliar a regra, alguns segundos cada nos intervalos deste
curso. O `for: 2m` o segura por dois minutos. O Alertmanager espera 30 segundos para agrupá-lo com
outros. O serviço de plantão toca um telefone. O que sobra é a margem para uma pessoa acordar e
confirmar. **Com `for: 5m`, o requisito já está quebrado antes de alguém ser avisado**, o que a
próxima seção prova com um teste.

## Menos alertas, para cada um ser lido

**Fadiga de alertas** é o que acontece com uma equipe acionada por coisas que não pedem ação: ela
para de ler os acionamentos. O alerta que importa chega no meio de uma enxurrada dos que não
importavam, às 03:00, e é confirmado e ignorado junto com os outros. Muitos relatos de uma queda que
o monitoramento pegou e ninguém tratou descrevem exatamente isso.

As regras contra isso são curtas. **Todo acionamento tem de precisar de um humano, agora.** Se a
resposta certa é "olhar amanhã", é um chamado. Se ninguém pode fazer nada, é um gráfico. Se ele
dispara toda semana e está sempre tudo bem, o limite está errado ou o alerta deve sair, e apagar um
alerta faz parte do trabalho tanto quanto escrever um. Uma equipe que conta os seus acionamentos por
semana, e trata uma contagem subindo como um defeito, mantém o próximo valendo a leitura.
