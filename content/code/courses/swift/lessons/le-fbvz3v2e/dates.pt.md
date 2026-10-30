---
title: Datas, e o número que ninguém esperava
version: 1
---

Uma sessão de estudo acontece num horário, e `Date` é `Codable`. A surpresa é **como** ela é
codificada quando ninguém diz nada:

```swift
// Dates.swift
import Foundation

struct StudySession: Codable {
    var date: Date
    var minutes: Int
}

let session = StudySession(date: Date(timeIntervalSince1970: 1_793_041_200), minutes: 45)

let plain = try JSONEncoder().encode(session)
print(String(decoding: plain, as: UTF8.self))

let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
let iso = try encoder.encode(session)
print(String(decoding: iso, as: UTF8.self))

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
let back = try decoder.decode(StudySession.self, from: iso)
print(back.date, back.date == session.date)

do {
    _ = try JSONDecoder().decode(StudySession.self, from: iso)
} catch {
    print(error)
}
```

```
ana@vm:~/sw/l13$ swift Dates.swift
{"date":814734000,"minutes":45}
{"date":"2026-10-26T19:00:00Z","minutes":45}
2026-10-26 19:00:00 +0000 true
DecodingError.typeMismatch: Expected value of type Double. Path: date. Debug description: Expected to decode Double but found a string instead.
```

A data da sessão é 26 de outubro de 2026, 19:00 UTC, que é 16:00 em São Paulo. Sem estratégia
definida, **o encoder escreveu `814734000`**: o número de segundos desde 1º de janeiro de 2001, a data de
referência a partir da qual o `Date` da Apple conta. Nenhum servidor fora os da própria Apple espera
esse número, e nada nele diz o que ele é.

`dateEncodingStrategy = .iso8601` escreve o mesmo instante como **`"2026-10-26T19:00:00Z"`**, a forma ISO
8601 que a maioria das APIs usa: uma data, um `T`, uma hora, e `Z` para UTC. Um decoder com a mesma
estratégia a lê de volta, e `back.date == session.date` é `true`, o mesmo instante até o segundo.
Imprimir um `Date` o mostra em UTC, `+0000`, seja qual for o fuso horário da máquina.

O último bloco é o erro no seu habitat natural: uma string ISO decodificada **sem** a estratégia. O
decoder padrão espera o número de 2001, encontra uma string, e diz isso: `typeMismatch`, `Expected to
decode Double but found a string instead`, no caminho `date`. A seção 06 lê erros como este em
detalhe.

## Escolha uma estratégia e mantenha em toda parte

Datas são onde um app e o servidor dele mais discordam, porque os dois lados funcionam nos testes e só
falham quando se encontram. **Decida o formato uma vez, ISO 8601 a menos que o servidor diga outra
coisa, e ajuste-o em todo encoder e decoder que toca o tipo**, ou escreva-o num lugar que os dois usem.
As estratégias incluem também `.secondsSince1970`, para servidores que mandam um timestamp Unix, e
`.formatted`, para um padrão fixo seu.
