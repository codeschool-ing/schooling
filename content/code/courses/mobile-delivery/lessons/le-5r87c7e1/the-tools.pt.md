---
title: As ferramentas, e o que elas coletam por padrão
version: 1
---

**A maioria das equipes manda eventos para um produto de analytics em vez de uma tabela SQLite
própria, e todo produto coleta mais por padrão do que o esquema do planner permite.** O trabalho é
configurar o produto até a decisão, e não aceitar os padrões dele. *Nenhum foi configurado para este
curso; lido na documentação de cada produto, outubro de 2026.*

| produto | o que é | o que desligar para as regras do planner |
|---|---|---|
| **Google Analytics for Firebase** | gratuito, parte do Firebase, nas duas plataformas e no React Native | o identificador de publicidade, os Google signals, nomes de tela automáticos se eles incluem conteúdo |
| **Amplitude**, **Mixpanel** | pagos, com planos gratuitos, feitos em torno de funis e coortes | guardar o endereço IP, a coleta automática de identificadores do aparelho |
| **PostHog** | código aberto, pode rodar nos seus servidores | gravação de sessão, captura automática de todo toque e do texto dele |

A **captura automática** (autocapture) merece uma frase própria. Ela registra todo toque com o texto
do elemento tocado, o que numa tela do planner inclui nomes de curso e anotações. Ela é o contrário de
um esquema, e vem ligada por padrão em vários produtos.

## Uma função na frente do produto

Seja qual for o produto, o app o chama num lugar só, uma função `track` como a da seção "Um funil",
que confere o esquema e só então entrega o evento:

```kotlin
// Analytics.kt: the schema checked first, then Firebase
object Analytics {
    private val schema = mapOf("session_done" to setOf("minutes"), "course_added" to setOf("course_count"))
    fun track(name: String, props: Map<String, Long>) {
        val allowed = schema[name] ?: error("event $name is not in the schema")
        require(props.keys.all { it in allowed }) { "event $name: property not in the schema" }
        Firebase.analytics.logEvent(name) { props.forEach { (k, v) -> param(k, v) } }
    }
}
```

```swift
// Analytics.swift: the same check in front of Firebase
enum Analytics {
    static let schema: [String: Set<String>] = ["session_done": ["minutes"], "course_added": ["course_count"]]
    static func track(_ name: String, _ props: [String: Int]) {
        guard let allowed = schema[name], Set(props.keys).isSubset(of: allowed) else {
            assertionFailure("event \(name) or a property is not in the schema"); return
        }
        FirebaseAnalytics.Analytics.logEvent(name, parameters: props)
    }
}
```

```typescript
// analytics.ts in React Native: the lesson's own function, with the product behind it
import analytics from "@react-native-firebase/analytics";
export async function track(name: string, props: Record<string, number> = {}) {
  const allowed = SCHEMA[name];
  if (!allowed || Object.keys(props).some((k) => !allowed.includes(k))) throw new Error(`${name} is not in the schema`);
  await analytics().logEvent(name, props);
}
```

*As três listagens foram escritas a partir da documentação do Firebase e não foram rodadas.* Trocar
de produto depois significa mudar uma função, e não todas as telas, e o esquema sobrevive à troca.
