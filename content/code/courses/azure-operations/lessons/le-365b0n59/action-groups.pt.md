---
title: Action groups: quem fica sabendo
version: 1
---

**Uma regra de alerta não sabe a quem avisar; ela nomeia um ou mais action groups, e eles avisam.** Um action group é uma
lista reutilizável de destinatários, então as doze regras que devem acordar o plantonista nomeiam todas o mesmo grupo, e
mudar quem está de plantão é uma edição em vez de doze.

```bicep
// action-group.bicep
resource onCall 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-shop-oncall'
  location: 'Global'
  properties: {
    groupShortName: 'shoponcall'
    enabled: true
    emailReceivers: [
      { name: 'on-call', emailAddress: 'oncall@example.com', useCommonAlertSchema: true }
    ]
    webhookReceivers: [
      { name: 'chat', serviceUri: 'https://chat.example.com/hooks/shop', useCommonAlertSchema: true }
    ]
  }
}
```

```
ana@laptop:~/azure/alerts$ bicep build action-group.bicep; echo "exit status $?"
exit status 0
```

Os destinatários aqui são um endereço de e-mail e um **webhook**, um endpoint HTTPS que recebe o alerta como JSON, que é
como alertas chegam a um canal de chat, a um serviço de plantão ou à automação da própria loja. Os dois endereços são das
faixas da documentação: `example.com` não pertence a ninguém. Action groups também oferecem SMS e ligação de voz, um push
para o aplicativo móvel do Azure, e ações que rodam código: uma Azure Function, um Logic App, um runbook do Automation. SMS e
voz são cobrados por mensagem e por ligação, e os dois têm limites por número por hora, um dos motivos para guardá-los para
severidades 0 e 1.

**`useCommonAlertSchema: true`** faz todo alerta chegar num formato JSON único, seja qual for o tipo de regra que disparou.
Sem isso, um alerta de métrica e um alerta de pesquisa de log chegam em formatos diferentes, e todo consumidor precisa
entender os dois. Ligue em todo lugar; não há motivo para não ligar.

O que decide se o plantonista confia na chamada não é o action group; é a regra. Um action group que recebe uma chamada por
dia por coisas que ninguém resolve ensina quem segura o telefone a ignorá-lo. A lição 14 é sobre escolher as regras para uma
chamada significar que um cliente foi afetado.
