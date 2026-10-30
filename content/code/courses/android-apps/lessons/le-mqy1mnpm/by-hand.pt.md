---
title: Injeção à mão, antes de qualquer biblioteca
version: 1
---

**Injeção de dependência é uma ideia simples com um nome intimidador: uma classe recebe o que precisa
em vez de ir buscar.** O `WeekViewModel` faz isso desde a aula 10, quando recebeu o
`SavedStateHandle` pelo construtor e a seção 07 daquela aula pôde passar um construído a partir de um
mapa. A aula 11 lhe deu um `SessionStore` do mesmo jeito, e foi por isso que o `CancelTest` pôde
entregar a ele um store que leva dez segundos para escrever.

A parte que a aula 11 deixou bagunçada é quem constrói o store. Ela escreveu um `object Stores` com o
único `InMemorySessionStore`, e uma fábrica no companion do ViewModel que ia buscá-lo ali. Funciona, e
não cresce. Uma segunda tela precisa do mesmo store e escreve a própria fábrica; uma terceira precisa
do store, de um relógio e de um cliente de rede; e cada fábrica é uma lista escrita à mão do que
passar, que ninguém confere até uma tela quebrar em tempo de execução com a coisa errada.

A versão arrumada, ainda sem biblioteca, é uma classe que constrói tudo uma vez, num lugar só,
em geral chamada de **contêiner**:

```kotlin
class AppContainer {
    val clock: Clock = Clock.systemDefaultZone()
    val sessions: SessionStore = InMemorySessionStore()
}
```

O `Application` guarda um contêiner, cada activity o pede ao seu `Application`, e cada fábrica de
ViewModel tira dali o que precisa. O próprio guia de arquitetura Android do Google ensina exatamente
isso primeiro, como injeção de dependência manual, e para um app de três telas é o bastante.

**O que ele deixa para você é a fiação.** Cada classe nova é mais uma linha no contêiner, mais um
argumento em alguma fábrica, e mais uma decisão sobre quanto tempo o objeto vive: um por app, um por
tela, um novo a cada vez. Erre a última e duas telas discordam sobre as sessões, porque cada uma
construiu o próprio store.

## O que o Hilt faz no lugar

**O Hilt escreve o contêiner para você, em tempo de compilação, a partir de anotações.** Você marca um
construtor com `@Inject` para dizer "me construa com estes", uma classe com `@Singleton` para dizer
"um por app", e um ViewModel com `@HiltViewModel` para dizer "construa este para uma tela". O Hilt,
construído sobre o Dagger do Google, gera o código que chama esses construtores na ordem certa, e **se
recusa a compilar quando algo não pode ser construído**. Essa última propriedade é o motivo para
usá-lo: o erro que a fábrica escrita à mão comete em tempo de execução vira um erro de build, que a
seção 05 produz de propósito.

O custo é um gerador de código no build, o KSP, e um vocabulário de uma dúzia de anotações. Esta aula
usa nove delas no app e mais três no teste.
