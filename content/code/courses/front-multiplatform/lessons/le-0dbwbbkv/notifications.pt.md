---
title: Notificações locais, um lembrete de manhã
version: 1
---

**Uma notificação local é agendada pelo próprio app, no aparelho, sem servidor.** Essa é a diferença
para uma notificação push, que um servidor manda pelo serviço da Apple ou do Google e que exige contas
nos dois. O "Remind me on" uma data do planner agenda uma para as oito da manhã daquele dia.

Pedida sem ninguém para responder, a solicitação volta indecisa:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click Guitar --click 'Remind me on 2026-10-21' --wait 300 | tail -n 2
  - button "Photo of my notes"
  - status: notifications are prompt
```

**`prompt` não é uma recusa.** Quer dizer que a pergunta não foi respondida, e nesta execução não havia
ninguém para responder: um navegador sem janela não tem diálogo para mostrar. O `remind()` desiste e diz
isso, que é o comportamento certo para um não também. Rode de novo com a permissão concedida antes, como
uma pessoa a concederia apertando Permitir:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click Guitar --grant notifications --click 'Remind me on 2026-10-21' --wait 300 | tail -n 2
  - button "Photo of my notes"
  - status: reminder at 21/10/2026, 08:00:00
```

A notificação de 21 de outubro está agendada. Na web, o plugin a guarda com um temporizador na página,
então ela só dispara com a aba aberta, que é o exemplo mais claro deste curso de uma implementação web
que só faz as vezes da verdadeira.

## Num celular

No Android e no iOS quem guarda a agenda é o sistema. **A notificação dispara com o app fechado**, e no
Android também depois de o celular reiniciar, e é por isso que o manifesto Android do próprio plugin
pede para ser avisado quando o aparelho liga. Três regras da documentação do plugin valem saber antes
da primeira ser agendada:

- **O Android 13 e os seguintes perguntam à pessoa**, como o iOS. Antes do 13, notificações eram
  permitidas por padrão. Chame `requestPermissions()` num momento em que o motivo é claro, aqui quando a
  pessoa aperta o botão, e nunca quando o app abre.
- **Horário exato é uma permissão própria no Android 12 e nos seguintes.** Sem `SCHEDULE_EXACT_ALARM`,
  o sistema pode mover uma notificação para poupar bateria; com ela, a pessoa ainda pode desligar os
  alarmes exatos nas configurações do app.
- **Um id é a identidade da notificação.** Agendar de novo com o mesmo id a substitui, e é por isso que
  o `remind()` usa o número da sessão: apertar o botão duas vezes deixa um lembrete só.
