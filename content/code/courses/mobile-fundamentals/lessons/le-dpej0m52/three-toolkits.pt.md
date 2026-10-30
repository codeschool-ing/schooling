---
title: As mesmas duas abas em três toolkits
version: 1
---

**O toolkit de cada plataforma tem uma biblioteca de navegação, e cada uma guarda a mesma coisa que o
`backstack.ts` guarda: uma lista de telas por pilha, e uma regra para o que voltar faz.** A grafia
muda. Abaixo estão as abas do planner em Jetpack Compose com Navigation Compose, em SwiftUI e em React
Navigation. Elas foram adaptadas da documentação de cada biblioteca, são fragmentos e não apps
inteiros, e **não foram compiladas nem executadas para este curso**. Leia-as para reconhecer a pilha,
as abas e a raiz em cada uma.

## Android: Navigation Compose

```kotlin
// Navigation Compose: routes are values, and the NavHost holds the stack
@Serializable object Courses
@Serializable data class Course(val id: String)

NavHost(navController, startDestination = Courses) {
    composable<Courses> {
        CourseList(onOpen = { id -> navController.navigate(Course(id)) })
    }
    composable<Course> { entry -> CourseDetail(entry.toRoute<Course>().id) }
}

// A tap on the bottom bar's Week item: save this tab's stack, restore Week's.
navController.navigate(Week) {
    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
    launchSingleTop = true
    restoreState = true
}
```

**`navigate` é o `open`, e `startDestination` é a raiz.** O segundo bloco é o que merece atenção. É
assim que o guia do Android sobre várias pilhas de volta troca de aba: `popUpTo` até a start
destination com `saveState` guarda a pilha da aba atual em vez de jogá-la fora, e `restoreState` traz
de volta a pilha que a outra aba tinha. Sem essas duas opções, toda troca de aba recomeçaria a aba da
raiz, que é o erro que o guia existe para evitar. O voltar do sistema não precisa de código nenhum
aqui; a biblioteca desempilha a própria pilha, e na start destination deixa o sistema levar o app
embora.

## iOS: SwiftUI

```swift
// SwiftUI: a TabView of two tabs, each with a NavigationStack of its own
TabView {
    Tab("Courses", systemImage: "book") {
        NavigationStack {
            CourseList()
                .navigationDestination(for: Course.self) { course in
                    CourseDetail(course: course)
                }
        }
    }
    Tab("Week", systemImage: "calendar") {
        NavigationStack { WeekView() }
    }
}
```

**Dois `NavigationStack` dentro de um `TabView` é a estrutura do planner, escrita por extenso.** Cada
aba tem uma pilha, então trocar mantém as duas. Um `NavigationLink` dentro de `CourseList` empilha um
`Course`, e o modificador de destino diz qual view o desenha. A documentação da Apple sobre
`NavigationStack` diz que a pilha "não permite que a view raiz seja removida" e que o sistema desativa
os controles de voltar quando só a raiz aparece, que é o `backButton` devolvendo `false`. Não há voltar
do sistema para responder.

## React Native: React Navigation

```tsx
// React Navigation: a native stack nested inside each bottom tab
const Tabs = createBottomTabNavigator();
const CoursesStack = createNativeStackNavigator();

function CoursesTab() {
  return (
    <CoursesStack.Navigator>
      <CoursesStack.Screen name="CourseList" component={CourseList} />
      <CoursesStack.Screen name="CourseDetail" component={CourseDetail} />
    </CoursesStack.Navigator>
  );
}

export default function App() {
  return (
    <NavigationContainer>
      <Tabs.Navigator>
        <Tabs.Screen name="Courses" component={CoursesTab} />
        <Tabs.Screen name="Week" component={WeekScreen} />
      </Tabs.Navigator>
    </NavigationContainer>
  );
}
```

**Um navegador de pilha aninhado dentro de um navegador de abas dá a cada aba a própria pilha**, e a
documentação do React Navigation chama isso de aninhamento. O mesmo JavaScript roda nas duas
plataformas, e a biblioteca responde a cada uma do seu jeito: o voltar do sistema do Android desempilha
a pilha aninhada e depois sai, enquanto num iPhone a pilha nativa desenha um botão de voltar e o
deslize da borda. Um segundo toque na aba que já aparece desempilha a pilha aninhada até a primeira
tela; a documentação das abas inferiores lista isso como padrão, em `tabBarRepeatedPressBehavior`.

| | Navigation Compose | SwiftUI | React Navigation |
|---|---|---|---|
| uma pilha | o `NavHost` e o seu `navController` | `NavigationStack` | um navegador de pilha |
| empilhar | `navigate(Course(id))` | um `NavigationLink` | `navigation.navigate("CourseDetail")` |
| abas | uma barra inferior, com estado guardado | `TabView` de `Tab`s | um navegador de abas inferiores |
| a raiz | `startDestination` | a view dentro da pilha | a primeira tela da pilha |

Cada biblioteca ganha uma aula própria depois da bifurcação: Navigation Compose na aula 9 de
`android-apps`, `NavigationStack` na aula 9 de `ios-apps`, e React Navigation na aula 8 de
`react-native`: uma das três, conforme o caminho que você tomar na bifurcação.
