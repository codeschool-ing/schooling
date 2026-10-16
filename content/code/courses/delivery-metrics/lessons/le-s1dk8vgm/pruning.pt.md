---
title: Remover, rebaixar e corrigir alertas
version: 1
---

O programa dá três veredictos, e cada um é um trabalho diferente. Nenhum deles é "deixe como está e tome mais cuidado".

## Remover, ou transformar em chamado

Quatro dos alertas do time de Billing nunca precisaram de uma pessoa em treze semanas. Para cada um, o time fez uma pergunta: **tem alguma coisa aqui que alguém deveria saber nesta semana?**

- **"Database disk over 80%"** virou um chamado, aberto automaticamente quando a previsão é de o disco encher em até duas semanas no ritmo atual. Um disco que enche ao longo de dias é um problema de planejamento; uma previsão avisa disso no horário de trabalho, com tempo para agir.
- **"TLS certificate expires in 30 d"** também virou chamado. Trinta dias de aviso são a razão de ser do alerta, e ninguém precisa ouvi-lo às duas da manhã.
- **"API CPU over 85%"** foi para o painel, ao lado da latência das cobranças que ele poderia explicar. É uma causa, útil ao investigar um sintoma e inútil sozinha.
- **"Health check failed once"** foi apagado. Uma checagem falha em centenas é um soluço; o alerta que importa é o de cobranças falhando, e o time já o tem.

**Apagar um alerta parece perigoso e raramente é.** O medo é que o alerta apagado fosse justamente o que pegaria alguma coisa. A resposta é perguntar o que pegaria essa coisa no lugar dele, e, num serviço com um bom alerta de sintoma, a resposta quase sempre é o alerta de sintoma.

## Corrigir

Dois alertas precisavam de uma pessoa às vezes, e menos vezes do que acionavam. Esses não são para apagar; são para tornar precisos.

- **"Card provider p99 over 2 s"** foi substituído pelo alerta de burn rate da aula 16. A lentidão do provedor só importa quando as lojas esperam o bastante para as cobranças contarem como ruins; o burn rate aciona exatamente aí, e na tarde de 30 de setembro teria acionado às 17:30 com um sintoma que ninguém poderia chamar de ruído. O alerta antigo ficou no painel.
- **"Statement queue over 500"** ganhou uma duração: acionar só se a fila ficar acima de 500 por vinte minutos e não estiver diminuindo. Uma fila que dá um pico e escoa é uma fila funcionando; uma que cresce por vinte minutos é um extrato que vai atrasar no dia 1º.

Acrescentar **uma duração** e **uma taxa de variação** são as duas correções mais baratas para um alerta que dispara com pressa demais. A maioria dos alertas ruidosos dispara com um único minuto ruim, e a maioria dos problemas reais dura mais do que um.

## Manter, com um dono e um runbook

Os três alertas com uma taxa de acionáveis alta ficam, e cada um ganha duas coisas que não tinha:

- **um dono**, uma pessoa que responde pela qualidade do alerta, lê os acionamentos dele nas notas de troca e o altera quando ele se comporta mal;
- **um runbook**, com link no próprio acionamento, que a aula 17 pediu e a seção 03 tornou regra.

## A regra para alertas novos

Podar uma vez não basta; um time que acrescenta alertas à vontade vai estar de volta ao ponto de partida em um ano. O time de Billing acrescentou uma regra ao seu acordo de trabalho: **um alerta novo que aciona vem com seu runbook e seu dono, na mesma mudança, e começa como chamado por duas semanas** antes de poder acordar alguém. Duas semanas de chamados mostram com que frequência ele teria acionado, e se alguém teria feito alguma coisa, antes da primeira noite que ele custa.
