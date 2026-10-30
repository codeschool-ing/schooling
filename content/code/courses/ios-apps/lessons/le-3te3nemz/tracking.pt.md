---
title: Rastreamento, e o alerta que o planner nunca mostra
version: 1
---

**Rastreamento tem um sentido estreito no iOS, e não é "coletar dados".** A Apple o define como ligar
dados do seu app a dados de apps e sites de outras empresas, para publicidade ou para medir
publicidade, ou compartilhá-los com um corretor de dados. Um app que faz isso tem de perguntar
antes, pelo framework **App Tracking Transparency**, e o alerta dele carrega a string de
`NSUserTrackingUsageDescription`. Nada aqui foi executado; foi escrito a partir da documentação da
Apple para essa chave e para o `ATTrackingManager`, lida em 30 de outubro de 2026.

A documentação da chave é direta sobre o que acontece sem ela: "Your app crashes if it attempts to
use the AppTrackingTransparency framework without including the key". E a diretriz 5.1.2(i)
acrescenta que "you must receive explicit permission from users via the App Tracking Transparency
APIs to track their activity".

```swift
// Tracking.swift: the request, for an app that tracks
import AppTrackingTransparency

func askToTrack() async -> Bool {
    await ATTrackingManager.requestTrackingAuthorization() == .authorized
}
```

## O planner não rastreia

O planner guarda o plano no telefone e, a partir da aula 12, no seu próprio servidor. Ele não manda
nada a uma rede de publicidade e não liga nada aos dados de mais ninguém. **Então ele nunca chama
isto, não tem `NSUserTrackingUsageDescription`, e o manifesto de privacidade dele diz que
`NSPrivacyTracking` é falso.** A seção 06 confere que os dois concordam.

A falha a evitar é o SDK de terceiros que ninguém leu. Uma biblioteca de analytics ou de publicidade
acrescentada por causa de um recurso pode rastrear em nome do app, e o app responde por ela: a
documentação da Apple sobre manifestos de privacidade pede que todo SDK assim traga um manifesto
próprio, que o Xcode junta ao do app num relatório só. **Leia o manifesto de um SDK antes de
acrescentá-lo**, do mesmo jeito que você lê uma licença.
