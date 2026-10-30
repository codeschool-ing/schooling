---
title: Alert processing rules: quando ninguém deve ficar sabendo
version: 1
---

**Uma alert processing rule muda o que acontece com os alertas depois que disparam, sem mexer nas regras que os
dispararam.** Os dois trabalhos comuns dela são acrescentar um action group a todo alerta num escopo e tirar todos por um
período. O segundo é manutenção:

```bicep
// maintenance.bicep
resource quietDuringMaintenance 'Microsoft.AlertsManagement/actionRules@2021-08-08' = {
  name: 'quiet-during-db-maintenance'
  location: 'Global'
  properties: {
    enabled: true
    scopes: [ resourceGroup().id ]
    actions: [
      { actionType: 'RemoveAllActionGroups' }
    ]
    schedule: {
      timeZone: 'E. South America Standard Time'
      effectiveFrom: '2026-10-25T02:00:00'
      effectiveUntil: '2026-10-25T04:00:00'
    }
    description: 'Planned SQL maintenance: alerts still fire and are recorded; nobody is paged.'
  }
}
```

```
ana@laptop:~/azure/alerts$ bicep build maintenance.bicep; echo "exit status $?"
exit status 0
```

No domingo, 25 de outubro, entre 02:00 e 04:00 em São Paulo, o banco SQL da loja fica fora para manutenção planejada, e o
checkout vai falhar. Sem esta regra, o `checkout-failing` chama o plantonista às 02:05 por algo que todo mundo sabia que ia
acontecer. Com ela, **o alerta continua disparando e sendo registrado**; só a notificação é removida. Essa diferença é o
motivo para suprimir aqui em vez de desativar a regra de alerta: uma regra desativada não registra nada, então se outra coisa
quebrar durante a janela não fica rastro. E uma regra desativada para manutenção é uma regra que alguém esquece de reativar.

O horário recebe um nome de fuso do Windows, `E. South America Standard Time`, que é o de São Paulo. Errar o fuso é o erro
clássico aqui: uma janela escrita em UTC silencia das 23:00 à 01:00 e chama todo mundo às 02:05.

As processing rules também são onde uma equipe acrescenta um action group a todo alerta de uma assinatura de uma vez, para
uma regra nova que ninguém ligou a nada ainda chegar a alguém. A loja tem uma: todo alerta de severidade 0 da assinatura
também vai para o webhook do chat, diga o que disser a própria regra.
