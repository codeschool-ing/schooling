---
title: Notificações remotas, e o token que endereça um telefone
version: 1
---

**Uma notificação remota vem de um servidor, pelo serviço de notificações push da Apple, para um app num
aparelho.** O app não mantém uma conexão aberta para isso; o telefone mantém, com o APNs, para todos os
apps de uma vez. O que o servidor do planner precisa é de um endereço, e a documentação da Apple sobre
registrar no APNs o chama de **token do aparelho**: "único para o aparelho e para o seu app", e o
servidor tem de tê-lo antes de conseguir entregar qualquer coisa. Nada disso foi executado para o curso:
precisa de um aparelho, de uma conta de desenvolvedor paga e de uma chave do APNs, e a aula 21 é onde a
conta entra.

## Quatro passos, dois deles no telefone

| passo | quem | o que acontece |
|---|---|---|
| 1 | o Xcode, uma vez | a capacidade *Push Notifications* acrescenta o entitlement `aps-environment` ao app |
| 2 | o app, a cada abertura | `UIApplication.shared.registerForRemoteNotifications()` pede o token ao APNs |
| 3 | o app | `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` o recebe, e o envia ao servidor do planner |
| 4 | o servidor | envia o payload da seção 07 ao APNs com esse token, assinado com a chave do time |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l17-push\" aria-label=\"Três colunas, da esquerda para a direita: o planner no telefone, o serviço de notificações push da Apple, e o servidor do planner. O tempo corre para baixo. Primeiro o app pede registro ao APNs e recebe um token do aparelho. Depois o app envia esse token ao servidor do planner, que o guarda com a conta. Mais tarde, quando uma sessão é acrescentada em outro aparelho, o servidor envia ao APNs um payload com o token, e o APNs o entrega ao telefone, que o mostra.\"><defs><marker id=\"l17-push-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l17-push-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17-push-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l17-push-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"16\" width=\"190\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o planner, no telefone</text><path d=\"M110 52 L110 312\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><rect x=\"265\" y=\"16\" width=\"190\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">APNs</text><path d=\"M360 52 L360 312\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><rect x=\"515\" y=\"16\" width=\"190\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o servidor do planner</text><path d=\"M610 52 L610 312\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M114 82 L356 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-push-ah-phosphor)\"></path><text x=\"235\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">registerForRemoteNotifications()</text><path d=\"M356 118 L114 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-push-ah-phosphor)\"></path><text x=\"235\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">token do aparelho</text><path d=\"M114 160 L606 160\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-push-ah-amber)\"></path><text x=\"360\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o token, enviado a cada abertura e guardado com a conta</text><text x=\"610\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">depois: uma sessão acrescentada em outro lugar</text><path d=\"M606 236 L364 236\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-push-ah-amber)\"></path><text x=\"485\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">payload + token</text><path d=\"M356 276 L114 276\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-push-ah-amber)\"></path><text x=\"235\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a notificação</text></svg>", "caption": "O token vai do telefone ao servidor, de novo a cada abertura; toda notificação vai então do servidor ao APNs, e do APNs ao telefone.", "same": ["APNs", "payload + token"]}
```

A documentação da Apple para o passo 2 diz para registrar a cada abertura, e que o token chega no app
delegate, o mesmo `AppDelegate` da seção 05:

```swift
// AppDelegate.swift, the token
func application(_ application: UIApplication,
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    Task { await sendTokenToServer(token) }
}

func application(_ application: UIApplication,
                 didFailToRegisterForRemoteNotificationsWithError error: Error) {
    pushError = error        // shown in the reminders settings, never swallowed
}
```

**O token são dados, enviados como texto hexadecimal.** Ele não é um segredo como uma senha é, mas é o
endereço de um app no telefone de uma pessoa, então o servidor o trata como dado pessoal: ele é guardado
junto da conta, e removido quando a conta é.

A documentação é explícita em dois pontos que vale repetir. Um token pertence a um app: dois apps no
mesmo telefone recebem tokens diferentes. E o app se registra e recebe o token a cada abertura, então
envia o que acabou de receber em vez de confiar no último que enviou; um servidor com um token que já não
é o do telefone envia para ninguém, e nada falha onde alguém veja.

## Permissão, de novo

Registrar-se para um token não precisa da permissão da pessoa; mostrar algo precisa. A documentação da
Apple para `registerForRemoteNotifications()` diz que, sem a autorização da seção 02, "o sistema entrega
todas as notificações remotas ao seu app em silêncio". Então o planner pergunta no mesmo momento que para
os lembretes locais, e uma resposta cobre os dois.

## O que o planner envia, e por que tão pouco

O servidor do planner envia um tipo de push: uma sessão foi acrescentada em outro aparelho do estudante.
Ele poderia, em vez disso, manter o telefone em dia em silêncio, com pushes em segundo plano, e a
documentação da Apple para esses diz que o sistema os trata como baixa prioridade, não garante a entrega,
pode limitá-los, e pede no máximo dois ou três por hora. A aula 16 trata do que o iOS permite em segundo
plano, e a resposta do planner ali, atualizar quando o app abre, vale aqui também: **um push diz que algo
aconteceu, e o app busca o quê**.
