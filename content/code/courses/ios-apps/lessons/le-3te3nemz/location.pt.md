---
title: Localização, e o planner que não precisa dela
version: 1
---

**A localização tem dois níveis, e o planner não precisa de nenhum.** Ela está nesta aula porque "a
localização deixaria isto mais bonito?" é uma pergunta que todo app encontra, e a resposta aqui
mostra como decidir. Nada nesta seção foi executado; ela foi escrita a partir do artigo da Apple
*Requesting authorization to use location services*, lido em 30 de outubro de 2026.

Os dois níveis, nas palavras do artigo:

- **When In Use** "makes location updates available only when someone uses your app", e o artigo o
  chama de "the preferred choice, because it has better privacy and battery life implications". A
  chave é `NSLocationWhenInUseUsageDescription`.
- **Always** "makes location updates available at any time, and lets the system launch your app
  quietly to handle some updates". Ele precisa de `NSLocationAlwaysAndWhenInUseUsageDescription`
  além da primeira chave, e o iOS lembra a pessoa mais tarde de que o app anda usando a localização.

É do artigo também a regra sobre o momento: "make authorization requests only when someone engages
a part of your app that requires that data", porque um pedido "immediately at app launch, or in a
part of your app that doesn't clearly use location data" é um que a pessoa "might misinterpret" e
nega.

```swift
// Nearby.swift: what asking would look like, if the planner needed it
import CoreLocation

final class Nearby: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    func start() {
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }
}
```

O pedido volta na hora e a resposta chega depois, no delegate, porque a pessoa pode levar o tempo
que quiser com o alerta.

## Decidindo, para o planner

Uma ideia que aparece: lembrar a pessoa de estudar quando ela chegar à biblioteca. Ela precisa do
**Always**, o nível mais forte que o iOS tem, para poupar alguém de escolher um horário. A aula 17 já
agenda um lembrete num horário que a pessoa escolheu, sem localização nenhuma. **Um recurso que
precisa de uma permissão mais forte que o problema que ele resolve tem de merecê-la**, e a diretriz
5.1.1(iii) diz o mesmo com as palavras da Apple: pedir "access to data relevant to the core
functionality of the app". O núcleo de um planner de estudos é o plano, então o planner não pede
localização, não escreve nenhuma chave de localização e tem um alerta a menos para explicar.
