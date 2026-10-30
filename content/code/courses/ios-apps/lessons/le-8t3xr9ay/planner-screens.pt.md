---
title: A tela de curso do planner, com um plano dentro
version: 1
---

**A tela de curso agora tem tudo de que esta aula trata: um dono, linhas que o mudam por bindings, e
um total que é calculado.** As quatro telas do planner são as mesmas em toda plataforma para a qual a
trilha `mobile` o constrói: `CourseListView`, `CourseDetailView`, `SessionForm` e `WeekView`. Esta
seção junta as duas primeiras em volta de um `@State`. Nada nela foi executado; ela foi escrita a
partir da documentação da Apple para `List`, `ForEach`, `Toggle` e `NavigationLink`, e dos tipos do
próprio pacote, que a seção 06 testou.

```schooling-example
{"language": "swift", "file": "CourseListView.swift", "parts": [{"code": "// CourseListView.swift\nimport SwiftUI\nimport PlannerCore\n\nstruct CourseListView: View {\n    @State private var plan: Plan\n    let today: String\n\n    init(plan: Plan, today: String) {\n        _plan = State(initialValue: plan)\n        self.today = today\n    }\n", "note": "A lista é a dona. Ela é a primeira tela e nada acima dela precisa do plano, então este é o único `@State` do app por enquanto. A aula 7 o leva para um modelo observável quando uma segunda tela precisar dele."}, {"code": "    var body: some View {\n        NavigationStack {\n            List(plan.courses) { course in\n                NavigationLink(course.title) {\n                    CourseDetailView(course: course, plan: $plan, today: today)\n                }\n            }\n            .navigationTitle(\"Courses\")\n        }\n    }\n}\n", "note": "Cada curso abre a sua tela de detalhe, e a tela de detalhe recebe `$plan`, um binding. A aula 9 trata da navegação em si."}]}
```

```schooling-example
{"language": "swift", "file": "CourseDetailView.swift", "parts": [{"code": "// CourseDetailView.swift\nimport SwiftUI\nimport PlannerCore\n\nstruct CourseDetailView: View {\n    let course: Course\n    @Binding var plan: Plan\n    let today: String\n", "note": "Nenhum `@State` aqui. A tela de detalhe muda o plano, então recebe um binding para o da lista."}, {"code": "    var body: some View {\n        let total = plan.weekTotal(today: today)\n        List {\n            ForEach($plan.sessions) { $session in\n                if session.courseID == course.id {\n                    SessionRow(session: $session)\n                }\n            }\n            Text(\"This week: \\(total.done) of \\(total.planned) minutes\")\n        }\n        .navigationTitle(course.title)\n    }\n}\n", "note": "Um binding por sessão, filtrado para este curso, e o total da semana calculado a partir do mesmo plano no mesmo `body`. Marcar uma linha escreve por `$session` e `$plan` no estado da lista, e as duas telas são desenhadas de novo a partir dele."}]}
```

**Siga um toque do dedo até o rodapé.** O `Toggle` da `SessionRow` escreve `true` no seu
`Binding<Bool>`. Esse binding foi estreitado de `$session`, que foi estreitado de `$plan`, que é o
`@State` da lista; então a escrita cai no único plano que o app tem. O SwiftUI vê a mudança de estado
e roda o `body` de toda view que o leu. A linha é redesenhada marcada, e o rodapé calcula o
`weekTotal` de novo a partir do plano que agora inclui o toque. **Nenhuma linha deste código copia um
número de um lugar para outro**, e por isso nenhuma linha pode esquecer de copiar.

O que o código ainda não faz é guardar o plano quando o app fecha, compartilhá-lo com a tela da semana
sem passar bindings por todos os níveis, ou buscá-lo num servidor. As aulas 7, 12 e 14 acrescentam
isso, uma de cada vez, e a regra da seção 02 continua a mesma nas três.
