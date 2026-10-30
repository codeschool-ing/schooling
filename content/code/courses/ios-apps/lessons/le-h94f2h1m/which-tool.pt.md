---
title: Qual ferramenta, para qual estado
version: 1
---

**As aulas 6 e 7 deram seis jeitos de entregar dados a uma view, e a escolha entre eles é uma pergunta
sobre posse.** Quem cria o valor, quem o muda, e quão longe está a view que o lê. A tabela diz isso uma
vez:

| a view… | o dado é… | escreva |
|---|---|---|
| só o lê | um valor | `let session: StudySession` |
| é dona dele, e ninguém mais precisa | um valor | `@State private var expanded = false` |
| muda um valor de que o pai é dono | um valor | `@Binding var session: StudySession` |
| cria um modelo compartilhado | uma classe `@Observable` | `@State private var model = PlannerModel(…)` |
| lê ou chama um modelo que recebeu | uma classe `@Observable` | `let model: PlannerModel` |
| precisa de bindings para um modelo que recebeu | uma classe `@Observable` | `@Bindable var model: PlannerModel` |
| lê um modelo de que muitas views em muitas profundidades precisam | uma classe `@Observable` | `@Environment(PlannerModel.self) private var model` |

**Duas perguntas resolvem quase todos os casos.** Primeira: isto é um valor ou um objeto? Um valor
— uma sessão, um rascunho sendo digitado, uma flag — vai para o `@State` com o seu dono e viaja por
`let` ou `@Binding`. Um objeto guarda estado que dura mais que uma tela e que várias telas
compartilham. Segunda: quem o cria? Quem cria o guarda em `@State`, valor ou objeto, e é o único que
faz isso.

No planner isso vira quatro decisões. O `PlannerApp` cria o `PlannerModel` e o põe no ambiente. A
`CourseListView`, a `CourseDetailView` e a `WeekView` o leem de lá. A `SessionRow` recebe um
`@Binding` para uma sessão, ou um valor simples mais uma closure. E a `SessionForm`, da aula 10,
guarda o seu rascunho no próprio `@State` até a pessoa salvar, porque uma sessão digitada pela metade
ainda não pertence a mais ninguém.

**O que nunca está na lista** é um segundo dono: uma filha que copia um valor recebido para o próprio
`@State`, ou uma view que faz o seu próprio `PlannerModel()` em vez de receber o que o app criou. Os
dois compilam, os dois funcionam na primeira tela, e os dois dão ao app dois planos.
