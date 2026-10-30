---
title: Pedir, uma vez, no momento certo
version: 1
---

**Um app não pode mostrar uma notificação até a pessoa dizer sim, e ele tem uma chance de perguntar.** A
documentação da Apple sobre pedir permissão para usar notificações é direta sobre as duas coisas: o
primeiro pedido mostra o aviso do sistema e registra a resposta, e "pedidos de autorização seguintes não
perguntam de novo à pessoa". Um não é um não até a pessoa mudá-lo nos Ajustes, o que a maioria nunca
faz. Nada nesta seção foi executado; ela segue essa documentação e a do `UNUserNotificationCenter`, lidas
em 30 de outubro de 2026.

## Quando perguntar

O erro mais comum é perguntar na abertura, antes de a pessoa ver o que o app faz. A documentação dá a
alternativa no próprio exemplo: "num app de tarefas que envia lembretes, você pode fazer o pedido depois
que a pessoa agenda uma primeira tarefa". **O planner é esse app**, então ele pergunta quando o estudante
acrescenta uma primeira sessão e liga o lembrete dela, o momento em que a pergunta tem um motivo óbvio:

```swift
// Asking when the first reminder is turned on
import UserNotifications

func turnOnReminders() async -> Bool {
    let center = UNUserNotificationCenter.current()
    do {
        return try await center.requestAuthorization(options: [.alert, .sound])
    } catch {
        reminderError = error        // shown under the switch
        return false
    }
}
```

O `requestAuthorization(options:)` pede o que o planner usa, um alerta e um som, e nada mais: a
documentação manda um app "pedir só as opções de autorização que pretende usar". Um selo no ícone,
contando sessões não feitas, seria mais uma coisa a explicar e mais um motivo para dizer não.

O `Bool` que volta é `true` quando a pessoa permitiu uma ou mais opções e `false` quando negou ou ainda
não decidiu. Quando a tela precisa saber qual, ela pede os ajustes atuais com `notificationSettings()`, a
forma `async` de `getNotificationSettings(completionHandler:)`, cujo `authorizationStatus` distingue os
casos.

## Antes de perguntar: a explicação é do app

O aviso do sistema mostra o nome do app e os botões, e nada sobre o motivo. Então o planner explica
primeiro, com as suas palavras, no interruptor que liga os lembretes: "Remind me the evening before each
session". **A pessoa toca nesse interruptor, e só então o sistema pergunta**, para que o aviso dele
responda a uma pergunta que a pessoa acabou de se fazer.

## Provisória: experimentar primeiro, decidir depois

A documentação descreve uma segunda forma, a **autorização provisória**, pedida com a opção
`.provisional`. Ela não mostra aviso nenhum. As notificações chegam em silêncio, só na Central de
Notificações, com botões para mantê-las ou desligá-las, então a pessoa decide depois de ver uma em vez
de antes. Para lembretes que um estudante ligou de propósito ela não serve, porque ele pediu para ser
interrompido; para um resumo semanal que o estudante nunca pediu, é a forma honesta de oferecê-lo.

## Quando a resposta é não

O planner continua funcionando: um lembrete negado é um conforto a menos, nunca um plano quebrado. O
interruptor mostra que os lembretes estão desligados nos Ajustes, com um botão que abre a página do app
ali. A aula 18 trata do caminho da recusa de toda permissão, e esta segue a mesma regra: **dizer o que
está desligado, dizer onde ligar, e nunca perguntar de novo em laço**, o que o sistema nem mostraria.
